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

## 2. Commands

```bash
# Apply templates to a new project
./scripts/bootstrap.sh --type {go|node|python|rust|flutter} --base {develop|main|master} [PROJECT_PATH]

# Check compliance of an existing project
./scripts/audit.sh [PROJECT_PATH]

# Install globally (hooks + commands + agents)
./scripts/install.sh

# Validate templates (dry-run)
./scripts/bootstrap.sh --type go --base develop --dry-run /tmp/test-project
```

Or via `make`:

```bash
make help          # List all targets
make install       # Global install
make audit         # Audit current directory
make regression    # Audit all registered projects
make validate      # Dry-run all 5 stack templates
make lint          # Bash syntax check
make test          # lint + validate
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
