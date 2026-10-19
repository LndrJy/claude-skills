---
name: skill-baas-backend
description: >
  BaaS backend development companion for the mvp-baas-backend SDK by BayaniChain —
  TypeScript + Azure Functions (production) + Express (local dev) + Cosmos DB +
  Azure Blob Storage + Azure Key Vault + ethers.js v6 (Polygon) + Temporal
  workflows. Acts as a switchboard: triggers itself on any backend task and
  points Claude at the right specialised installed skill (`skill-azure-cosmos-ts`,
  `skill-azure-storage-blob-ts`, `skill-azure-keyvault-secrets-ts`, `skill-azure-keyvault-keys-ts`,
  `skill-azure-identity-ts`, `skill-cosmosdb-best-practices`, `skill-temporal-developer`,
  `skill-nodejs-keccak256`, `skill-evm-token-decimals`, `skill-typescript-pro`,
  `skill-secure-code-guardian`, `skill-code-reviewer`, `skill-debugging-wizard`, `skill-test-master`,
  and the `superpowers` skill tree).

  Trigger whenever the user works on mvp-baas-backend or asks about: backend
  routes, entity classes, Cosmos containers, Express vs Functions runtimes, Zod
  schemas, JWT/Key Vault, ethers.js contract reads, Temporal starters, or
  branch reviews of `feature/*` branches in the repo. Also trigger for entity
  names (ORGANIZATION, BYC_ADMIN, DEVELOPER, BRIDGEPASS, EXPLORER), module
  names (ADMIN, FILES, WALLETS, APIKEYS, REPORTS, WEBHOOKS, POLICIES,
  PAYMENTS, PLANS, GAS_STATION, ORGANIZATIONS, USER), class names
  (EntityModuleAPIs, IContainerWrapper, IPreMiddleware, OrganizationFilesAPIs,
  DirectoryItemsImport, Explorer, ExternalContractScraper,
  AzureFunctionInstance, ExpressInstance, RequestNormalizer), or tech stack
  terms (`@azure/cosmos`, `@azure/storage-blob`, `@azure/keyvault-secrets`,
  `@azure/identity`, `@temporalio/client`, `ethers`, Polygon, Amoy, Glassnet,
  Prismo, partition keys, RU budgeting, EntityModule pattern).

  Defers domain-wide platform questions (frontend webapps, design system,
  contracts repo) to `skill-lumen-dev`. Defers L2 chain infrastructure to
  `skill-prismo-dev`.
---

# BaaS Backend Skill

Aggregator skill for the **mvp-baas-backend** repository. The codebase is a TypeScript SDK that runs in two modes — Azure Functions for production and Express for local dev — and serves five entities (ORGANIZATION, BYC_ADMIN, DEVELOPER, BRIDGEPASS, EXPLORER) with 18 entity/module combinations. The pattern is OOP with abstract base classes (`EntityModuleAPIs`, `IContainerWrapper<T>`), Zod validation at boundaries, and Cosmos DB partition-keyed data access. This skill routes you to the right specialised skill for whatever subsystem you're touching — load it first, then load the specialist.

## When to use this skill vs other Lumen skills

| If user is asking about… | Use this skill | Or escalate to… |
|---|---|---|
| `src/api/*`, `src/entities/*`, route handlers, Zod, error classes | **this skill** | — |
| Frontend webapps, design system, components | — | `skill-lumen-dev` |
| L2 chain infra, Kubernetes, Helm, CDK Erigon | — | `skill-prismo-dev` |
| Smart contract Solidity work | — | `skill-lumen-dev` (mvp-baas-contracts) |
| Cosmos query / RU question | **this** + `skill-cosmosdb-best-practices` | — |
| Azure SDK usage (Cosmos / Blob / Vault / Identity) | **this** + matching `azure-*-ts` | — |
| ethers.js selector or balance bug | **this** + `skill-nodejs-keccak256` / `skill-evm-token-decimals` | — |
| Temporal workflow non-determinism | **this** + `skill-temporal-developer` | — |
| TDD / debugging methodology / planning | **this** + relevant `superpowers/*` skill | — |

## Architecture Quick Reference

### Entity–Module pattern

```
src/api/azure/{entity}/{module}.ts        # Azure Functions handlers
src/api/express/{entity}/{module}.ts      # Express handlers
src/entities/{Domain}/{Class}.ts          # Business logic (OOP, inheritance)
src/azure/cosmos/{Container}.ts           # Cosmos container wrappers (extend IContainerWrapper<T>)
src/web3/contracts/{deployer|utility|events|verification}/{Contract}.ts
src/temporal/starters/{starter}.ts        # Workflow starters (worker lives in sibling Temporal-workflow repo)
src/interfaces/                            # Domain types (no logic)
src/schema/                                # Zod schemas for boundary validation
src/errors/                                # Domain-typed error classes (DirectoryItemsError, AdminError, …)
```

### Dual runtime

| Runtime | Entry | Used for |
|---|---|---|
| Azure Functions | `af.js` → `new AzureFunctionInstance()` | Production (each entity-module = one Function App) |
| Express | `scripts/express-entry.js` → `new ExpressInstance().start()` | Local dev, modules not yet on Functions |

Both runtimes inherit `process.env`. Local dev consolidated to **one `.env`** at repo root (`local.settings.json` removed). Runner scripts inject `LUMEN_API_INSTANCE_ENTITY` / `LUMEN_API_INSTANCE_MODULE` per invocation. See `references/local-dev-runners.md`.

### Layered structure

```
HTTP → middleware (auth, Zod) → API handler → Entity class → Container/SDK → Cosmos / Blob / Vault / Chain
                                       ↘ Temporal starter → workflow (sibling repo)
```

Always validate at the boundary (Zod). Internal entity methods trust their callers.

## Bundles (prefer these for multi-skill tasks)

Four bundle skills group related specialists so one slash command loads several at once. Use a bundle when the task spans multiple specialists; use a single specialist when the task is narrow.

| Bundle | Loads | Use for |
|---|---|---|
| **`multiskill-baas-azure`** | 6 Azure SDK + Cosmos best-practices skills | Anything touching `src/azure/**` |
| **`multiskill-baas-evm`** | ethers safety + Temporal | Anything in `src/web3/**` or `src/temporal/**` (BE side) |
| **`multiskill-baas-blockchain`** | 10 Solidity + OpenZeppelin + L2 + gas + standards skills | Smart contracts, proxy upgrades, Glassnet migration |
| **`multiskill-baas-architect`** | 8 architect/CTO skills | High-level design, ADRs, migrations |
| **`multiskill-baas-quality`** | 5 quality skills (TS, security, review, debug, tests) | Daily implementation + PR reviews |

## Per-task skill activation table

This is the **switchboard**. When the agent triggers `skill-baas-backend`, scan this table and also load the specialised skill (or bundle) that matches the task.

| Task | Load these skills | Why |
|---|---|---|
| Add or modify a Cosmos query / container | `skill-azure-cosmos-ts` + `skill-cosmosdb-best-practices` | SDK usage rules + RU/partition guidance |
| Blob upload / download / SAS | `skill-azure-storage-blob-ts` | BlobServiceClient + ContainerClient patterns |
| Read or write a Key Vault secret | `skill-azure-keyvault-secrets-ts` + `skill-secure-code-guardian` | SDK + JWT/secret-handling patterns |
| Cryptographic key ops (sign / encrypt) | `skill-azure-keyvault-keys-ts` | Key ops, rotation |
| Service principal / managed identity setup | `skill-azure-identity-ts` | `DefaultAzureCredential`, SP wiring |
| Temporal starter or workflow change | `skill-temporal-developer` | Non-determinism, signals/queries, sagas, versioning |
| ethers.js contract read or selector hash | `skill-nodejs-keccak256` | Keccak-256 vs SHA3 silent-fail trap |
| Reading ERC-20 / ERC-721 balances or amounts | `skill-evm-token-decimals` | Decimal-mismatch traps across chains |
| New REST route / Zod schema | `skill-typescript-pro` + `skill-secure-code-guardian` | Generics + branded types + input validation |
| PR / branch review (read-only audit) | `skill-code-reviewer` | Bugs + N+1 + security pass |
| Bug triage from stack trace | `skill-debugging-wizard` | Hypothesis-driven trace |
| Test scaffolding (unit / integration / E2E) | `skill-test-master` | Coverage strategy + mocking |
| Implement a new feature (start) | `superpowers/architecture/*` + `superpowers/problem-solving/*` | Decomposition + planning |
| TDD-style implementation | `superpowers/testing/test-driven-development` | RED → GREEN → REFACTOR enforcement |
| Stuck debugging | `superpowers/debugging/root-cause-tracing` + `skill-debugging-wizard` | Systematic methodology |
| Verifying work before claiming done | `superpowers/debugging/verification-before-completion` | Pre-handoff check |

## Reference Files

| File | Purpose |
|---|---|
| `references/entity-module-pattern.md` | When to add a new entity vs new module; class hierarchy |
| `references/cosmos-partition-keys.md` | Per-container partition key map + RU notes |
| `references/express-vs-func-runtime.md` | Where the two diverge; RequestNormalizer behavior |
| `references/local-dev-runners.md` | `npm run func` / `npm run express` + `port-map.js` |

These reference files capture **workspace-specific knowledge** that isn't available elsewhere. For feature-specific docs (external collections flow, Glassnet migration, etc.), read the markdown files at the repo root directly (`EXTERNAL_COLLECTIONS_FLOW.md`, `GLASSNET_MIGRATION_PREREQ.md`).

## How to Help

When this skill triggers, the agent should:

1. **Identify the subsystem** from the user's wording (Cosmos / Blob / Vault / Temporal / ethers / route / review / debug).
2. **Look up the row** in the per-task table above.
3. **Load the specialist skill(s)** named in that row by invoking the `Skill` tool with the skill name.
4. **Reference repo-specific patterns** from the reference files when the question is workspace-specific (partition keys, runtime split, feature flow).
5. **Defer cross-platform questions** (frontend, design system, smart contract Solidity) to `skill-lumen-dev`. Defer L2 infra to `skill-prismo-dev`.

If the user gives a slash command (`/skill-baas-backend`), treat it as an explicit "prime the context" request — read this whole SKILL.md and the reference files into context, but don't pre-load every specialist skill (that bloats context). Wait for the specific task before loading specialists.

## Incremental Growth Protocol

As subsystems are tackled in new sessions, drop deeper docs into `references/`:

- Found a tricky Cosmos query pattern? Add a note in `references/cosmos-partition-keys.md`.
- Discovered a Temporal non-determinism quirk? Add to a new `references/temporal-gotchas.md`.
- Hit a `feature/*` branch worth documenting? Add `references/feature-{branch}.md` pointing to the repo's planning doc.

Keep the SKILL.md body **stable** — only the routing table and headers should evolve. Move detail into `references/`.

## Related skills (already installed)

| Skill | Origin | Trigger |
|---|---|---|
| `skill-azure-cosmos-ts` | microsoft/skills | `@azure/cosmos`, partition key, CosmosClient |
| `skill-azure-storage-blob-ts` | microsoft/skills | `@azure/storage-blob`, BlobServiceClient |
| `skill-azure-keyvault-secrets-ts` | microsoft/skills | `@azure/keyvault-secrets`, SecretClient |
| `skill-azure-keyvault-keys-ts` | microsoft/skills | `@azure/keyvault-keys`, KeyClient |
| `skill-azure-identity-ts` | microsoft/skills | `DefaultAzureCredential`, managed identity |
| `skill-cosmosdb-best-practices` | AzureCosmosDB/cosmosdb-agent-kit | Cosmos RU budgeting + query rules |
| `skill-temporal-developer` | temporalio/claude-temporal-plugin | `@temporalio/*`, workflows, signals |
| `skill-nodejs-keccak256` | affaan-m/ECC | Ethereum hashing, selectors |
| `skill-evm-token-decimals` | affaan-m/ECC | ERC-20/721 decimal handling |
| `skill-typescript-pro` | jeffallan/claude-skills | Generics, branded types, type-level work |
| `skill-secure-code-guardian` | jeffallan/claude-skills | OWASP, JWT, Zod, password hashing |
| `skill-code-reviewer` | jeffallan/claude-skills | Broad-scope review (read-only) |
| `skill-debugging-wizard` | jeffallan/claude-skills | Stack-trace tracing, hypothesis-driven |
| `skill-test-master` | jeffallan/claude-skills | Test scaffolding + coverage analysis |
| `superpowers/*` | obra/superpowers-skills | 31 SKILL.md files: architecture, debugging, testing, problem-solving, collaboration |
