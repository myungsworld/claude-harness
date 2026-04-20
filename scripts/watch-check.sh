#!/usr/bin/env bash
# watch-check.sh — Watch source checker
# Called by session-start hook or manually. Checks overdue watch sources
# and outputs instructions for Claude to execute WebSearch/WebFetch.
#
# Usage:
#   ./scripts/watch-check.sh                  # Check all overdue
#   ./scripts/watch-check.sh --id <source-id> # Check specific source
#   ./scripts/watch-check.sh --status         # Show all sources status
#   ./scripts/watch-check.sh --update-checked <source-id>  # Mark as checked
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
WATCHLIST="${HARNESS_DIR}/watchlist/watchlist.yaml"
SNAPSHOTS="${HARNESS_DIR}/watchlist/snapshots"
WATCH_LOG="${HARNESS_DIR}/watchlist/state/watch-log.jsonl"

mkdir -p "$SNAPSHOTS" "$(dirname "$WATCH_LOG")"

if [ ! -f "$WATCHLIST" ]; then
  echo "No watchlist.yaml found at: $WATCHLIST"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 required for YAML parsing"
  exit 1
fi

# Prefer the harness-managed venv (install.sh creates it with PyYAML).
# Falls back to system python3 with a clear error if PyYAML is missing.
HARNESS_VENV_PY="${HOME}/.claude-harness/venv/bin/python3"
if [ -x "$HARNESS_VENV_PY" ]; then
  PY="$HARNESS_VENV_PY"
else
  PY="python3"
  if ! "$PY" -c "import yaml" >/dev/null 2>&1; then
    cat >&2 <<'PYERR'
Error: PyYAML is not available to python3, and the harness venv is missing.
Fix by running:   bash scripts/install.sh
Or install manually:   python3 -m pip install --user --break-system-packages pyyaml
PYERR
    exit 2
  fi
fi

ACTION="${1:---check}"
TARGET_ID="${2:-}"

# ── Status: show all sources ──────────────────────────────
if [ "$ACTION" = "--status" ]; then
  "$PY" -c "
import yaml
from datetime import datetime, timedelta

with open('$WATCHLIST') as f:
    data = yaml.safe_load(f)

defaults = data.get('defaults', {})
default_interval = defaults.get('interval_days', 14)
today = datetime.now()

print(f'Watch sources ({len(data.get(\"sources\", []))} registered):')
print(f'{\"ID\":<25} {\"Type\":<18} {\"Interval\":<10} {\"Last Checked\":<15} {\"Status\"}')
print('-' * 85)

for src in data.get('sources', []):
    sid = src['id']
    stype = src.get('type', '?')
    interval = src.get('interval_days', default_interval)
    last = src.get('last_checked')

    if last is None:
        status = 'NEVER CHECKED'
        last_str = 'never'
    else:
        if isinstance(last, str):
            last_dt = datetime.fromisoformat(last.replace('Z','').replace('+00:00',''))
        else:
            last_dt = last
        last_str = last_dt.strftime('%Y-%m-%d')
        days_since = (today - last_dt).days
        if days_since > interval:
            status = f'OVERDUE ({days_since - interval}d)'
        else:
            status = f'OK (next in {interval - days_since}d)'

    print(f'{sid:<25} {stype:<18} {interval:<10} {last_str:<15} {status}')

schedule = data.get('schedule', {})
print()
print(f'Schedule: {\"enabled\" if schedule.get(\"enabled\") else \"disabled\"} | cron: {schedule.get(\"cron\", \"N/A\")}')
"
  exit 0
fi

# ── Update last_checked timestamp ─────────────────────────
if [ "$ACTION" = "--update-checked" ] && [ -n "$TARGET_ID" ]; then
  "$PY" -c "
import yaml
from datetime import datetime

with open('$WATCHLIST') as f:
    data = yaml.safe_load(f)

for src in data.get('sources', []):
    if src['id'] == '$TARGET_ID':
        src['last_checked'] = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
        break
else:
    print(f'Source not found: $TARGET_ID')
    exit(1)

with open('$WATCHLIST', 'w') as f:
    yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

print(f'Updated last_checked for: $TARGET_ID')
"
  exit 0
fi

# ── Check: find overdue sources and output instructions ───
if [ "$ACTION" = "--check" ] || [ "$ACTION" = "--id" ]; then
  "$PY" -c "
import yaml, json, sys
from datetime import datetime, timedelta

with open('$WATCHLIST') as f:
    data = yaml.safe_load(f)

defaults = data.get('defaults', {})
default_interval = defaults.get('interval_days', 14)
today = datetime.now()
target_id = '$TARGET_ID' if '$ACTION' == '--id' else ''

overdue = []
for src in data.get('sources', []):
    if target_id and src['id'] != target_id:
        continue

    interval = src.get('interval_days', default_interval)
    last = src.get('last_checked')

    is_overdue = False
    if last is None:
        is_overdue = True
    else:
        if isinstance(last, str):
            try:
                last_dt = datetime.fromisoformat(last.replace('Z','').replace('+00:00',''))
            except:
                is_overdue = True
                last_dt = None
        else:
            last_dt = last
        if last_dt and today - last_dt > timedelta(days=interval):
            is_overdue = True

    if is_overdue or target_id:
        overdue.append(src)

if not overdue:
    print('All watch sources are up to date.')
    sys.exit(0)

print(f'Found {len(overdue)} source(s) to check:')
print()

for src in overdue:
    sid = src['id']
    stype = src.get('type', 'unknown')
    name = src.get('name', sid)
    focus = src.get('focus', [])
    affects = src.get('affects', [])

    print(f'--- {name} ({sid}) [{stype}] ---')

    if stype == 'web':
        urls = src.get('urls', [])
        print(f'Action: WebSearch + WebFetch the following URLs:')
        for url in urls:
            print(f'  - {url}')
        print(f'Focus on: {json.dumps(focus)}')
        print(f'Compare with: $SNAPSHOTS/{sid}.latest.md')

    elif stype == 'github-release':
        repo = src.get('repo', '?')
        print(f'Action: Check latest release of {repo}')
        print(f'  gh api repos/{repo}/releases/latest')
        print(f'Focus on: {json.dumps(focus)}')
        print(f'Compare with: $SNAPSHOTS/{sid}.latest.md')

    elif stype in ('npm', 'pypi', 'crates', 'pub'):
        pkg = src.get('package', src.get('repo', '?'))
        print(f'Action: Check latest version of {pkg} on {stype}')
        print(f'Focus on: {json.dumps(focus)}')

    elif stype == 'internal':
        scans = src.get('scan', [])
        triggers = src.get('triggers', {})
        print(f'Action: Scan local signal files:')
        for s in scans:
            print(f'  - {s}')
        print(f'Triggers: {json.dumps(triggers)}')

    print(f'Affects: {json.dumps(affects)}')
    print(f'After checking: run ./scripts/watch-check.sh --update-checked {sid}')
    print()
"
  exit 0
fi

echo "Usage: watch-check.sh [--check|--status|--id <id>|--update-checked <id>]"
exit 1
