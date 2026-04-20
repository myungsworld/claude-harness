# /harness/evolve — Harness Self-Improvement Cycle

A **conversational cycle** between Claude and the user that:
1. Scans the ecosystem (Anthropic, Claude Code, language frameworks, AI tooling) — not just the registered URL list.
2. Refreshes the `docs/` knowledge base with what was found.
3. Decides, finding by finding, what to apply (templates, hooks, scripts, watchlist) and what to just keep as reference.

Everything is decided in dialogue. Nothing is auto-applied. When the conversation ends, the cycle ends.

> Guardrail: Claude proposes and explains in detail; the user decides every finding.

## Usage

```
/harness/evolve
```

No flags, no sub-commands.

## Mental model

| Layer | Purpose | Lives at |
|---|---|---|
| **Watchlist** | Short list of registered sources with intervals | `watchlist/watchlist.yaml` |
| **Broad scan** | Live exploration beyond the watchlist (WebSearch-driven) | in-conversation only |
| **Knowledge base** | Durable, structured reference that Claude reads next cycle | `docs/` |
| **Harness assets** | Hooks, scripts, templates that actually govern projects | `hooks/`, `scripts/`, `templates/` |
| **Cycle log** | One markdown file per cycle — what was discussed + decided | `watchlist/cycles/<date>.md` |

Findings flow between layers. A new hook event found in the broad scan →
recorded in `docs/claude/hooks.md` (always) → optionally subscribed via
`hooks/*.sh` (if user says apply). Reference first; apply second.

## Finding types

Every finding presented in the review loop must declare which type(s) it touches:

- **reference-update** — only `docs/` changes (the finding is worth knowing but not acting on)
- **watchlist-update** — add/remove/redirect a source in `watchlist/watchlist.yaml`
- **script-update** — change to `scripts/` or `hooks/`
- **template-update** — change to `templates/<lang>/*` (may be preceded by a matured reference in `docs/<lang>/`)

A finding can carry multiple types. E.g. "new hook event `PostToolUseFailure`" is both `reference-update` (record it in `docs/claude/hooks.md` no matter what) and `script-update` (optionally add `hooks/post-tool-use-failure.sh`).

## Procedure (6 steps)

### Step 1 — Scope the cycle

Ask the user what to emphasize this cycle (default: Claude/Anthropic core +
whatever is overdue in the watchlist). Optional emphases the user can add:
- A specific language's architecture trends (e.g. "Go architecture trends")
- A specific framework/tool (e.g. "latest Next.js app router patterns")
- A specific pain point from recent work

Keep the scope reasonable — better to go deep on 2–3 topics than shallow on 20.

### Step 2 — Ecosystem scan (broad, WebSearch-driven)

Based on the scope, run WebSearch queries like:
- "Anthropic model releases last 30 days"
- "Claude Code new features <YYYY-MM>"
- "MCP protocol changes <YYYY-MM>"
- "<language> modern architecture patterns <YYYY>"
- "AI coding tools ecosystem changes <YYYY-MM>"

For each hit that looks material, WebFetch the page and extract specifics.
Cross-reference against the current `docs/` entries (see Step 4) to identify what
is genuinely new vs. already recorded.

This is the step where surprises are caught — e.g. a model version bump, a new
agent framework, a shift in best practices. The registered `watchlist.yaml`
complements but does not replace this.

### Step 3 — Registered sources + internal signals

```bash
bash $HARNESS_ROOT/scripts/watch-check.sh --check       # overdue sources
bash $HARNESS_ROOT/scripts/evolve.sh --phase internal   # signals + drift + churn
```

For each overdue source, do the appropriate check (WebFetch / `gh api` / internal scan),
pipe through `snapshot-diff.sh`, and `--update-checked` after. Any substantive
diff becomes a finding.

### Step 4 — Reconcile with `docs/` knowledge base

Before presenting findings to the user, open the relevant `docs/` entries and
check whether what was found is:

- **new information** that should be written to `docs/` regardless of any apply decision
- **a correction** to an existing entry (upstream deprecated something we had recorded)
- **already covered** — then it isn't a finding, just a "no change" note

Any finding whose body is "this is a thing that exists and should be known"
always gets `reference-update` as one of its types. That write happens
even when the user defers or dismisses the application side — the reference is
the memory between cycles.

### Step 5 — Review loop

Present findings **one at a time** with detailed context. Template per finding:

```
### F<n> — <short title>  (types: reference-update, template-update)

**What changed upstream:**
<concrete description: version, URL, specific behavior change>

**Why it matters for the harness:**
<how it connects to hooks/templates/scripts/watchlist>

**Recommended action:**
- reference-update: write/update `docs/<path>.md` with section "<heading>" describing ...
- template-update: modify `templates/<lang>/<file>` to add/remove/change ...
  (show the concrete diff or at least the specific lines)

**Impact:**
- Files touched: `<path>`, `<path>`
- Registered projects affected: <list or "none">
- Risk: <concrete — e.g. breaks existing hook behavior / behavior-preserving / additive only>

**Question:** apply / defer / dismiss?
```

Rules for this step:
- **Never pre-decide `defer` on the user's behalf.** Even low-priority-looking
  findings are presented with a recommendation; the user calls it.
- **Never collapse sub-findings into a bulk decision.** If a finding expands
  (e.g. "26 new hook events" → one decision per event grouping), expand it.
- If `apply` is chosen, do the work **in this conversation** before moving on
  to the next finding. Apply-then-ask-next preserves context and catches errors
  early.
- Edits follow refactor-by-deletion: when you change a file, actively remove
  what your change makes obsolete in the same edit. Don't leave dead code or
  stale comments as hedges.

### Step 6 — Close the cycle

Once every finding has a decision:

1. Append a session block (`## Session <HH:MM>`) to `watchlist/cycles/<YYYY-MM-DD>.md`,
   or create the file if this is the first session of the day.
2. In the session block, record for each finding: types, decision, action taken
   (if applied), and a one-line reason (if deferred/dismissed).
3. Report to the user what was applied, what was deferred, what was dismissed,
   and point to any new/updated `docs/` files.

No resume, no pending state. The next `/harness/evolve` starts a fresh scan.

## Cycle log format

```markdown
---
date: 2026-04-20
session: 14:30
---

## Session 14:30

### Scope
<what was emphasized this cycle>

### Ecosystem scan hits
- <source/topic>: <one-line summary>

### Decisions

#### F1 — <title>  (types: …)
**Decision:** applied / deferred / dismissed
**Action taken:** <empty if not applied>
**Reason:** <empty if applied>

### Summary
N applied, M deferred, K dismissed. docs/ touched: <list>. templates/ touched: <list>.
```

Multiple sessions per day append to the same file.

## Knowledge base (`docs/`) rules

- Structure: `docs/<area>/<topic>.md` where `<area>` is one of `claude`, `<language>`, `tooling`, or another focused bucket.
- Every file has frontmatter: `type: reference`, `topic: <slug>`, `updated: <YYYY-MM-DD>`, `tags: [...]`, and `source:` when applicable.
- **Obsidian-aware, not Obsidian-dependent.** Use standard markdown links (`[text](path.md)`), not wikilinks. The folder can be opened as an Obsidian vault without any change.
- Reference files are current-state, not append-logs. When something is superseded, replace it; don't stack.
- See `docs/README.md` for the full conventions.

## What was removed from this command

Earlier versions of `/harness/evolve` supported `--watch-only`, `--signals-only`,
`--list`, `--apply <id>`, `--dismiss <id>`, and a persistent proposal-with-checkbox
file format under `watchlist/proposals/`. Those are gone. Earlier versions also
treated the registered watchlist as the whole of external signal — that was
too narrow. The cycle now opens with a broad scan and maintains a durable
`docs/` knowledge base between sessions.
