---
type: reference
topic: claude-code-hooks
updated: 2026-04-20
tags: [claude, hooks, events]
source: https://code.claude.com/docs/en/hooks
---

# Claude Code — Hook Events

Full enumeration of hook event types Claude Code currently emits, and the
harness's adoption state for each. Refreshed on every `/harness/evolve` cycle
whose scope includes Claude Code.

## Currently subscribed by the harness

| Event | File | Purpose |
|---|---|---|
| `SessionStart` | [hooks/session-start.sh](../../hooks/session-start.sh) | Inject harness context + warn on overdue watch sources |
| `SessionEnd` | [hooks/session-end.sh](../../hooks/session-end.sh) | Append a summary + raw signals to `watchlist/state/signals.jsonl` |

## Available but not subscribed

Each entry has a **potential value (harness-scope)** assessment. These are
working notes — revisit when real signal data (`signals.jsonl`) is non-empty.

### High potential value (signal-capture upgrades)

#### `PostToolUseFailure`
**Fires:** after a tool call fails.
**Payload:** tool name, error, failure context.
**Harness value:** direct source for error-pattern aggregation. Today
`scripts/evolve.sh --phase internal` infers error patterns by scanning
signals.jsonl; subscribing here would give a first-class signal instead of
inference.
**Blockers:** none — additive. Would need a new `hooks/post-tool-use-failure.sh`
that appends a compact JSON line.
**Status:** candidate for next cycle.

#### `SubagentStop`
**Fires:** when a spawned subagent finishes.
**Payload:** subagent type, duration, outcome.
**Harness value:** lets the evolve engine report subagent usage patterns
(which subagent types are used, how often, how long). Today this is 100% blind.
**Blockers:** we emit the harness's own subagents rarely; data may be sparse
unless the harness actively uses subagents.
**Status:** worthwhile but low-urgency.

#### `TaskCompleted`
**Fires:** when a task (TodoWrite item) is marked complete.
**Payload:** task description, elapsed, outcome.
**Harness value:** richer session summary than `SessionEnd` alone — per-task
rather than whole-session. Could feed drift detection if tasks repeat across
sessions.
**Blockers:** tight coupling to TodoWrite usage; only useful if Claude actually
uses TodoWrite in that cycle.
**Status:** nice-to-have after `PostToolUseFailure` and `SubagentStop`.

#### `PreCompact`
**Fires:** immediately before Claude Code compacts context.
**Payload:** pre-compaction context summary.
**Harness value:** correct timing to flush in-flight signals to
`signals.jsonl` before they're lost. Today `session-end.sh` flushes at session
close, which misses long sessions that compact mid-flight.
**Blockers:** none.
**Status:** candidate once signal volume justifies it.

#### `UserPromptSubmit`
**Fires:** each time the user submits a prompt.
**Payload:** the prompt itself (!).
**Harness value:** prompt pattern analysis (e.g. "user keeps asking about X —
should we add a skill?"). Potentially high.
**Blockers:** **privacy**. User prompts can contain secrets, PII, or confidential
context. Would need a strict allowlist / redaction step before persisting.
**Status:** defer until privacy posture is decided.

### Low potential value (out of harness scope)

Grouped here are events whose purpose is IDE/editor UX, MCP server internals,
or UI plumbing — outside the harness's governance/self-improvement remit. For
each, we skip subscription unless a concrete need arises.

| Event | Why out-of-scope for harness |
|---|---|
| `PreToolUse` | Per-call gate; our governance lives at commit/push time via lefthook. |
| `PostToolUse` | Too chatty; aggregate signals we care about are already in SessionEnd. |
| `PermissionRequest` | UI layer event. Permission policy belongs in `settings.json`, not hooks. |
| `PermissionDenied` | Same as above. |
| `Notification` | Display concern; no harness signal. |
| `SubagentStart` | Mirror of `SubagentStop` but without outcome — `Stop` is strictly more informative. |
| `TaskCreated` | Mirror of `TaskCompleted`; only completion signal is useful to the harness. |
| `InstructionsLoaded` | Diagnostic for CLAUDE.md/rules loading — debug-only use. |
| `ConfigChange` | Mid-session `settings.json` edits — rare and not governed. |
| `CwdChanged` | IDE concern. |
| `FileChanged` | IDE concern (diff / external-edit awareness). |
| `WorktreeCreate` / `WorktreeRemove` | Git worktree lifecycle — belongs in git workflow, not hooks. |
| `PostCompact` | Pair to `PreCompact`; we only need the pre-side for signal flush. |
| `Elicitation` / `ElicitationResult` | MCP server prompt-to-user bridge; governance not applicable. |
| `TeammateIdle` | Agent-team feature; not the harness's layer. |
| `Stop` / `StopFailure` | End-of-turn signals; `SessionEnd` already captures what we need. |

## Deprecations

- **PreToolUse top-level `decision` / `reason`** — deprecated in favor of
  `hookSpecificOutput.permissionDecision` /
  `hookSpecificOutput.permissionDecisionReason`. Legacy values
  `"approve"`/`"block"` map to `"allow"`/`"deny"`. Not relevant today
  (harness does not subscribe to `PreToolUse`) but flag if that changes.

## Open questions for the next cycle

- Does Claude Code expose a hook-level throttle / sampling rate? We should not
  overwhelm `signals.jsonl` if we subscribe to high-frequency events.
- Is there a canonical schema for hook payloads, or only per-event
  documentation?
