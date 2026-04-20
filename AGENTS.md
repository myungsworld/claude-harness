# AGENTS.md — claude-harness

> Single source of truth for AI agents working in this repo.
> Compatible with Claude Code, Codex, Cursor, and other AI coding assistants.

## 1. What is claude-harness?

A **self-improving governance framework** for AI-assisted development.
It manages multi-stack project templates, enforces quality gates via git hooks,
and automatically evolves itself by watching external ecosystem changes and
internal usage patterns.

### Core Loop

```
External signals (web docs, releases)  ──┐
                                          ├──▶ Proposals ──▶ Human gate ──▶ Harness update
Internal signals (usage, drift, errors) ──┘
```

## 2. CLI

After `make install`, the `harness` CLI is available at `~/.claude-harness/bin/harness`.

```bash
harness install              # Re-run global install
harness bootstrap [args...]  # Apply templates to a project
harness audit [DIR]          # Compliance audit
harness status               # Dashboard for registered projects
harness register [DIR]       # Register a project
harness watch [--status]     # Check/show watch sources
harness evolve               # Show internal signal snapshot (cycle itself is driven by /harness/evolve)
harness update               # Pull latest + install + sync all
harness version              # Show version
```

Or via `make`:

```bash
make help          # List all targets
make install       # Global install (includes CLI)
make audit         # Audit current directory
make regression    # Audit all registered projects
make validate      # Dry-run all 5 stack templates
make lint          # Bash syntax check
make test          # lint + validate
```

### Slash commands (Claude Code)

```
/harness/evolve     # Conversational self-improvement cycle (no flags, no sub-commands)
```

The cycle runs end-to-end in the conversation. Nothing persists in a "pending" state —
when the conversation ends, the cycle ends. See `commands/harness/evolve.md`.

## 3. Project Structure

```
claude-harness/
├── commands/harness/     # Slash commands (markdown prompts)
├── hooks/                # Auto-executed hooks (session lifecycle)
├── scripts/              # Bash utilities (install, bootstrap, audit, watch)
├── templates/            # Multi-stack golden patterns
│   ├── common/           # Shared across all stacks
│   ├── go/ node/ python/ rust/ flutter/
├── watchlist/            # Self-improvement engine
│   ├── watchlist.yaml    # Registered watch sources
│   ├── snapshots/        # Point-in-time snapshots (baselines for diffing)
│   ├── cycles/           # Append-only cycle logs (one file per cycle)
│   └── state/            # Internal signal accumulation
├── agents/               # Specialized sub-agents
├── skills/harness/       # Isolated execution skills
└── docs/                 # Architecture & guides
```

## 4. Self-Improvement System

### External Watch (ecosystem changes)

`watchlist/watchlist.yaml` registers external sources (docs, releases, packages).
Session-start prints overdue sources as a hint to run `/harness/evolve`; the cycle
checks them during the conversation.

| Source Type | Method | Example |
|-------------|--------|---------|
| `web` | WebSearch + WebFetch | Claude Code docs, Next.js ESLint guide |
| `github-release` | GitHub API | lefthook, gitleaks releases |
| `npm` / `pypi` / `crates` / `pub` | Registry API | Package breaking changes |
| `internal` | Local log scan | Command usage, error patterns, drift |

### Internal Evolve (usage patterns)

Session-end hooks collect signals. `scripts/evolve.sh --phase internal` summarizes
them for the cycle. Triggers Claude should watch for:

| Signal | Finding type |
|--------|--------------|
| Command unused 30d | Deprecation candidate |
| Hook warns N+ times same pattern | Promote to rule |
| Template drifts in 3+ projects | Template revision |
| Manual fix repeated | New hook/skill candidate |

### Evolve Command

`/harness/evolve` is a **conversational cycle** — Claude and the user review
findings together and decide, in dialogue, whether to apply, defer, or dismiss
each one. There is no persistent proposal file to Apply/Dismiss later.

Five steps (detail in `commands/harness/evolve.md`):
1. Watchlist coverage check — does the watchlist still cover what matters?
2. Internal signals — scan via `evolve.sh --phase internal`
3. External watch — Claude executes WebSearch/WebFetch + `watch-check.sh` for each source
4. Review loop — findings presented individually, each decided in dialogue
5. Cycle close — a single log written to `watchlist/cycles/<date>.md`

### Human Gate

Nothing is ever auto-applied. Claude proposes and reasons; the user decides.
Claude MUST NOT pre-decide `defer` on a finding because it "needs more data" —
every finding is presented, every decision is the user's.

## 5. Code Style

- **Bash scripts**: `set -euo pipefail`, ShellCheck compliant
- **YAML**: 2-space indentation
- **Template variables**: `{{PROJECT_NAME}}`, `{{BASE_BRANCH}}`, `{{TODAY}}`
- **Idempotency**: All scripts safe to re-run. Existing files backed up (`.bak`) before overwriting.

## 6. Git Workflow

- **Branches**: `feat/*`, `fix/*`, `docs/*`, `chore/*`
- **Base branch**: `main`
- **Commit messages**: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`)

## 7. Boundaries

### Always
- Guarantee idempotency for all scripts
- Create backup (`.bak.*`) before overwriting
- Human gate on every evolve finding — never auto-mutate
- When editing, refresh obsolete code in the same pass (no "append-only" growth)

### Ask first
- Adding a new project type
- Adding an external tool dependency
- Changing watch intervals or sources

### Never
- Auto-apply evolve findings without user confirmation
- Pre-decide `defer` on a finding on the user's behalf
- Hardcode secrets or PII in templates
- Skip the human gate under any circumstance
