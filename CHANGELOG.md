# Changelog

All notable changes to claude-harness will be documented in this file.

## [0.1.0] - 2026-04-14

### Added
- Initial project skeleton
- `watchlist/watchlist.yaml` — external source watch registry
- `hooks/session-start.sh` — auto watch check + context injection
- `hooks/session-end.sh` — internal signal collection
- `scripts/install.sh` — global hook + command installation
- `scripts/bootstrap.sh` — idempotent template application
- `scripts/audit.sh` — compliance check
- `scripts/watch-check.sh` — watch execution logic
- Multi-stack templates: Go, Node, Python, Rust, Flutter
- Snapshot + diff + proposal generation pipeline
- Human gate on all proposals (never auto-apply)
