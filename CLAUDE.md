# CLAUDE.md

@AGENTS.md

## Claude Code Notes

### Development
- After editing hooks/, run `make lint` to verify bash syntax
- After editing templates/, run `make validate` to dry-run all 5 stacks
- `watchlist/watchlist.yaml` changes take effect on next session start

### Watch System
- Hooks auto-check overdue watch sources on session start
- Snapshots stored in `watchlist/snapshots/` — never edit manually
- Proposals in `watchlist/proposals/` — review before applying

### Change Impact
- Template changes affect all registered projects
- Always run `make regression` before merging template PRs
