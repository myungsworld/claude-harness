# claude-code-docs — baseline 2026-04-20

Source URLs (original in watchlist.yaml):
- https://docs.anthropic.com/en/docs/claude-code  → 301 → https://code.claude.com/docs
- https://docs.anthropic.com/en/docs/claude-code/hooks  → 301 → https://code.claude.com/docs/en/hooks

## Supported hook events (code.claude.com/docs/en/hooks)

- SessionStart
- UserPromptSubmit
- PreToolUse
- PermissionRequest
- PermissionDenied
- PostToolUse
- PostToolUseFailure
- Notification
- SubagentStart
- SubagentStop
- TaskCreated
- TaskCompleted
- Stop
- StopFailure
- TeammateIdle
- InstructionsLoaded
- ConfigChange
- CwdChanged
- FileChanged
- WorktreeCreate
- WorktreeRemove
- PreCompact
- PostCompact
- Elicitation
- ElicitationResult
- SessionEnd

## Deprecations

- PreToolUse: top-level `decision` / `reason` deprecated. Use `hookSpecificOutput.permissionDecision` + `hookSpecificOutput.permissionDecisionReason`. Legacy `"approve"`/`"block"` map to `"allow"`/`"deny"`.

## Product-surface notes (from /docs overview)

- Routines (Anthropic-hosted scheduled runs), `/schedule` slash command
- Desktop scheduled tasks
- `/loop` for in-session polling
- Remote Control, Channels, Dispatch, Web, `--teleport` flag
- GitHub Actions / GitLab CI/CD integrations
