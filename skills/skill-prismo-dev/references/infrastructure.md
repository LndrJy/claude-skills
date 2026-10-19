# Prismo Infrastructure Reference

## Table of Contents
1. [Cloud Stack Overview](#cloud-stack-overview)
2. [Terraform Modules](#terraform-modules)
3. [Kubernetes (EKS)](#kubernetes-eks)
4. [Security Architecture](#security-architecture)
5. [Storage Architecture](#storage-architecture)
6. [Networking](#networking)
7. [Cost Overview](#cost-overview)

---

## Cloud Stack Overview

Everything runs on AWS. The infrastructure layers:

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Cloud Provider | **AWS** | All infrastructure |
| IaC | **Terraform ≥ 1.6** | VPC, EKS, RDS, KMS, IAM as code |
| Container Orchestration | **Kubernetes (EKS) v1.29** | Runs all workloads |
| Package Management | **Helm ≥ 3.14** | Deploys apps to K8s via charts |
| Secrets | **AWS Secrets Manager + ESO** | Stores and syncs credentials |
| Key Management | **AWS KMS (secp256k1)** | Hardware signing for sequencer/aggregator |
| Database | **RDS PostgreSQL 15** | L2 chain state |
| Storage | **EBS gp3/io2** | Persistent volumes |
| Load Balancing | **ALB + NLB** | HTTPS ingress + L1 P2P traffic |
| TLS/Certs | **cert-manager** | Automated certificate management |

### Required CLI Tools

| Tool | Min Version | Purpose |
|------|------------|---------|
| AWS CLI | ≥ 2.15 | AWS operations (EKS, KMS, Secrets Manager, S3, IAM) |
| kubectl | ≥ 1.29 | Kubernetes management |
| Helm | ≥ 3.14 | Chart-based deployments |
| Terraform | ≥ 1.6 | Infrastructure as code |
| Node.js | ≥ 20 | Hardhat contract deployment |
| jq | any | JSON parsing in scripts |

Check versions:
```bash
aws --version && kubectl version && helm version && terraform version && node --version && jq --version
```

---

## Terraform Modules

The `terraform/` directory defines all AWS resources:

```
terraform/
├── main.tf          ← Root module, wires all child modules
├── variables.tf     ← Input variables with defaults
├── outputs.tf       ← Exported values (ARNs, endpoints) → .env
├── providers.tf     ← AWS, K8s, Helm providers + S3 backend
├── testnet.tfvars   ← Testnet-specific overrides
└── modules/
    ├── vpc/         ← VPC (10.0.0.0/16), 3 AZs, subnets, NAT, security groups
    ├── eks/         ← EKS v1.29, OIDC for IRSA, EBS CSI driver
    ├── rds/         ← PostgreSQL 15, Secrets Manager integration
    ├── kms/         ← 3 secp256k1 signing keys + 1 symmetric key
    └── iam/         ← IRSA roles per workload
```

### What Terraform creates (~15 minutes)

| Resource | Details |
|----------|---------|
| VPC | `10.0.0.0/16`, 3 AZs, public + private subnets, NAT gateway |
| EKS | K8s v1.29, OIDC provider for IRSA, EBS CSI driver |
| Node Group | 2× `m6i.2xlarge` (8 vCPU, 32 GiB), scalable to 6 |
| RDS | PostgreSQL 15 `db.r6g.large`, 100GB gp3, encrypted, single-AZ |
| KMS | 3 secp256k1 keys (sequencer, aggregator, sender) + 1 symmetric |
| IAM | IRSA roles for sequencer, aggregator, bridge, External Secrets |
| Security Groups | Separate SGs for sequencer, RPC, DB, L1 node, ALB |

### Terraform state

State is stored in S3 so multiple developers/CI can share it. The prerequisites script (`00-prerequisites.sh`) creates the bucket if it doesn't exist.

### Terraform commands

```bash
cd terraform/
terraform plan -var-file=testnet.tfvars     # Preview changes
terraform apply -var-file=testnet.tfvars    # Apply changes
# ⚠ NEVER run terraform destroy on production
```

---

## Kubernetes (EKS)

### Namespaces

| Namespace | Security Level | Contents |
|-----------|---------------|----------|
| `prismo-l1` | restricted | L1 node (Geth + Lighthouse) |
| `prismo-l2` | restricted | Sequencer, RPC, Prover, Aggregator, Bridge |
| `prismo-monitoring` | standard | Prometheus, Grafana, Alertmanager |
| `kube-system` | standard | ALB controller, EBS CSI, CoreDNS |
| `cert-manager` | standard | TLS certificate automation |
| `external-secrets` | standard | External Secrets Operator |

The `restricted` Pod Security Standard enforces: no privilege escalation, no host networking, no root containers, read-only root filesystem.

### Workload Types

**StatefulSets** (stable identity, persistent storage):
- Sequencer (1 replica, 500GB io2)
- L1 Node (1 replica, 2TB gp3)

**Deployments** (stateless, scalable):
- RPC nodes (HPA 2→8 based on CPU)
- Mock Prover
- Aggregator
- Bridge Service (2 replicas)

### EKS Bootstrap Components

Installed by `02-bootstrap-eks.sh`:
- Namespaces (prismo-l1, prismo-l2, prismo-monitoring)
- StorageClasses (`gp3-ebs` default, `gp3-ebs-io2` for sequencer)
- AWS Load Balancer Controller (ALB/NLB from K8s)
- cert-manager (TLS)
- External Secrets Operator (AWS Secrets Manager → K8s)
- NetworkPolicies (default-deny)
- IngressClass (ALB as default)

---

## Security Architecture

### IRSA (IAM Roles for Service Accounts)

Each pod gets its own AWS identity with minimal permissions:
- Sequencer → `kms:Sign` on its own KMS key only
- Aggregator → `kms:Sign` on its own KMS key only
- ESO → `secretsmanager:GetSecretValue` on Prismo secrets only

If one pod is compromised, the attacker only gets that pod's narrow permissions.

### KMS Signing

3 secp256k1 asymmetric keys in AWS KMS (hardware-backed):
- Sequencer key
- Aggregator key
- Sequence-sender key

Private keys never leave tamper-proof hardware. Pods call `kms:Sign` to sign Ethereum transactions.

Key rotation for asymmetric keys is manual: create new key → update IRSA policies → redeploy → update L1 contract config.

### External Secrets Operator (ESO)

```
AWS Secrets Manager → ESO syncs → K8s Secrets → mounted as env vars/volumes in pods
```

No plaintext secrets in K8s etcd. Rotate in AWS → ESO auto-pushes.

### NetworkPolicies

Default-deny all traffic. Explicit allows:
- L1 node → internet (P2P: 30303, 9000)
- Sequencer → L1 node RPC (8545)
- RPC → Sequencer (8545)
- Aggregator → Mock Prover (gRPC 50071)
- Aggregator → L1 node RPC (8545)
- Bridge → L1 node + L2 RPC
- Prometheus → all metrics ports (9091, 6060, 9090)
- ALB → RPC (8545), Bridge (8080), Grafana (3000)

---

## Storage Architecture

| Workload | StorageClass | Size | Type |
|----------|-------------|------|------|
| L1 node | `gp3-ebs` | 2 TiB | Shared PVC, Retain policy |
| Sequencer | `gp3-ebs-io2` | 500 GiB | High IOPS (16,000), Retain |
| Prometheus | `gp3-ebs` | 200 GiB | Metrics |
| Grafana | `gp3-ebs` | 10 GiB | Dashboards |
| Alertmanager | `gp3-ebs` | 5 GiB | Alert state |

All volumes encrypted at rest. StorageClasses have `allowVolumeExpansion: true`.

EBS expansion:
```bash
kubectl patch pvc <pvc-name> -n <namespace> \
  --type merge -p '{"spec":{"resources":{"requests":{"storage":"3Ti"}}}}'
```

---

## Networking

### Load Balancers

| Type | Purpose | Target |
|------|---------|--------|
| ALB | HTTPS ingress for public services | RPC, Bridge, Grafana |
| NLB | L1 P2P peer discovery | Geth (30303), Lighthouse (9000) |

### Endpoints

| Service | URL |
|---------|-----|
| RPC | `https://rpc.<BASE_DOMAIN>` |
| Bridge | `https://bridge.<BASE_DOMAIN>` |
| Grafana | `https://grafana.<BASE_DOMAIN>` |

### Internal service discovery

Within the cluster, services find each other via K8s DNS:
- L1 RPC: `http://l1-node-rpc.prismo-l1.svc.cluster.local:8545`
- Sequencer: `http://cdk-erigon-sequencer.prismo-l2.svc.cluster.local:8545`

---

## Cost Overview

Monthly testnet estimate (us-east-1):

| Resource | Config | Est. Monthly |
|----------|--------|-------------|
| EKS cluster | Control plane | $73 |
| EC2 nodes | 2× m6i.2xlarge | $280 |
| RDS | db.r6g.large single-AZ | $130 |
| EBS volumes | ~3TB gp3/io2 | $250 |
| NAT Gateway | 1 AZ | $35 |
| NLB | 1× | $18 |
| ALB | 1× | $18 |
| **Total** | | **~$804/mo** |

### Cost reduction

- Spot instances for RPC nodes (stateless)
- Scheduled scale-down during off-hours
- gp3 instead of io2 if sequencer IOPS aren't critical
- Reduce Prometheus retention (30d → 14d)
- Single RPC replica during low traffic
