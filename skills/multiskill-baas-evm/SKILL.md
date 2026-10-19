---
name: multiskill-baas-evm
description: >
  Bundle skill — loads ethers.js v6 safety nets + Temporal workflow knowledge
  in one shot. Use when working on anything that touches `src/web3/**` or
  `src/temporal/**`: contract reads/writes, event listeners, scrapers,
  workflow starters, long-running blockchain operations. Triggers: ethers,
  Polygon, Amoy, Glassnet, Prismo, ERC-721, ERC-20, contract address,
  selector, keccak256, token balance, decimals, Temporal, workflow,
  activity, signal, non-determinism, @temporalio/*, retryScheduler.

  Loads these specialist skills sequentially:
    - skill-nodejs-keccak256
    - skill-evm-token-decimals
    - skill-temporal-developer

  Prefer this bundle when the task spans on-chain reads + workflow
  orchestration (e.g. external-collection import, gas station refuel,
  archive flow). For pure contract-read work use the EVM skills alone.
---

# BaaS EVM + Temporal Stack Bundle

This bundle activates the **blockchain + durable-execution toolset** for mvp-baas-backend. Use when your task spans contract reads/writes AND workflow orchestration — the two domains are deeply intertwined in this codebase (every contract op that exceeds 230s gets wrapped in Temporal).

## What this bundle loads

When this skill triggers, invoke the `Skill` tool for each of the following:

1. **`skill-nodejs-keccak256`** — Prevents the silent SHA3-256 vs Keccak-256 trap in selectors, signatures, storage slots, address derivation
2. **`skill-evm-token-decimals`** — Prevents ERC-20/721 decimal-mismatch bugs across chains
3. **`skill-temporal-developer`** — Workflows, activities, signals/queries, non-determinism debugging, sagas, versioning, continue-as-new

## When to use this bundle vs an individual skill

| Use the bundle when… | Use a single skill when… |
|---|---|
| Building or reviewing an import / sync / archive flow | Just hashing a function selector |
| Debugging a Temporal workflow that calls ethers.js | Computing a token's decimal-safe amount |
| Designing a new long-running chain operation | Reading a single non-determinism quirk |
| Reviewing `feature/externalCollections` style PRs | — |

## Workspace-specific pointers

- ethers.js v6 (not v5). All providers use `ethers.JsonRpcProvider` with the URL from `POLYGON_RPC_HTTPS_URL`.
- Chain ID + network: `POLYGON_CHAIN_ID` (`'80002'` non-prod, `'137'` prod) + `ETHEREUM_NETWORK` (`'EVM'`).
- Workflow starters live in `src/temporal/starters/`. Worker lives in the sibling `Temporal-workflow` repo.
- Long ops wrapped in Temporal: import-external-collection, sync-external-collection, archive, copy, move, rename, file ops, plan-downgrade credit reset.
- Native gas token defaults: 70 MATIC (DEV) / 50 MATIC (PROD) — recalibrate per `GasStation.ts` if migrating to a chain with different gas economics.

For workspace-wide architecture context, also load `skill-baas-backend`.
