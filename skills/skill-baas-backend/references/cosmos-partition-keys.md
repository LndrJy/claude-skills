# Cosmos DB Partition Keys (mvp-baas-backend)

## Why this matters

Every Cosmos container in the workspace declares its partition keys as a class field on `IContainerWrapper<T>`. Cross-partition queries cost more RU and scale worse — design queries to stay within one partition when possible.

For full Cosmos guidance, also load the **`skill-cosmosdb-best-practices`** skill.

## Partition key map (key containers)

| Container | Partition keys | Notes |
|---|---|---|
| `DirectoryItems` | `['OrganizationID', 'Path']` | Folder/file tree per org. Reads scoped by `(orgID, path)`. |
| `ArchivedDirectoryItems` | `['OrganizationID', 'Path']` | Mirror of DirectoryItems for archived rows. |
| `DirectoryItemsLogs` | `['OrganizationID', 'Path']` | Audit log rows live with their item. |
| `Admin` | `['OrganizationID']` | All admins for an org in one partition. |
| `ExternalContracts` | `['Network', 'ChainID']` | All external collections on a chain. |
| `ExternalNFT` | `['Network', 'ChainID', 'ContractAddress']` | Per-contract tokens. |
| `Contracts` (native) | `['Network', 'ChainID']` | All Lumen-deployed contracts on a chain. |
| `NFT` (native) | `['Network', 'ChainID', 'ContractAddress']` | Per-contract native mints. |
| `EventLogs` | `['Network', 'ChainID', 'ContractAddress']` | One chain-event row per `(contract, token)` or contract-wide. |
| `NFTLogs` | `['Network', 'ChainID', 'ContractAddress']` | Per-token audit log. |
| `Organizations` | `['id']` | One org per partition (effectively a point lookup). |

## RU-aware patterns to follow

- **Point reads** (`readItem(id, partitionKey)`) are ~1 RU. Use whenever you have both the id and the partition key.
- **Single-partition queries** (predicate includes all partition keys) are cheap. Always scope by `Network`/`ChainID` for web3 containers and by `OrganizationID`/`Path` for DirectoryItems.
- **Cross-partition queries** (predicate omits a partition key) cost more — confine to admin/BYC reports, not hot paths.
- **`COUNT(1)` queries** with `SELECT VALUE COUNT(1)` are efficient when properly partitioned; expensive when cross-partition.

## Anti-patterns observed in the repo

- `Explorer.getter` hardcodes `network = ETHEREUM_NETWORK` / `chainId = POLYGON_CHAIN_ID`. Multi-chain Explorer requires parameterising those getters (see `references/glassnet-migration.md`).
- `MAX_MERGE_FETCH = 500` in `Explorer.ts` bounds per-source fetches when merging native + external rows client-side. Beyond ~page 25, cross-source ordering may drift on deep pages — acceptable trade-off vs RU cost.

## See also

- `skill-cosmosdb-best-practices` skill — official Cosmos performance rules
- `skill-azure-cosmos-ts` skill — `@azure/cosmos` SDK patterns
- `references/entity-module-pattern.md` — class hierarchy + container locations
