---
name: multiskill-baas-architect
description: >
  Bundle skill — loads the full senior-engineer / architect / CTO toolset
  in one shot. Use when planning new features, decomposing services,
  refactoring at scale, or making technology decisions for mvp-baas-backend.
  Triggers: architecture, system design, ADR, architecture decision,
  microservices, monolith, bounded context, DDD, hexagonal, ports and
  adapters, clean architecture, strangler fig, legacy migration, API
  design, OpenAPI, cloud architecture, Well-Architected, cost optimization,
  CTO, tech lead, senior, technical strategy, scalability planning.

  Loads these specialist skills sequentially:
    - skill-architecture-designer
    - skill-architecture-decision-records
    - skill-cloud-architect
    - skill-microservices-architect
    - skill-hexagonal-architecture
    - skill-backend-patterns
    - skill-api-designer
    - skill-legacy-modernizer

  Use this bundle when stepping back to think at a higher abstraction
  level — designing rather than coding. For surgical pattern questions
  invoke a specific skill instead.
---

# BaaS Architect / Senior / CTO Stack Bundle

This bundle loads the **senior-engineer thinking toolset** in one slash command. Use it when you're zooming out — designing a new feature end-to-end, planning a migration, deciding between two patterns, or producing an ADR. For tactical "show me how to write this query" work, skip the bundle and call the relevant specialist directly.

## What this bundle loads

When this skill triggers, invoke the `Skill` tool for each of:

1. **`skill-architecture-designer`** — System design, diagrams, scalability planning, tech trade-offs
2. **`skill-architecture-decision-records`** — ADR capture, decision context + rationale
3. **`skill-cloud-architect`** — Azure/AWS/GCP architecture, Well-Architected Framework, cost optimization, DR
4. **`skill-microservices-architect`** — Bounded contexts, sagas, event sourcing, CQRS, distributed tracing
5. **`skill-hexagonal-architecture`** — Ports & Adapters, dependency inversion, domain isolation
6. **`skill-backend-patterns`** — Repository/service/controller layers, N+1, caching, server-side patterns
7. **`skill-api-designer`** — REST/GraphQL design, OpenAPI specs, versioning, pagination
8. **`skill-legacy-modernizer`** — Strangler-fig, branch-by-abstraction, monolith decomposition, language/framework upgrades

## When to use this bundle vs individual skills

| Use the bundle when… | Use a single skill when… |
|---|---|
| Designing a new entity-module from scratch | Just sketching one route |
| Planning the Glassnet chain migration | Asking about one ADR detail |
| Refactoring the dual-runtime split | Looking up one Well-Architected pillar |
| Decomposing a monolith piece | — |
| Drafting an OpenAPI spec for a new endpoint | — |
| Producing a CTO-level technical review | — |

## Workspace-specific pointers

The mvp-baas-backend codebase already implements several patterns this bundle covers — recognise them when reviewing:

- **Entity-Module pattern** — a domain-driven decomposition. Each entity is a bounded context; each module is a capability within it. See `references/entity-module-pattern.md` in `skill-baas-backend`.
- **Hexagonal-ish layout** — abstract `EntityModuleAPIs` / `IContainerWrapper<T>` / `IPreMiddleware` are ports; concrete subclasses are adapters. The workspace doesn't strictly enforce hexagonal but the bones are there.
- **Dual runtime as a port** — `RequestNormalizer` abstracts Azure Functions vs Express request shapes, treating both as adapters of the same port.
- **Saga-style flows** — `DirectoryItemsImport.importCollection` builds a rollback stack as it goes (PK store → ABI blob → Cosmos folder → EventLogs). Pure saga pattern, no Temporal — for longer flows, Temporal is the saga engine.

For workspace-wide architecture context, also load `skill-baas-backend`.
