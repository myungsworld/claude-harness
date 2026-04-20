---
type: reference
topic: claude-models
updated: 2026-04-20
tags: [claude, models, anthropic]
source: https://docs.anthropic.com/en/docs/about-claude/models
---

# Claude — Current Model Lineup

State of the Claude model family at the last evolve cycle. Update when a new
model ships or an existing one deprecates.

## Claude 4.x family (current)

| Tier | Model ID | Context | Notes |
|---|---|---|---|
| **Opus** | `claude-opus-4-7` | 1M (with `[1m]` suffix) | Top capability; this harness runs on it |
| **Sonnet** | `claude-sonnet-4-6` | Standard | Balance tier |
| **Haiku** | `claude-haiku-4-5-20251001` | Standard | Fast tier |

## Capabilities by tier (harness-relevant)

| Capability | Opus 4.7 | Sonnet 4.6 | Haiku 4.5 |
|---|:-:|:-:|:-:|
| 1M context window | ✓ (opt-in via `[1m]` suffix) | — | — |
| Prompt caching | ✓ | ✓ | ✓ |
| Tool use / function calling | ✓ | ✓ | ✓ |
| Extended thinking | ✓ | ✓ | — |

## Naming convention

Model IDs follow `claude-<tier>-<major>-<minor>[-<date>]`. The trailing date
(e.g. `-20251001`) is a snapshot ID for immutability; omit it to float to the
latest. When building against the Claude API, pin the date for production
reliability and float for development.

## Harness adoption state

- **Harness itself runs on Opus 4.7 [1m].** No hardcoded model IDs in
  harness scripts today (grep checked: no matches in `scripts/`, `hooks/`, `commands/`).
- **Templates** do not currently pin a model — projects choose at their own
  level. If a future `docs/claude/models.md` cycle adds a harness-wide
  recommendation, that would be a `template-update` candidate.

## Open questions for the next cycle

- Does Opus 4.7's `[1m]` context change the economics of prompt-caching enough
  to recommend it as the default for harness-managed projects?
- Are there deprecation timelines for Claude 4.5 / 4.4 that projects need to
  migrate off? (watch source candidate)
