---
name: skill-prismo-dev
description: >
  Development companion for Prismo — a hybrid L2 blockchain on Polygon CDK Erigon zkRollup, deployed on AWS EKS
  with Terraform, Helm, and Kubernetes. Trigger whenever the user mentions Prismo, CDK Erigon, zkRollup, zk-SNARK,
  Polygon CDK, L2 chain development, sequencer, aggregator, prover, bridge service, PRSM token, or any related task.
  Also trigger for: Helm charts in prismo-testnet, Terraform modules (VPC, EKS, RDS, KMS, IAM), Solidity zkEVM
  contract deployment, kubectl on prismo-l1/prismo-l2/prismo-monitoring namespaces, CDK Erigon config, mock prover,
  KMS signing, deployment scripts (00-prerequisites through 99-health-check), Grafana dashboards, Prometheus alerts,
  or architecture questions. Even if the user just says "help me with my L2" or "working on my chain" — use this skill.
---

# Prismo Development Skill

A development companion for building, deploying, operating, and debugging the Prismo L2 blockchain.

## Who this is for

The developer using this skill knows ERC-20 and ERC-721 smart contracts but is new to:
- L2/zkRollup architecture and zero-knowledge proofs
- Infrastructure-as-code (Terraform), Kubernetes, Helm
- The Polygon CDK Erigon stack specifically
- DevOps patterns like IRSA, KMS signing, NetworkPolicies

Always explain new concepts with analogies and connect them back to things the user already knows (Ethereum, tokens, Solidity basics). Avoid assuming familiarity with infrastructure jargon — define terms on first use.

## What is Prismo

Prismo is a **hybrid L2 blockchain** deployed on Ethereum (Sepolia for testnet, mainnet for production) using the **Polygon CDK Erigon zkRollup** stack. Key facts:

- **L2 Chain ID**: `101001000`
- **L1**: Sepolia (chain ID `11155111`)
- **Gas Token**: PRSM (custom ERC-20, not ETH)
- **Rollup type**: zkRollup with zk-SNARK proofs
- **Prover mode**: Mock prover on testnet, real GPU prover for production

The chain uses a **hybrid** model with public and private node elements.

## Architecture Overview

When answering questions about how Prismo works, use this mental model:

```
User tx → RPC (port 8545) → Sequencer (orders & batches)
  → sequence-sender posts batch data to L1
  → Aggregator sends batch to Prover (gRPC port 50071)
  → Prover returns zk-SNARK proof
  → Aggregator signs via AWS KMS and posts proof to L1 zkEVM contracts
  → L1 verifies → state finalized on Ethereum
```

Bridge Service runs independently, handling L1↔L2 asset transfers.

### Component Map

| Component | What it does | K8s Type | Key Detail |
|-----------|-------------|----------|------------|
| **CDK Erigon Sequencer** | Orders txs, creates batches | StatefulSet (1 replica) | 500GB io2, signs via KMS |
| **CDK Erigon RPC** | Serves JSON-RPC to users | Deployment (HPA 2→8) | Same Docker image as Sequencer, different config |
| **Mock Prover** | Generates ZK proofs (mock on testnet) | Deployment | gRPC on port 50071 |
| **Aggregator** | Coordinates proofs, posts to L1 | Deployment | Signs via KMS + IRSA |
| **Bridge Service** | L1↔L2 token transfers | Deployment (2 replicas) | Monitors deposit/withdrawal events |
| **L1 Node** | Self-hosted Sepolia node | StatefulSet | Geth (exec) + Lighthouse (consensus), 2TB PVC |

### Three Kubernetes Namespaces

| Namespace | Contains |
|-----------|----------|
| `prismo-l1` | L1 Ethereum node (Geth + Lighthouse) |
| `prismo-l2` | Sequencer, RPC, Prover, Aggregator, Bridge |
| `prismo-monitoring` | Prometheus, Grafana, Alertmanager |

## Reference Files

This skill has detailed reference files for different domains. **Read the relevant reference before answering domain-specific questions:**

| File | When to read | Covers |
|------|-------------|--------|
| `references/infrastructure.md` | Terraform, AWS, EKS, KMS, IRSA, networking questions | Full infra stack, Terraform modules, security, secrets, storage |
| `references/blockchain.md` | Architecture, CDK Erigon, Prover, Aggregator, Bridge, ZK proofs | All blockchain components, data flow, configuration, smart contracts |
| `references/operations.md` | Deployment, kubectl, Helm, monitoring, troubleshooting | Deployment scripts, day-to-day ops, health checks, alerting, upgrades |

## How to Help

### When the user asks about architecture or "how does X work"
1. Read `references/blockchain.md`
2. Explain using the transaction flow as an anchor
3. Use analogies (the Sequencer is like the sole cashier, RPC nodes are information desks, etc.)
4. Draw ASCII diagrams when helpful

### When the user asks about infrastructure or deployment
1. Read `references/infrastructure.md` and `references/operations.md`
2. Show the specific Terraform module, Helm chart, or script involved
3. Explain what each command does before suggesting they run it
4. Always warn about destructive operations (especially `terraform destroy`)

### When the user asks about smart contracts
1. Read `references/blockchain.md` (contracts section)
2. Connect to what they already know — PRSM is just an ERC-20 with mint+burn, built with OpenZeppelin
3. Explain the zkEVM contracts (RollupManager, Bridge, Global Exit Root) at a high level first

### When the user asks about debugging/troubleshooting
1. Read `references/operations.md` (troubleshooting section)
2. Start with the simplest diagnostic (pod status, logs)
3. Walk through the checklist step by step
4. Explain what each command output means

### When the user asks about ZK proofs or cryptography
- zk-SNARK = **Z**ero-**K**nowledge **S**uccinct **N**on-interactive **AR**gument of **K**nowledge
- Explain it as: "The Prover proves all txs in a batch are valid without revealing their contents. The proof is tiny (few hundred bytes) even for thousands of txs. Anyone can verify it without talking to the Prover."
- On testnet the mock prover skips real proof generation — same API, instant results
- For production: swap the container image to real `zkevm-prover` on GPU nodes

## Repository Structure

The `prismo-testnet/` repo has 7 directories that map to the deploy order:

```
terraform/   → AWS infra (VPC, EKS, RDS, KMS, IAM)
k8s/         → Base K8s manifests (namespaces, network policies, secrets, ingress)
helm/        → One Helm chart per component
contracts/   → Solidity (PRSM.sol + zkEVM contracts via Hardhat)
configs/     → Runtime config (sequencer, aggregator, bridge)
monitoring/  → Prometheus + Grafana + alerts
scripts/     → Numbered deployment scripts (00 through 99)
```

The `.env` file is the glue — Terraform exports ARNs/endpoints → contracts export addresses → configs read from `.env` → Helm uses it for IRSA ARNs.

## Deployment Order

```
00 prerequisites → 01 terraform → 02 EKS bootstrap → 03 L1 node
→ 04 contracts → 05 L2 core → 06 prover pipeline → 07 bridge
→ 08 monitoring → 99 health check
```

Each step depends on the previous. You can't deploy L2 (05) before contracts (04) because L2 needs contract addresses. You can't deploy contracts (04) before L1 (03) because contracts deploy to Sepolia via the L1 node.

## Common Patterns to Teach

When the user encounters these patterns for the first time, explain them:

- **IRSA** (IAM Roles for Service Accounts): Like giving each pod its own AWS badge instead of sharing a master key. If one pod is compromised, the attacker only gets that pod's permissions.
- **KMS signing**: Private keys live in tamper-proof hardware. The Sequencer and Aggregator never touch the raw key — they ask KMS to sign on their behalf.
- **External Secrets Operator**: Secrets live in AWS Secrets Manager (encrypted vault) and auto-sync to Kubernetes. Change the secret in AWS → ESO pushes the update. No plaintext secrets anywhere.
- **NetworkPolicies**: Default-deny firewall. Everything is blocked, then you punch specific holes (e.g., Aggregator can reach Prover on port 50071).
- **StatefulSet vs Deployment**: StatefulSet = named, persistent, ordered (Sequencer needs this). Deployment = disposable, interchangeable (RPC nodes can be killed freely).
- **HPA**: Auto-scales RPC pods from 2 to 8 based on CPU. Like adding more cashiers when the store gets busy.

## Production Readiness Checklist

When discussing going from testnet to production, reference these upgrades:
- Replace mock prover → real `zkevm-prover` on GPU nodes
- Enable RDS Multi-AZ
- Set up Velero for PVC backups
- Add ACM certificate for HTTPS
- Remove `DEPLOYER_PRIVATE_KEY` from `.env`
- Enable WAF + rate limiting on ALB
- Multi-AZ NAT Gateway
- Spot instances for RPC nodes
