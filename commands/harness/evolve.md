# /harness/evolve — Harness Self-Improvement (Gated)

Generates **human-reviewed proposals** to improve claude-harness by combining:
1. **Internal signals** — command usage, error patterns, template drift (local data)
2. **External watch** — Claude Code docs, tool releases, security advisories (web search)

> Guardrail: proposals are **never auto-applied**. Always requires explicit user confirmation.

## Usage

```
/harness/evolve                    # Full: internal signals + external watch
/harness/evolve --watch-only       # External sources only (WebSearch/WebFetch)
/harness/evolve --signals-only     # Internal patterns only (local analysis)
/harness/evolve --list             # List pending proposals
/harness/evolve --apply <id>       # Apply a specific proposal
/harness/evolve --dismiss <id>     # Dismiss a proposal
```

## Procedure

### Step 1: Parse arguments

```
ARGS = user arguments after /harness/evolve
HARNESS_ROOT = the claude-harness project root (find via: git rev-parse --show-toplevel, or locate watchlist/watchlist.yaml)
```

If `--list`: run `bash $HARNESS_ROOT/scripts/evolve.sh --list` and stop.
If `--apply <id>`: run `bash $HARNESS_ROOT/scripts/evolve.sh --apply <id>` and stop.
If `--dismiss <id>`: run `bash $HARNESS_ROOT/scripts/evolve.sh --dismiss <id>` and stop.

### Step 2: Internal signal collection (skip if --watch-only)

Run:
```bash
bash $HARNESS_ROOT/scripts/evolve.sh --phase internal
```

Save the output — it contains command usage frequency, error patterns, template drift, and harness churn data.

Look for these patterns:
| Signal | Trigger | Action |
|---|---|---|
| Command used 0 times in 30d | Low utility | Deprecation candidate |
| Same error pattern 10+ times | Recurring pain | Promote to rule/hook |
| Template drifts in 3+ projects | Drift hotspot | Template revision |
| Manual fix repeated across sessions | Missing automation | New hook/skill candidate |

### Step 3: External watch check (skip if --signals-only)

Run:
```bash
bash $HARNESS_ROOT/scripts/watch-check.sh --check
```

For each overdue source, execute the appropriate check:

#### Type: `web`
1. **WebSearch** for the listed URLs and focus areas
2. **WebFetch** each URL to get current content
3. Write findings to a temp file
4. Run: `bash $HARNESS_ROOT/scripts/snapshot-diff.sh <source-id> <temp-file>`
5. Run: `bash $HARNESS_ROOT/scripts/watch-check.sh --update-checked <source-id>`

#### Type: `github-release`
1. Run: `gh api repos/<repo>/releases/latest --jq '.tag_name + " " + .name + "\n" + .body'`
2. Write the output to a temp file
3. Run: `bash $HARNESS_ROOT/scripts/snapshot-diff.sh <source-id> <temp-file>`
4. Run: `bash $HARNESS_ROOT/scripts/watch-check.sh --update-checked <source-id>`

#### Type: `internal`
Already handled in Step 2. Just mark as checked:
```bash
bash $HARNESS_ROOT/scripts/watch-check.sh --update-checked internal-usage
```

### Step 4: Synthesize proposal

Combine findings from Steps 2 and 3. Generate a proposal:

```bash
# Pipe combined findings into proposal generator
echo "<combined findings>" | bash $HARNESS_ROOT/scripts/evolve.sh --phase propose
```

Or manually edit the generated proposal file in `watchlist/proposals/` to add:
- **External Findings** section with WebSearch/WebFetch results
- **Proposed Changes** section with specific file diffs
- **Risk Assessment** with affected project list

### Step 5: Present to user (Human Gate)

Print the proposal summary to the conversation. Include:
- Key findings (internal + external)
- Recommended changes with file paths
- Impact assessment

**NEVER apply changes without user confirmation.**
To apply: `/harness/evolve --apply <proposal-id>`

## Cross-referencing (internal + external)

The most valuable proposals come from correlating both sources:

| Internal Signal | External Signal | Combined Proposal |
|---|---|---|
| lefthook.yml drifts in 3+ projects | lefthook new major release | Template update + migration |
| gitleaks custom rules in projects | gitleaks adds those rules as defaults | Remove custom rules from template |
| Claude hook errors increasing | Claude docs show new hook API | Update hooks to new API |
| Command X unused 30d | (none) | Deprecation candidate |
| (none) | New Claude Code capability | New hook/command candidate |
| (none) | Security advisory for dependency | Patch template + notify projects |

## Relation to other commands

| Command | Scope |
|---|---|
| `/harness/evolve` | Is the **harness itself** still the right shape? |
| `harness audit` | Is a **target project** compliant with the harness? |
| `harness watch --status` | What are the **watch sources** and their state? |

## Output example

```
=== Internal Signal Analysis (30-day window) ===
  Recent: 12 sessions
  Command Usage:
    8  /harness/work
    3  /harness/review
    0  /harness/docs   <-- deprecation candidate

  Template Drift:
    project-a: .gitleaks.toml
    project-b: .gitleaks.toml lefthook.yml
    project-c: .gitleaks.toml
    WARNING: 3 projects drifting — template revision candidate

=== External Watch ===
  claude-code-docs: New "SubAgentStart" hook event type added (2026-04-10)
  lefthook-releases: v2.1.0 — new "files" filter syntax
  gitleaks-releases: v8.22.0 — no breaking changes

=== Proposal ===
  1. Update templates/*/lefthook.yml for lefthook v2.1 "files" syntax
  2. Revise .gitleaks.toml template (drifting in 3/5 projects)
  3. Consider deprecating /harness/docs (unused 30d)
  4. Add SubAgentStart hook support to session-start.sh

  Saved: watchlist/proposals/evolve-2026-04-15.md
  To apply: /harness/evolve --apply evolve-2026-04-15
```
