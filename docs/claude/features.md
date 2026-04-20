---
type: reference
topic: claude-code-features
updated: 2026-04-20
tags: [claude-code, features, surfaces]
source: https://code.claude.com/docs
---

# Claude Code — Product Surfaces & Features

Non-hook Claude Code capabilities that might be relevant to the harness.
Update when new surfaces ship or behaviors change.

## Surfaces (ways to run Claude Code)

| Surface | URL / Install | Harness relevance |
|---|---|---|
| **Terminal CLI** | `curl -fsSL https://claude.ai/install.sh \| bash` | Primary environment the harness is designed for |
| **VS Code extension** | marketplace: `anthropic.claude-code` | Secondary; harness hooks still fire via the same session model |
| **JetBrains plugin** | JetBrains marketplace | Same as VS Code |
| **Desktop app** | `claude.ai/download` | Separate signal flow possible (runs sessions locally but UI differs) |
| **Web** | claude.ai/code | Out-of-scope for harness hooks |
| **Mobile (iOS)** | Claude app | Out-of-scope |

## Scheduled-execution features

| Feature | Summary | Harness relevance |
|---|---|---|
| **Routines** | Anthropic-hosted cron-like scheduled runs. Created from web, Desktop, or `/schedule` in CLI. Runs even when user's computer is off. | Direct analog to the harness's `schedule:` block in `watchlist.yaml`. If we ever enable it, Routines is the likely substrate. |
| **Desktop scheduled tasks** | Runs on the user's machine with local file access. | Less reliable than Routines (needs the machine up) but has full filesystem access. |
| **`/loop`** | Repeat a prompt inside a single CLI session. | Useful for long-running polling within one evolve cycle — not for between-cycle automation. |

## Remote / multi-surface

| Feature | Summary | Harness relevance |
|---|---|---|
| **Remote Control** | Drive an existing local session from phone/browser. | Out-of-scope for harness automation. |
| **Channels** | Push events from Telegram/Discord/iMessage/webhooks into a session. | Potentially useful for triggering evolve from external signals, but adds attack surface; leave unmanaged. |
| **Dispatch** | Phone-initiated Desktop sessions. | Out-of-scope. |
| **`--teleport`** | Move a started-elsewhere task into the terminal. | Out-of-scope. |

## CI / automation

| Feature | Summary | Harness relevance |
|---|---|---|
| **GitHub Actions integration** | Automate PR reviews, issue triage via Anthropic-provided actions. | Could pair with harness's `audit.sh` to run compliance checks on PRs; not currently wired. |
| **GitLab CI/CD integration** | Same for GitLab. | Same; not wired. |
| **GitHub Code Review** | Automatic review on every PR. | External service; harness doesn't own this. |
| **Slack integration** | `@Claude` in Slack → PR back. | Out-of-scope. |

## MCP (Model Context Protocol)

Open standard for connecting AI tools to external data. Claude Code supports
MCP servers for reading design docs (Drive), updating tickets (Jira), etc.

**Harness stance today:** no MCP servers configured by default. `settings.json`
templating leaves this to the project.

## Custom commands and skills

- **Slash commands** (like `/harness/evolve`) live in `commands/<namespace>/*.md`
  and are installed globally by `scripts/install.sh` via symlink.
- **Skills** are sandboxed, Claude-invocable capabilities (e.g. the
  `osn/*-sandbox` skills from the OSN system).
- The harness currently ships commands only; no skills.

## Harness adoption state

The harness uses Claude Code as the runtime but does not actively drive any of
the above scheduled / remote / CI features. The `schedule:` block in
`watchlist.yaml` is a placeholder — Routines is the intended future substrate
if we ever enable cross-session automation.

## Open questions for the next cycle

- Does Routines expose a Webhook-style trigger to fire an evolve cycle from
  the outside (e.g. on a dependency CVE feed hit)?
- Is there a way to make session-start.sh aware of which surface it's running
  on? Different advice makes sense in terminal vs. VS Code.
