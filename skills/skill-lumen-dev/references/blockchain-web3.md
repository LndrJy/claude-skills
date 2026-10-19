# Blockchain & Web3 Reference

## Blockchain Overview

| Property | Mainnet (PROD) | Testnet (DEV/TEST/STAGING) |
|----------|---------------|---------------------------|
| **Network** | Polygon | Polygon Amoy |
| **Chain ID** | 137 | 80002 |
| **RPC (HTTPS)** | `https://polygon-mainnet.infura.io/v3/{key}` | `https://polygon-amoy.infura.io/v3/{key}` |
| **RPC (WSS)** | `wss://polygon-mainnet.infura.io/ws/v3/{key}` | `wss://polygon-amoy.infura.io/ws/v3/{key}` |
| **Explorer** | `https://polygonscan.com/` | `https://amoy.polygonscan.com/` |

**Toggle**: `IS_MAINNET = LUMEN_SERVER_MODE === 'PROD'` in `src/web3/Config.ts`

## Web3 Config (`src/web3/Config.ts`)

```typescript
export const IS_MAINNET = LUMEN_SERVER_MODE === 'PROD';
export const ETHEREUM_NETWORK = "EVM";
export const ETHERSCAN_V2_API_URL = 'https://api.etherscan.io/v2/api';
export const LUMEN_CONTRACT_ADDRESS = process.env.LUMEN_CONTRACT_ADDRESS || '';
```

RPC URLs are constructed using `INFURA_API_KEY_ID` env var.

## Smart Contract Architecture

### Proxy Pattern (TransparentUpgradeableProxy)

All contracts use OpenZeppelin's **TransparentUpgradeableProxy** with EIP-1967 storage slots:

```
Implementation Slot: 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc
Admin Slot:          0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
```

**How it works**:
1. **Proxy contract** — permanent address, holds state, delegates all calls to implementation
2. **Implementation contract** — contains logic, can be swapped via upgrade
3. **ProxyAdmin** — only address authorized to upgrade the implementation

Think of it like a phone number (proxy) that forwards to different offices (implementations). The number stays the same, but the office behind it can change.

### Deployment Flow
```
1. Deploy implementation contract (ERC721Files, Organization, etc.)
2. Wait for confirmation
3. Deploy TransparentUpgradeableProxy pointing to implementation
4. Proxy becomes the public-facing address
5. All interactions go through proxy → delegatecall → implementation
```

### Upgrade Flow
```
1. Deploy new implementation contract
2. Call ProxyAdmin.upgrade(proxyAddress, newImplementationAddress)
3. Proxy now delegates to new implementation
4. State is preserved (stored in proxy, not implementation)
```

## Contract Catalog (`src/web3/contracts/artifacts/`)

| Contract | ABI File | Purpose |
|----------|----------|---------|
| **Lumen** | `Lumen.json` | Master platform contract — registry of organizations |
| **Organization** | `Organization.json` | Per-org factory contract — manages collections |
| **ERC721Files** | `ERC721Files.json` | NFT representing files — 49 functions, 34 events, policy enforcement hooks |
| **ActionPolicy** | `ActionPolicy.json` | Base policy interface for access control |
| **TimeBoundPolicy** | `TimeBoundPolicy.json` | Time-window restrictions (start/end timestamps) |
| **CounterBoundPolicy** | `CounterBoundPolicy.json` | Usage-count limits (max N operations) |
| **RoleBoundPolicy** | `RoleBoundPolicy.json` | Role-based access (admin, minter, viewer) |
| **StateBoundPolicy** | `StateBoundPolicy.json` | State-dependent rules (locked, unlocked, etc.) |
| **TransparentUpgradeableProxy** | `TransparentUpgradeableProxy.json` | OpenZeppelin proxy |
| **ProxyAdmin** | `ProxyAdmin.json` | Proxy upgrade authority |

## Contract Deployer (`src/web3/contracts/deployer/`)

### Base Class (`SmartContract.ts`)
```typescript
abstract class SmartContract {
  txTimeoutMS: number = 60000;
  provider: ethers.JsonRpcProvider;
  signer: ethers.Wallet;
  abi: ethers.Interface | ethers.InterfaceAbi;

  static async ENSURE_TRANSACTION(tx)        // Verify tx success
  static async GET_TX_TIMESTAMP(receipt)      // Extract block timestamp
  static async AWAIT_WITH_TIMEOUT(tx, 180000) // Wait with timeout
}
```

### Deployment Classes

1. **ProxyAdminContractDeployer** — Deploys ProxyAdmin contract
   - `deployAndWait()` — Deploy + wait for confirmation

2. **UpgradeableContractDeployer** — Manages proxy deployments
   - `deploy()` — Deploy proxy with implementation
   - `deployAndWait()` — Deploy + wait
   - `IS_PROXY_CONTRACT(address)` — Check if address is a proxy
   - `EMPTY_INITIALIZATION_DATA()` — Generate empty init calldata

3. **SmartContractDeployer** (abstract) — Domain-specific deployers extend this
   - `deployUpgradableContractAndWait()` — Full deployment: implementation + proxy
   - Returns `IDeployedUpgradableContract`: implementation address, proxy address, tx hash

### Specific Deployers
- `Organization.ts` — Deploys Organization contracts per org
- `ERC721Files.ts` — Deploys ERC721Files NFT collections

## Contract Upgrader (`src/web3/contracts/upgrader/`)

**File**: `SmartContract.ts` (755 lines)

Handles upgrading implementation contracts behind existing proxies:
1. Deploy new implementation
2. Call `ProxyAdmin.upgrade()` or `ProxyAdmin.upgradeAndCall()` on the proxy
3. Verify new implementation address matches expected
4. Record upgrade history in Cosmos DB (`UpgradeContractHistory` on Contracts document)

## Contract Events (`src/web3/contracts/events/`)

| File | Purpose |
|------|---------|
| `BlockchainEngine.ts` | Main event listener — syncs on-chain events to Cosmos DB |
| `Deployment.ts` | Listens for contract deployment events |
| `ERC721.ts` | ERC721 transfer, mint, burn events |
| `WebhookEventHandler.ts` | Relays on-chain events to webhook subscribers (15KB) |

**Event Flow**:
```
On-chain event emitted
    → BlockchainEngine listener catches it
    → Stores in EventLogs / NFTLogs container
    → WebhookEventHandler checks for matching webhook subscriptions
    → Delivers to subscribed webhook URLs with Ed25519 signature
```

## Contract Verification (`src/web3/contracts/verification/`)

**File**: `PolygonscanVerifier.ts` (220 lines)

Uses **Etherscan V2 API** (`https://api.etherscan.io/v2/api`) for source code verification:
- Supports both Polygon mainnet and Amoy
- Submits source code + compiler settings
- Polls for verification result
- Requires `ETHERSCAN_API_KEY` env var

## NFT Minting Flow

```
1. Organization creates a Collection (folder with SmartContract)
   → Deploys ERC721Files proxy via deployer

2. Admin/Developer creates a File (DirectoryItem with type='file')
   → File metadata stored in Cosmos DB (DirectoryItems container)
   → File content uploaded to Azure Blob Storage

3. Mint NFT for the file
   → Calls ERC721Files.mint(ownerAddress, tokenURI)
   → tokenURI points to IPFS metadata (via Infura or Pinata)
   → NFT record stored in Cosmos DB (NFT container)
   → EventLog stored for the mint transaction

4. Policy enforcement (optional)
   → Attach policies to the collection contract
   → Policies checked on transfer, mint, burn operations
```

## Policy System

### 5 Policy Types

| Policy | What it Controls | Example |
|--------|-----------------|---------|
| **ActionPolicy** | Base interface — generic action gating | Allow/deny any contract call |
| **TimeBoundPolicy** | Time windows | "Transfers only between 9 AM-5 PM" |
| **CounterBoundPolicy** | Usage limits | "Max 100 mints per collection" |
| **RoleBoundPolicy** | Role-based access | "Only MINTER role can mint" |
| **StateBoundPolicy** | State machine | "Can only transfer when state is UNLOCKED" |

### How Policies Combine
- Each collection (ERC721Files contract) can have multiple policies
- A **default policy** applies to all operations unless overridden
- Policies are deployed as separate proxy contracts
- Policy addresses stored in the Contracts document: `Policies` and `DefaultPolicy` fields
- On-chain: ERC721Files checks attached policies before executing operations

### Policy Entity (`src/entities/Policies/`)
- `PolicyEntity.ts` — CRUD for policy configurations
- Links to on-chain policy contract deployments
- Stored in `Policies` Cosmos container (BLOCKCHAIN_ENGINE_DB)

## Gas Station

### Purpose
Manages gas (MATIC/POL) distribution to organization wallets for sponsored transactions. Organizations don't need to manage their own gas — the platform distributes from a treasury.

### Components

| Component | File | Purpose |
|-----------|------|---------|
| **GasStation utility** | `src/web3/gas-station/GasStation.ts` | Gas price estimation, token distribution |
| **GasStation entity** | `src/entities/GasStation/` | Business logic for accounts, requests, transactions |
| **GasStationAccounts** | Cosmos container | Per-org gas station config |
| **GasStationTokenRequests** | Cosmos container | Token request tracking |
| **GasStationTransactions** | Cosmos container | Transaction records |

### Flow
```
1. Organization requests gas tokens
   → GasStationTokenRequest created in Cosmos
2. Platform reviews and approves
   → Treasury wallet (LUMEN_TREASURY_WALLET_PK) sends tokens
3. Transaction recorded in GasStationTransactions
4. Organization wallet now has gas for contract operations
```

### Available to Entities
- ORGANIZATION (GAS_STATION module)
- BYC_ADMIN (GAS_STATION module) — admin oversight
- DEVELOPER (GAS_STATION module) — developer access

## IPFS Integration

### Dual Provider Strategy

| Provider | Utility File | Purpose |
|----------|-------------|---------|
| **Infura** | `src/utility/infura/` | Primary IPFS pinning |
| **Pinata** | `src/utility/pinata/` | Alternative IPFS pinning |

**Usage**: NFT metadata (name, description, image, attributes) is uploaded to IPFS. The resulting CID becomes the `tokenURI` for the ERC721 token.

**Config**: `INFURA_API_KEY_ID` env var for Infura IPFS gateway.

## Wallet Management

### Organization Wallets (`src/entities/OrganizationWallets/`)
- Each organization has one or more wallets
- Wallets stored in `OrganizationWallets` container (partition: OrganizationID, Ownership)
- Used for signing contract transactions

### BridgePass Wallets (`src/bridgepass/`)
- End-user wallets via wallet-as-a-service
- Authentication codes for wallet connections
- DKG (Distributed Key Generation) support in `src/bridgepass/dkg/`

### ethers.js v6 Patterns
- `ethers.Wallet` — Signer instances from private keys
- `ethers.JsonRpcProvider` — Connects to Polygon via Infura RPC
- `ethers.Contract` — Interacts with deployed contracts using ABIs
- Transaction timeout: 60s default, 180s for `AWAIT_WITH_TIMEOUT`
