# Architecture Reference

## Layer Overview

The codebase follows a strict layered architecture:

```
API Layer (src/api/)           — Route registration, platform abstraction
    |
Middleware Layer (middlewares/) — Auth, logging, validation, audit
    |
Entity Layer (src/entities/)   — Business logic, CRUD operations
    |
Service Layer (src/azure/, src/web3/, src/utility/) — External service integrations
```

Each layer only depends on the layers below it. Never import entities into the API layer directly — the middleware handles the bridge.

## Request Lifecycle (Step-by-Step)

### Azure Functions Path
1. HTTP request hits Azure Functions runtime (`af.js` entry)
2. `Setup.ts` registers HTTP triggers with route patterns
3. Request matched to handler in `src/api/azure/{entity}/`
4. Handler's middleware class (e.g., `OrganizationAdminRequestHandler`) fires:
   - `_preProcessRequest()` — validates JWT/API key, loads org, admin, sets `lumenContext`
   - Business logic handler runs (the actual entity method)
   - `_postProcessResponse()` — writes audit logs, directory item logs
5. Response returned through Azure Functions runtime

### Express Path
1. HTTP request hits Express server (`express.js` entry → `ExpressInstance.ts`)
2. Global middleware: CORS, JSON parsing, health check
3. Route matched via `ROUTER_INSTANCE_MAPPING[entity][module]`
4. Entity-specific router handles the request
5. Error handling stack: credit errors → audit log errors → generic error handler

### BasePath Logic (Express)
```
EXPLORER entity → /api
All other entities → /api/{module}

Examples:
  ORGANIZATION + FILES    → /api/files
  ORGANIZATION + WEBHOOKS → /api/webhooks
  EXPLORER + FILES        → /api
```

## Middleware Pipeline

### Per-Entity Middleware Classes (`src/api/azure/middlewares/`)

| File | Entity | Auth Method |
|------|--------|-------------|
| `OrganizationAdmin.ts` | ORGANIZATION | JWT (Admin RSA key from Key Vault) |
| `OrganizationDeveloper.ts` | DEVELOPER | API Key (AES encrypted) |
| `OrganizationUser.ts` | ORGANIZATION (user) | JWT (Org User RSA key) |
| `OrganizationPlans.ts` | ORGANIZATION | JWT + Plans validation |
| `BYCAdmin.ts` | BYC_ADMIN | Azure Entra + authenticator OTP |
| `BYCAdminAudit.ts` | BYC_ADMIN | Read-only audit access |
| `BridgepassOrganization.ts` | BRIDGEPASS | Wallet session token |
| `EventGrid.ts` | Internal | Azure Event Grid validation |
| `HealthCheck.ts` | All | Health check secret header |
| `Unauthorized.ts` | Public | No auth required |
| `Internal.ts` | Internal | Internal API key |

### Middleware Lifecycle Pattern
```typescript
class OrganizationAdminRequestHandler extends Functions {
  // 1. Pre-processing: auth + context building
  protected async _preProcessRequest(request, context) {
    const { Organization, Admin, Token } = await this.orgAdmin.validate(request, context);
    this._updateLumenContextContent('admin', Admin);
    this._updateLumenContextContent('organization', Organization);
    this._updateLumenContextContent('token', Token);
    await this.walletBalance.validateWithLumen(request, context, this.lumenContext);
  }

  // 2. Post-processing: logging
  protected async _postProcessResponse(request, response, context, lumenContext) {
    await this.auditLog.successfulLog(request, response, context, lumenContext);
    if (LUMEN_API_INSTANCE_MODULE === 'FILES') {
      await this.directoryItemLog.successfulLog(request, response, context, lumenContext);
    }
  }
}
```

### Generic Middleware Base (`src/api/generic/Middlewares.ts`)

Abstract hierarchy that both Azure and Express implementations extend:

- `IMiddlewares` — Base with `_getRequestorOrganization()` (validates org status)
- `IPreMiddleware<T>` — Pre-request validation (`validate()`, `validateWithLumen()`)
- `IPostMiddlewareLogging<T>` — Post-response logging
- `IPreValidationPostLoggingMiddleware<T>` — Composite of both

## IEntityLayer / IContainerLayer (`src/entities/Entity.ts`)

### IContainerLayer (base)
```typescript
abstract class IContainerLayer<ICosmosDBContainer extends CosmosDBContainer> {
  id?: string;
  container!: ICosmosDBContainer;
  partitionKeys: string | Array<string> = 'id';
}
```

### IEntityLayer (extends IContainerLayer)
```typescript
abstract class IEntityLayer<ICosmosDBContainer> extends IContainerLayer {
  async update(updatedData)   // Update document in Cosmos
  async delete(id, partitionKeys)  // Hard delete
  async archive(id, partitionKeys) // Soft delete: IsArchived=true, ArchivedTS=now
  async restore(id, partitionKeys) // Restore: IsArchived=false, ArchivedTS=now
}
```

**Soft-delete pattern**: All archivable documents have `IsArchived: boolean` and `ArchivedTS: number` (epoch seconds). Archive/restore toggle these fields. Attempting to archive an already-archived record throws `RECORD_ALREADY_ARCHIVED`.

## Adding a New Entity or Module

### Checklist (8 steps)

1. **Define types** in `src/Config.ts`:
   - Add module to entity's module type (e.g., `TOrganizationModule`)
   - Add to `TEntityModuleMap`
   - Add API URL to `LUMEN_API_URLS`

2. **Create interface** in `src/interfaces/{domain}/`:
   - Define `I{Domain}Item` with all document fields
   - Export from `src/interfaces/index.ts`

3. **Create Zod schema** in `src/schema/{domain}/`:
   - Define request validation schemas
   - Export from `src/schema/index.ts`

4. **Create Cosmos container** in `src/azure/cosmos/`:
   - Extend `CosmosDBContainer` from core-sdk
   - Define partition key(s)
   - Add to `ensureAllContainers()` in `EnsureContainers.ts`

5. **Create entity logic** in `src/entities/{Domain}/`:
   - Extend `IEntityLayer` or `IContainerLayer`
   - Implement business methods

6. **Create error class** in `src/errors/{Domain}.ts`:
   - Define domain-specific error codes
   - Extend `StandardError` from core-sdk

7. **Create API routes**:
   - Generic: `src/api/generic/{entity}/`
   - Azure: `src/api/azure/{entity}/`
   - Express: `src/api/express/{entity}/`
   - Add to `API_INSTANCE_MAPPING` (Azure) or `ROUTER_INSTANCE_MAPPING` (Express)

8. **Add to CI/CD**:
   - Add entry to `ALL_APPS` matrix in `.github/workflows/`
   - Choose type: `func` (Azure Functions) or `express`

## Error Handling

### Error Class Hierarchy

All errors extend `StandardError` from `@bayanichain/core-sdk`:

```typescript
class GenericError extends StandardError<MergedGenericErrorCodes> {
  constructor(
    code: keyof typeof MergedGenericErrorCodes,  // Error code enum key
    msg: string,                                  // Human-readable message
    isForDeveloperOrStatus: number | boolean       // HTTP status or dev-only flag
  )
}
```

### Error Files (24 total in `src/errors/`)
Generic, Admin, APICredits, APIKeys, ArchivedDirectoryItems, BlobStorage, BYCAdmin, Developer, DirectoryItems, EventGrid, Events, FilterQuery, HealthCheck, KeyVault, ListQuery, LoginConfig, Middleware, OTP, OrganizationWallet, Payment, Plans, Policy, Report, Webhooks

### Common Error Codes
- `RECORD_ALREADY_ARCHIVED` / `RECORD_ALREADY_RESTORED` — soft-delete state
- `VALIDATION_ERROR` — Zod validation failure
- `POLICY_NOT_DEPLOYED` / `POLICY_NO_PROXY` — smart contract state
- `COLLECTION_NO_CONTRACT` — file collection missing contract

## Feature Flags (`LUMEN_DISABLED_ROUTES`)

Defined in `src/Config.ts` as `Record<TServerMode, string[]>`:

```typescript
LUMEN_DISABLED_ROUTES = {
  PROD: ['file/transfer', 'file/rename', 'file/copy', 'file/move', 'files/delete', ...],
  STAGING: ['files/copy', 'files/move', 'folder/copy', ...],
  TEST: ['file/transfer', 'file/rename', ...],
  DEV: [],  // Everything enabled
}
```

The `FeatureDisabler` utility checks the current route against this list. Disabled routes return **503 Service Unavailable**.

## Zod Validation

Schemas in `src/schema/` mirror the `src/interfaces/` structure by domain:
- `organization/Organization.ts` — Registration, login, rejection
- `admin/Admin.ts` — Admin creation, login, password reset
- `api-key/APIKeys.ts` — API key creation, updates, toggles
- `api-key/APICredits.ts` — Credit allocation
- `files/DirectoryItems.ts` — File/folder operations
- `webhooks/Webhooks.ts` — Webhook creation, updates
- `policies/Policies.ts` — Policy assignment
- `web3/Chains.ts`, `web3/NFT.ts` — Chain and NFT validation
- `report/AuditLog.ts` — Audit log queries
- `Generic.ts`, `FilterQuery.ts`, `ListQuery.ts` — Shared validation

Validators run in the middleware pipeline before business logic executes.

## Logging

Uses **Pino** (`src/utility/logger/`):
- Structured JSON logging in production
- Pretty-printed in development (via `pino-pretty`)
- Request/response logging in middleware
- Error logging with stack traces
