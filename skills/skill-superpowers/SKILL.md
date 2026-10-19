---
name: skill-superpowers
description: Superpowers — Jesse Vincent / obra's agentic skills framework + software-development methodology (cloned from obra/superpowers). Bundle of 14 composable sub-skills: brainstorming, writing-plans, executing-plans, test-driven-development, systematic-debugging, subagent-driven-development, dispatching-parallel-agents, using-git-worktrees, verification-before-completion, requesting-code-review, receiving-code-review, finishing-a-development-branch, writing-skills, using-superpowers. Use whenever the user invokes "/superpowers", asks to brainstorm a spec, design an implementation plan, run TDD red/green, debug systematically, spawn parallel subagents, work in a git worktree, verify before marking done, request or receive code review, finish a branch, or write a new skill. Also trigger for terms: superpowers, subagent-driven development, TDD red green, YAGNI, systematic debugging, plan-then-execute, parallel agents, worktree workflow, verification-before-completion, code-review cycle.
metadata:
  source: https://github.com/obra/superpowers
  type: bundle
---

# skill-superpowers

This is a thin wrapper that registers the cloned `obra/superpowers` plugin as a single discoverable skill. The real content lives in the `skills/` subdirectory — each is a full skill with its own `SKILL.md`.

## How to use

When this skill matches the user's intent, do not try to summarize the methodology — **read the relevant sub-skill's `SKILL.md` first**, then follow its instructions. Most sub-skills are short and prescriptive.

Top-level guidance the framework expects you to internalize lives in:

- [CLAUDE.md](CLAUDE.md) — methodology overview, when to invoke which skill
- [AGENTS.md](AGENTS.md) — agent-facing instructions
- [skills/using-superpowers/SKILL.md](skills/using-superpowers/SKILL.md) — entry point: read this first if unsure which sub-skill applies

## Sub-skills (in `skills/`)

| Sub-skill | When to use |
|---|---|
| [using-superpowers](skills/using-superpowers/SKILL.md) | Entry point — routes to the right sub-skill |
| [brainstorming](skills/brainstorming/SKILL.md) | User has a vague idea; tease out a spec before any code |
| [writing-plans](skills/writing-plans/SKILL.md) | Spec is locked; produce an implementation plan a junior could follow |
| [executing-plans](skills/executing-plans/SKILL.md) | Plan approved; walk through it step by step |
| [test-driven-development](skills/test-driven-development/SKILL.md) | True red/green TDD — failing test first, then code |
| [systematic-debugging](skills/systematic-debugging/SKILL.md) | Hypothesis-driven debugging when a bug is non-obvious |
| [subagent-driven-development](skills/subagent-driven-development/SKILL.md) | Long-running autonomous work — delegate tasks to subagents with inspection |
| [dispatching-parallel-agents](skills/dispatching-parallel-agents/SKILL.md) | Independent tasks that can run concurrently |
| [using-git-worktrees](skills/using-git-worktrees/SKILL.md) | Isolated experimentation or parallel branches without polluting the working tree |
| [verification-before-completion](skills/verification-before-completion/SKILL.md) | Before marking work done — verify it actually works |
| [requesting-code-review](skills/requesting-code-review/SKILL.md) | Send work for review |
| [receiving-code-review](skills/receiving-code-review/SKILL.md) | Handle inbound review feedback |
| [finishing-a-development-branch](skills/finishing-a-development-branch/SKILL.md) | Wrap up a branch — squash, rebase, PR-ready |
| [writing-skills](skills/writing-skills/SKILL.md) | Author a new skill following the framework's conventions |

## Provenance

Cloned from <https://github.com/obra/superpowers> on 2026-05-22. To update, run `git pull` inside this directory. License: see [LICENSE](LICENSE).
