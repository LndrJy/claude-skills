# Prismo Operations Reference

## Table of Contents
1. [Deployment Flow](#deployment-flow)
2. [Environment Variables](#environment-variables)
3. [Day-to-Day kubectl Commands](#day-to-day-kubectl-commands)
4. [Helm Chart Operations](#helm-chart-operations)
5. [Monitoring & Alerting](#monitoring--alerting)
6. [Troubleshooting Guide](#troubleshooting-guide)
7. [Maintenance Procedures](#maintenance-procedures)
8. [Production Readiness Checklist](#production-readiness-checklist)

---

## Deployment Flow

10 scripts run in order. Each depends on the previous:

```
00 prerequisites → 01 terraform → 02 EKS bootstrap → 03 L1 node
→ 04 contracts → 05 L2 core → 06 prover pipeline → 07 bridge
→ 08 monitoring → 99 health check
```

### Script Details

**Step 0 — Configure environment**
```bash
cp .env.example .env
# Edit .env — fill in ALL values
```

**Step 1 — Validate prerequisites**
```bash
./scripts/00-prerequisites.sh
```
Checks: 6 CLI tools installed, AWS auth valid, .env variables present, Terraform state bucket exists, Helm repos configured.

**Step 2 — Deploy AWS infrastructure**
```bash
./scripts/01-deploy-terraform.sh
```
Creates VPC, EKS, RDS, KMS, IAM (~15 min). Shows plan for review (type `y`). Exports outputs to `.env`, updates kubeconfig.

**Step 3 — Bootstrap EKS**
```bash
./scripts/02-bootstrap-eks.sh
```
Installs: namespaces, StorageClasses, ALB controller, cert-manager, ESO, NetworkPolicies, IngressClass.

**Step 4 — Deploy L1 Sepolia Node**
```bash
./scripts/03-deploy-l1-node.sh
```
Deploys Geth + Lighthouse StatefulSet. Uses checkpoint sync (~15-30 min). Creates NLB for P2P.

**Step 5 — Deploy Smart Contracts**
```bash
./scripts/04-deploy-contracts.sh
```
Requires `DEPLOYER_PRIVATE_KEY` in .env (funded Sepolia wallet, ~0.1 ETH). Deploys PRSM token + zkEVM contracts. Saves addresses to .env, updates config files.

**Step 6 — Deploy L2 Core**
```bash
./scripts/05-deploy-l2-core.sh
```
Deploys Sequencer (StatefulSet, 1 replica, 500GB io2) + RPC nodes (Deployment, HPA 2→8).

**Step 7 — Deploy Prover Pipeline**
```bash
./scripts/06-deploy-prover-pipeline.sh
```
Deploys Mock Prover + Aggregator. Verifies aggregator → prover connectivity on port 50071.

**Step 8 — Deploy Bridge Service**
```bash
./scripts/07-deploy-bridge.sh
```
Deploys bridge (2 replicas) with ALB ingress at `bridge.<BASE_DOMAIN>`.

**Step 9 — Deploy Monitoring**
```bash
./scripts/08-deploy-monitoring.sh
```
Installs Prometheus (200GB, 30d retention), Grafana (3 dashboards), Alertmanager.

**Step 10 — Health Check**
```bash
./scripts/99-health-check.sh
```
Validates all 8 subsystems: pod health, L1 sync, Sequencer chain ID, RPC replicas, Prover, Aggregator, Bridge, Prometheus targets.

---

## Environment Variables

### AWS & Infrastructure

| Variable | Description | Example |
|----------|-------------|---------|
| `AWS_REGION` | AWS region | `us-east-1` |
| `AWS_ACCOUNT_ID` | AWS account number | `123456789012` |
| `TF_STATE_BUCKET` | S3 bucket for Terraform state | `prismo-testnet-tfstate` |
| `CLUSTER_NAME` | EKS cluster name | `prismo-testnet` |
| `K8S_VERSION` | Kubernetes version | `1.29` |
| `BASE_DOMAIN` | Domain for ALB ingress | `testnet.prismo.xyz` |

### Blockchain

| Variable | Description | Example |
|----------|-------------|---------|
| `L1_RPC_URL` | Sepolia RPC endpoint | `https://sepolia.example.com` |
| `L1_WS_URL` | Sepolia WebSocket endpoint | `wss://sepolia.example.com/ws` |
| `L1_CHAIN_ID` | Sepolia chain ID | `11155111` |
| `L2_CHAIN_ID` | Prismo chain ID | `101001000` |

### Wallet Addresses

| Variable | Description |
|----------|-------------|
| `DEPLOYER_ADDRESS` | Contract deployer wallet |
| `DEPLOYER_PRIVATE_KEY` | Deployer private key (⚠ delete after deployment!) |
| `SEQUENCER_ADDRESS` | Sequencer ETH address (derived from KMS) |
| `AGGREGATOR_ADDRESS` | Aggregator ETH address (derived from KMS) |

### Auto-populated by Scripts

| Variable | Set by |
|----------|--------|
| `RDS_HOST` | `01-deploy-terraform.sh` |
| `SM_SEQUENCER_KEY_ARN` | `01-deploy-terraform.sh` |
| `SM_AGGREGATOR_KEY_ARN` | `01-deploy-terraform.sh` |
| `PRSM_TOKEN_ADDRESS` | `04-deploy-contracts.sh` |
| `POLYGON_ZKEVM_ADDRESS` | `04-deploy-contracts.sh` |
| `POLYGON_ZKEVM_BRIDGE_ADDRESS` | `04-deploy-contracts.sh` |

---

## Day-to-Day kubectl Commands

### View pods

```bash
kubectl get pods -n prismo-l2
kubectl get pods -n prismo-l1
kubectl get pods -n prismo-monitoring
```

### Check logs

```bash
# Sequencer
kubectl logs -f -n prismo-l2 cdk-erigon-sequencer-sequencer-0

# RPC
kubectl logs -f -n prismo-l2 deploy/cdk-erigon-rpc-rpc

# Aggregator
kubectl logs -f -n prismo-l2 deploy/aggregator-aggregator

# Mock Prover
kubectl logs -f -n prismo-l2 deploy/mock-prover-mock-prover

# L1 Geth
kubectl logs -f -n prismo-l1 l1-node-l1-node-0 -c geth

# L1 Lighthouse
kubectl logs -f -n prismo-l1 l1-node-l1-node-0 -c lighthouse
```

### Check scaling & protection

```bash
kubectl get hpa -n prismo-l2          # RPC auto-scaling status
kubectl get pdb -n prismo-l2          # Pod disruption budgets
kubectl get pdb -n prismo-l1
```

### Quick health checks

```bash
# Sequencer storage
kubectl exec -n prismo-l2 cdk-erigon-sequencer-sequencer-0 -- df -h /data

# RPC health
kubectl exec -n prismo-l2 cdk-erigon-sequencer-sequencer-0 -- \
  curl -sf http://localhost:8545 -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Send a test transaction

```bash
# Port-forward RPC
kubectl port-forward -n prismo-l2 svc/cdk-erigon-rpc 8545:8545

# Check chain ID (expect 0x1343a95 = 101001000)
curl -s -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'

# Send test tx (needs funded L2 wallet + cast from Foundry)
cast send --rpc-url http://localhost:8545 \
  --private-key <TEST_PRIVATE_KEY> \
  <RECIPIENT> --value 0.001ether
```

---

## Helm Chart Operations

### Charts (one per component)

```
helm/
├── l1-node/                 ← Geth + Lighthouse StatefulSet
├── cdk-erigon-sequencer/    ← Sequencer StatefulSet with PDB
├── cdk-erigon-rpc/          ← RPC Deployment with HPA
├── mock-prover/             ← Mock prover Deployment
├── aggregator/              ← Aggregator Deployment with IRSA
└── bridge-service/          ← Bridge Deployment with ingress
```

### Chart structure (typical)

```
helm/<component>/
├── Chart.yaml              ← Name, version, description
├── values.yaml             ← Default config (image tag, replicas, resources)
└── templates/
    ├── deployment.yaml (or statefulset.yaml)
    ├── service.yaml
    ├── configmap.yaml
    ├── hpa.yaml             ← (RPC only)
    ├── pdb.yaml             ← (Sequencer, L1 node)
    └── serviceaccount.yaml
```

### Common operations

```bash
# Install
helm install <name> helm/<chart> -n <namespace>

# Upgrade
helm upgrade --install <name> helm/<chart> -n <namespace>

# Example: upgrade sequencer
helm upgrade --install cdk-erigon-sequencer helm/cdk-erigon-sequencer \
  --namespace prismo-l2 \
  --set serviceAccount.roleArn="<SEQUENCER_IRSA_ARN>" \
  --set config.l1RpcUrl="http://l1-node-rpc.prismo-l1.svc.cluster.local:8545" \
  --wait
```

---

## Monitoring & Alerting

### Access

| Service | Access Method |
|---------|-------------|
| Grafana | `https://grafana.<BASE_DOMAIN>` (admin) |
| Prometheus | `kubectl port-forward -n prismo-monitoring svc/kube-prom-kube-prometheus-stack-prometheus 9090:9090` |
| Sequencer metrics | `kubectl port-forward -n prismo-l2 svc/cdk-erigon-sequencer 9091:9091` |

### Dashboards (3 pre-configured)

| Dashboard | Shows |
|-----------|-------|
| Sequencer | Blocks produced, tx throughput, batch rate, gas, CPU/memory |
| L1 Node | Sync status, peers, chain head, block import, disk |
| Prover Pipeline | Proof gen time, aggregator submission rate, proof queue |

### Prometheus Scrape Targets

| Job | Target | Path |
|-----|--------|------|
| cdk-erigon-sequencer | :9091 | /metrics |
| cdk-erigon-rpc | :9091 | /metrics |
| aggregator | :9091 | /metrics |
| l1-node-geth | :6060 | /debug/metrics/prometheus |
| bridge-service | :9090 | /metrics |

### Alert Rules

**Blockchain** (`monitoring/alert-rules/blockchain.yaml`):
- Sequencer not producing blocks
- Proof submission delays
- Bridge deposit/withdrawal stuck
- Chain ID mismatch

**Infrastructure** (`monitoring/alert-rules/infrastructure.yaml`):
- Disk usage > 80%
- Pod restart loops (CrashLoopBackOff)
- High CPU on sequencer
- Node not ready
- PVC running out of space

### Alertmanager Routing

Alerts grouped by `[alertname, namespace]`. Destinations:
- Email: `ops@prismo.xyz` (configurable in .env)
- Slack: Optional, set `SLACK_WEBHOOK_URL` in .env

---

## Troubleshooting Guide

### Sequencer not producing blocks

```bash
# 1. Check pod status
kubectl get pod -n prismo-l2 -l app.kubernetes.io/name=cdk-erigon-sequencer

# 2. Check logs
kubectl logs -n prismo-l2 cdk-erigon-sequencer-sequencer-0 --tail=100

# 3. Common causes:
#    - L1 node not synced → check L1 pod logs
#    - KMS access denied → check IRSA role and KMS key policy
#    - DB connection failed → check RDS endpoint and credentials
#    - Incorrect contract addresses → verify .env and configs/
```

### L1 node stuck syncing

```bash
# Check Geth sync status
kubectl exec -n prismo-l1 l1-node-l1-node-0 -c geth -- \
  geth attach --exec 'eth.syncing' /data/geth/geth.ipc

# Check Lighthouse status
kubectl exec -n prismo-l1 l1-node-l1-node-0 -c lighthouse -- \
  curl -s http://localhost:5052/eth/v1/node/syncing | jq .

# If stuck, try restarting with fresh checkpoint sync
kubectl delete pod l1-node-l1-node-0 -n prismo-l1
```

### Aggregator can't reach mock prover

```bash
# 1. Verify mock prover is running
kubectl get pods -n prismo-l2 -l app.kubernetes.io/name=mock-prover

# 2. Test gRPC connectivity
kubectl exec -n prismo-l2 deploy/aggregator-aggregator -- \
  nc -zv mock-prover 50071

# 3. Check NetworkPolicy allows traffic
kubectl get networkpolicy -n prismo-l2 -o yaml | grep -A5 mock-prover
```

### Bridge service unhealthy

```bash
# Check health endpoint
kubectl exec -n prismo-l2 deploy/bridge-service-bridge -- \
  curl -s http://localhost:8080/healthz | jq .

# Check logs
kubectl logs -n prismo-l2 deploy/bridge-service-bridge --tail=50

# Common cause: DB not accessible → verify External Secrets synced
kubectl get externalsecret -n prismo-l2
```

### Pods in CrashLoopBackOff

```bash
# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check previous container logs
kubectl logs <pod-name> -n <namespace> --previous

# Common causes:
#   - Missing environment variables
#   - Wrong config (check ConfigMaps)
#   - Resource limits too low (OOMKilled)
#   - Image pull errors (check image tag)
```

### External Secrets not syncing

```bash
# Check ClusterSecretStore
kubectl get clustersecretstore -o yaml

# Check individual ExternalSecret
kubectl get externalsecret -n prismo-l2 -o yaml

# Verify IRSA role for ESO
kubectl describe sa external-secrets -n external-secrets
# Look for: eks.amazonaws.com/role-arn annotation
```

---

## Maintenance Procedures

### Restarting components

```bash
# Sequencer (StatefulSet — keeps PVC data)
kubectl rollout restart statefulset/cdk-erigon-sequencer-sequencer -n prismo-l2

# RPC pods (all replicas restart)
kubectl rollout restart deployment/cdk-erigon-rpc-rpc -n prismo-l2

# Aggregator
kubectl rollout restart deployment/aggregator-aggregator -n prismo-l2

# L1 node (⚠ may trigger re-sync if interrupted badly)
kubectl rollout restart statefulset/l1-node-l1-node -n prismo-l1
```

### Scaling RPC manually

```bash
# Override to 4 replicas
kubectl scale deployment cdk-erigon-rpc-rpc -n prismo-l2 --replicas=4

# Or update HPA limits
kubectl patch hpa cdk-erigon-rpc-hpa -n prismo-l2 \
  --type merge -p '{"spec":{"minReplicas":3,"maxReplicas":10}}'
```

### Upgrading a component

1. Edit `helm/<component>/values.yaml` → change image tag
2. Re-deploy via script or:
```bash
helm upgrade --install <release> helm/<chart> --namespace <ns> --wait
```

### Database maintenance

- **RDS backups**: Daily, 7-day retention (03:00-04:00 UTC)
- **Maintenance window**: Sundays 04:00-05:00 UTC
- **Connect for debugging**:
```bash
aws secretsmanager get-secret-value \
  --secret-id /prismo-testnet/rds/credentials \
  --query SecretString --output text | jq .

kubectl run pg-debug --rm -it --image=postgres:15 -n prismo-l2 -- \
  psql "host=<RDS_HOST> dbname=prismo_l2 user=prismo_admin password=<password>"
```

### Key rotation

- **KMS keys** (secp256k1): Manual — create new key, update IRSA, redeploy, update L1 contract config
- **RDS password**: Rotate in Secrets Manager → ESO auto-syncs
- **Grafana password**: Stored in Secrets Manager at `<CLUSTER_NAME>/grafana/admin`

### EBS volume expansion

```bash
kubectl exec -n prismo-l1 l1-node-l1-node-0 -c geth -- df -h /data

kubectl patch pvc data-l1-node-l1-node-0 -n prismo-l1 \
  --type merge -p '{"spec":{"resources":{"requests":{"storage":"3Ti"}}}}'
```

---

## Production Readiness Checklist

Before going from testnet to production:

- [ ] Replace mock prover → real `zkevm-prover` on GPU nodes
- [ ] Enable RDS Multi-AZ (`multi_az = true` in terraform/modules/rds/main.tf)
- [ ] Set up Velero for PVC snapshot backups
- [ ] Add ACM certificate (set `ACM_ARN` in .env for HTTPS)
- [ ] Remove `DEPLOYER_PRIVATE_KEY` from .env
- [ ] Enable WAF on ALB (protect public RPC)
- [ ] Rate limiting on ALB/Nginx for public endpoints
- [ ] Multi-AZ NAT Gateway
- [ ] Spot instances for RPC nodes
- [ ] Enable RDS Performance Insights (review in AWS Console)
- [ ] Review security groups (tighten IP ranges)
- [ ] Set up log aggregation (deploy Loki)
