---
name: skill-lumen-dev
description: >
  Unified development companion for the entire Lumen BaaS ecosystem by Bayanichain — spanning 40+ repos across
  backend SDK, Azure Function microservices, frontend webapps, design systems, smart contracts, blockchain explorer,
  Temporal workflows, API tests, and CI/CD infrastructure. Trigger whenever the user mentions Lumen, BaaS, mvp-baas,
  Bayanichain, or works in ANY repo in the Bayanichain GitHub org related to the Lumen platform. Also trigger for:
  mvp-baas-backend, mvp-baas-org-webapp, mvp-byc-portal-webapp, lumen-explorer-webapp, lumen-design-system,
  lumen-explorer-design-system, mvp-baas-contracts, mvp-baas-api-tests, mvp-baas-authenticator-webapp,
  mvp-baas-redirect-webapp, mvp-baas-dapps, Temporal-workflow, core-sdk, contract-sdk, any mvp-baas-*-func repo,
  marissa-*, jci-wc-*, entity types (ORGANIZATION, BYC_ADMIN, DEVELOPER, BRIDGEPASS, EXPLORER), module names
  (ADMIN, PLANS, APIKEYS, WALLETS, FILES, REPORTS, WEBHOOKS, POLICIES, PAYMENTS, GAS_STATION, USER, ORGANIZATIONS),
  Azure Functions, Express routes, Cosmos DB, Blob Storage, Key Vault, smart contracts, Polygon, ethers.js, Hardhat,
  OpenZeppelin, Temporal, PayMongo, IPFS, Pinata, Infura, gas station, API keys, JWT auth, Ed25519 webhooks,
  DirectoryItems, NFT minting, policy enforcement, BridgePass, Web3Auth, lumen-mint-webapp, lumen-onboarding-kit,
  lumen-agent-demo, LumenMainButton, LumenDropdownButton, BatchSelectButton, ContentModal, ConfirmationModal, Table,
  FilterBar, LumenFilter, Spinner, SkeletonLoader, CustomToast, EnvironmentBadge, LumenSelect, TimePeriodSelector,
  Pagination, usePagination, design tokens, Tailwind preset, Sora font, flat design, monochrome palette, classNames,
  base.css, Headless UI, lucide-react, react-select, RequestNormalizer, middleware pipeline, Zod schemas,
  IEntityLayer, IContainerLayer, CosmosDBContainer, Dockerfile, CI/CD, GitHub Actions, Azure Container Registry,
  or architecture questions about the BaaS platform. Even if the user just says "help me with Lumen",
  "working on the backend", "org webapp", "explorer", "portal", "design system", "design tokens", or "BaaS"
  — use this skill.
---

# Lumen Ecosystem Development Skill

Unified companion for developing across the full Lumen BaaS platform by Bayanichain.

This skill grows incrementally — reference files are added as we work on each repo.

## Ecosystem Map

### Core SDK Layer (npm packages)

| Package | Repo | Purpose |
|---------|------|---------|
| `@bayanichain/mvp-baas-sdk` | `mvp-baas-backend` | Business logic SDK — entities, modules, middleware, Cosmos, Web3, Temporal |
| `@bayanichain/core-sdk` | `core-sdk` | Base classes: CosmosDBContainer, CosmosDBClient, shared utilities |
| `@bayanichain/contract-sdk` | `contract-sdk` | Smart contract interaction SDK |
| `@bayanichain/lumen-design-system` | `lumen-design-system` | Org webapp design system — React 19, Tailwind 4, flat/monochrome |
| `@bayanichain/lumen-explorer-design-system` | `lumen-explorer-design-system` | Explorer design system — React 19, Tailwind 4 |

### Backend & Microservices

| Repo | Entity / Module | Notes |
|------|----------------|-------|
| **mvp-baas-backend** | ALL | The SDK monorepo — all business logic lives here |
| mvp-baas-org-admin-func | ORGANIZATION / ADMIN | Azure Functions microservice |
| mvp-baas-org-apikeys-func | ORGANIZATION / APIKEYS | Azure Functions microservice |
| mvp-baas-org-files-func | ORGANIZATION / FILES | Azure Functions microservice |
| mvp-baas-org-plans-func | ORGANIZATION / PLANS | Azure Functions microservice |
| mvp-baas-org-reports-func | ORGANIZATION / REPORTS | Azure Functions microservice |
| mvp-baas-org-wallets-func | ORGANIZATION / WALLETS | Azure Functions microservice |
| mvp-baas-admin-org-func | BYC_ADMIN / ORGANIZATIONS | Azure Functions microservice |
| mvp-baas-bridgepass-user-func | BRIDGEPASS / USER | Azure Functions microservice |
| mvp-baas-dev-files-func | DEVELOPER / FILES | Azure Functions microservice |
| mvp-baas-dev-wallet-func | DEVELOPER / WALLET | Azure Functions microservice |
| mvp-baas-dev-blockchain-func | DEVELOPER / BLOCKCHAIN | Template (not populated) |
| mvp-baas-dev-contract-func | DEVELOPER / CONTRACT | Template (not populated) |
| mvp-baas-dev-nft-func | DEVELOPER / NFT | Template (not populated) |
| mvp-baas-org-webhooks-server | ORGANIZATION / WEBHOOKS | Webhook delivery server |
| mvp-baas-containerized-function-app | — | Template for new Azure Function apps |
| Temporal-workflow | — | Temporal worker — file ops, credit resets, plan downgrades |

All func repos depend on `@bayanichain/mvp-baas-sdk` + `@bayanichain/core-sdk`. They're thin wrappers: import SDK, register Azure Function handlers, deploy.

### Frontend Webapps

| Repo | What it is | Stack | Dev Port |
|------|-----------|-------|----------|
| **mvp-baas-org-webapp** | Organization admin dashboard | React 19, Vite 6, Tailwind 4, Web3, Formik, Recharts | 5173 |
| **mvp-byc-portal-webapp** | BYC Admin portal (platform ops) | React 19, Vite, Tailwind 4 | 5173 |
| **lumen-explorer-webapp** | Blockchain explorer UI | React 19, Vite 8, Tailwind 4, lucide-react | 5173 |
| **lumen-mint-webapp** | NFT minting UI | React, Vite | 5173 |
| **mvp-baas-authenticator-webapp** | OAuth/social login gateway | React 19, Vite 6, Tailwind 4, Web3Auth | 5173 |
| **mvp-baas-redirect-webapp** | Wallet redirect handler | React 19, Vite 6, Tailwind 4, Web3Auth, Ethers 6 | 5173 |
| **mvp-baas-dapps** | Smart contract demo dApps | React 19, Vite 6, Tailwind 4, Web3 | 5173 |
| **mvp-baas-dev-webapp** | Developer portal (docs/playground) | React, Vite | 5173 |

### Smart Contracts

| Repo | What it is | Stack | Local |
|------|-----------|-------|-------|
| **mvp-baas-contracts** | Lumen platform contracts (ERC721Files, policies, proxy) | Hardhat, OpenZeppelin, Polygon | Yes |
| **marissa-smart-contract** | DBM tokenization contract | Hardhat, OpenZeppelin, Ethers 6 | Yes |
| **marissa-multisig-contract** | DBM multisig contract | Hardhat | — |
| **dbm-smart-contracts** | DBM smart contracts | Hardhat | Yes |
| **erc721-contract** | Standalone ERC721 contract | Hardhat | Yes |
| **gaa-smart-contracts** | GAA smart contracts | Hardhat | Yes |
| **likha-smart-contracts** | Likha smart contracts | Hardhat | Yes |
| **inscription-playground-contracts** | Inscription playground contracts | Hardhat | Yes |
| **smart-contract-playground** | Smart contract playground/experiments | Hardhat | Yes |
| **test-smart-contracts** | Test smart contracts | Hardhat | Yes |

### Backend Services & SDKs (additional)

| Repo | What it is | Local |
|------|-----------|-------|
| **blockchain-engine-server** | Blockchain engine server | Yes |
| **gas-station** | Gas station service/contract | Yes |
| **gov-sdk** | Governance SDK | Yes |
| **dev-webhooks** | Developer webhooks service | Yes |

### Testing & Tooling

| Repo | Purpose |
|------|---------|
| **mvp-baas-api-tests** | API integration test suite (TypeScript, axios, mvp-baas-sdk) |
| **mvp-baas-adminInt-test** | Admin integration tests |
| **lumen-automated-testing** | Automated E2E testing |
| **azure-cosmos-tool** | Cosmos DB utility tooling |

### Infrastructure

| Repo | What it is | Local |
|------|-----------|-------|
| **infra** | Lumen platform infrastructure (Terraform/IaC) | Yes |
| **infra-jci** | JCI infrastructure | Yes |

### Adjacent Projects (same org, shared infra)

| Repo | What it is | Stack | Local |
|------|-----------|-------|-------|
| **marissa-func** | DBM Azure Function backend | TypeScript, Azure Functions, OpenAI, Moralis, Pinata | Yes |
| **marissa-webapp** | DBM user webapp | React 18, Vite 5, Tailwind 3, Redux Toolkit | Yes |
| **marissa-admin-console-webapp** | DBM admin console | React 18, Vite 5, Tailwind 3, Azure MSAL | Yes |
| **marissa-minting-func** | DBM minting backend | Azure Functions | — |
| **marissa-multisig-signer** | DBM multisig signer service | — | — |
| **jci-wc-admin-api** | JCI World Congress admin backend | Express 5, TypeScript, Cosmos, Swagger | Yes |
| **jci-wc-admin-webapp** | JCI World Congress admin UI | React 19, Vite 8, Tailwind 4, motion | Yes |
| **jci-wc-user-webapp** | JCI World Congress user portal | React 19, Vite 6, Tailwind 3, react-hook-form | Yes |
| **jci-wc-user-api** | JCI World Congress user backend | Express 5, TypeScript, Cosmos, Swagger | Yes |
| **jci-wc-system-design** | JCI system design documentation | — | Yes |
| **GAA** | GAA project | — | Yes |

### Other Lumen Repos

| Repo | Purpose | Local |
|------|---------|-------|
| **lumen-onboarding-kit** | Onboarding materials for new orgs | — |
| **lumen-agent-demo** | AI agent demo for BD | — |
| **lumen-tech-presentation** | Tech presentation materials | — |
| **byc-dev-notes** | Developer notes / documentation | Yes |

---

## Architecture Quick Reference

### Entity-Module Pattern

Every Lumen microservice = one entity + one module. The SDK monorepo (`mvp-baas-backend`) contains ALL business logic. Each `mvp-baas-*-func` repo is a thin deployment wrapper.

```
Entity (WHO)         Module (WHAT)
─────────────        ──────────────────────────────────────────────
ORGANIZATION    →    ADMIN, PLANS, APIKEYS, WALLETS, FILES, REPORTS,
                     WEBHOOKS, POLICIES, PAYMENTS, GAS_STATION
BYC_ADMIN       →    ORGANIZATIONS, GAS_STATION
DEVELOPER       →    FILES, WALLETS, POLICIES, GAS_STATION
BRIDGEPASS      →    USER
EXPLORER        →    FILES
```

### Request Flow (Backend SDK)

```
Client Request
    |
    v
Azure Function Handler  /  Express Route Handler
    |
    v
Middleware Pipeline:
  Auth (JWT or API Key) --> Logger --> URL Parser --> Validator --> Verifier
    |
    v
RequestNormalizer (abstracts Azure vs Express differences)
    |
    v
Entity Business Logic (src/entities/)
    |
    +---> Cosmos DB (src/azure/cosmos/)       - 3 databases, 24+ containers
    +---> Blob Storage (src/azure/storage/)   - file content storage
    +---> Key Vault (src/azure/vault/)        - secrets, JWT RSA keys
    +---> Web3 (src/web3/)                    - smart contracts on Polygon
    +---> PayMongo (src/utility/payments/)    - payment processing
    +---> Temporal (src/temporal/)            - async workflow orchestration
    +---> IPFS (src/utility/infura/, pinata/) - decentralized file storage
    |
    v
Response
```

### Deployment URL Pattern

```
https://lumen-{entity-short}-{module}-func-{env}.azurewebsites.net/api/
```

### Infrastructure

| Service | Purpose |
|---------|---------|
| Azure Cosmos DB | Primary database (3 DBs: lumen, blockchain-engine, wallet) |
| Azure Blob Storage | File storage (one container per org) |
| Azure Key Vault | JWT keys, encryption secrets |
| Azure Communication Services | Email delivery |
| Azure Event Grid | Webhook event dispatch |
| Polygon (Infura) | Blockchain — Mainnet (PROD) / Amoy testnet (others) |
| Temporal Cloud | Workflow orchestration |
| Pinata / Infura | IPFS file pinning |
| PayMongo | Subscription billing |
| Azure Container Registry | Docker images (`byclumen.azurecr.io`) |
| GitHub Actions | CI/CD pipelines |

### Auth Patterns

| Actor | Auth Method |
|-------|------------|
| Organization Admin | JWT (RSA from Key Vault) via `org-admin-token` header |
| BYC Admin | Azure Entra + OTP via `byc-admin-token` header |
| Developer | AES-encrypted API Key via `x-api-key` + `x-api-secret` |
| BridgePass User | Wallet session token |
| Explorer | No auth (public) |

### Tech Stack Generations

| Generation | React | Vite | Tailwind | Era |
|-----------|-------|------|----------|-----|
| Legacy | 18 | 5 | 3 | marissa-* repos |
| Current | 19 | 6 | 4 | mvp-baas-*, jci-wc-* |
| Cutting Edge | 19 | 8 | 4 | lumen-explorer-*, jci-wc-admin-* |

---

## Lumen Design System — `@bayanichain/lumen-design-system`

**Package**: v1.1.0, published to GitHub Package Registry
**Repo**: `lumen-design-system`
**19 components** across 11 categories, **design tokens** (colors, typography, spacing), **Tailwind v4 preset**, **usePagination** hook

### Four Design Principles (non-negotiable)

1. **Flat / Sharp** — `border-radius: 0` on everything. No `rounded-*` anywhere. Enforced via Tailwind preset.
2. **Monochrome** — Black/white/gray only. Two exceptions: `error` (#ef4444), `success` (#22c55e). No brand colors, no gradients.
3. **Typographic** — Sora font (-0.04em tracking), Inter fallback. Visual hierarchy through weight/spacing, not color.
4. **Minimal** — No shadows, no gradients, no decorative elements. 1px solid borders in light grays only.

**When reviewing PRs or suggesting changes, enforce these principles.** If someone adds `rounded-lg`, a colored background, or a shadow — flag it.

### Package Exports

| Export Path | Content |
|------------|---------|
| `.` (main) | Everything — components + tokens + hooks + helpers |
| `./tokens` | `colors`, `tailwindColors`, `typography`, `spacing` |
| `./tailwind-preset` | Tailwind config preset |
| `./styles` | `base.css` global stylesheet |
| `./components` | All 19 components + types |
| `./helpers` | `classNames` utility |
| `./hooks` | `usePagination` + `PAGE_SIZES` |

### Component Map

```
LumenMainButton ──→ Spinner, classNames, react-router
LumenDropdownButton ──→ Spinner, classNames, lucide-react (ChevronDown)
BatchSelectButton ──→ (standalone)
ContentModal ──→ Headless UI (Dialog/Transition), classNames
ConfirmationModal ──→ ContentModal, LumenMainButton, Spinner
Table ──→ react-router (Link), react-icons (sort arrows)
FilterBar ──→ react-select, LumenMainButton, react-icons
LumenFilter ──→ (standalone)
LumenSelect ──→ react-select, design tokens (colors)
TimePeriodSelector ──→ (standalone)
Pagination ──→ usePagination hook, Headless UI (Listbox)
EnvironmentBadge ──→ (standalone)
CustomToast ──→ (standalone, used with react-toastify)
All Skeleton Loaders ──→ (standalone, CSS animations)
Spinner ──→ (standalone, SVG + CSS animation)
DesignSystemShowcase ──→ ALL components + tokens (interactive demo)
```

### Peer Dependencies (host app must provide)

`react` ^19, `react-dom` ^19, `react-router` ^7, `@headlessui/react` ^2, `tailwindcss` ^4, `clsx` ^2, `lucide-react` >=0.400, `react-select` ^5, `react-toastify` ^11, `formik` ^2

### Tailwind Integration

```ts
// tailwind.config.ts
import lumenPreset from '@bayanichain/lumen-design-system/tailwind-preset';
export default { presets: [lumenPreset] };
```
```ts
// app entry
import '@bayanichain/lumen-design-system/styles';
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Component files | PascalCase `.tsx` | `LumenMainButton.tsx` |
| Shared components | `Lumen` prefix | `LumenMainButton`, `LumenSelect` |
| Skeleton loaders | `SkeletonLoader` prefix | `SkeletonLoaderLines` |
| Boolean props | `is` prefix | `isLoading`, `isOpen` |
| Handler props | `on` prefix | `onClose`, `onConfirm` |
| CSS classes | kebab-case with prefix | `.lumen-card`, `.auth-buttons` |
| Tailwind tokens | `lumen-` prefix | `bg-lumen-dark`, `text-lumen-muted` |

### Common Design System Patterns

- **Button/Link Hybrid**: `LumenMainButton` renders `<button>` or `<Link>` depending on `to` prop
- **Headless UI Modal**: `ContentModal` wraps Dialog+Transition; `ConfirmationModal` composes ContentModal+LumenMainButton
- **URL-Based Pagination**: `usePagination` stores page/size/sort in URL search params via `useSearchParams`
- **react-select Styling**: `LumenSelect` + `FilterBar` apply flat design via custom `styles` objects (borderRadius: 0, monochrome)
- **Skeleton Variants**: 4 types match content layouts — lines, table, file cards, pagination
- **EnvironmentBadge Auto-Hide**: Hides in PROD, shows "SANDBOX" for STAGING, "TEST" for others
- **Barrel Exports**: Every dir has `index.ts`. Main `src/index.ts` re-exports all barrels.

---

## Reference Files

Reference files in `references/` — read the relevant one before answering domain-specific questions.

### Backend SDK (from mvp-baas-backend)

| File | Covers |
|------|--------|
| `references/architecture.md` | Codebase layers, request lifecycle, RequestNormalizer, IEntityLayer, error handling, feature flags, Zod validation |
| `references/azure-services.md` | 3 databases, 24+ Cosmos containers with partition keys, Blob storage patterns, env var catalog, Dockerfiles |
| `references/blockchain-web3.md` | Contract artifacts, deployer, upgrader, ERC721Files, 5 policy types, gas station, IPFS pinning |
| `references/entities-modules.md` | All 5 entities, their modules, JWT/API key auth, Zod schemas, 24 custom error classes, Temporal, PayMongo |

### Design System (from lumen-design-system)

| File | Covers |
|------|--------|
| `references/ds-tokens.md` | All 17 color tokens, font config, spacing scale, Tailwind preset, CSS custom properties |
| `references/ds-components.md` | All 19 components with props tables, usage examples, composition patterns |
| `references/ds-patterns-and-governance.md` | Form patterns, page layouts, naming conventions, contribution workflow, PR review checklist |

### Other Repos (incremental — added as we work on them)

| File | Covers | Status |
|------|--------|--------|
| `references/org-webapp.md` | mvp-baas-org-webapp pages, components, state, API integration | To be created |
| `references/byc-portal.md` | mvp-byc-portal-webapp admin portal | To be created |
| `references/explorer-webapp.md` | lumen-explorer-webapp blockchain explorer UI | To be created |
| `references/smart-contracts.md` | mvp-baas-contracts, Hardhat, deploy/upgrade patterns | To be created |
| `references/temporal-workflows.md` | Temporal-workflow worker, starters, file ops | To be created |
| `references/api-tests.md` | mvp-baas-api-tests test patterns | To be created |
| `references/jci-wc.md` | JCI World Congress system (admin + user, API + webapp) | To be created |
| `references/marissa.md` | DBM/Marissa ecosystem | To be created |
| `references/cicd-infra.md` | GitHub Actions, Dockerfiles, Azure Container Registry | To be created |

---

## How to Help

### General approach
1. Identify which repo(s) the user is working in
2. Check if a reference file exists — if yes, read it
3. If no reference exists, read the repo's code directly and offer to create the reference after

### Backend SDK questions
1. Read `references/architecture.md` for structure/middleware/request flow
2. Read `references/azure-services.md` for Cosmos/Blob/Key Vault
3. Read `references/blockchain-web3.md` for smart contracts/Web3
4. Read `references/entities-modules.md` for business logic/auth/errors

### Design system questions
1. Read `references/ds-tokens.md` for colors/typography/spacing
2. Read `references/ds-components.md` for component props/usage
3. Read `references/ds-patterns-and-governance.md` for patterns/naming/PRs
4. Always enforce the four design principles (flat, monochrome, typographic, minimal)

### Cross-repo tasks
When a task spans multiple repos (e.g., "add a new API endpoint and wire it up in the org webapp"):
1. Start from the SDK layer (mvp-baas-backend) — define the entity method, schema, route
2. Move to the func repo — ensure the Azure Function handler is registered
3. Move to the webapp — add the API call and UI (using design system components)
4. Check API tests — add coverage

### Adding a new microservice
1. Copy `mvp-baas-containerized-function-app` as template
2. Set `LUMEN_API_INSTANCE_ENTITY` and `LUMEN_API_INSTANCE_MODULE`
3. Add `@bayanichain/mvp-baas-sdk` dependency
4. Register in GitHub Actions workflow matrix (`ALL_APPS` JSON)
5. Create Azure Function App + container in Azure

### Adding a new design system component
1. Create component in `src/components/{category}/ComponentName.tsx` (PascalCase)
2. Export from `src/components/index.ts` barrel
3. Export from `src/index.ts` main barrel
4. Use `classNames` helper for conditional classes
5. Enforce: no `rounded-*`, no `shadow-*`, no color backgrounds
6. Add section to `DesignSystemShowcase`

### SDK version management
All func repos pin a specific `@bayanichain/mvp-baas-sdk` version. After publishing a new SDK version:
- Update the version in each func repo's `package.json`
- Current versions cluster around `1.0.0-alpha.285` (most) and `1.0.0-staging.*` (some)

---

## Incremental Growth Protocol

When we work on a repo that lacks a reference file:
1. I'll read the codebase during the task
2. After the task, I'll offer to save a reference file capturing what I learned
3. The reference file gets added to the table above
4. Future conversations benefit from the accumulated knowledge
