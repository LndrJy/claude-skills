---
name: multiskill-baas-quality
description: >
  Bundle skill — loads the implementation-quality toolset in one shot:
  TypeScript patterns, security hardening, code review, debugging,
  testing. Use when writing production-grade code in mvp-baas-backend,
  reviewing PRs, hardening security, or hunting a bug. Triggers:
  TypeScript, branded types, generics, tRPC, Zod, OWASP, JWT, security
  audit, code review, PR review, debugging, stack trace, root cause,
  unit test, integration test, E2E, coverage, mocking, k6, OWASP testing.

  Loads these specialist skills sequentially:
    - skill-typescript-pro
    - skill-secure-code-guardian
    - skill-code-reviewer
    - skill-debugging-wizard
    - skill-test-master

  Use this bundle when shipping new code or reviewing existing code at
  any layer. Pair with `multiskill-baas-azure` or `multiskill-baas-evm`
  if the task also spans one of those domains.
---

# BaaS Quality Stack Bundle

This bundle loads the **implementation-quality toolset** — the daily essentials for writing code that doesn't ship bugs. Use whenever you're authoring or reviewing code in `src/`.

## What this bundle loads

When this skill triggers, invoke the `Skill` tool for each of:

1. **`skill-typescript-pro`** — Generics, conditional/mapped types, discriminated unions, branded types, tRPC
2. **`skill-secure-code-guardian`** — OWASP Top 10, JWT, Zod input validation, password hashing, CORS/CSP
3. **`skill-code-reviewer`** — Bugs, security vulns, code smells, N+1, naming, architecture concerns
4. **`skill-debugging-wizard`** — Stack-trace analysis, log correlation, hypothesis-driven root cause
5. **`skill-test-master`** — Unit/integration/E2E test scaffolding, mocking, coverage, k6 perf, OWASP testing

## When to use this bundle vs individual skills

| Use the bundle when… | Use a single skill when… |
|---|---|
| Implementing a new feature end-to-end | Just writing one Zod schema |
| Doing a PR review for `feature/*` branches | Just running one type-level inference question |
| Hunting a production bug across multiple files | Just looking up one OWASP rule |
| Writing test coverage for a new entity-module | Just adding a unit test |
| Hardening an auth path | — |

## Workspace-specific pointers

- **Zod is the boundary** — every API handler validates `lumenContext.request` via a Zod schema in `src/schema/`. Inside entity methods, types are trusted.
- **Custom typed error classes** — `DirectoryItemsError`, `AdminError`, `KeyVaultError`, etc. extend `StandardError<typeof MergedErrorCodes>` and carry `code`, `message`, `statusCode`, `timestamp`. Always throw these; never raw `Error`.
- **`IContainerWrapper<T>`** is a generic abstract base. Subclasses fix `T` to a concrete interface (`IDirectoryItemsItem`, `IAdminItem`, etc.). `T` propagates through `readItem` / `queryItems` / `upsert` — useful pattern to recognise.
- **JWT keys live in Key Vault** — never bake into env. The `LUMEN_ADMIN_JWT_PRIV_NAME` env var stores the secret NAME, not the value.
- **No mocks for Cosmos in tests** — feedback memory: integration tests must hit a real Cosmos instance, not mocks (mock/prod divergence caused a prior incident).

For workspace-wide architecture context, also load `skill-baas-backend`.
