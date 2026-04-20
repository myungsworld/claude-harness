# docs/ — Knowledge Base

Durable reference material maintained by `/harness/evolve`. This is where the
harness remembers things between cycles.

## Who reads this

1. **Claude (primary)** — loads the relevant `docs/<area>/*.md` at the start of
   each `/harness/evolve` cycle to reconcile new findings against what is
   already known. Also read when working on related tasks.
2. **You (secondary)** — human browsing / searching, optionally through
   Obsidian (the folder works as a vault without any config change).

## Structure

```
docs/
├── README.md                  # this file — rules and conventions
├── claude/                    # Anthropic / Claude Code ecosystem
│   ├── hooks.md               # all hook events + harness adoption state
│   ├── models.md              # current model lineup + capabilities
│   └── features.md            # Claude Code surfaces: Routines, Channels, etc.
├── tooling/                   # adjacent AI tooling (MCP, agent frameworks, …)
└── <language>/                # mirrors templates/<language>/
    └── architecture.md        # current architecture patterns for that stack
```

New areas can be added when the evolve cycle surfaces something that doesn't
fit an existing bucket.

## File conventions

Every file starts with frontmatter:

```yaml
---
type: reference
topic: <slug matching filename without .md>
updated: 2026-04-20       # YYYY-MM-DD of last evolve cycle that touched this
tags: [claude, hooks]      # for search/filtering
source: https://…          # upstream URL (if there is a canonical one)
---
```

Body rules:

- **Current-state, not append-log.** When upstream deprecates something,
  replace the section — don't stack a "deprecated in v2.2" note next to the
  current truth. History lives in `git log` and `watchlist/cycles/`.
- **Standard markdown links** (`[text](./path.md)`) — never wikilink syntax
  (`[[path]]`). Keeps GitHub rendering intact; Obsidian resolves both.
- **Claude-readable first**: tables and bullet lists beat long prose. Include
  concrete identifiers (event names, model IDs, version strings) so Claude can
  grep them.
- **Flag "harness adoption state" when relevant.** For each subscribable item
  (a hook event, a model capability, a tooling feature), note whether the
  harness currently adopts it, and if not, under what condition it should.

## Updating

`docs/` is updated **only during `/harness/evolve` cycles**. Direct edits
outside a cycle are allowed for typo fixes, but any substantive content change
should happen inside a review loop so the decision is recorded in the cycle
log.

When a reference matures (content has stabilized and is actionable), that's the
trigger to consider a **template-update** finding in the next cycle — promoting
reference knowledge into the actual `templates/` that get applied to projects.

## Relationship to other directories

| Directory | Role | Relationship to `docs/` |
|---|---|---|
| `watchlist/snapshots/` | Raw dumps for diffing (latest baseline of each source) | Feeds `docs/` but is not human-readable |
| `watchlist/cycles/` | Append-only per-cycle decision logs | Records *which cycle* updated a given `docs/` file |
| `templates/<lang>/` | What gets copied into registered projects | Receives promotions from mature `docs/<lang>/` references |
| `hooks/`, `scripts/` | Harness internals | Receive changes when a `docs/claude/*.md` entry matures into a script-update |
