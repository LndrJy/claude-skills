# Prismo Blockchain Reference

## Table of Contents
1. [CDK Erigon zkRollup Architecture](#cdk-erigon-zkrollup-architecture)
2. [Three CDK Deployment Modes](#three-cdk-deployment-modes)
3. [Component Deep Dive](#component-deep-dive)
4. [Transaction Lifecycle](#transaction-lifecycle)
5. [Smart Contracts](#smart-contracts)
6. [Docker Images](#docker-images)
7. [Configuration Files](#configuration-files)
8. [Zero-Knowledge Proofs Explained](#zero-knowledge-proofs-explained)
9. [Glossary](#glossary)

---

## CDK Erigon zkRollup Architecture

Prismo is an L2 built with Polygon's Chain Development Kit (CDK) using the Erigon execution client in zkRollup mode. The architecture has two main layers:

**CDK-Erigon (L2 Node)** — receives user transactions, orders them, creates batches:
- RPC: receives user txs via JSON-RPC (port 8545)
- Sequencer: orders and batches transactions
- tx-pool-manager: manages pending txs between RPC and Sequencer

**cdk-node** — handles L1 settlement and proof coordination:
- sequence-sender: sends batched sequences to L1 contracts
- aggregator: coordinates proof generation with the Prover
- cli: command-line dev tool

**External components:**
- Prover: generates zk-SNARK proofs
- Agglayer: submits final proof to L1, handles cross-chain interop
- L1 zkEVM Contracts: verify proofs and settle state on Ethereum

```
                        User / dApp
                            │
                            ▼
┌─────────── CDK-Erigon (L2 Node) ───────────────┐
│  [RPC] ←── syncs ──→ [Sequencer]                │
│  receives user txs     orders & batches txs      │
│       │                     │                    │
│       ▼                     ▼                    │
│            [tx-pool-manager]                      │
└────────────────────┬─────────────────────────────┘
                     │ batches
                     ▼
┌─────────── cdk-node ────────────────────────────┐
│  [sequence-sender]              [aggregator]      │
│  sends batches to L1            coordinates       │
│  contracts                      with Prover       │
└────────┬────────────────────────────┬────────────┘
         │                            │
         │                            ▼
         │                       [Prover]
         │                       generates ZK proofs
         │                            │
         ▼                            ▼
   ┌─────────────┐            ┌──────────────┐
   │ L1 zkEVM    │ ◄────     │  Agglayer    │
   │ Contracts   │            │  submits     │
   │ (verify &   │            │  final proof │
   │  settle)    │            └──────────────┘
   └─────────────┘
```

---

## Three CDK Deployment Modes

Prismo uses **zkRollup** — the most secure option:

| Mode | Data Availability | Proof Type | Security |
|------|-------------------|------------|----------|
| Sovereign | Pessimistic proofs | No full zk-SNARK | Lightest, least secure |
| Validium | Off-chain (DAC nodes) | zk-SNARK | Cheaper, data stored off-chain |
| **zkRollup** | **On-chain (Ethereum L1)** | **zk-SNARK** | **Full security — Prismo uses this** |

Why zkRollup specifically:
- All transaction data posted **on-chain to Ethereum** (full data availability)
- Validity proofs (zk-SNARKs) guarantee correctness — no trust needed
- Inherits **Ethereum's security** at L2 speed and cost

---

## Component Deep Dive

### CDK Erigon Sequencer

The single source of truth for transaction ordering. Runs as a StatefulSet (exactly 1 replica).

- **What it does**: Receives transactions from the tx-pool, decides their order, groups them into batches, writes to PostgreSQL (RDS)
- **Why only one**: Two sequencers = two traffic controllers at the same intersection = chaos. Transaction ordering must be deterministic.
- **Storage**: 500GB io2 EBS (16,000 IOPS) — writes constantly
- **Signing**: Uses AWS KMS via IRSA — private key never leaves hardware
- **Docker image**: `hermeznetwork/cdk-erigon:2.0.0`

### CDK Erigon RPC Nodes

Read-only mirrors of the Sequencer's state. Serve user queries.

- **What they do**: Answer JSON-RPC calls (check balance, get block, etc.). When they get a write-transaction, they forward it to the Sequencer.
- **Scaling**: HPA scales from 2 to 8 replicas based on CPU
- **Key insight**: Same Docker image as Sequencer (`hermeznetwork/cdk-erigon:2.0.0`). The difference is **configuration** — Sequencer gets write permissions, RPC gets read-only.
- **Port**: 8545 (standard Ethereum JSON-RPC)

### Mock Prover

Generates ZK proofs. On testnet, this is a mock that returns instant "proofs."

- **How it works**: Receives batches from the Aggregator via gRPC (port 50071), returns a proof
- **Testnet**: Mock prover fakes it instantly — no GPU needed
- **Production**: Swap container image to real `zkevm-prover` on GPU nodes. Real proofs take minutes of heavy computation. Zero code changes needed — same gRPC API.
- **Analogy**: Practice exam with answer key vs. real exam — same format, different difficulty

### Aggregator

The coordinator between the Prover and L1.

- **What it does**: Requests proofs from the Prover, then posts them to L1 zkEVM contracts
- **Signing**: Via AWS KMS (hardware-backed, IRSA-scoped)
- **Communication**: gRPC to Prover (port 50071), JSON-RPC to L1 node (port 8545)

### Bridge Service

Enables asset transfers between L1 (Sepolia) and L2 (Prismo).

- **How it works**: Monitors deposit/withdrawal events on both chains
- **Replicas**: 2 (for availability)
- **Health endpoint**: `/healthz` on port 8080
- **What users do with it**: Move PRSM tokens between L1 and L2

### L1 Node (Self-Hosted Sepolia)

A full Ethereum Sepolia node running in the `prismo-l1` namespace.

Two containers in one pod:
- **Geth** (`ethereum/client-go:v1.13.14`): Execution client — processes transactions, stores state
- **Lighthouse** (`sigp/lighthouse:v5.1.3`): Consensus client — handles proof-of-stake / beacon chain

**Why self-hosted?** Managed RPC services (Infura, Alchemy) rate-limit at ~100 req/s. The Sequencer needs thousands/sec. Self-hosting = unlimited requests.

**Why two containers?** Since Ethereum's Merge (Sept 2022), you need both an execution client and a consensus client. They're two halves of one brain.

- **Storage**: 2TB shared EBS PVC
- **P2P ports**: Geth 30303, Lighthouse 9000 (exposed via NLB)
- **Internal RPC**: `http://l1-node-rpc.prismo-l1.svc.cluster.local:8545`
- **Sync**: Uses checkpoint sync (~15-30 minutes)

---

## Transaction Lifecycle

The complete journey of a transaction through Prismo:

**Step 1 — User sends transaction**
User/dApp calls RPC endpoint via JSON-RPC on port 8545 (MetaMask, ethers.js, Hardhat all use this).

**Step 2 — RPC forwards to Sequencer**
RPC nodes are read-heavy. Write transactions get forwarded to the Sequencer — the only component allowed to write.

**Step 3 — Sequencer orders and batches**
Sequencer decides order, groups txs into batches, writes to PostgreSQL (RDS). Batching is essential — posting one tx at a time to L1 would be insanely expensive.

**Step 4 — Aggregator sends batch to Prover**
Aggregator sends the batch to Mock Prover via gRPC (port 50071). Prover's job: generate a proof that all txs in this batch are valid.

**Step 5 — Prover returns proof**
Proof comes back to the Aggregator. It now holds: batch data + validity proof.

**Step 6 — Aggregator posts proof to L1**
Aggregator calls AWS KMS to sign the Ethereum transaction, then submits to L1 zkEVM contracts on Sepolia.

**Step 7 — L1 verifies, state finalized**
L1 smart contracts check the proof. If valid → L2 state is finalized on Ethereum (settlement). Nobody can dispute it.

**Meanwhile**: Bridge Service runs independently, watching for deposit/withdrawal events on both chains.

---

## Smart Contracts

### PRSM Token (`contracts/src/PRSM.sol`)

A standard ERC-20 with mint and burn capabilities:

```solidity
contract PRSM is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 initialSupply) ERC20("Prismo Token", "PRSM") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * (10 ** 18));
    }
    function mint(address to, uint256 amount) external onlyOwner { ... }
}
```

- **ERC20**: Standard token interface (this is familiar territory)
- **ERC20Burnable**: Token holders can destroy their tokens
- **Ownable**: Only deployer can mint new tokens
- **Initial supply**: 1 billion PRSM (18 decimals)

### Polygon zkEVM Contracts

Deployed to Sepolia L1 by `deploy-zkevm-contracts.js`:
- **RollupManager**: Manages the L2 rollup lifecycle
- **Bridge**: Handles cross-chain asset locking/unlocking
- **Global Exit Root**: Tracks cross-chain state commitments

### Deployment Tooling

| Tool | Version | Purpose |
|------|---------|---------|
| Hardhat | latest | Solidity development framework |
| Solidity | 0.8.24 | Smart contract language (optimizer: 200 runs) |
| OpenZeppelin | v5 | Battle-tested token standards |
| Polygon zkEVM contracts | v5 | Rollup infrastructure contracts |
| ethers.js | v6 | Ethereum interaction library |

### Contract Address Flow

```
04-deploy-contracts.sh
  → deploys PRSM.sol → captures PRSM_TOKEN_ADDRESS → .env
  → deploys zkEVM contracts → captures addresses → .env
  → updates configs/cdk-erigon/config.yaml
  → updates configs/aggregator/config.toml
  → updates configs/bridge/config.toml
```

---

## Docker Images

| Component | Image | Tag |
|-----------|-------|-----|
| Geth (L1) | `ethereum/client-go` | `v1.13.14` |
| Lighthouse (L1) | `sigp/lighthouse` | `v5.1.3` |
| CDK Erigon (Seq + RPC) | `hermeznetwork/cdk-erigon` | `2.0.0` |
| Mock Prover | zkevm-prover (mock mode) | — |
| Aggregator | zkevm-node | — |
| Bridge | zkevm-bridge-service | — |

Image pull policy: `IfNotPresent` — Kubernetes only pulls if not cached. Since we pin specific tags, we know exactly what version runs.

To update an image: edit `helm/<component>/values.yaml` → change tag → re-deploy via script or `helm upgrade`.

---

## Configuration Files

```
configs/
├── cdk-erigon/config.yaml   ← Sequencer + RPC: chain ID, L1 contracts, gas params
├── aggregator/config.toml   ← Proof intervals, DB, KMS key, L1 contracts
└── bridge/config.toml       ← L1/L2 RPC endpoints, bridge contracts, DB
```

These are updated by deployment scripts (especially `04-deploy-contracts.sh`) when contract addresses are known. Mounted into pods as ConfigMaps.

---

## Zero-Knowledge Proofs Explained

### What is Zero Knowledge (ZK)?

A cryptographic method where one party (the Prover) can prove to another party (the Verifier) that a statement is true — **without revealing any information** beyond the truth of the statement.

In Prismo: the Prover proves "all transactions in this batch are valid" to Ethereum, without Ethereum needing to re-execute every transaction.

### What is a zk-SNARK?

**Z**ero-**K**nowledge **S**uccinct **N**on-interactive **AR**gument of **K**nowledge:

- **Zero-Knowledge**: Proves something without revealing the data
- **Succinct**: The proof is tiny (few hundred bytes) even for thousands of transactions
- **Non-interactive**: Prover generates once, anyone can verify — no back-and-forth
- **Argument of Knowledge**: The Prover must actually know the valid data (can't fake it)

### Why this matters for Prismo

L1 (Ethereum) just checks a small proof instead of replaying thousands of transactions. Many L2 transactions settle with a single proof. Users get fast, cheap transactions on L2, backed by Ethereum's security.

---

## Glossary

| Term | Meaning |
|------|---------|
| L1 | Layer 1 — Ethereum mainnet/Sepolia (base layer) |
| L2 | Layer 2 — Prismo chain, built on top of L1 |
| zkRollup | Rollup using ZK proofs to validate batches |
| CDK | Chain Development Kit — Polygon's L2 builder toolkit |
| Erigon | Performance-optimized Ethereum execution client |
| Sequencer | Orders and batches transactions (single authority) |
| Agglayer | Cross-chain interop and final proof submission |
| Hybrid Chain | Blockchain combining public and private elements |
| FEP | Full Execution Proofs |
| tx-pool-manager | Manages pending txs between RPC and Sequencer |
| sequence-sender | Sends batched sequences to L1 contracts |
| aggregator | Coordinates proof generation with the Prover |
| cdk-node | Package containing cli, sequence-sender, aggregator |
| DAC | Data Availability Committee (Validium mode only, not zkRollup) |
| gRPC | Fast binary protocol for Aggregator ↔ Prover (port 50071) |
