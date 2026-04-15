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
harness evolve [args...]     # Self-improvement engine (see below)
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
/harness/evolve                    # Full self-improvement (internal + external)
/harness/evolve --watch-only       # External sources only
/harness/evolve --signals-only     # Internal patterns only
/harness/evolve --list             # List pending proposals
/harness/evolve --apply <id>       # Apply a proposal
/harness/evolve --dismiss <id>     # Dismiss a proposal
```

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
│   ├── snapshots/        # Point-in-time snapshots
│   ├── proposals/        # Auto-generated improvement proposals
│   └── state/            # Internal signal accumulation
├── agents/               # Specialized sub-agents
├── skills/harness/       # Isolated execution skills
└── docs/                 # Architecture & guides
```

## 4. Self-Improvement System

### External Watch (ecosystem changes)

`watchlist/watchlist.yaml` registers external sources (docs, releases, packages).
Hooks automatically check overdue sources and propose harness updates.

| Source Type | Method | Example |
|-------------|--------|---------|
| `web` | WebSearch + WebFetch | Claude Code docs, Next.js ESLint guide |
| `github-release` | GitHub API | lefthook, gitleaks releases |
| `npm` / `pypi` / `crates` / `pub` | Registry API | Package breaking changes |
| `internal` | Local log scan | Command usage, error patterns, drift |

### Internal Evolve (usage patterns)

Session-end hooks collect signals. When patterns emerge:

| Signal | Trigger | Proposal |
|--------|---------|----------|
| Command unused 30d | Low utility | Deprecation candidate |
| Hook warns N+ times same pattern | Recurring pain | Promote to rule |
| Template drifts in 3+ projects | Drift hotspot | Template revision |
| Manual fix repeated | Missing automation | New hook/skill candidate |

### Evolve Command

`/harness/evolve` orchestrates the full self-improvement cycle:

1. **Internal analysis** (`evolve.sh --phase internal`) — scans signals.jsonl for
   command usage, error patterns, template drift across registered projects
2. **External watch** (`watch-check.sh --check`) — Claude uses WebSearch/WebFetch
   to check overdue sources (docs, releases, security advisories)
3. **Proposal generation** (`evolve.sh --phase propose`) — cross-references
   internal + external findings into an actionable proposal
4. **Human gate** — user reviews and chooses Apply / Defer / Dismiss

Key architecture: WebSearch/WebFetch are Claude tools, not bash — so the slash
command (`commands/harness/evolve.md`) instructs Claude on the 2-phase flow.

### Human Gate

Proposals are **never auto-applied**. The user sees:
```
"lefthook v2.0 released — config structure changed"
  [Apply]  [Later]  [Dismiss]
```

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
- Human gate on all proposals — never auto-mutate

### Ask first
- Adding a new project type
- Adding an external tool dependency
- Changing watch intervals or sources

### Never
- Auto-apply proposals without user confirmation
- Hardcode secrets or PII in templates
- Skip the human gate under any circumstance
