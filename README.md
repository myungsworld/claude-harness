# claude-harness

A **self-improving governance framework** for AI-assisted development.

Manages multi-stack project templates, enforces quality gates via git hooks, and **automatically evolves itself** by watching external ecosystem changes and internal usage patterns — with human approval on every change.

## How It Works

```
                    ┌──────────────────────┐
                    │    claude-harness     │
                    │    (this repo)        │
                    └──────────┬───────────┘
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                 ▼
       ┌────────────┐  ┌────────────┐   ┌─────────────┐
       │  External   │  │  Internal   │   │  Templates   │
       │  Watch      │  │  Evolve     │   │  & Hooks     │
       │             │  │             │   │              │
       │ Web docs    │  │ Usage logs  │   │ Go/Node/Py/  │
       │ Releases    │  │ Drift map   │   │ Rust/Flutter  │
       │ Packages    │  │ Error ptrns │   │              │
       └──────┬─────┘  └──────┬─────┘   └──────┬──────┘
              │                │                 │
              ▼                ▼                 ▼
       ┌─────────────────────────────────────────────┐
       │              Proposals                       │
       │  (never auto-applied — human gate always)    │
       └──────────────────┬──────────────────────────┘
                          │
                   [Apply] [Later] [Dismiss]
                          │
                          ▼
                 Updated harness → synced to all projects
```

### Two axes of self-improvement

| Axis | Source | Example |
|------|--------|---------|
| **External Watch** | Web docs, GitHub releases, package registries | "Next.js 15 changed ESLint config structure" |
| **Internal Evolve** | Usage logs, template drift, error patterns | "This command hasn't been used in 30 days" |

## Quick Start

```bash
# 1. Clone
git clone https://github.com/myungsworld/claude-harness.git
cd claude-harness

# 2. Install globally (hooks + commands)
make install

# 3. Set scope (which projects are governed)
# Edit ~/.claude-harness/config:
#   SCOPE_PARENTS=("$HOME/projects")

# 4. Bootstrap a project
./scripts/bootstrap.sh --type node /path/to/my-project

# 5. Register it
make register P=/path/to/my-project

# 6. Check compliance
make audit DIR=/path/to/my-project
```

## Features

### Multi-Stack Templates

Golden patterns for 5 stacks, each with tailored lefthook hooks and AI collaboration guides:

| Stack | Pre-commit | Pre-push |
|-------|-----------|----------|
| **Go** | gitleaks + gofmt | go vet + go test |
| **Node** | gitleaks | eslint + jest (selective) |
| **Python** | gitleaks | ruff + mypy + pytest (selective) |
| **Rust** | gitleaks + rustfmt | clippy + cargo test |
| **Flutter** | gitleaks + dart format | flutter analyze + test (selective) |

### Watch System (External Signals)

Register sources in `watchlist/watchlist.yaml`:

```yaml
sources:
  - id: claude-code-docs
    type: web
    urls: ["https://docs.anthropic.com/en/docs/claude-code"]
    focus: ["hooks API changes", "new tools"]
    affects: ["hooks/*"]
    interval_days: 7
```

On every session start, overdue sources are automatically checked via WebSearch/WebFetch. Changes produce proposals in `watchlist/proposals/`.

### Evolve System (Internal Signals)

Session-end hooks silently collect:
- Command/hook usage frequency
- Error patterns
- Template drift across projects

When patterns emerge (unused commands, repeated warnings, cross-project drift), proposals are generated.

### Human Gate

**Nothing is ever auto-applied.** Every proposal requires explicit user approval:

```
"lefthook v2.0 released — config structure changed"
  [Apply]  [Later]  [Dismiss]
```

## Project Structure

```
claude-harness/
├── hooks/                # Auto-executed (session lifecycle)
│   ├── _scope.sh         # Scope gating (opt-in)
│   ├── session-start.sh  # Context injection + watch trigger
│   └── session-end.sh    # Signal collection
├── scripts/
│   ├── install.sh        # Global installation
│   ├── bootstrap.sh      # Template application
│   ├── audit.sh          # Compliance check
│   ├── watch-check.sh    # Watch execution
│   └── snapshot-diff.sh  # Change detection + proposal gen
├── templates/
│   ├── common/           # Shared (gitleaks, security rules, docs)
│   └── {go,node,python,rust,flutter}/
├── watchlist/
│   ├── watchlist.yaml    # Watch source registry
│   ├── snapshots/        # Point-in-time snapshots
│   ├── proposals/        # Generated improvement proposals
│   └── state/            # Signal accumulation
├── AGENTS.md             # AI agent guide
└── Makefile              # Common operations
```

## Make Targets

```
make help           # Show all targets
make install        # Global install (hooks + commands)
make audit          # Audit current directory
make regression     # Audit all registered projects
make validate       # Dry-run all 5 stack templates
make lint           # Bash syntax check
make test           # lint + validate
make register P=..  # Register a project
make watch-status   # Show watch sources status
```

## Design Principles

1. **Governance as Code** — Quality standards maintained by system, not convention
2. **Self-Improving** — Both external (ecosystem) and internal (usage) feedback loops
3. **Human-in-the-Loop** — Automation proposes, human decides
4. **Idempotent** — Every script safe to re-run, backups created before overwrites
5. **Opt-in Scope** — Only governs explicitly registered projects
6. **Multi-Stack** — One harness, five language ecosystems

## Background

Built from patterns validated across 5 production projects in a fintech environment. The template system, hook architecture, and self-improvement engine are battle-tested — this repo provides the generic, organization-agnostic framework.

## License

MIT
