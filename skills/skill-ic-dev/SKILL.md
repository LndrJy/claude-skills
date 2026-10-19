---
name: skill-ic-dev
description: >
  Development companion for the IntegrityChain (IC) / DPWH government project — a 7-repo blockchain-document-integrity
  system spanning 4 Azure Functions backends and 3 React/Vite frontends, deployed across DPWH-IC-Dev / DPWH-IC-Test /
  DPWH-IC-Live resource groups under the Hacktiv-BYC Azure tenant. Trigger whenever the user mentions IC,
  IntegrityChain, DPWH, dpwh, ic-admin, ic-validator, ic-dpwh, ic-pubsub, integritychain, IntegrityChainDPWH,
  ic-admin-api, ic-admin-webapp, ic-validator-api, ic-validator-webapp, ic-dpwh-api, ic-dpwh-webapp, ic-pubsub-api,
  IC-WORKSPACE, IC_SECURITY_AUDIT_REPORT, the audit report, the validator side, the admin portal, the dpwh side,
  or works in ANY of the 7 IC repos. Also trigger for IC-specific Cosmos containers (AdminIC, AdminDPWH, RoleIC,
  RoleDPWH, Validators, ValidatorsRegistration, Packages, PackageReview, PackageApprovalFlows, ReviewPeriod,
  Feedbacks, FeedbackReply, ContractLogs, AdminLogs, RoleLogs, ManageICAdminLogs), Cosmos databases (user,
  transaction, setup), IC Azure Function names (LoginValidation, LoginAdminDPWH, ApproveContract, RejectContract,
  LaunchPackage, ArchivePackage, RevisePackage, CreatePackage, CreateNewVersionContractPackage, CreateAdmin,
  CreateRole, DeleteRole, CreateRoleDPWH, RoleDPWHStatus, UpdateAdminRole, UpdateAdminStatus, UpdateRoleStatus,
  SetupPassword, SetupDPWHPassword, ResetPassword, ForgotPassword, SendOTP, AdminDPWHOTP, AdminDPWHOTPValidation,
  AdminDPWHInvite, AdminDPWHResetLink, ValidateOTPLogin, DPWHCommunications, Negotiate, Notifications,
  Reauthenticate, BrowseProjects, BrowseProjectsReview, ApprovalFlowStatus, CreateApprovalFlow, CreateFeedback,
  CreateFeedbackReply, NewContractPackageFile, NewContractPackageFiles, AdminFileView, PackageFileView,
  ContractFileView, RoleFileView, DeleteContractPackageFile, ChecktNextVersionContractPackage,
  ContractApprovalList, ContractCompleteList, ContractLaunchList, ContractRevisionList, Dashboard, Report,
  SASTokenURLDocument, ViewPackageDetails, ViewPackageDetailsPublic, ReviewContractPackages), Lumen integration
  inside IC (@hacktivcolabinc/hacktiv-core-sdk, AzureCommunicationService, JWTInstance, CosmosDBService,
  sanitizedItems, createdTS, generateRandomString, LUMEN_API_KEY, LUMEN_API_SECRET, LUMEN_URL, LUMEN_WALLET,
  LUMEN_WEB_REDIRECT, LUMEN_ADMIN_REDIRECT, LUMEN_VALIDATOR_REDIRECT), IC env vars (COSMOS_DB, SECRET_KEY,
  ENCRYPTION_KEY, STORAGE_CONN_STR, STORAGE_NAME, STORAGE_KEY, ACS_CONN_STR, EMAIL_SENDER, WEBPUBSUB_KEY,
  WEBPUBSUB_CONN_STRING, WEBPUBSUB_ENDPOINT, WEB_APP_URL, VALIDATOR_WEB_APP_URL, HEADER_AUTHENTICATION,
  PUBSUB_URL, MODE, DEPLOYMENT_STORAGE_CONNECTION_STRING, VITE_IC_VALIDATOR_API_URL, VITE_IC_VALIDATOR_SECRET_KEY,
  VITE_IC_ADMIN_SECRET_KEY, VITE_IC_DPWH_API_URL, VITE_API_BASE_URL, VITE_AZURE_MAPS_KEY, VITE_GEMINI_API_KEY),
  or any task referencing the DPWH contract review / approval-flow / validator workflow. Even if the user just
  says "help me with IC", "the validator side", "dpwh stuff", "the admin portal", "the audit fixes", "pull
  settings from azure", "ic-WORKSPACE", or works inside `IC-WORKSPACE.code-workspace` — use this skill.
---

# IntegrityChain (IC) Development Skill

Unified companion for the 7-repo IC / DPWH government project deployed on Azure under the Hacktiv-BYC tenant.

This skill grows incrementally — sections are extended as fixes land.

---

## Ecosystem Map

### Backends (Azure Functions, Node.js v3 runtime, TypeScript)

| Repo | Role | Local port | Azure Function App (dev) |
|---|---|---|---|
| `ic-admin-api` | Admin / Validator-onboarding backend; manages `AdminIC`, `RoleIC`, `Validators` | 7071 | `ic-admin-api-dev` |
| `ic-validator-api` | Validator-facing API for project browsing, review, registration | 7072 | `ic-validator-api-dev` |
| `ic-dpwh-api` | DPWH operations backend — 70+ functions covering packages, contracts, approvals, feedback | 7073 | `ic-dpwh-api-dev` |
| `ic-pubsub-api` | Web PubSub negotiation + notification broadcaster (hub: `notifications`) | 7074 | `ic-pubsub-api-dev` |

### Frontends (Vite + React + TypeScript)

| Repo | Role | Stack | Local port |
|---|---|---|---|
| `ic-validator-webapp` | Citizen / validator-facing site | Vite 5, React 19 | 5173 |
| `ic-admin-webapp` | Admin dashboard | Vite 6, React 19 + Redux | 5174 |
| `ic-dpwh-webapp` | DPWH internal admin portal | Vite 5, React 18 | 5175 |

> **Production branch is `live`.** Default `main` is stale or empty (esp. `ic-dpwh-api` `main` is empty — production code only exists on `live`).

---

## Cross-Repo Architecture

```
 ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
 │ validator-webapp │   │  admin-webapp    │   │  dpwh-webapp     │
 │   (port 5173)    │   │   (port 5174)    │   │   (port 5175)    │
 └────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
          │                      │                      │
          ▼                      ▼                      ▼
 ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
 │ validator-api    │   │  admin-api       │   │  dpwh-api        │
 │   (port 7072)    │   │   (port 7071)    │   │   (port 7073)    │
 └────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
          │                      │                      │
          └──────────┬───────────┘                      │
                     ▼                                  ▼
       ┌───────────────────────────────────────────────────┐
       │  Cosmos DB (user / transaction / setup)            │
       │  Blob Storage (lgu-documents)                      │
       │  Azure Communication Services (email)              │
       │  Lumen API (@hacktivcolabinc/hacktiv-core-sdk)     │
       └───────────────────────────────────────────────────┘
                                ▲
                                │  (broadcast notifications)
                                │
                     ┌──────────────────┐
                     │  pubsub-api      │
                     │   (port 7074)    │   ← Web PubSub hub: "notifications"
                     └──────────────────┘
```

---

## Local Dev Quick-Start

### Prerequisites

- Azure CLI logged into Hacktiv-BYC tenant (`az account show` → `"name": "Hacktiv-BYC"`)
- Azure Functions Core Tools `func` v4+ installed
- Node.js v18+ via nvm-windows
- `npm` (no pnpm in this workspace)

### Pulling `local.settings.json` from Azure (per backend)

```powershell
cd c:\Users\irent\OneDrive\Documents\GitHub\<repo>
func azure functionapp fetch-app-settings <function-app-name>-dev --output-file local.settings.json
```

Mapping:

| Repo | Function App |
|---|---|
| `ic-admin-api` | `ic-admin-api-dev` |
| `ic-validator-api` | `ic-validator-api-dev` |
| `ic-dpwh-api` | `ic-dpwh-api-dev` |
| `ic-pubsub-api` | `ic-pubsub-api-dev` |

After fetch, edit each `local.settings.json` to add a unique local port under `"Host"`:

```json
"Host": {
  "LocalHttpPort": 7071,   // 7071 / 7072 / 7073 / 7074 per table above
  "CORS": "*"
}
```

Verify `local.settings.json` is in `.gitignore` (`git status -s` must come back clean).

### Frontend `.env.local`

| Frontend | Required keys |
|---|---|
| `ic-validator-webapp` | `VITE_IC_VALIDATOR_API_URL=http://localhost:7072/api/`, `VITE_IC_VALIDATOR_SECRET_KEY=...`, `VITE_AZURE_MAPS_KEY=...` |
| `ic-admin-webapp` | `VITE_API_BASE_URL=http://localhost:7071/api/`, `VITE_IC_ADMIN_SECRET_KEY=...`, `VITE_GEMINI_API_KEY=...` |
| `ic-dpwh-webapp` | `VITE_IC_DPWH_API_URL=http://localhost:7073/api/`, plus any other `VITE_*` pulled from the matching Static Web App / App Service config |

### Boot order

```powershell
# In 4 separate terminals (or VSCode task)
cd ic-admin-api;     npm install; npm run build; func start --port 7071
cd ic-validator-api; npm install; npm run build; func start --port 7072
cd ic-dpwh-api;      npm install; npm run build; func start --port 7073
cd ic-pubsub-api;    npm install; npm run build; func start --port 7074

# Then in 3 more terminals
cd ic-validator-webapp; npm install; npm run dev -- --port 5173
cd ic-admin-webapp;     npm install; npm run dev -- --port 5174
cd ic-dpwh-webapp;      npm install; npm run dev -- --port 5175
```

---

## Cosmos DB Layout

Single Cosmos account: `dpwh-ic-cosmos-dev` (dev), `*-test`, `*-live` mirrors.

| Database | Containers |
|---|---|
| `user` | `AdminIC`, `RoleIC`, `AdminDPWH`, `RoleDPWH`, `Validators`, `ValidatorsRegistration` |
| `transaction` | `Packages`, `PackageReview`, `PackageApprovalFlows`, `Feedbacks`, `FeedbackReply`, `ContractLogs`, `AdminLogs`, `RoleLogs`, `ManageICAdminLogs` |
| `setup` | `ReviewPeriod` |

All queries use Cosmos parameterized syntax (`@email` placeholders) via `SqlQuerySpec` — no classic SQL injection. **Exception:** `ic-validator-api/SharedCode/Azure/Cosmos/PaginationQuery.ts:175,180` interpolates `sortBy` and `searchFields` raw — flagged as audit H4.

---

## File Conventions (all 4 backends)

```
<repo>/
├── <FunctionName>/
│   ├── function.json        ← bindings + authLevel
│   └── index.ts             ← AzureFunction httpTrigger entry
├── SharedCode/
│   ├── Helper/
│   │   ├── JWT.ts           ← customJWT.generateToken/decodeToken
│   │   ├── Crypto.ts        ← AES helpers (hardcoded fallback key here — audit H3)
│   │   ├── PasswordValidation.ts
│   │   ├── Setup.ts         ← env var exports (SECRET_KEY, ENCRYPTION_KEY, …)
│   │   └── Date.ts / SanitizedItems.ts / ConvertToBase64.ts
│   ├── Azure/
│   │   ├── Cosmos/
│   │   │   ├── Container.ts             ← CosmosDBContainer wrappers
│   │   │   ├── Authentication.ts        ← Reauthenticate
│   │   │   ├── Admin.ts / AdminDPWH.ts  ← admin entity logic
│   │   │   ├── Role.ts / RoleDPWH.ts
│   │   │   ├── Validator.ts
│   │   │   ├── Package.ts               ← contract package logic (dpwh-api)
│   │   │   └── Logs.ts                  ← audit log (mutable blob — audit M1)
│   │   └── Communication/
│   │       ├── EmailServices.ts         ← AzureCommunicationService wrapper
│   │       └── EmailTemplate/*.ts
│   └── Schema/
│       ├── ValidateZodSchema.ts          ← contains `vali:` typo (audit C6)
│       ├── LoginSchema.ts
│       └── *Schema.ts
├── host.json
├── local.settings.json       ← MUST be gitignored
├── package.json
└── tsconfig.json             ← strict: false everywhere (audit M)
```

Frontend convention:

```
<repo>/
├── src/
│   ├── api/         ← axios clients
│   ├── components/
│   ├── pages/
│   ├── hooks/
│   ├── data/        ← stores (Zustand-style) or Redux slices
│   ├── setup/       ← routePermissions, config
│   └── App.tsx / main.tsx
├── .env             ← gitignored (but ic-validator-webapp had it committed — audit C1)
└── vite.config.ts
```

---

## Common Tasks (recipes)

### 1. Replace `jwt.decode()` with `jwt.verify()`

In every `Reauthenticate` function across the 4 backends:

```typescript
// BEFORE
const decodedToken = jwt.decode(token) as any;

// AFTER
import { SECRET_KEY } from "../../Setup";
const decodedToken = jwt.verify(token, SECRET_KEY, { algorithms: ["HS256"] }) as any;
```

### 2. Remove password from JWT payload

In `Admin.ts`, `Validator.ts`, `AdminDPWH.ts`:

```typescript
// BEFORE
const token = customJWT.generateToken({ Email, Password, UserType });

// AFTER — store session server-side, JWT carries only opaque references
const sessionId = await createSession({ userId: account[0].id });
const token = customJWT.generateToken({ sub: account[0].id, sid: sessionId });
```

### 3. Add bcrypt password hashing (migration)

```powershell
npm install bcrypt @types/bcrypt
```

```typescript
import bcrypt from "bcrypt";

// On account creation / setup
const hashedPassword = await bcrypt.hash(plainPassword, 12);

// On login
const valid = await bcrypt.compare(req.Password, account[0].Password);
```

Migration: write a one-off Azure Function or script to walk every `AdminIC` / `AdminDPWH` / `Validators` row and re-hash. Old `customJWT`-encoded passwords are reversible — decode them, bcrypt them, write back.

### 4. Fix the `vali` typo + missing-`return` chain (audit C6)

```typescript
// SharedCode/Schema/ValidateZodSchema.ts:8
// BEFORE
return { vali: false, errors: result.error.issues };
// AFTER
return { valid: false, errors: result.error.issues };
```

In **every** endpoint, after the validation check:

```typescript
if (!validateinput.valid) {
  context.res = { status: 400, body: validateinput };
  return;  // ← ADD THIS
}
```

### 5. Standardize `Superadmin` role string (audit C7)

Pick one canonical form (recommend `"Superadmin"` no space, matches the majority of checks). Then:

```powershell
# Find all writes of the wrong form
rg "Super Admin" --type ts
# Targets to fix:
#   ic-admin-api/SharedCode/Azure/Cosmos/Lumen.ts:47
#   ic-pubsub-api/SharedCode/Azure/Cosmos/AdminDPWH.ts:71
```

### 6. Rotate a secret via Azure Key Vault

```powershell
az keyvault secret set --vault-name dpwh-ic-kv-dev --name SECRET-KEY --value "<new>"
az functionapp config appsettings set -g DPWH-IC-Dev -n ic-admin-api-dev `
  --settings "SECRET_KEY=@Microsoft.KeyVault(SecretUri=https://dpwh-ic-kv-dev.vault.azure.net/secrets/SECRET-KEY/)"
# Restart Function App so Managed Identity picks up the reference
az functionapp restart -g DPWH-IC-Dev -n ic-admin-api-dev
```

---

## Audit Report Reference

Full audit: `ic-validator-webapp/IC_SECURITY_AUDIT_REPORT.md` (also `.pdf`).

**Severity legend:** 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low
**Final tally:** 31 Critical · 34 High · 40 Medium · 4 Low

### Top 5 still-open critical bugs (quick reference)

| ID | Bug | Where |
|---|---|---|
| C6 | Zod validation completely dead — `vali:` typo + missing `return` in every endpoint | `*-api/SharedCode/Schema/ValidateZodSchema.ts:8` + all `*/index.ts` |
| C1 | Password embedded in JWT payload | `Admin.ts:55-58`, `Validator.ts:45-49`, `AdminDPWH.ts:34-37` (×4 backends) |
| C4 | `jwt.decode()` accepted instead of `jwt.verify()` in `Reauthenticate` | `Admin.ts:421`, `AdminDPWH.ts:509, AdminDPWH.ts:15` |
| C3 | `DPWHCommunications` endpoint is `authLevel: anonymous` | `ic-pubsub-api/DPWHCommunications/function.json:4` |
| C6 | `ApproveContract` IDOR — role check but not contract-assignment check | `ic-dpwh-api/Package.ts:1103-1110` |

### Phase priorities

- **P0 (24 hrs):** rotate every committed secret, take 4 unauthenticated endpoints offline, fix `vali` typo, add `return` statements, standardize Superadmin string, BFG git history.
- **P1 (1 week):** remove password from JWT, bcrypt migration, `jwt.verify` everywhere, rate limiting (Azure API Management), fix `ApproveContract` IDOR, `UpdateAdminStatus`/`UpdateAdminRole` IDOR, file-upload path traversal, verified DPWH email domain.
- **P2 (2 weeks):** CORS whitelist, httpOnly cookies, CSRF tokens, security headers, Key Vault migration, fail-fast env validation, Gemini key proxy, webhook HMAC.
- **P3 (1 month):** append-only Cosmos audit log, TypeScript `strict: true`, `crypto.randomInt` OTPs, password policy NIST SP 800-63B, tests, axios CVE patch, CI/CD with OIDC, bounce handling, external security review.

---

## Conventions & Gotchas

- **Azure Functions v3 programming model** — not v4. Each function is its own folder with `function.json` + `index.ts`. Migration to v4 is P3 work.
- **`SharedCode/Helper/Setup.ts`** is the single source for env-derived constants. **All** of them currently `|| ""` fallback to empty strings, masking missing env vars at boot.
- **`@hacktivcolabinc/hacktiv-core-sdk`** provides `CosmosDBService`, `AzureCommunicationService`, `JWTInstance`, `sanitizedItems`, `createdTS`, `generateRandomString`. This is the same SDK pattern as Lumen — when in doubt, check `skill-lumen-dev` for related patterns.
- **`customJWT`** in this codebase = an instance of `JWTInstance` configured with `SECRET_KEY`. `customJWT.generateToken()` signs HS256 by default.
- **`local.settings.json`** is the deployment vehicle for env vars on Azure — `func azure functionapp publish` will sync settings AND code, so be careful when running publishes.
- **Cosmos partition keys:** `AdminIC`/`AdminDPWH` use `Email`, `Validators` uses `Email`, `Packages` uses `PackageID`. Sanity-check via `Container.ts` before adding `updateItem` calls.
- **HTTP status conventions are broken:** the codebase returns `200` with `body.valid = false` for auth failures instead of `401`/`403`. Audit P0 says fix it; until then, expect 200s for failed auth.
