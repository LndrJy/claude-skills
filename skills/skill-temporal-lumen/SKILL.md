---
name: skill-temporal-lumen
description: Workspace-tuned Temporal companion for the Lumen ecosystem — the *starter-side* lives in `mvp-baas-backend/src/temporal/starters/` (kicks off workflows from Azure Functions / Express) and the *worker-side* lives in the sibling `Temporal-workflow` repo (defines workflows + activities, registers per-task-queue workers). This skill captures the conventions that diverge from generic Temporal usage and the gotchas the team has accumulated. Trigger when the user is writing or debugging anything involving workflow IDs, task queues, signal/update/query handlers, ApplicationFailure mapping, the `awaitWorkflowUpdate` recovery, SDK version pinning between repos, or worker registration. For raw Temporal SDK questions (non-Lumen), use `skill-temporal-developer` instead.
---

# Lumen Temporal Skill

Workspace-tuned companion for the Lumen ecosystem's Temporal usage. The platform is split across **two repos**:

| Repo | Role | What lives here |
|---|---|---|
| `mvp-baas-backend` | **Starter side** | `src/temporal/starters/*.ts` — kicked from Azure Functions / Express handlers. Builds workflow input + ID, calls `client.workflow.start`, awaits an update for synchronous result delivery. |
| `Temporal-workflow` (sibling repo) | **Worker side** | `src/workflows/`, `src/activities/`, `src/worker/`. Defines workflow logic, proxies activities, registers workers per task queue. |

Both depend on `@bayanichain/mvp-baas-sdk` — the backend's published package. Activities `require()` SDK entities and call entity methods (e.g. `new DirectoryItems().createFolder(...)`). **SDK version pinning between repos is the single most common source of silent bugs** (see §8).

## When to use this skill vs others

| If user is asking about… | This skill | Or escalate to… |
|---|---|---|
| Workflow IDs / task queue strings / signal+update+query names in `Temporal-workflow` or `src/temporal/starters/` | **this** | — |
| Raw Temporal SDK semantics (non-determinism rules, versioning API, child workflows) | `skill-temporal-developer` | + this for the Lumen pattern |
| `ApplicationFailure` → HTTP error mapping | **this** (§5, §7) | `skill-baas-backend` for the error class itself |
| Why a mint landed on the wrong chain | **this** (§8 SDK version pinning) + `skill-baas-backend` | — |
| New entity or new module | `skill-baas-backend` first | this for the Temporal touchpoints |
| Cosmos query inside an activity | `skill-azure-cosmos-ts` + `skill-cosmosdb-best-practices` | this for the activity wrapping |

## 1. Workflow ID conventions

Workflow IDs encode *entity context* deterministically so external systems (e.g. `blockchain-engine-server`) can compute the same ID and signal/query without lookup.

**Three structural shapes** (`src/temporal/starters/createFolderStarter.ts:49–55`):

```ts
// Collection folder with smart contract — chain-bound
`create-folder-NET${chain.Network}-CHAIN${chain.ChainID}-CON${contractID}`

// Sub-collection — inherits parent chain, name+path hashed
`create-folder-sub-NET${chain.Network}-CHAIN${chain.ChainID}-${SHA1(orgID/path/name)}`

// Directory — no chain context
`create-folder-dir-${SHA1(orgID/path/name)}`
```

**Operation-based pattern for files** (most other starters):

```ts
`copy-file-${SHA1(contextPath)}`
`delete-file-${SHA1(contextPath)}`
`batch-upload-${batchKey}-${timestampMs}`   // batch uploads stamp epoch to allow re-runs
```

**Default `workflowIdReusePolicy`**: `'ALLOW_DUPLICATE'`. This lets the same path/contract be recreated after deletion. Don't use `REJECT_DUPLICATE` unless you specifically want to fail the second call.

**External signaler contract**: `blockchain-engine-server` reconstructs the collection workflow ID from a contract's stamped `Network` + `ChainID` + `ContractID` to send `contractDeployedSignal`. Keep the format stable.

## 2. Task queue catalog

**17 distinct queues**, segmented by operation domain. No central constants file — each starter hardcodes its queue string. When adding a new starter, **grep first for an existing queue that fits** before inventing a new one:

| Domain | Queues |
|---|---|
| Folder/contract lifecycle | `create-folder-contract-workflow`, `create-policy-contract-workflow` |
| File operations | `file-lifecycle-task-queue`, `file-queue-task-queue` (per-file singleton), `delete-file-task-queue`, `ipfs-mint-task-queue` (slow path) |
| Folder operations | `copy-folder-task-queue`, `move-folder-task-queue`, `archive-task-queue` |
| Billing | `subscription-operations`, `credit-operations` |
| AI agent | `ai-agent-{action}-workflow` (per-action) |

**Slow-vs-fast split**: `fileLifecycleWorkflow.ts:48–96` proxies different activity groups to different queues — fast Cosmos ops on the default queue (5 min timeout), slow IPFS/mint on `ipfs-mint-task-queue` (10 min timeout). When an activity is slow + uses external network, give it its own queue + worker so backpressure doesn't stall the fast path.

**Singleton workflow pattern**: `fileQueueStarter.ts:27` uses `signalWithStart` against a workflow ID derived from the FILE, so concurrent ops on the same file are serialized into a queue inside that workflow. Useful for any "operations on resource X must be ordered" pattern.

## 3. Update vs Signal vs Query patterns

Lumen heavily favors **updates over signals** for API-blocking calls because updates return values synchronously to the starter:

| Mechanism | When to use | Examples in repo |
|---|---|---|
| **Update** (`defineUpdate`, `handle.executeUpdate`) | API request needs to block until a workflow step completes and return a value | `folderCreatedUpdate`, `fileCreatedUpdate`, `{operation}CompletedUpdate` |
| **Signal** (`defineSignal`, `handle.signal`) | Fire-and-forget event from an external source (blockchain listener, parent workflow) | `contractDeployedSignal`, `blobEventSignal`, `transferEventSignal`, `subscribeFileWorkflowSignal` |
| **Query** (`defineQuery`) | Read live workflow state without changing it | `folderLifecycleStatusQuery`, `fileLifecycleStatusQuery` (return phase: `'creating_folder' \| 'deploying_contract' \| 'minting' \| …`) |

**Naming conventions**:
- Updates: `{thing}Created`, `{operation}Completed` (past tense)
- Signals: `{event}Signal` (always suffixed `Signal`)
- Queries: `{entity}StatusQuery` (always suffixed `Query`)

**Update + `condition` pattern** (`createFolderWorkflow.ts:127–130`):
```ts
setHandler(folderCreatedUpdate, async () => {
  await condition(() => createdFolder !== null, '5m');  // wait up to 5m for state
  return createdFolder!;
});
```

The starter `await`s the update; the workflow blocks the update with `condition` until the relevant state is set, then returns it. Effectively gives the API caller a synchronous result without polling.

## 4. The `awaitWorkflowUpdate` recovery (Lumen-specific defensive code)

`src/temporal/starters/temporalErrorHelper.ts:82–98` — `awaitWorkflowUpdate` exists because of a real bug:

If a workflow throws an `ApplicationFailure` BEFORE the update RPC has been delivered to the worker, Temporal's `executeUpdate` rejects with the generic *"Workflow Update failed because the Workflow completed before the Update completed."* — that message does NOT contain the actual cause in its chain. So the starter would see a generic timeout-ish error instead of the real `NAME_ALREADY_EXISTS` / `PERMISSION_DENIED`.

```ts
export async function awaitWorkflowUpdate<T>(handle, updateName): Promise<T> {
  try {
    return await handle.executeUpdate<T, []>(updateName);
  } catch (updateError: any) {
    if (/completed before the [Uu]pdate/.test(updateError?.message)) {
      // Throws the workflow's terminal failure (ApplicationFailure-bearing) — re-extract real cause downstream.
      await handle.result();
    }
    throw updateError;
  }
}
```

**Always** use `awaitWorkflowUpdate(handle, updateName)` in starters, never raw `handle.executeUpdate(...)`.

## 5. Error mapping table

`temporalErrorHelper.ts:9–45` maps `ApplicationFailure.type` strings → `DirectoryItemsErrorCodes` + HTTP status. This is the contract activities throw against:

```ts
// In an activity — throw with the type string that matches the map:
import { ApplicationFailure } from '@temporalio/common';

throw ApplicationFailure.nonRetryable(
  'A folder with this name already exists in this location.',  // user-facing message
  'NAME_ALREADY_EXISTS'                                         // type — keys the mapping
);
```

The starter's catch block calls `rethrowFolderErrorAsDirectoryItemsError(error)` which:
1. Walks the cause chain to find a non-retryable `ApplicationFailure`
2. Maps its `type` → `DirectoryItemsErrorCodes`
3. Throws a `DirectoryItemsError(code, message, status)` with the right HTTP status

**Mapped types** (must be one of these for proper propagation): `NO_FILES_SELECTED`, `FILE_COUNT_EXCEEDED`, `FILE_SIZE_EXCEEDED`, `UNSUPPORTED_FILE_TYPE`, `DESTINATION_FOLDER_NOT_FOUND`, `PERMISSION_DENIED`, `FILE_NOT_FOUND`, `FILE_ALREADY_EXISTS`, `UPLOAD_TIMED_OUT`, `UPLOAD_INTERRUPTED`, `BLOCKCHAIN_TRANSACTION_FAILED`, `BLOCKCHAIN_SYNC_DELAY`, `MINT_FAILED`, `INCOMPLETE_RESPONSE`, `NAME_ALREADY_EXISTS`, `INVALID_PATH`, `FOLDER_NOT_FOUND`, `INVALID_FOLDER_NAME`, `INVALID_FOLDER_TYPE`.

**HTTP statuses** (unmapped → 400 for folder, 500 for file generic):
- 409 — `NAME_ALREADY_EXISTS`, `FILE_ALREADY_EXISTS`
- 404 — `*_NOT_FOUND`
- 403 — `PERMISSION_DENIED`
- 400 — `INVALID_*` and default

**Generic fallbacks**:
- Folder catch-all → `FOLDER_OPERATION_FAILED` (500) + logs the original error inline (recent fix — see `temporalErrorHelper.ts:140–150`)
- File catch-all → `FILE_UPLOAD_FAILED` (500)

## 6. Activity throw conventions

Activities NEVER re-throw raw SDK errors directly. They wrap via helpers in `Temporal-workflow/src/activities/_activityHelpers.ts`:

| Helper | What it catches | What it throws |
|---|---|---|
| `withNonRetryableOnNameExists(op, msg)` | `DirectoryItemsError(code='NAME_ALREADY_EXISTS')` OR Cosmos 409 | `ApplicationFailure.nonRetryable(msg, 'NAME_ALREADY_EXISTS')` |
| `withNonRetryableOnPolicy(op)` | `code='PERMISSION_DENIED'` or known policy error messages | `nonRetryable(...,  'PERMISSION_DENIED')` |
| `withCompactError(op)` | Anything with multi-KB Cosmos diagnostic blobs | Re-throws with `compactErrorMessage()` (≤1500 chars) — stays under Temporal's **256KB payload ceiling** |
| `ignoreConflict(op)` | Cosmos 409 on `create*` operations | Returns `undefined` — idempotent retry safety |

**Always** wrap your activity body in one of these. Raw throws lose the type mapping in §5 and may exceed the 256KB ceiling.

## 7. Workflow file structure

Every workflow follows this template (`fileLifecycleWorkflow.ts`, `createFolderWorkflow.ts`, etc.):

```ts
// 1. Activity proxy setup at module level — segment by speed/queue
import * as activities from '../activities';
import * as ipfsActivities from '../activities/ipfsActivities';

const fast = proxyActivities<typeof activities>({
  startToCloseTimeout: '5m',
  retry: { initialInterval: '1s', maximumAttempts: 5 },
});

const slow = proxyActivities<typeof ipfsActivities>({
  startToCloseTimeout: '10m',
  taskQueue: 'ipfs-mint-task-queue',                // dedicated worker
  retry: { initialInterval: '2s', maximumAttempts: 3 },
});

// 2. Signal/Query/Update definitions at module scope
export const folderCreatedUpdate = defineUpdate<IDirectoryFolderItem, []>('folderCreated');
export const contractDeployedSignal = defineSignal<[{ contractAddress: string }]>('contractDeployedSignal');
export const folderLifecycleStatusQuery = defineQuery<string>('folderLifecycleStatusQuery');

// 3. Strongly-typed input — no untyped Workflow Args
export async function createFolderWorkflow(
  organizationID: string,
  prepared: IDirectoryFolderPreCreate,
  performerID?: string,
): Promise<void> {
  let createdFolder: IDirectoryFolderItem | null = null;
  let phase = 'creating_folder';

  // 4. Handlers inside workflow body
  setHandler(folderLifecycleStatusQuery, () => phase);
  setHandler(folderCreatedUpdate, async () => {
    await condition(() => createdFolder !== null, '5m');
    return createdFolder!;
  });
  setHandler(contractDeployedSignal, ({ contractAddress }) => {
    // mutate state — workflow continues
  });

  // 5. Workflow body — activities, conditions, sleep, continueAsNew
  createdFolder = await fast.createFolderRow(organizationID, prepared, performerID);
  // …
}
```

**Activity proxy guidance**:
- Default fast queue, 5 min timeout for Cosmos ops
- `ipfs-mint-task-queue`, 10 min timeout for IPFS/mint
- Tight retry policy (`maximumAttempts: 3`, fixed-interval) for post-mint finalization

## 8. The SDK version pinning trap (⚠️ critical)

**`Temporal-workflow/package.json` pins `@bayanichain/mvp-baas-sdk`**. Activities import SDK entities (`DirectoryItems`, `EventGrid`, `ERC721Contract`, etc.) from that published version. **Activities will silently use whatever SDK was published, even if the backend's `feature/*` branch has newer code.**

**The 2026-05-26 bug** (documented in `PRISMO_PROGRESS.md §3` on the `feature/PrismoDev` branch of `mvp-baas-backend`):

- Worker depended on `@bayanichain/mvp-baas-sdk: ^1.3.0-staging.10`
- That version pre-dated commit `e45b2fcb` ("feat(event-grid): resolve mint RPC from contract doc's stamped ChainID")
- The published SDK still had `new ERC721Contract(secret, address)` without `rpcUrl`
- Mints fell back to `POLYGON_RPC_HTTPS_URL` → tx landed on Amoy at the Prismo contract address
- That address doesn't exist on Amoy, so the tx mined as a 0-value transfer with mint calldata — no NFT created
- **Diagnosis**: the file's Cosmos doc had `ChainID: "101001000"` (Prismo), and the backend log showed the right resolution — but the worker, on the old SDK, never read it.

**Three fix paths when this happens**:

| Path | When | Lifetime |
|---|---|---|
| **A** — publish new SDK staging version, bump worker's dep | Right answer for shipping. Multi-dev teams. | Permanent |
| **B** — `npm link` local SDK into worker | Fastest iteration. Single machine. | Dev session |
| **C** — `"file:../mvp-baas-backend"` dep in worker | Survives across machines if relative path stable | Per-developer |

**Rule of thumb**: before debugging an "activity does the wrong thing" issue, **check the worker's installed SDK version** against `git log` for the backend commit that introduced the expected behavior:

```bash
cd Temporal-workflow
cat node_modules/@bayanichain/mvp-baas-sdk/package.json | grep version
```

## 9. "Prepare before workflow start" pattern

In `createFolderStarter.ts`, `prepareFolderData` runs **synchronously before `workflow.start`**:

```ts
const directoryItems = new DirectoryItemsCreateFolder();
const prepared = await directoryItems.prepareFolderData(organizationID, folderData);  // validates + writes Cosmos row

// only THEN start the workflow with the already-prepared data
const handle = await client.workflow.start('createFolderWorkflow', {
  args: [organizationID, prepared, performerID],
  // …
});
```

**Why**: the validation step throws `DirectoryItemsError` synchronously (e.g. `NAME_ALREADY_EXISTS` → 409). The API caller gets the right error code WITHOUT having to spin up a workflow first.

**When to use this pattern**:
- Validation that can be done without on-chain or long-running calls
- Cosmos writes that should fail fast on conflict
- Anything where the API caller needs to know "this was rejected" with a specific error code

**When NOT to use it**:
- File-create style flows where the work itself is the validation — those flow straight to the workflow and the worker activities surface errors via `ApplicationFailure`

## 10. Worker entry point

`Temporal-workflow/src/worker/index.ts` orchestrates ~26 parallel workers. Each follows the same shape (`creditWorker.ts` is the canonical example):

```ts
const connection = await createTemporalConnection();  // cloud-or-local auto-detection
const worker = await Worker.create({
  connection,
  namespace: process.env.TEMPORAL_NAMESPACE!,
  taskQueue: 'credit-operations',                     // one queue per worker
  workflowBundle,                                      // pre-compiled once (see below)
  activities: creditActivities,                        // only this worker's activities
  maxConcurrentActivityTaskExecutions: 5,
});
await worker.run();
```

**Pre-compiled workflow bundle**: `bundleWorkflowCode()` is called ONCE at startup (`index.ts:92–94`) and shared across all 26 workers. Without this, webpack compiles 26 times sequentially — slow startup.

**Health server**: main `index.ts` runs an HTTP server on `AZURE_HEALTH_PORT` (default 80) that reports per-worker status (`starting` / `running` / `failed`). Azure Container App's liveness probe hits this.

**Adding a worker**:
1. New file `src/worker/{domain}Worker.ts` matching the credit-worker shape
2. Register it in `src/worker/index.ts`'s startup list
3. Set its `taskQueue` to match the queue your starters use
4. Add the matching activities import — usually one activity module per worker

## 11. Cloud vs local routing

`src/worker/connection.ts:11–12` detects Temporal Cloud by URL suffix:

```ts
const isCloud = address.includes('.tmprl.cloud') || address.includes('.temporal.io');
```

**Cloud connection** (`TEMPORAL_ADDRESS=ap-southeast-1.aws.api.temporal.io:7233`):
- Requires `TEMPORAL_API_KEY` env (JWT — see `.env.example`)
- Optional `TEMPORAL_MTLS_TLS_CERT` + `TEMPORAL_MTLS_TLS_KEY` for mTLS
- Namespace: `quickstart-lumen-workflow-scheduler.fvu8x` (DEV) — check `TEMPORAL_NAMESPACE`

**Local connection** (`TEMPORAL_ADDRESS=localhost:7233`):
- No auth, no TLS
- Run `temporal server start-dev` from the Temporal CLI

No explicit toggle — detection is automatic. If env points to a `localhost:7233` you forgot to start, the worker logs `Failed to connect` and crashes; no fallback.

## 12. Lumen-specific quirks (read once, save hours later)

- **`patched()` for in-flight workflows after migration** (`createFolderWorkflow.ts:166`): `patched('poll-contract-deployment-via-cosmos')` lets a workflow started before the migration take the old branch and new starts take the new one. Use this when changing logic that runs in long-lived workflows; do NOT just delete old code paths.
- **Polling via retry-loop instead of `sleep`** (`createFolderWorkflow.ts:24–36`): `waitForContractDeployed` activity throws while `status !== 'Deployed'`, with `backoffCoefficient: 1` (constant interval) + `maximumAttempts: 600` + 30s heartbeat. Avoids bloating workflow history with sleep events.
- **Compact error messages to stay under 256KB**: `compactErrorMessage()` (`_activityHelpers.ts:87–106`) strips Cosmos diagnostic blobs to 1500 chars. Always wrap your throw if the error might carry SDK diagnostic data.
- **Idempotent creates**: `ignoreConflict()` (`_activityHelpers.ts:74–81`) on activity-level Cosmos create operations — Temporal retries don't fail on duplicate-key. Pair this with deterministic IDs (e.g. UUIDv5 from input) for fully idempotent activities.
- **Activity-level error labels with `chainTag`**: For chain-bound work, prefix log lines with `[ContractDeployment:${chainTag}]` / `[ChainBlockMonitor:${Network}-${ChainID}]` for grep-ability across multi-chain flows.

## 13. Adding a new workflow — recipe

1. **Pick or create a task queue** in §2. New queue → new worker in §10.
2. **In `Temporal-workflow/src/workflows/`**: new file. Module-level `proxyActivities` (segment by speed) + signal/update/query `define*` exports + typed input + `setHandler` registrations + workflow body.
3. **In `Temporal-workflow/src/activities/`**: matching activity file. Wrap each activity body with the right `_activityHelpers` helper (§6).
4. **In `mvp-baas-backend/src/temporal/starters/`**: new file `start{Operation}Workflow.ts`. Build the workflow ID per §1. `await prepareData(...)` if applicable (§9). `client.workflow.start(...)`. `await awaitWorkflowUpdate(handle, updateName)` (§4). Wrap in `rethrowAsDirectoryItemsError` (§5).
5. **Register the new worker** in `Temporal-workflow/src/worker/index.ts` if the queue is new.
6. **Bump SDK version + republish** if the workflow needs newer backend code (§8).
7. **Test locally**: `npm run dev` in `Temporal-workflow`, then run the Express handler in `mvp-baas-backend` that fires the starter.

## 14. Common gotchas — quick reference

| Symptom | Likely cause | Fix |
|---|---|---|
| API returns generic 500, no specific error code | `awaitWorkflowUpdate` not used; raw `executeUpdate` swallowed the workflow's real failure | Use `awaitWorkflowUpdate` from `temporalErrorHelper.ts` |
| Mint lands on wrong chain | Worker's SDK pre-dates chain-aware code | Check `node_modules/@bayanichain/mvp-baas-sdk/package.json` version; pick path A/B/C from §8 |
| Activity payload too big to deserialize | Throwing raw Cosmos error with multi-KB diagnostic | Wrap throw with `compactErrorMessage()` or `withCompactError(...)` |
| Workflow stuck "creating_folder" forever | Update handler `condition` never resolves | Check that the state variable the condition reads is being set in the workflow body |
| `signalWithStart` says "workflow already running" | Singleton-workflow pattern (§2) — that's expected | Catch + ignore for fire-and-forget signals |
| Worker can't connect on startup | `TEMPORAL_ADDRESS` env wrong, or `TEMPORAL_API_KEY` expired in Cloud | Check env vars; for Cloud, check key expiry in Temporal Cloud UI |
| New workflow not picked up | Worker doesn't subscribe to its task queue | Add worker registration in `worker/index.ts` |
| Workflow history exploding | `sleep()` polling instead of retry-loop activity | Switch to activity with `backoffCoefficient: 1` + `maximumAttempts` |

## Companion skills

Load these alongside this skill for related work:

| Skill | Why |
|---|---|
| `skill-temporal-developer` | Raw SDK semantics (versioning, child workflows, non-determinism) — generic Temporal questions |
| `skill-baas-backend` | When the starter lives in `mvp-baas-backend`, this points at the entity/module/error-class plumbing |
| `skill-azure-cosmos-ts` + `skill-cosmosdb-best-practices` | When an activity does Cosmos reads/writes |
| `skill-prismo-dev` | When the workflow signals/queries from `blockchain-engine-server` (chain side) |

## Key file pointers

**Starter side** (`mvp-baas-backend`):
- `src/temporal/starters/createFolderStarter.ts` — workflow ID + start + `awaitWorkflowUpdate`
- `src/temporal/starters/temporalErrorHelper.ts` — error mapping + recovery helper
- `src/temporal/starters/fileQueueStarter.ts` — singleton-workflow + `signalWithStart`
- `src/temporal/client/client.ts` — cloud/local connection construction

**Worker side** (`Temporal-workflow`):
- `src/worker/index.ts` — orchestration of 26 workers
- `src/worker/connection.ts` — cloud/local auto-detect
- `src/worker/creditWorker.ts` — canonical worker template
- `src/workflows/createFolderWorkflow.ts` + `fileLifecycleWorkflow.ts` — canonical workflow templates
- `src/activities/createFolderActivities.ts` — typed activity wrappers
- `src/activities/_activityHelpers.ts` — `withNonRetryableOnNameExists`, `withCompactError`, `ignoreConflict`, `compactErrorMessage`

## Versioning

Keep this skill aligned with `feature/PrismoDev` branch of both repos. When a Temporal pattern changes (new queue, new helper, new error code), update the matching section here and bump the file's mtime.
