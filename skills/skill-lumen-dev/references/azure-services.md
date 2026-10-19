# Azure Services Reference

## Azure Services Overview

| Service | Purpose | Key File(s) |
|---------|---------|-------------|
| **Cosmos DB** | Document database (3 instances) | `src/azure/cosmos/` |
| **Blob Storage** | File content storage | `src/azure/storage/BlobStorage.ts` |
| **Key Vault** | Secrets, JWT RSA keys, Ed25519 keys | `src/azure/vault/` |
| **Communication Services** | Email sending | `src/azure/communication-services/` |
| **Event Grid** | Event publishing | `src/azure/event-grid/` |
| **Functions v4** | Serverless compute (primary runtime) | `src/api/azure/` |

## Cosmos DB Setup (`src/azure/cosmos/Setup.ts`)

### Three Database Clients

```typescript
export const LUMEN_DB = new CosmosDBClient(LUMEN_DB_CONN_STRING);
export const BLOCKCHAIN_ENGINE_DB = new CosmosDBClient(CONTRACT_ENGINE_DB_CONN_STRING || LUMEN_DB_CONN_STRING);
export const WALLET_DB = new CosmosDBClient(WALLET_DB_CONN_STRING || LUMEN_DB_CONN_STRING);
```

- `LUMEN_DB` — Main application data (orgs, files, keys, reports, gas station)
- `BLOCKCHAIN_ENGINE_DB` — Web3 data (contracts, NFTs, chains, event logs). Falls back to LUMEN_DB if not configured
- `WALLET_DB` — BridgePass wallet data. Falls back to LUMEN_DB if not configured

### Database Name Convention
- DEV/TEST/STAGING: Prefixed names (`web3-setup`, `wallet-user`)
- PROD: Base names (`setup`, `user`)

## Cosmos DB Container Catalog

### LUMEN_DB > setup (7 containers)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `Organizations` | `/id` | Organization master records (name, status, contact, subscription) |
| `DirectoryItems` | `/OrganizationID`, `/Path` | File/folder hierarchy with NFT metadata |
| `ArchivedDirectoryItems` | `/OrganizationID`, `/Path`, `/DirectoryItemsID` | Archived files for recovery |
| `Webhooks` | `/OrganizationID` | Webhook endpoint configurations |
| `APIKeys` | `/OrganizationID` | API key credentials and access controls |
| `LoginConfig` | `/OrganizationID` | Ephemeral login codes (TTL: 24h) |
| `OrganizationUserLogs` | `/id` | Organization user activity logs |

### LUMEN_DB > transaction (5 containers)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `APICredits` | `/OrganizationID` | API credit balances with expiry dates |
| `OTP` | `/ActionName` | One-time passwords for auth actions |
| `WebhookTriggers` | `/OrganizationID` | Webhook event triggers and delivery history |
| `GasStationTransactions` | `/OrganizationID` | Gas station transaction records |
| `GasStationTokenRequests` | `/OrganizationID` | Gas station token request tracking |

### LUMEN_DB > user (3 containers)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `Admins` | `/OrganizationID` | Admin user accounts (name, email, password hash) |
| `OrganizationWallets` | `/OrganizationID`, `/Ownership` | Wallet records per organization |
| `GasStationAccounts` | `/OrganizationID` | Gas station account config per org |

### LUMEN_DB > report (5 containers)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `AuditLogs` | `/OrganizationID` | Comprehensive audit trail |
| `Reports` | `/OrganizationID` | Report data and analytics |
| `DirectoryItemsLogs` | `/OrganizationID`, `/Path` | File/folder operation logs |
| `APICreditsLogs` | `/OrganizationID` | Credit deduction and usage logs |
| `SystemErrors` | `/id` | Error tracking and diagnostics |

### BLOCKCHAIN_ENGINE_DB > web3-setup (4 containers)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `Chains` | `/Network` | Blockchain network definitions |
| `Contracts` | `/Network`, `/ChainID` | Smart contract deployments |
| `NFT` | `/Network`, `/ChainID`, `/ContractAddress` | NFT tokens from deployed contracts |
| `Policies` | `/OrganizationID` | ActionPolicy contract deployments |

### BLOCKCHAIN_ENGINE_DB > web3-report (2 containers)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `EventLogs` | `/Network`, `/ChainID`, `/ContractAddress` | Contract event logs |
| `NFTLogs` | `/Network`, `/ChainID`, `/ContractAddress` | NFT event history |

### WALLET_DB > wallet-user (1 container)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `Wallets` | `/Ownership` | Web3 wallet records |

### WALLET_DB > wallet-transaction (1 container)

| Container | Partition Key(s) | Purpose |
|-----------|-----------------|---------|
| `AuthenticationCode` | `/id` | Wallet connection auth codes |

### Container Initialization (`EnsureContainers.ts`)

`ensureAllContainers()` runs on every startup. Idempotent — uses `createIfNotExists()` for both databases and containers. Supports single and MultiHash partition keys. Logs creation/existing status per container.

## Blob Storage (`src/azure/storage/BlobStorage.ts`)

- Connection: `LUMEN_STORAGE_CONN_STRING`
- Stores actual file content (DirectoryItems metadata is in Cosmos DB)
- Operations: upload, download, delete, list, generate SAS URLs
- Container naming tied to organization

## Key Vault (`src/azure/vault/`)

| File | Purpose |
|------|---------|
| `Vault.ts` | Base vault client initialization |
| `VaultKey.ts` | RSA key operations (JWT signing/verification) |
| `VaultSecret.ts` | Secret retrieval (Ed25519 keys, API secrets) |

**Key Vault Name**: `LUMEN_KEY_VAULT_NAME` env var

**Stored Keys/Secrets**:
- `LUMEN_ADMIN_JWT_PRIV_NAME` — RSA private key for admin JWT signing
- `LUMEN_ORG_USER_JWT_PRIV_NAME` — RSA private key for org user JWT signing
- Organization Ed25519 keys — for webhook signing (cached 1 hour)

## Azure Communication Services

- Connection: `LUMEN_ACS_CONN_STRING`
- Senders: `LUMEN_ACS_BYC_SENDER` (BYC admin emails), `LUMEN_ACS_ORG_SENDER` (org emails)
- HTML email templates in `src/utility/email/templates/`
- Used for: verification emails, OTP, password reset, notifications

## Azure Event Grid

- Used for internal event publishing between services
- Middleware handler in `src/api/azure/middlewares/EventGrid.ts`
- Validates Event Grid subscription handshake

## Azure Functions v4 Setup

**Entry point**: `af.js` → imports from built SDK

**Registration** (`src/api/azure/Setup.ts`):
- Reads `LUMEN_API_INSTANCE_ENTITY` and `LUMEN_API_INSTANCE_MODULE`
- Instantiates correct `AzureFunctionInstance` from `API_INSTANCE_MAPPING`
- Registers HTTP triggers with route patterns

**API_INSTANCE_MAPPING** (`src/api/azure/APIs.ts`):
```
BRIDGEPASS    → { USER: BridgepassUserAPIs }
DEVELOPER    → { WALLETS, FILES }
BYC_ADMIN    → { ORGANIZATIONS }
ORGANIZATION → { REPORTS, WALLETS, FILES, ADMIN, APIKEYS, PLANS, WEBHOOKS }
```

## Express v5 Alternative

**Entry point**: `express.js` → `ExpressInstance.ts`

**When to use**: Local development, containerized deployment (Dockerfile.express)

**ROUTER_INSTANCE_MAPPING**:
```
BYC_ADMIN    → { ORGANIZATIONS, GAS_STATION }
ORGANIZATION → { WEBHOOKS, POLICIES, PAYMENTS, GAS_STATION, ... }
DEVELOPER    → { POLICIES, GAS_STATION }
EXPLORER     → { FILES }
```

**Startup lifecycle**:
1. `ensureAllContainers()` — create missing Cosmos containers
2. Start webhook retry scheduler (WEBHOOKS module only)
3. Sync PayMongo plans (PAYMENTS module only)
4. Mount routers at basePath
5. Attach error handling stack

## Environment Variable Catalog

### Database Connection Strings
| Variable | Purpose |
|----------|---------|
| `LUMEN_DB_CONN_STRING` | Main Cosmos DB |
| `CONTRACT_ENGINE_DB_CONN_STRING` | Blockchain engine Cosmos DB |
| `WALLET_DB_CONN_STRING` | Wallet Cosmos DB |
| `LUMEN_STORAGE_CONN_STRING` | Azure Blob Storage |
| `LUMEN_ACS_CONN_STRING` | Azure Communication Services |

### Azure Identity
| Variable | Purpose |
|----------|---------|
| `AZURE_TENANT_ID` | Azure Entra tenant |
| `AZURE_CLIENT_ID` | Azure user/app ID |
| `AZURE_CLIENT_SECRET` | Azure client secret |
| `AZURE_ENTRA_AUDIENCE` | Entra audience value (BYC Admin auth) |
| `LUMEN_KEY_VAULT_NAME` | Key Vault name |

### Authentication
| Variable | Purpose |
|----------|---------|
| `LUMEN_ADMIN_JWT_PRIV_NAME` | Key Vault secret name for admin JWT RSA key |
| `LUMEN_ADMIN_JWK_KID` | Admin JWT key ID |
| `LUMEN_ADMIN_JWT_ISS` | Admin JWT issuer |
| `LUMEN_ORG_USER_JWT_PRIV_NAME` | Key Vault secret name for org user JWT RSA key |
| `LUMEN_ORG_USER_JWK_KID` | Org user JWT key ID |
| `LUMEN_ORG_USER_JWT_ISS` | Org user JWT issuer |
| `LUMEN_MODULE_APIKEY_ENCRYPTOR_SECRET` | AES hex key for API secret encryption |
| `LUMEN_BYC_ADMIN_AUTH_SECRET` | BYC admin authenticator secret |
| `LUMEN_WALLET_AUTH_SECRET` | Wallet session token encryption key |
| `LUMEN_HEALTH_CHECK_SECRET` | Health check header secret |

### Blockchain
| Variable | Purpose |
|----------|---------|
| `INFURA_API_KEY_ID` | Infura API key for Polygon RPC |
| `LUMEN_SIGNER_PK` | Primary signer private key |
| `LUMEN_TREASURY_WALLET_PK` | Treasury wallet key (falls back to SIGNER_PK) |
| `ETHERSCAN_API_KEY` | Etherscan V2 for contract verification |

### Services
| Variable | Purpose |
|----------|---------|
| `LUMEN_SERVER_MODE` | DEV / TEST / STAGING / PROD |
| `LUMEN_API_INSTANCE_ENTITY` | Entity type for this instance |
| `LUMEN_API_INSTANCE_MODULE` | Module for this instance |
| `LUMEN_EVENTS_LISTENER_API_URL` | Blockchain events listener URL |
| `TEMPORAL_API_KEY` | Temporal Cloud API key |
| `TEMPORAL_ADDRESS` | Temporal server address |
| `TEMPORAL_NAMESPACE` | Temporal namespace |
| `PAYMONGO_SECRET_KEY` | PayMongo API secret |
| `PAYMONGO_WEBHOOK_SECRET` | PayMongo webhook verification |

### Webhooks
| Variable | Purpose |
|----------|---------|
| `LUMEN_WEBHOOK_TIMEOUT_MS` | Delivery timeout (default: 30000ms) |
| `LUMEN_WEBHOOK_MAX_PAYLOAD_SIZE` | Max payload (default: 1MB) |
| `LUMEN_WEBHOOK_KEY_CACHE_TTL_MS` | Ed25519 key cache (default: 1 hour) |

## Dockerfiles

### `Dockerfile` (Azure Functions)
- Base: `mcr.microsoft.com/azure-functions/node:4-node22`
- Copies built SDK + `package.func.json`
- Runs Azure Functions runtime

### `Dockerfile.express` (Express)
- Base: `node:22-slim`
- Copies built SDK + `package.express.json`
- Exposes port 80
- Entry: `node express.js`

### Build Arguments
Both use the pre-built `dist/` output. The separate `package.func.json` and `package.express.json` contain only runtime dependencies for each platform.
