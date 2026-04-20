# gitleaks-releases — baseline 2026-04-20

Latest: **v8.30.1** (published 2026-03-21)

## Recent versions

| Tag     | Published           |
|---------|---------------------|
| v8.30.1 | 2026-03-21          |
| v8.30.0 | 2025-11-26          |
| v8.29.1 | 2025-11-19          |
| v8.29.0 | 2025-11-04          |
| v8.28.0 | 2025-07-20          |

## v8.30.0 new default rules (now inherited automatically)

- Looker client ID / client secret detection (#1947)
- Airtable Personal Access Token detection (#1952)

## v8.30.1 changes

- goreleaser update, report-template cleanup, Go 1.24 build.

## Assessment

- No config-format breaking changes.
- Our `templates/common/.gitleaks.toml` only defines an allowlist; default ruleset is inherited, so new 8.30 rules apply automatically once users upgrade the gitleaks binary.
- No custom rules in template that overlap with the new defaults — no dedup needed.
- No action needed on template.
