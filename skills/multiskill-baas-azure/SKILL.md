---
name: multiskill-baas-azure
description: >
  Bundle skill — loads the full Azure SDK + Cosmos best-practices toolset
  in one shot. Use when working on anything that touches `src/azure/**`:
  Cosmos containers, Blob Storage, Key Vault secrets/keys, service principal
  auth, RU/partition design. Triggers: Azure, Cosmos, Blob, Key Vault,
  storage container, partition key, RU, DefaultAzureCredential, managed
  identity, @azure/*, lumen-cosmos-*, lumen-vault-*, lumen-sto*.

  Loads these specialist skills sequentially:
    - skill-azure-cosmos-ts
    - skill-azure-storage-blob-ts
    - skill-azure-keyvault-secrets-ts
    - skill-azure-keyvault-keys-ts
    - skill-azure-identity-ts
    - skill-cosmosdb-best-practices

  Prefer this bundle over calling each individually when the task spans
  multiple Azure services. For surgical work on one service, invoke the
  specific skill instead (e.g. just `skill-azure-cosmos-ts` for a query
  rewrite).
---

# BaaS Azure Stack Bundle

This bundle activates the **full Azure cloud-side toolset** for mvp-baas-backend in one slash command. Use when your task touches multiple Azure services or you want all the relevant SDK + best-practices context loaded at once.

## What this bundle loads

When this skill triggers, immediately invoke the `Skill` tool for each of the following — in order — so all their context is in scope before you start the task:

1. **`skill-azure-cosmos-ts`** — `@azure/cosmos` SDK: CRUD, queries, bulk ops, partition keys
2. **`skill-cosmosdb-best-practices`** — Cosmos performance/cost rules (RU, partitioning, query design)
3. **`skill-azure-storage-blob-ts`** — `@azure/storage-blob` SDK: BlobServiceClient, SAS, streaming
4. **`skill-azure-keyvault-secrets-ts`** — `@azure/keyvault-secrets` SDK: secret CRUD
5. **`skill-azure-keyvault-keys-ts`** — `@azure/keyvault-keys` SDK: signing, encryption, rotation
6. **`skill-azure-identity-ts`** — `@azure/identity` SDK: DefaultAzureCredential, managed identity, SP

## When to use this bundle vs an individual skill

| Use the bundle when… | Use a single skill when… |
|---|---|
| Adding a new entity-module that needs Cosmos + Blob + Vault | Just rewriting one Cosmos query |
| Debugging "why is this slow / expensive" across Azure surface | Reading a SAS token spec |
| Reviewing PRs that touch multiple Azure SDKs | Looking up one DefaultAzureCredential option |
| Onboarding a new dev to the workspace | — |

## Workspace-specific pointers

- All Cosmos containers extend `IContainerWrapper<T>` in `src/azure/cosmos/`. Each declares its partition keys as a class field.
- Blob storage uses **one container per organization**, keyed by `OrganizationID`. See `BlobStorage` in `src/azure/storage/`.
- Key Vault secrets follow naming patterns like `EXTCOL-<orgID>-<addr>` for external collections, `<env>-lumen-priv-pem-<env>` for JWT keys.
- Service principal config lives in `.env`: `AZURE_TENANT_ID`, `AZURE_CLIENT_ID`, `AZURE_CLIENT_SECRET`.

For workspace-wide architecture context, also load `skill-baas-backend` (the master switchboard).
