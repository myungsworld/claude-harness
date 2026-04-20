# Changelog

All notable changes to claude-harness will be documented in this file.

## [Unreleased]

### Changed
- `/harness/evolve` redesigned as a conversational cycle. Findings are reviewed
  individually in dialogue; Claude no longer pre-assigns priorities or decides
  `defer` on the user's behalf. Only one slash-command form remains
  (`/harness/evolve` — no flags).
- `watchlist/proposals/` replaced by `watchlist/cycles/` (append-only logs, one
  per cycle; no persistent pending state).
- `scripts/evolve.sh` slimmed to the internal-signal helper only. Removed
  `_phase_propose`, `_list`, `_show`, `_update_status` and the `--apply` /
  `--dismiss` / `--defer` actions.
- `scripts/install.sh` creates a harness-owned Python venv at
  `~/.claude-harness/venv/` with PyYAML, and `watch-check.sh` /
  `snapshot-diff.sh` prefer that interpreter.
- `scripts/install.sh` seeds user-preference memory files on every install
  (idempotent).

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
- Snapshot + diff pipeline with human gate on all changes
