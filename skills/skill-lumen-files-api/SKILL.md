---
name: skill-lumen-files-api
description: >
  Reference companion for implementing the Lumen Dev API in any project. Covers all 5 public sample
  webapps (files-management-sample-webapp, wallet-and-files-sample-webapp, wallet-management-sample-webapp,
  wallet-auth-sample-webapp, mvp-baas-dev-webapp) and the canonical Files API + Wallets API patterns.
  Trigger when the user mentions: Lumen Dev API, Lumen Files API, Lumen Wallets API, BridgePass, Custodial
  wallet, lumen-api-key, lumen-api-secret, lumen-user-token, lumen-authentication-code, SAS URL upload,
  directoryItems, /file/create, /files/create, /folder/create, deployContract, mint workflow,
  WorkflowID, getWorkflowStatus, MintReceipt, on-chain provenance, encodePath, BFF proxy pattern. Also
  trigger when working in any of the 5 sample webapps, or implementing Lumen integration in IC DPWH,
  JCI, marissa, mvp-baas-*, or any other Lumen-adjacent project. Files API is the primary focus; Wallets
  API documented for context. Pairs with skill-lumen-dev for ecosystem-wide context.
---

# Lumen Dev API — Implementation Companion (Files API focus)

Authoritative reference for calling the Lumen Dev API from an integrator's perspective. Pulled from the five public sample webapps shipped by the Lumen platform team. **Files API is the primary focus** (mintable document custody). Wallets API and developer-portal patterns are documented for context.

> **Scope:** This skill is strictly about **API integration** — endpoints, payloads, headers, auth, encoding, verification. It does NOT cover frontend implementation, UI component design, state management, or UX flows. Those concerns belong to the consuming application (e.g., IC DPWH rework, JCI, marissa) and are not opinions this skill holds. When the samples are referenced (§7), only their **API client wrappers and BFF patterns** are in scope — not their React components, screens, or visual design.

---

## 1. Architecture overview — the BFF pattern

Every sample uses the same three-layer shape. Don't bypass it.

```
┌─────────────────┐    HTTPS    ┌────────────────┐    HTTPS    ┌────────────────────┐
│  Browser (SPA)  │───────────▶│  Express BFF   │───────────▶│  Lumen APIM        │
│  React / Vite   │            │  Node, port    │            │  *.azure-api.net   │
└─────────────────┘            │  3001/8787     │            └────────────────────┘
                               └────────────────┘
       no secrets               injects:                       routes to
       in browser              lumen-api-key                  /wallet/*
                               lumen-api-secret                /file/*
                               per-request: user-token
                                          auth-code
```

**Why a BFF (Backend-For-Frontend):**
- Keeps `lumen-api-key` + `lumen-api-secret` server-side. The browser never sees them.
- Centralizes CORS, rate-limit (typical: 100 req / 15 min per IP), Helmet, input validation (Zod).
- Lets you swap the upstream Lumen URL without redeploying the browser bundle.

**When direct-to-Lumen is acceptable:** server-to-server only (one Azure Function calling Lumen as part of a backend workflow). Never browser-to-Lumen.

---

## 2. Files API contract (the primary surface)

Base URL pattern: `{LUMEN_FILES_API_BASE_URL}/{endpoint}`
Typical value: `LUMEN_FILES_API_BASE_URL=https://lumen-apim-stg.azure-api.net/file`

### 2.0 Folder hierarchy semantics — parent folder type DETERMINES mint behavior (★ critical)

This is the single most important rule in Files API and the one most likely to bite an integrator who hasn't been told it explicitly.

```
Folder created with FolderType = "directory"     →   files inside it are OFF-CHAIN ONLY
Folder created with FolderType = "collection"    →   files inside it MINT on-chain
```

Stated as a hard rule: **a file mints if and only if its DIRECT parent folder is `collection`.** No exceptions. The rule cascades:

- `/A/` is `directory` + `/A/B/` is `collection` + file at `/A/B/file.png` → file MINTS ✓ (direct parent `/A/B/` is collection)
- `/A/` is `collection` + `/A/B/` is `directory` + file at `/A/B/file.png` → file DOES NOT MINT ✗ (direct parent `/A/B/` is directory; "collection" status of grandparent does not cascade down)
- `/A/` is `collection` + file at `/A/file.png` → file MINTS ✓ (direct parent `/A/` is collection)
- Root `/` and any unrooted file (no parent folder explicitly created) → file DOES NOT MINT ✗

**Consequences for folder-tree design:**

| Goal | Correct shape | Wrong shape (won't mint) |
|---|---|---|
| Per-package contract, all files mint | `/{Type}/` directory + `/{Type}/{Package}/` collection + files flat inside | `/{Type}/{Package}/v1/gallery/` as directory tree — files inside `gallery/` won't mint |
| Per-folder shared contract (legacy IC pattern) | `/{Type}/Gallery/` as collection + all files flat inside | (correct, but every file in the type shares one contract — no per-package provenance) |
| Off-chain working files / drafts | Any directory tree, no collection ancestor in the direct line | n/a |

**Symptom of getting this wrong:** files create successfully (POST `/file/create/{path}` returns 200 with a `WorkflowID`), the SAS upload succeeds, the file shows up in `/directoryItems/{parent}` — but the WorkflowID never confirms (or confirms as "no-op"). No `TransactionHash`, no `ContractAddress`. IC's pre-rework codebase hit this for years because the team assumed "file created → file minted" without verifying the parent-folder type.

**Folder-create call site:** `POST /folder/create/{encodedPath}` body `{ Path, Name, FolderType: 'directory' | 'collection' }`. The `FolderType` is sticky — once a folder is created with one type, it stays that type for its lifetime. You cannot convert a directory into a collection (or vice versa) after the fact.

**Implementation pattern for "per-package contract" systems** (IC DPWH rework, similar projects):

```
1. Ensure /{Type}/ exists as directory      (idempotent; create on first package of that type)
2. Create /{Type}/{Code}/ as collection     ★ this folder = the per-package contract address
3. POST /file/create/ targeting /{Type}/{Code}/{filename}
   → file mints into the {Code} contract
4. Subsequent files for the same package mint into the SAME contract because they share /{Type}/{Code}/ as direct parent
5. Revisions (v2, v3, ...) of the same package mint MORE tokens into the same contract — use a flat filename like v2-gallery-cover.png to keep namespace clean
```

This is the shape that aligns with the platform's parent-must-be-collection rule, gives per-package provenance, and lets a single Lumen folder hold multiple mint versions of the same package.

### 2.1 Path encoding rule (critical — this was the source of every Files-API bug in IC's audit)

```js
export function encodePath(path) {
  const stripped = String(path ?? '').replace(/^\/+/, '')   // drop leading slashes
  if (!stripped) return '%2F'                                 // root → '%2F'
  return encodeURIComponent(stripped)                         // whole path as ONE segment
}
```

- The entire path becomes **one URL-encoded segment**.
- Slashes (`/`) become `%2F`.
- Spaces (` `) become `%20`.
- Do **not** encode per-segment — that produces a URL like `Flood%20Control/Package` which the APIM router rejects with a generic 404.
- The body's `Path` field carries the **leading slash form** (e.g. `"/Flood Control/Package"`), while the URL carries the **encoded form** (`Flood%20Control%2FPackage`). They are not the same shape.

### 2.2 Endpoints

| Endpoint | Method | Inputs | Returns | Notes |
|---|---|---|---|---|
| `/directoryItems/{encodedPath}` | GET | query: `pageSize`, `pageNumber`, `search`, `sortBy` | `{ Items: DirectoryItem[], Pagination }` | List files + folders in a path. Root = `%2F`. |
| `/folder/{encodedPath}` | GET | — | `{ Folder: DirectoryItem }` | Single-folder metadata. |
| `/folder/create/{encodedPath}` | POST | body: `{ Path, Name, FolderType: 'directory'\|'collection' }` | `{ Folder: DirectoryItem }` | Create folder. Required to exist before files can be created beneath it. |
| `/file/{encodedPath}` | GET | — | `{ File: DirectoryItem }` | File metadata + URLs. |
| `/file/create/{encodedPath}` | POST | body: `{ Path, Name, Description?, FileExtension, Checksum, Size, MimeType, OwnerAddress }` | `{ File: DirectoryItem, SASURL, WorkflowID }` | Register single file → returns SAS URL. Then PUT bytes to SAS. |
| `/files/create/{encodedPath}` | POST | body: `{ Path, Files: [{...same shape}], OwnerAddress? }` | `{ Files: [...], SASURLs: [...], WorkflowID }` | Batch register (≤20 per request). Returns one SAS per file. |
| `/file/metadata/{encodedPath}` | PATCH | body: `{ Description, ...editable fields }` | updated metadata | Edit file metadata (not bytes). |
| `/file/archive/{encodedPath}` | DELETE | — | confirmation | Move to archive (recoverable). |
| `/file/restore/{encodedPath}` | PATCH | — | restored metadata | Restore from archive. |
| `/file/delete/{encodedPath}` | DELETE | — | confirmation | Permanent delete. |
| `/archivedFiles/{encodedPath}` | GET | pagination | `{ Items, Pagination }` | List archived files. |

### 2.3 Required body fields on `/file/create` (gotchas)

The deployed Lumen server enforces all of these, even though some are marked optional in the published TypeScript types:

| Field | Required | Notes |
|---|---|---|
| `Path` | ✅ | Leading `/` form: `"/Flood Control/Documents"`. |
| `Name` | ✅ | Original filename including extension. |
| `FileExtension` | ✅ | Lowercased extension without dot: `"pdf"`, `"png"`. |
| `Checksum` | ✅ | Base64 of MD5 hash of file bytes. Must equal what Azure Blob computes from `x-ms-blob-content-md5`. |
| `Size` | ✅ | Bytes (number). Server caps at 20MB. |
| `MimeType` | ✅ | Standard MIME (e.g. `"image/png"`, `"application/pdf"`). |
| `OwnerAddress` | ✅ | Org's custodial wallet address (the one bound to `LUMEN_API_KEY`). Mismatch → on-chain mint reverts. |
| `Description` | optional | Free text. |

Omitting any required field returns the generic `{"errorMsg":"Please complete all required fields."}` — no per-field detail.

### 2.4 Two-step upload sequence

```
Step 1: POST /file/create/{encodedPath}
        body: { Path, Name, FileExtension, Checksum, Size, MimeType, OwnerAddress }
        ─────────────────────────────────────────────────────────────────────────
        ← { File: DirectoryItem, SASURL, WorkflowID }

Step 2: PUT {SASURL}
        headers:
          x-ms-blob-type: BlockBlob
          x-ms-blob-content-type: {file.type}
          x-ms-blob-content-md5: {Checksum}    ← MUST match the Checksum from Step 1
        body: <raw file bytes>
        ─────────────────────────────────────────────────────────────────────────
        ← 201 Created (Azure Blob direct response)
```

The `WorkflowID` returned in Step 1 identifies the **mint workflow** that Lumen kicks off after Step 2 completes. It does NOT confirm the file is minted — only that the workflow is queued. Verification requires polling (see §6).

---

## 3. Wallets API contract (for context — IC rework Track 2 doesn't use this)

Base URL pattern: `{LUMEN_API_BASE_URL}` (also called `LUMEN_WALLET_URL`)
Typical value: `https://lumen-apim-stg.azure-api.net/wallet`

### 3.1 Custodial OAuth dance (4 steps, from wallet-auth-sample-webapp)

```
1. Browser → BFF        POST /api/auth/login-config
   BFF → Lumen          POST /Custodial/login-config
   body: { AllowedLoginMethods: { SocialMedia: ['GOOGLE','FACEBOOK'] }, RedirectURL }
   ← { LoginURL, Config }

2. Browser              window.location.href = LoginURL
   User → BridgePass    completes social login
   BridgePass → Browser redirects to RedirectURL?AuthCode=<short-lived, single-use>

3. Browser → BFF        GET /api/auth/access-token
                        header: lumen-authentication-code: <AuthCode>
   BFF → Lumen          GET /Custodial/access-token
                        headers: lumen-api-key, lumen-api-secret, lumen-authentication-code
   ← { Token, Wallet }   Token is the long-lived session token; Wallet has address/name/email

4. Browser              sessionStorage.setItem('token', Token)
                        (NOT localStorage — clears on tab close, smaller XSS surface)
   Browser → BFF        every subsequent request
                        header: lumen-user-token: <Token>  (injected by axios interceptor)
```

### 3.2 Other wallet endpoints

| Endpoint | Method | Use |
|---|---|---|
| `/Custodial/authenticate` | GET | Verify a session token is still valid (header: `lumen-user-token`). Use on app load. |
| `/Custodial/logout` | DELETE | Invalidate session (header: `lumen-user-token`). |
| `/wallets/Custodial` | GET | Org admin: list all custodial wallets (paginated). |
| `/wallets/Custodial/{id}` | GET | Wallet detail. |
| `/wallets/Custodial/{addr}/files` | GET | List files owned by an address. |
| `/wallets/Custodial/{addr}/transactions` | GET | Tx history. |

---

## 4. Auth modes — which headers to send when

| Mode | Headers | Use case |
|---|---|---|
| **API key + secret** | `lumen-api-key`, `lumen-api-secret` | Server-side admin ops (file CRUD, login-config, list-wallets). Default for the BFF → Lumen leg. |
| **API key + auth-code** | `lumen-api-key`, `lumen-api-secret`, `lumen-authentication-code` | Exchanging an OAuth AuthCode for a session token. Single-use. |
| **API key + user-token** | `lumen-api-key`, `lumen-user-token` | End-user actions performed in the context of a custodial wallet. Token comes from §3.1 step 3. Note: secret is NOT sent in this mode. |

**Header injection pattern (BFF-side):**

```js
client.interceptors.request.use((cfg) => {
  cfg.headers.set('lumen-api-key', process.env.LUMEN_API_KEY)
  cfg.headers.set('lumen-api-secret', process.env.LUMEN_API_SECRET)
  if (cfg._userToken) cfg.headers.set('lumen-user-token', cfg._userToken)
  if (cfg._authCode)  cfg.headers.set('lumen-authentication-code', cfg._authCode)
  return cfg
})
```

Pass `_userToken` / `_authCode` as ad-hoc properties on the request config — the interceptor lifts them onto headers.

---

## 5. Canonical client implementation (copy from samples)

The single most reusable code in the Lumen ecosystem is the client wrapper in `wallet-auth-sample-webapp/server/src/lumenClient.js`. Copy it verbatim per service:

```js
import axios from 'axios'

function makeClient(baseURL) {
  const client = axios.create({
    baseURL,
    headers: { 'Content-Type': 'application/json' },
    timeout: 30000,
  })
  client.interceptors.request.use((cfg) => {
    cfg.headers.set('lumen-api-key', process.env.LUMEN_API_KEY)
    cfg.headers.set('lumen-api-secret', process.env.LUMEN_API_SECRET)
    if (cfg._userToken) cfg.headers.set('lumen-user-token', cfg._userToken)
    if (cfg._authCode)  cfg.headers.set('lumen-authentication-code', cfg._authCode)
    return cfg
  })
  return client
}

// Two clients — one per APIM service prefix
let walletsClient = null
let filesClient = null
const getWalletsClient = () => walletsClient ??= makeClient(process.env.LUMEN_API_BASE_URL)
const getFilesClient   = () => filesClient   ??= makeClient(process.env.LUMEN_FILES_API_BASE_URL)

export const callLumen      = (opts) => getWalletsClient().request(opts)
export const callLumenFiles = (opts) => getFilesClient().request(opts)
```

**Error normalizer (from wallet-management-sample):**

```js
export function extractError(err) {
  return (
    err?.response?.data?.errorMsg ??
    err?.response?.data?.error ??
    err?.response?.data?.message ??
    err?.response?.data?.details ??
    err?.message ??
    'Unknown Lumen error'
  )
}
```

**Fail-fast env check (from wallet-auth-sample/server/src/middleware/envCheck.js):**

```js
const required = [
  'LUMEN_API_BASE_URL',
  'LUMEN_FILES_API_BASE_URL',
  'LUMEN_API_KEY',
  'LUMEN_API_SECRET',
]
const missing = required.filter((k) => !process.env[k])
if (missing.length) {
  console.error(`[envCheck] Missing required env vars: ${missing.join(', ')}`)
  process.exit(1)
}
```

Run before the HTTP server starts. Crashes early with a clear message instead of returning 500s at runtime.

---

## 6. MintReceipt pattern — IC's verification loop addition

**This is NOT in any sample.** The sample apps demonstrate calling Lumen; they do not demonstrate *verifying* mint completion. For systems with strong on-chain provenance requirements (like IC's DPWH project), IC adds this pattern on top.

### 6.1 The receipt

Stored in IC's own Cosmos container `MintReceipts`, partitioned by `/PackageID`:

```ts
type MintReceipt = {
  id: string
  PackageID: string
  Version: number
  FileID: string | null          // null for Kind='DeployContract'
  Kind: 'DeployContract' | 'MintFile'
  Status: 'Pending' | 'Confirmed' | 'Failed'
  LumenWorkflowID: string         // returned by /file/create or /file/deployContract
  ContractAddress?: string        // populated on deploy-contract confirmation
  TransactionHash?: string        // populated on mint confirmation
  ConfirmedTS?: number
  Error?: string
  RetryCount: number
  CreatedTS: number
  UpdatedTS: number
}
```

### 6.2 The lifecycle

```
Phase A — IC commits BEFORE the Lumen call
  Insert MintReceipt(Status='Pending', LumenWorkflowID=null)

Phase B — Lumen call
  POST /file/create/{encodedPath}  →  { WorkflowID }
  Update MintReceipt(LumenWorkflowID=WorkflowID)

Phase C — Verification worker (timer, every 30s)
  Query MintReceipts WHERE Status='Pending' AND RetryCount < 20
  For each:
    GET /file/workflow/{WorkflowID}/status   (confirm route with Lumen team)
    → 'Confirmed':  record TransactionHash, ConfirmedTS, Status='Confirmed'
    → 'Failed':     record Error, Status='Failed', push WebPubSub MINT_FAILED to admin UI
    → still 'Pending': RetryCount++, leave for next tick
    → after 20 retries: Status='Failed' with a TIMEOUT error
```

**Why this matters:** the WorkflowID from Lumen is a queue ticket, not a confirmation. Without the verification loop, an IC system has no way to distinguish "the mint succeeded" from "the mint failed silently". For a government document-integrity system, that distinction is the whole product.

### 6.3 Guarantees

- Every Lumen call has an IC commit BEFORE the call (Phase A) — no orphan calls possible.
- A network blip between Phase A and Phase B leaves a recoverable Pending receipt with `LumenWorkflowID=null` — detectable, retriable.
- Partial failure (5 files, 1 fails) is recoverable per-receipt — retry just the failed FileID, don't re-mint the package.

---

## 7. Sample webapp index

| Sample | Persona | What to copy from it |
|---|---|---|
| **files-management-sample-webapp** | Org admin managing files | The full Files API client + route shapes. Two-step upload. Folder create. Metadata edit / archive / restore / delete. UI for org file CRUD. |
| **wallet-and-files-sample-webapp** | Org admin combining both APIs | The two-base-URL pattern (`walletsClient` + `filesClient`). Confirms `LUMEN_API_BASE_URL` ends in `/wallet`, `LUMEN_FILES_API_BASE_URL` ends in `/file`. |
| **wallet-management-sample-webapp** | Org admin managing custodial wallets | Pagination + sort + search query shape. `shortenAddress` UI helper. `extractError` normalizer. Rate-limit + Helmet on BFF. |
| **wallet-auth-sample-webapp** | End user signing in | The complete Custodial OAuth dance. sessionStorage token pattern. `envCheck` middleware. Per-request `lumen-user-token` injection. |
| **mvp-baas-dev-webapp** | Developer exploring APIs | OpenAPI-driven explorer. `useOpenApiSpec` hook. `resolveRequiredAuthHeaders`. Three auth modes UI. Standalone tools: ChecksumGenerator, SasUrlPutTester (great QA helpers). |

When in doubt, **start from `wallet-auth-sample-webapp`** — it has the cleanest client + middleware structure and is the most copy-pastable.

---

## 8. Common pitfalls (from IC's audit debugging session)

These are the specific bugs that bit IC's old codebase. Don't repeat them.

1. **Per-segment path encoding instead of whole-string.** Wrong: `Flood%20Control/Documents`. Right: `Flood%20Control%2FDocuments`. The APIM router rejects the wrong form with the generic gateway 404 (`{"statusCode":404,"message":"Resource not found"}`), making it look like the route doesn't exist when actually only the encoding is wrong.

2. **Forgetting the APIM service-prefix suffix.** Wrong: `LUMEN_URL=https://lumen-apim-stg.azure-api.net`. Right: `LUMEN_WALLET_URL=https://lumen-apim-stg.azure-api.net/wallet` and `LUMEN_FILES_URL=https://lumen-apim-stg.azure-api.net/file`. Without the suffix every route 404s.

3. **Missing `OwnerAddress` on file-create body.** The published dev-kit type marks it optional. The deployed server requires it. Omission → generic "complete all required fields" error.

4. **Missing `Size` or `MimeType`.** Same as above — published types say optional, server says required.

5. **Body `Path` without leading slash.** Wrong: `{"Path":"Flood Control/Package"}`. Right: `{"Path":"/Flood Control/Package"}`. Lumen returns `INVALID_PATH` (no detail) if missing.

6. **Using `localStorage` for session token.** Wrong (persists across tab close, larger XSS attack surface). Right: `sessionStorage`.

7. **Calling Lumen from the browser.** Wrong (exposes API key + secret). Right: all calls via a BFF.

8. **Treating WorkflowID as confirmation.** Wrong. Right: poll `getWorkflowStatus` until `Confirmed` or `Failed`. The WorkflowID is a queue ticket, not a receipt.

9. **Per-folder pre-deployed contracts.** Older Lumen orgs sometimes had ContractAddress baked into folder metadata, so every file in `/Type/Gallery` minted into the same contract. This destroys per-package provenance. New integrations should deploy a contract per logical unit (per package, per asset, etc.) and store the address on the unit, not the folder.

10. **Treating Lumen as a general document store.** Lumen is a minting + provenance layer. Files that don't need an on-chain audit trail should live in your own storage. Pushing everything to Lumen creates unnecessary friction, costs gas you don't need to pay, and couples your data model to Lumen's constraints (naming, structure, latency).

11. **Assuming "file created" means "file minted."** ★ The most common silent failure. The file's DIRECT parent folder must be `FolderType: 'collection'` for the mint to fire. If the parent is `'directory'` (or a directory tree of any depth — even with a `collection` ancestor higher up), the file lives off-chain and never gets a TransactionHash. POST /file/create returns 200 either way, the SAS upload works either way, the file shows up in directoryItems either way — but the mint workflow either fires or no-ops based purely on the direct parent's `FolderType`. See §2.0. **Always verify the direct parent folder's FolderType before assuming a file will mint.** If you're designing a folder tree for a per-package contract pattern, make the package-level folder the collection and put files flat directly inside it.

---

## 9. Reference files (incremental)

These reference files in `references/` will be populated as the IC rework progresses through Track 2. They're stubs for now — added here so the skill structure stays consistent with `skill-lumen-dev`'s convention.

| File | Covers | Status |
|---|---|---|
| `references/files-api.md` | Full Files API endpoint reference with curl examples | TBD — populate during Phase 4 |
| `references/wallets-api.md` | Full Wallets API + Custodial OAuth flow examples | TBD — only if Track 2 expands to wallet flows |
| `references/sample-webapps.md` | Deep inventory of all 5 sample webapps | TBD — populate during Step 0 follow-up |
| `references/mint-receipts.md` | MintReceipt schema + worker implementation patterns | TBD — populate during Phase 5 |
| `references/troubleshooting.md` | All the gotchas from §8 with reproduction + fix steps | TBD — populate as bugs surface during execution |

---

## How to use this skill

When the user is integrating Lumen Dev APIs in any project:

1. **Identify which API surface** (Files vs Wallets vs both).
2. **Identify the persona** (org admin, end user, developer) — this picks the auth mode.
3. **Read the relevant section above** before writing code.
4. **Copy the canonical client (§5) verbatim** as your starting point.
5. **For systems that need on-chain provenance, add the MintReceipt pattern (§6)** on top of the bare Lumen integration — the samples don't do this, but the samples aren't government-grade audit systems.
6. **Run through the pitfalls in §8** before declaring done.

## Provenance

Authored 2026-06-05 as part of the IC DPWH rework plan (`C:\Users\irent\.claude\plans\great-now-we-have-sequential-wall.md`, Pre-Execution Step 0). Source material: 5 sample webapps in `C:\Users\irent\OneDrive\Documents\GitHub\`. Pairs with `skill-lumen-dev` for ecosystem-wide context (entities, modules, infrastructure).
