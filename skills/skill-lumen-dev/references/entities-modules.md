# Entities & Modules Reference

## Entity-Module Matrix

| Entity | Module | Description | Runtime |
|--------|--------|-------------|---------|
| **ORGANIZATION** | ADMIN | Org admin user management, login, JWT auth | Azure Functions |
| | PLANS | Subscription plan management | Azure Functions |
| | APIKEYS | API key CRUD, AES encryption, access control | Azure Functions |
| | WALLETS | Organization wallet management | Azure Functions |
| | FILES | DirectoryItems — file/folder CRUD, NFT minting | Azure Functions |
| | REPORTS | Reporting and analytics | Azure Functions |
| | WEBHOOKS | Webhook config, Ed25519 signing, delivery | Express |
| | POLICIES | Policy CRUD, on-chain deployment | Express |
| | PAYMENTS | PayMongo subscription management | Express |
| | GAS_STATION | Gas token management for org | Express |
| **BYC_ADMIN** | ORGANIZATIONS | Approve/reject/suspend organizations | Azure Functions |
| | GAS_STATION | Platform-wide gas station admin | Express |
| **DEVELOPER** | FILES | Developer API for file operations | Azure Functions |
| | WALLETS | Developer wallet operations | Azure Functions |
| | POLICIES | Developer policy management | Express |
| | GAS_STATION | Developer gas station access | Express |
| **BRIDGEPASS** | USER | End-user wallet auth, session management | Azure Functions |
| **EXPLORER** | FILES | Read-only file/document explorer | Express |

## ORGANIZATION Entity (10 modules)

### ADMIN Module
- **Entity**: `src/entities/Admins/`
- **Auth**: JWT with RSA keys from Key Vault
- Admin lifecycle: create → email verify → active / suspended / archived
- Password management: bcrypt hashing, salt length configurable
- Default admin created on org registration

### PLANS Module
- **Entity**: `src/entities/Plans/`
- **Auth**: JWT (org admin)
- Subscription plans tied to PayMongo
- Plan features define API credit allocation and feature access

### APIKEYS Module
- **Entity**: `src/entities/APIs/`
- **Auth**: JWT (org admin)
- API keys encrypted with AES (`LUMEN_MODULE_APIKEY_ENCRYPTOR_SECRET`)
- Each key has: Name, Description, Enabled flag, Access permissions
- Configuration: wallet type, allowed chains, default chain
- Access control: `true` (full access) or granular `IAPIKeyAccess` object

### WALLETS Module
- **Entity**: `src/entities/OrganizationWallets/`
- **Auth**: JWT (org admin)
- Wallet records with ownership tracking
- Links to blockchain addresses

### FILES Module (Largest)
- **Entity**: `src/entities/Files/` (13+ files)
- **Auth**: JWT (org admin) or API Key (developer)
- See "DirectoryItems Deep Dive" below

### REPORTS Module
- **Entity**: `src/entities/Reports/`
- **Auth**: JWT (org admin)
- Report generation and analytics queries

### WEBHOOKS Module
- **Entity**: `src/entities/Webhooks/`
- **Auth**: JWT (org admin)
- Webhook configuration CRUD
- Event types: Mint, Transfer, Archive, Restore, etc.
- Event sub-modules: Collection, File
- Scope: All, Collections, Files (with specific IDs)
- Retry config with exponential backoff (10 intervals)
- See "Webhook System" below

### POLICIES Module
- **Entity**: `src/entities/Policies/`
- **Auth**: JWT (org admin)
- CRUD for policy configurations
- Triggers on-chain policy contract deployment
- Links policies to collections (ERC721Files contracts)

### PAYMENTS Module
- **Entity**: `src/entities/Payments/PayMongoEntity.ts` (24KB)
- **Auth**: JWT (org admin)
- See "PayMongo Integration" below

### GAS_STATION Module
- **Entity**: `src/entities/GasStation/`
- **Auth**: JWT (org admin)
- Gas account management, token requests, transaction history

## BYC_ADMIN Entity (2 modules)

### ORGANIZATIONS Module
- **Auth**: Azure Entra + authenticator OTP
- Approve, reject, suspend organizations
- View all organizations and their status
- Manage platform-wide settings

### GAS_STATION Module
- **Auth**: Azure Entra + authenticator OTP
- Platform-level gas station oversight
- Approve/process token distribution requests

## DEVELOPER Entity (4 modules)

### FILES Module
- **Auth**: API Key (AES encrypted)
- Developer-facing file API (subset of Organization FILES)
- Used by external developers integrating with Lumen

### WALLETS Module
- **Auth**: API Key
- Developer wallet operations

### POLICIES Module
- **Auth**: API Key
- Developer policy management

### GAS_STATION Module
- **Auth**: API Key
- Developer gas station access

## BRIDGEPASS Entity (1 module)

### USER Module
- **Entity**: `src/entities/Bridgepass/`
- **Auth**: Wallet session tokens (`LUMEN_WALLET_AUTH_SECRET`)
- End-user wallet-as-a-service
- Authentication codes for wallet connections
- DKG (Distributed Key Generation) support
- OTP for verification

## EXPLORER Entity (1 module)

### FILES Module
- **Entity**: `src/entities/Explorer/`
- **Auth**: Varies (public or authenticated)
- Read-only file/document browser
- Routes use `/v1/` prefix: `/v1/dashboard`, `/v1/tx`, `/v1/document`, `/v1/address`, `/v1/search`
- Mounts at `/api` (no module suffix in path)

## DirectoryItems Deep Dive

### What it is
A virtual file system on Cosmos DB. Each file/folder is a `DirectoryItem` document with metadata, NFT references, and hierarchical path structure.

### Key Interface (`src/interfaces/files/DirectoryItems.ts`)
```typescript
interface IDirectoryItemsItem {
  Name, Path, Description
  OrganizationID, AdminID, OwnerID, OwnerAddress
  Type: 'folder' | 'file'
  SmartContract: IDirectoryItemSC    // ERC721 contract reference
  NFT: IFileNFT                      // Minted NFT details
  Folder: IFolder                    // Folder metadata
  File: IFile                        // File metadata
  Price: INFTPrice                   // NFT pricing
  IsArchived, ArchivedID
  CopyOrMove: IDirectoryItemsCopyMove
  WorkflowID                         // File lifecycle tracking
}
```

### Operations (13+ files in `src/entities/Files/`)
| Operation | Description |
|-----------|-------------|
| **Create** | Create file or folder, upload content to Blob Storage |
| **Read** | Get file/folder by ID or path |
| **Update** | Update metadata |
| **Archive** | Soft delete (IsArchived=true), moves to ArchivedDirectoryItems |
| **Restore** | Unarchive a soft-deleted item |
| **Delete** | Permanent delete |
| **Copy** | Copy file/folder to new location |
| **Move** | Move file/folder to new path |
| **Rename** | Change file/folder name (updates Path) |
| **Transfer** | Transfer NFT ownership |
| **UpdateMetadata** | Update on-chain NFT metadata |

### Path-Based Hierarchy
Files use path strings like `/org123/collection-a/subfolder/file.pdf`. Unique name enforcement within each folder. Path updates cascade to all children on rename/move.

### Feature Flags
Many operations are disabled in PROD/STAGING via `LUMEN_DISABLED_ROUTES` (copy, move, delete, archive, restore for files/folders). See `src/Config.ts`.

## Authentication Flows

### 1. Organization Admin JWT Auth
- **Used by**: ORGANIZATION entity (all modules)
- **Flow**: Admin login → validate credentials (bcrypt) → sign JWT with RSA key from Key Vault
- **Key Vault secrets**: `LUMEN_ADMIN_JWT_PRIV_NAME` (private key), `LUMEN_ADMIN_JWK_KID` (key ID)
- **JWT library**: `jose` (lightweight, modern)
- **Middleware**: `OrganizationAdminRequestHandler` in `src/api/azure/middlewares/OrganizationAdmin.ts`
- Validates: JWT signature, expiry, issuer (`LUMEN_ADMIN_JWT_ISS`), org status

### 2. Organization User JWT Auth
- **Used by**: Organization end-users
- **Key Vault secrets**: `LUMEN_ORG_USER_JWT_PRIV_NAME`, `LUMEN_ORG_USER_JWK_KID`
- **Middleware**: `OrganizationUser.ts`

### 3. API Key Auth (Developer)
- **Used by**: DEVELOPER entity
- **Flow**: API request includes API key in header → decrypt with AES → validate key exists and is enabled → check access permissions
- **Encryption**: AES with `LUMEN_MODULE_APIKEY_ENCRYPTOR_SECRET` (hex key)
- **Middleware**: `OrganizationDeveloperRequestHandler` in `OrganizationDeveloper.ts`
- Validates: key exists, enabled, access permissions match requested operation

### 4. BYC Admin Auth
- **Used by**: BYC_ADMIN entity
- **Flow**: Azure Entra token validation + authenticator OTP
- **Config**: `AZURE_ENTRA_AUDIENCE`, `LUMEN_BYC_ADMIN_AUTH_SECRET`
- **Middleware**: `BYCAdmin.ts`

### 5. BridgePass Wallet Auth
- **Used by**: BRIDGEPASS entity
- **Flow**: Wallet connection → authentication code → session token
- **Encryption**: `LUMEN_WALLET_AUTH_SECRET`
- **Middleware**: `BridgepassOrganization.ts`

## Zod Schema Catalog (`src/schema/`)

| Schema Directory | Key Schemas |
|-----------------|-------------|
| `organization/` | Registration, login, rejection, status update |
| `admin/` | Creation, login, password reset, email verify |
| `api-key/` | API key create/update/toggle, credit allocation |
| `files/` | DirectoryItem operations (archive, move, copy, rename, mint) |
| `webhooks/` | Webhook create, update, test delivery |
| `policies/` | Policy assignment, deployment |
| `web3/` | Chain config, NFT pricing/metadata |
| `developer/` | Developer-specific validations |
| `bridgepass/` | BridgePass auth validations |
| `report/` | Audit log queries, report filters |
| `gasstation/` | Gas account, token request validations |
| `Generic.ts` | Shared validators (ID, pagination, etc.) |
| `FilterQuery.ts` | Dynamic filter query validation |
| `ListQuery.ts` | List/pagination query validation |

Schemas run in the middleware pipeline's validation step before business logic.

## Custom Error Classes (`src/errors/`)

### 24 Error Files

| Error Class | Domain | Common Codes |
|-------------|--------|-------------|
| `GenericError` | Cross-cutting | RECORD_ALREADY_ARCHIVED, VALIDATION_ERROR, INVALID_SCOPE |
| `AdminError` | Admin management | ADMIN_NOT_FOUND, ADMIN_ALREADY_EXISTS, EMAIL_NOT_VERIFIED |
| `APIKeysError` | API key ops | APIKEY_NOT_FOUND, APIKEY_DISABLED, ACCESS_DENIED |
| `APICreditsError` | Credit system | INSUFFICIENT_CREDITS, CREDITS_EXPIRED |
| `DirectoryItemsError` | File ops | FILE_NOT_FOUND, FOLDER_NOT_FOUND, NAME_ALREADY_EXISTS |
| `ArchivedDirectoryItemsError` | Archived files | ARCHIVED_ITEM_NOT_FOUND |
| `BlobStorageError` | Blob ops | UPLOAD_FAILED, DOWNLOAD_FAILED |
| `BYCAdminError` | BYC admin | UNAUTHORIZED, INVALID_OTP |
| `DeveloperError` | Developer API | API_ENTITY_INVALID, UNAUTHORIZED |
| `EventsError` | Blockchain events | EVENT_NOT_FOUND, INVALID_EVENT |
| `EventGridError` | Event Grid | INVALID_PAYLOAD |
| `FilterQueryError` | Query filters | INVALID_FILTER |
| `HealthCheckError` | Health checks | INVALID_SECRET |
| `KeyVaultError` | Key Vault | SECRET_NOT_FOUND, KEY_NOT_FOUND |
| `ListQueryError` | Pagination | INVALID_PAGE, INVALID_LIMIT |
| `LoginConfigError` | Login | CODE_EXPIRED, CODE_INVALID |
| `MiddlewareError` | Middleware | AUTH_FAILED, TOKEN_EXPIRED |
| `OTPError` | OTP | OTP_EXPIRED, OTP_INVALID |
| `OrganizationWalletError` | Wallets | WALLET_NOT_FOUND |
| `PaymentError` | PayMongo | PAYMENT_FAILED, SUBSCRIPTION_ERROR |
| `PlansError` | Plans | PLAN_NOT_FOUND, PLAN_INACTIVE |
| `PolicyError` | Policies | POLICY_NOT_DEPLOYED, POLICY_NO_PROXY, POLICY_NOT_READY |
| `ReportError` | Reports | REPORT_NOT_FOUND |
| `WebhooksError` | Webhooks | WEBHOOK_NOT_FOUND, DELIVERY_FAILED |

All extend `StandardError` from `@bayanichain/core-sdk` with typed error codes.

## Webhook System

### Configuration (`src/entities/Webhooks/`)
```typescript
interface IWebhookConfigItem {
  OrganizationID, Name
  WebhookURL, EventModule
  EventTypes: ['Mint', 'Transfer', 'Archive', ...]
  EventSubModules: ['Collection', 'File']
  Scope: { type: 'All' | 'Collections' | 'Files', ids?: [...] }
  RetryConfig: { MaxRetries: number }
  IsActive, CreatedBy
}
```

### Delivery (`src/utility/webhooks/WebhookDelivery.ts`)
- **Signing**: Ed25519 via `@noble/curves`
- **Headers**: `X-Lumen-Signature`, `X-Lumen-Timestamp`, `X-Lumen-Webhook-ID`, `X-Lumen-Trigger-ID`, `X-Lumen-Delivery-Attempt`
- **Private key**: Fetched from Key Vault (organization-specific), cached for 1 hour
- **Timeout**: `LUMEN_WEBHOOK_TIMEOUT_MS` (default 30s)
- **Payload limit**: `LUMEN_WEBHOOK_MAX_PAYLOAD_SIZE` (default 1MB)

### Retry Strategy
10 retry intervals with exponential backoff:
```
0, 60s, 5m, 15m, 30m, 1h, 2h, 4h, 8h, 16h
```
Retry scheduler starts on WEBHOOKS module startup.

### Payload Structure
```typescript
interface IWebhookPayload {
  event: { name, module, subModule }
  blockchain: { network, chainID, blockNumber, txHash, addresses }
  data: { ... }  // Event-specific data
  timestamp: string  // ISO format
  isTest?: boolean
}
```

## Temporal Workflows (`src/temporal/`)

### Client Setup (`src/temporal/client/client.ts`)
- **Pattern**: Lazy singleton — connection and client cached across requests
- **Supports**: Self-hosted (localhost:7233) and Temporal Cloud
- **Auth**: mTLS certificates or API key (`TEMPORAL_API_KEY`)
- **Default namespace**: `quickstart-lumen-workflow-scheduler.fvu8x`

### Key Functions
- `getTemporalClient()` — Get/create cached client
- `closeTemporalConnection()` — Cleanup
- `getWorkflowHandle(workflowId)` — Get handle to running workflow
- `isWorkflowRunning(workflowId)` — Check status

### Workflow Starters (`src/temporal/starters/`)
Functions that start specific workflows (async operations like contract deployments, file processing).

## PayMongo Integration

### Client (`src/utility/payments/PayMongoClient.ts`)
- **Auth**: Basic Auth with `PAYMONGO_SECRET_KEY` (Base64 encoded)
- **Base URL**: `https://api.paymongo.com/v1`
- **Currency**: PHP (amounts in centavos, e.g., 99900 = ₱999.00)

### Operations
| Category | Methods |
|----------|---------|
| **Plans** | `listPlans()`, `createPlan()`, `retrievePlan()` |
| **Customers** | `createCustomer()`, `retrieveCustomer()` |
| **Subscriptions** | `createSubscription()`, `retrieveSubscription()`, `cancelSubscription()`, `updateSubscriptionPlan()` |
| **Webhooks** | `createWebhookEndpoint()`, `listWebhookEndpoints()` |

### Entity (`src/entities/Payments/PayMongoEntity.ts`)
- 24KB — largest entity file
- Manages full subscription lifecycle
- Syncs PayMongo plans with local Plans container on startup
- Handles webhook events from PayMongo

### Error Handling
Custom `PayMongoAPIError` with code, message, and status code from PayMongo API response.

## Audit Logging

### How It Works
Every request is logged via middleware post-processing:

```typescript
// In _postProcessResponse()
await this.auditLog.successfulLog(request, response, context, lumenContext);
```

### Audit Log Structure
```typescript
interface IAuditLogItem {
  OrganizationID, OrganizationName, OrganizationEmail
  Type: 'OrganizationAdmin' | 'BYCAdmin' | 'AdminManagement' | 'FileManagement' | 'WebhookManagement'
  Action: TAuditLogAction
  Status: 'Success' | 'Failed'
  PerformedBy: IAuditLogAdmin | IAuditLogAPIKey
  InvolvedAdmin, InvolvedDirectoryItem, InvolvedAPIKey
  RequestID, Error
}
```

Stored in `AuditLogs` container (LUMEN_DB > report).

## API Credits System

### How It Works
- Each organization has a credit balance (`APICredits` container)
- Credits have expiry dates — consumed oldest-first
- Every API call deducts credits (via middleware)
- Credit deductions logged in `APICreditsLogs`

### Structure
```typescript
interface IAPICreditsItem {
  OrganizationID
  Credits: Array<{
    RemainingCredits: number
    ExpiryTS: number       // Epoch seconds
    AddedTS: number
  }>
}
```

### Credit Middleware
Runs in the middleware pipeline — checks credit balance before allowing the request. If insufficient credits, returns error.

## List Query / Pagination

### Generic Pattern (`src/entities/ListQuery/`)
Shared list query logic used across all entities:
- Pagination: `page`, `limit`, `offset`
- Sorting: `sortBy`, `sortOrder`
- Filtering: Dynamic filter queries via Zod-validated `FilterQuery`

### Filter Query
Supports dynamic filtering with operators (equals, contains, gt, lt, etc.) validated via `src/schema/FilterQuery.ts`.
