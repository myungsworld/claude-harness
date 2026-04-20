# lefthook-releases — baseline 2026-04-20

Latest: **v2.1.6** (published 2026-04-16)

## Recent versions

| Tag    | Published           |
|--------|---------------------|
| v2.1.6 | 2026-04-16          |
| v2.1.5 | 2026-04-06          |
| v2.1.4 | 2026-03-12          |
| v2.1.3 | 2026-03-07          |
| v2.1.2 | 2026-03-01          |

## v2.1.6 changelog (excerpt)

- fix(packaging): do not pipe stdout and stderr (#1382)
- fix(windows): normalize lefthook path for sh script (#1383)
- fix: log full scoped name for skipped jobs (#1291)
- fix: normalize `root` to always include trailing slash before path replacement (#1381)
- fix: skip pty allocation when stdout is not a terminal (#1393)

## Assessment

- No breaking config-format changes in 2.1.x line — all bugfix releases.
- Config schema used in `templates/*/lefthook.yml` (pre-commit/pre-push + commands) remains valid.
- No action needed on templates.
