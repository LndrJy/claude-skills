# claude-skills

My personal Claude Code skills (92), from `claude-skills-2026-08-11.zip`.

## Install on a new device

```bash
git clone https://github.com/LndrJy/claude-skills.git ~/code/claude-skills
bash ~/code/claude-skills/install.sh          # installs into ~/.claude/skills
```

On Windows, run it from Git Bash, which Claude Code already needs. To update later: `git pull && bash install.sh`.
Restart Claude Code, or open a new session, to pick the skills up.

`install.sh` flattens nested skills, because Claude Code only discovers `~/.claude/skills/<name>/SKILL.md`:

- `skills/<name>/` goes to `~/.claude/skills/<name>/`, unchanged.
- `skills/skill-superpowers/skills/<n>/` goes to `~/.claude/skills/<n>/`.
- `skills/superpowers/<category>/` is copied whole, because those skills link to `~/.claude/skills/<category>/...`.
- Each classic skill also gets a discoverable copy at `~/.claude/skills/superpowers-classic-<n>/`, with its frontmatter `name` set to that slug.

It replaces only those folders and leaves anything else in `~/.claude/skills` alone.

Not wired up: the hook scripts (`skills/skill-superpowers/hooks/session-start`, `skills/superpowers/collaboration/remembering-conversations/tool/install-hook`). Register them yourself if you want them.

## Installed skills

| Skill | Description |
|---|---|
| `brainstorming` | You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requi... |
| `dispatching-parallel-agents` | Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies |
| `executing-plans` | Use when you have a written implementation plan to execute in a separate session with review checkpoints |
| `finishing-a-development-branch` | Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting s... |
| `multiskill-baas-architect` | Bundle skill — loads the full senior-engineer / architect / CTO toolset in one shot. Use when planning new features, decomposing services, refactoring at sca... |
| `multiskill-baas-azure` | Bundle skill — loads the full Azure SDK + Cosmos best-practices toolset in one shot. Use when working on anything that touches `src/azure/**`: Cosmos contain... |
| `multiskill-baas-blockchain` | Bundle skill — loads the full blockchain / Solidity / EVM toolset in one shot. Use when working on smart contract code, on-chain reads/writes, contract upgra... |
| `multiskill-baas-evm` | Bundle skill — loads ethers.js v6 safety nets + Temporal workflow knowledge in one shot. Use when working on anything that touches `src/web3/**` or `src/temp... |
| `multiskill-baas-quality` | Bundle skill — loads the implementation-quality toolset in one shot: TypeScript patterns, security hardening, code review, debugging, testing. Use when writi... |
| `receiving-code-review` | Use when receiving code review feedback, before implementing suggestions, especially if feedback seems unclear or technically questionable - requires technic... |
| `requesting-code-review` | Use when completing tasks, implementing major features, or before merging to verify work meets requirements |
| `skill-api-designer` | Use when designing REST or GraphQL APIs, creating OpenAPI specifications, or planning API architecture. Invoke for resource modeling, versioning strategies, ... |
| `skill-architecture-decision-records` | Capture architectural decisions made during Claude Code sessions as structured ADRs. Auto-detects decision moments, records context, alternatives considered,... |
| `skill-architecture-designer` | Use when designing new high-level system architecture, reviewing existing designs, or making architectural decisions. Invoke to create architecture diagrams,... |
| `skill-azure-cosmos-ts` | Azure Cosmos DB JavaScript/TypeScript SDK (@azure/cosmos) for data plane operations. Use for CRUD operations on documents, queries, bulk operations, and cont... |
| `skill-azure-identity-ts` | Authenticate to Azure services using Azure Identity library for JavaScript (@azure/identity). Use when configuring authentication with DefaultAzureCredential... |
| `skill-azure-keyvault-keys-ts` | Manage cryptographic keys using Azure Key Vault Keys SDK for JavaScript (@azure/keyvault-keys). Use when creating, encrypting/decrypting, signing, or rotatin... |
| `skill-azure-keyvault-secrets-ts` | Manage secrets using Azure Key Vault Secrets SDK for JavaScript (@azure/keyvault-secrets). Use when storing and retrieving application secrets or configurati... |
| `skill-azure-storage-blob-ts` | Azure Blob Storage JavaScript/TypeScript SDK (@azure/storage-blob) for blob operations. Use for uploading, downloading, listing, and managing blobs and conta... |
| `skill-baas-backend` | BaaS backend development companion for the mvp-baas-backend SDK by BayaniChain — TypeScript + Azure Functions (production) + Express (local dev) + Cosmos DB ... |
| `skill-backend-patterns` | Backend architecture patterns, API design, database optimization, and server-side best practices for Node.js, Express, and Next.js API routes. |
| `skill-caveman` | Ultra-compressed communication mode. Cuts token usage ~75% by speaking like caveman while keeping full technical accuracy. Supports intensity levels: lite, f... |
| `skill-cloud-architect` | Designs cloud architectures, creates migration plans, generates cost optimization recommendations, and produces disaster recovery strategies across AWS, Azur... |
| `skill-code-reviewer` | Analyzes code diffs and files to identify bugs, security vulnerabilities (SQL injection, XSS, insecure deserialization), code smells, N+1 queries, naming iss... |
| `skill-cosmosdb-best-practices` | Azure Cosmos DB performance optimization and best practices guidelines for NoSQL, partitioning, queries, and SDK usage. Use when writing, reviewing, or refac... |
| `skill-debugging-wizard` | Parses error messages, traces execution flow through stack traces, correlates log entries to identify failure points, and applies systematic hypothesis-drive... |
| `skill-eth-addresses` | Verified contract addresses for major Ethereum protocols across mainnet and L2s. Use this instead of guessing or hallucinating addresses. Includes Uniswap, A... |
| `skill-eth-gas` | Current Ethereum gas prices, transaction costs, and the real economics of building on Ethereum today. Use when estimating costs, choosing between mainnet and... |
| `skill-eth-l2s` | Ethereum Layer 2 landscape — Arbitrum, Optimism, Base, zkSync, Scroll, Unichain, Celo, and more. How they work, how to deploy on them, how to bridge, when to... |
| `skill-eth-security` | Solidity security patterns, common vulnerabilities, and pre-deploy audit checklist. The specific code patterns that prevent real losses — not just warnings, ... |
| `skill-eth-standards` | Ethereum token and protocol standards — ERC-20, ERC-721, ERC-1155, ERC-4337, ERC-8004, and newer standards. When to use each, how they work, key interfaces. ... |
| `skill-evm-token-decimals` | Prevent silent decimal mismatch bugs across EVM chains. Covers runtime decimal lookup, chain-aware caching, bridged-token precision drift, and safe normaliza... |
| `skill-hexagonal-architecture` | Design, implement, and refactor Ports & Adapters systems with clear domain boundaries, dependency inversion, and testable use-case orchestration across TypeS... |
| `skill-ic-dev` | Development companion for the IntegrityChain (IC) / DPWH government project — a 7-repo blockchain-document-integrity system spanning 4 Azure Functions backen... |
| `skill-legacy-modernizer` | Designs incremental migration strategies, identifies service boundaries, produces dependency maps and migration roadmaps, and generates API facade designs fo... |
| `skill-lumen-design-system` | Development companion for `@bayanichain/lumen-design-system` v1.1.0 — the org webapp design system by Bayanichain. React 19 + Tailwind v4 + Headless UI v2, w... |
| `skill-lumen-dev` | Unified development companion for the entire Lumen BaaS ecosystem by Bayanichain — spanning 40+ repos across backend SDK, Azure Function microservices, front... |
| `skill-lumen-files-api` | Reference companion for implementing the Lumen Dev API in any project. Covers all 5 public sample webapps (files-management-sample-webapp, wallet-and-files-s... |
| `skill-microservices-architect` | Designs distributed system architectures, decomposes monoliths into bounded-context services, recommends communication patterns, and produces service boundar... |
| `skill-nodejs-keccak256` | Prevent Ethereum hashing bugs in JavaScript and TypeScript. Node's sha3-256 is NIST SHA3, not Ethereum Keccak-256, and silently breaks selectors, signatures,... |
| `skill-oz-develop-secure-contracts` | Develop secure smart contracts using OpenZeppelin Contracts libraries. Use when users need to integrate OpenZeppelin library components — including token sta... |
| `skill-oz-setup-solidity-contracts` | Set up a Solidity smart contract project with OpenZeppelin Contracts. Use when users need to: (1) create a new Hardhat or Foundry project, (2) install OpenZe... |
| `skill-oz-upgrade-solidity-contracts` | Upgrade Solidity smart contracts using OpenZeppelin proxy patterns. Use when users need to: (1) make contracts upgradeable with UUPS, Transparent, or Beacon ... |
| `skill-postgres` | Use this skill for any PostgreSQL database work — table design, indexing, data types, constraints, extensions (pgvector, PostGIS, TimescaleDB), search, and m... |
| `skill-prismo-dev` | Development companion for Prismo — a hybrid L2 blockchain on Polygon CDK Erigon zkRollup, deployed on AWS EKS with Terraform, Helm, and Kubernetes. Trigger w... |
| `skill-secure-code-guardian` | Use when implementing authentication/authorization, securing user input, or preventing OWASP Top 10 vulnerabilities — including custom security implementatio... |
| `skill-superpowers` | Superpowers — Jesse Vincent / obra's agentic skills framework + software-development methodology (cloned from obra/superpowers). Bundle of 14 composable sub-... |
| `skill-temporal-developer` | Develop, debug, and manage Temporal applications across Python, TypeScript, Go, Java and .NET. Use when the user is building workflows, activities, or worker... |
| `skill-temporal-lumen` | Workspace-tuned Temporal companion for the Lumen ecosystem — the *starter-side* lives in `mvp-baas-backend/src/temporal/starters/` (kicks off workflows from ... |
| `skill-test-master` | Generates test files, creates mocking strategies, analyzes code coverage, designs test architectures, and produces test plans and defect reports across funct... |
| `skill-typescript-pro` | Implements advanced TypeScript type systems, creates custom type guards, utility types, and branded types, and configures tRPC for end-to-end type safety. Us... |
| `skill-ui-ux-pro-max` | AI-powered design intelligence toolkit — 67 UI styles, 161 color palettes, 57 font pairings, 99 UX guidelines, 25 chart types, logo generation (55 styles, Ge... |
| `skill-uplift-dev` | Development companion for the UPLIFT Crisis Dashboard Platform — a 4-repo full-stack system comprising uplift-dashboard-webapp (React 19 public dashboard), u... |
| `subagent-driven-development` | Use when executing implementation plans with independent tasks in the current session |
| `superpowers-classic-brainstorming` | Interactive idea refinement using Socratic method to develop fully-formed designs |
| `superpowers-classic-collision-zone-thinking` | Force unrelated concepts together to discover emergent properties - "What if we treated X like Y? |
| `superpowers-classic-condition-based-waiting` | Replace arbitrary timeouts with condition polling for reliable async tests |
| `superpowers-classic-defense-in-depth` | Validate at every layer data passes through to make bugs impossible |
| `superpowers-classic-dispatching-parallel-agents` | Use multiple Claude agents to investigate and fix independent problems concurrently |
| `superpowers-classic-executing-plans` | Execute detailed plans in batches with review checkpoints |
| `superpowers-classic-finishing-a-development-branch` | Complete feature development with structured options for merge, PR, or cleanup |
| `superpowers-classic-gardening-skills-wiki` | Maintain skills wiki health - check links, naming, cross-references, and coverage |
| `superpowers-classic-inversion-exercise` | Flip core assumptions to reveal hidden constraints and alternative approaches - "what if the opposite were true? |
| `superpowers-classic-meta-pattern-recognition` | Spot patterns appearing in 3+ domains to find universal principles |
| `superpowers-classic-preserving-productive-tensions` | Recognize when disagreements reveal valuable context, preserve multiple valid approaches instead of forcing premature resolution |
| `superpowers-classic-pulling-updates-from-skills-repository` | Sync local skills repository with upstream changes from obra/superpowers-skills |
| `superpowers-classic-receiving-code-review` | Receive and act on code review feedback with technical rigor, not performative agreement or blind implementation |
| `superpowers-classic-remembering-conversations` | Search previous Claude Code conversations for facts, patterns, decisions, and context using semantic or text search |
| `superpowers-classic-requesting-code-review` | Dispatch code-reviewer subagent to review implementation against plan or requirements before proceeding |
| `superpowers-classic-root-cause-tracing` | Systematically trace bugs backward through call stack to find original trigger |
| `superpowers-classic-scale-game` | Test at extremes (1000x bigger/smaller, instant/year-long) to expose fundamental truths hidden at normal scales |
| `superpowers-classic-sharing-skills` | Contribute skills back to upstream via branch and PR |
| `superpowers-classic-simplification-cascades` | Find one insight that eliminates multiple components - "if this is true, we don't need X, Y, or Z |
| `superpowers-classic-subagent-driven-development` | Execute implementation plan by dispatching fresh subagent for each task, with code review between tasks |
| `superpowers-classic-systematic-debugging` | Four-phase debugging framework that ensures root cause investigation before attempting fixes. Never jump to solutions. |
| `superpowers-classic-test-driven-development` | Write the test first, watch it fail, write minimal code to pass |
| `superpowers-classic-testing-anti-patterns` | Never test mock behavior. Never add test-only methods to production classes. Understand dependencies before mocking. |
| `superpowers-classic-testing-skills-with-subagents` | RED-GREEN-REFACTOR for process documentation - baseline without skill, write addressing failures, iterate closing loopholes |
| `superpowers-classic-tracing-knowledge-lineages` | Understand how ideas evolved over time to find old solutions for new problems and avoid repeating past failures |
| `superpowers-classic-using-git-worktrees` | Create isolated git worktrees with smart directory selection and safety verification |
| `superpowers-classic-using-skills` | Skills wiki intro - mandatory workflows, search tool, brainstorming triggers |
| `superpowers-classic-verification-before-completion` | Run verification commands and confirm output before claiming success |
| `superpowers-classic-when-stuck` | Dispatch to the right problem-solving technique based on how you're stuck |
| `superpowers-classic-writing-plans` | Create detailed implementation plans with bite-sized tasks for engineers with zero codebase context |
| `superpowers-classic-writing-skills` | TDD for process documentation - test with subagents before writing, iterate until bulletproof |
| `systematic-debugging` | Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes |
| `test-driven-development` | Use when implementing any feature or bugfix, before writing implementation code |
| `using-git-worktrees` | Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists vi... |
| `using-superpowers` | Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions |
| `verification-before-completion` | Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output... |
| `writing-plans` | Use when you have a spec or requirements for a multi-step task, before touching code |
| `writing-skills` | Use when creating new skills, editing existing skills, or verifying skills work before deployment |
