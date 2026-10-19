# Entity–Module Pattern (mvp-baas-backend)

## What it is

Code is organised by **actor (entity)** × **capability (module)**. Each combination maps to one Azure Function App in production and one local-dev port.

| Entity | Modules |
|---|---|
| `ORGANIZATION` | ADMIN, FILES, WALLETS, APIKEYS, REPORTS, WEBHOOKS, POLICIES, PAYMENTS, PLANS, GAS_STATION |
| `BYC_ADMIN` | ORGANIZATIONS, GAS_STATION |
| `DEVELOPER` | FILES, WALLETS, POLICIES, GAS_STATION |
| `BRIDGEPASS` | USER |
| `EXPLORER` | FILES |

Total: **18 entity-module combinations**. Each compiles to a separate Function App. Express runner serves them on ports 7071-7088 (see `local-dev-runners.md`).

## When to add a new entity vs new module

- **New entity** = new actor / persona (rare). Adds top-level routes under `src/api/{azure,express}/{entity}/`, new auth middleware patterns, new JWT key in Vault.
- **New module** = new capability for an existing actor (common). Drop a new handler under `src/api/{azure,express}/{entity}/{module}.ts`, register the routes in the parent `setup()`, and add a port row in `scripts/port-map.js`.

## Class hierarchy

```
EntityModuleAPIs (abstract)
├── OrganizationFilesAPIs
├── OrganizationAdminAPIs
├── BYCAdminOrganizationsAPIs
└── ...

IContainerWrapper<T> (abstract — Cosmos)
├── DirectoryItemsContainer
├── AdminContainer
├── ExternalContractsContainer
└── ...

IPreMiddlewareAF (abstract — request validation)
└── orgAdminRequestHandler, bycAdminRequestHandler, developerRequestHandler
```

Each entity-module API class registers its routes in `setup()`. The runtime instance (Azure Function or Express) reads `LUMEN_API_INSTANCE_ENTITY` / `LUMEN_API_INSTANCE_MODULE` from env to know which class's routes to register.

## Where to look in the repo

- Handlers: `src/api/azure/{entity}/{Module}.ts` + `src/api/express/{entity}/{Module}.ts`
- Business logic: `src/entities/{Domain}/{Class}.ts`
- Containers: `src/azure/cosmos/{Container}.ts`
- Routes: each handler class has a `setup()` method that calls `app.get/post/...`

## See also

- `references/express-vs-func-runtime.md` — where the two runtimes diverge
- `references/cosmos-partition-keys.md` — partition key conventions
