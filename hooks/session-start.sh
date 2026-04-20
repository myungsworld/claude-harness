#!/usr/bin/env bash
# session-start.sh — Project context injection + watch trigger (SessionStart)
# Analyzes project state, checks overdue watches, injects context into Claude conversation.
# stdout is appended to the conversation.

# Scope gate (strict opt-in)
SCOPE_LIB="$(dirname "$0")/_scope.sh"
if [ -f "$SCOPE_LIB" ]; then
  # shellcheck disable=SC1090
  . "$SCOPE_LIB" && harness_in_scope || exit 0
fi

CWD=$(pwd)
PROJECT_NAME=$(basename "$CWD")

# ─── Harness auto-sync (cooldown: 1 hour) ────────────────
SYNC_CHECK_FILE="${HARNESS_HOME}/.last-sync-check"
SYNC_INTERVAL=3600

_should_sync() {
  [ ! -f "$SYNC_CHECK_FILE" ] && return 0
  local last now diff
  last=$(cat "$SYNC_CHECK_FILE" 2>/dev/null || echo "0")
  now=$(date +%s)
  diff=$((now - last))
  [ $diff -ge $SYNC_INTERVAL ]
}

if [ -n "${HARNESS_ROOT:-}" ] && [ -d "${HARNESS_ROOT}/.git" ] && _should_sync; then
  date +%s > "$SYNC_CHECK_FILE"

  LOCAL_HEAD=$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null)
  REMOTE_HEAD=$(git -C "$HARNESS_ROOT" rev-parse origin/main 2>/dev/null || echo "")

  if [ -n "$REMOTE_HEAD" ] && [ "$LOCAL_HEAD" != "$REMOTE_HEAD" ]; then
    BEHIND=$(git -C "$HARNESS_ROOT" rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
    if [ -z "$(git -C "$HARNESS_ROOT" status --porcelain 2>/dev/null)" ]; then
      if git -C "$HARNESS_ROOT" pull --ff-only --quiet origin main 2>/dev/null; then
        echo "[harness] Updated (+${BEHIND} commits)"
        if [ -x "$HARNESS_ROOT/scripts/install.sh" ]; then
          "$HARNESS_ROOT/scripts/install.sh" >/dev/null 2>&1 && echo "  Global assets synced"
        fi
      fi
    fi
  fi
fi

# ─── Project type detection ──────────────────────────────
TYPE="unknown"
if [ -f "go.mod" ]; then TYPE="go"
elif [ -f "Cargo.toml" ]; then TYPE="rust"
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then TYPE="python"
elif [ -f "pubspec.yaml" ]; then TYPE="flutter"
elif [ -f "package.json" ]; then TYPE="node"
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
DIRTY=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

echo "[harness] ${PROJECT_NAME} (${TYPE}) | ${BRANCH} | ${DIRTY} uncommitted"

# ─── Watch: check overdue sources ────────────────────────
WATCHLIST="${HARNESS_ROOT:-}/watchlist/watchlist.yaml"
if [ -f "$WATCHLIST" ] && command -v python3 >/dev/null 2>&1; then
  OVERDUE=$(python3 -c "
import yaml, sys
from datetime import datetime, timedelta

try:
    with open('$WATCHLIST') as f:
        data = yaml.safe_load(f)
except:
    sys.exit(0)

if not data or 'sources' not in data:
    sys.exit(0)

defaults = data.get('defaults', {})
default_interval = defaults.get('interval_days', 14)
today = datetime.now()
overdue = []

for src in data['sources']:
    interval = src.get('interval_days', default_interval)
    last = src.get('last_checked')
    if last is None:
        overdue.append(f\"{src['id']} ({src['name']}) — never checked\")
        continue
    if isinstance(last, str):
        try:
            last_dt = datetime.fromisoformat(last.replace('Z', '+00:00').replace('+00:00', ''))
        except:
            overdue.append(f\"{src['id']} ({src['name']}) — invalid date\")
            continue
    elif isinstance(last, datetime):
        last_dt = last
    else:
        continue
    if today - last_dt > timedelta(days=interval):
        days_over = (today - last_dt).days - interval
        overdue.append(f\"{src['id']} ({src['name']}) — {days_over}d overdue\")

if overdue:
    print(f'  Watch: {len(overdue)} source(s) overdue')
    for o in overdue:
        print(f'    - {o}')
    print('  Run /harness/evolve to start a self-improvement cycle.')
" 2>/dev/null)

  if [ -n "$OVERDUE" ]; then
    echo ""
    echo "$OVERDUE"
  fi
fi

# ─── Stack preset (cold-start help) ─────────────────────
if [ "$TYPE" != "unknown" ]; then
  echo ""
  echo "  Stack ($TYPE):"
  case "$TYPE" in
    go)     echo "    test: go test ./... -race | lint: golangci-lint run" ;;
    node)   echo "    test: npx jest --findRelatedTests | lint: eslint" ;;
    python) echo "    test: pytest | lint: ruff check . && mypy ." ;;
    rust)   echo "    test: cargo test | lint: cargo clippy -- -D warnings" ;;
    flutter) echo "    test: flutter test | lint: flutter analyze" ;;
  esac
fi

exit 0
