#!/usr/bin/env bash
# evolve.sh — Self-improvement engine for claude-harness (internal-signal half)
#
# The /harness/evolve slash command runs the full conversational cycle
# (coverage check → internal signals → external watch → review loop → cycle log).
# This script implements only the one piece that has to be bash: reading local
# signal files and summarizing them for the model.
#
# Usage:
#   ./scripts/evolve.sh --phase internal   # Analyze internal signals (30d window)
#
# That's it. Proposal generation, status tracking, and per-item apply/dismiss
# state all live in the conversation itself — not in this script.

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
SIGNALS_FILE="${HARNESS_DIR}/watchlist/state/signals.jsonl"
CYCLES_DIR="${HARNESS_DIR}/watchlist/cycles"
WATCH_LOG="${HARNESS_DIR}/watchlist/state/watch-log.jsonl"
PROJECTS_FILE="${HOME}/.claude-harness/projects"
THIRTY_DAYS_AGO=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d "30 days ago" +%Y-%m-%d 2>/dev/null || echo "")

mkdir -p "$CYCLES_DIR" "$(dirname "$SIGNALS_FILE")"

ACTION="${1:-help}"
shift 2>/dev/null || true

_phase_internal() {
  echo "=== Internal Signal Analysis (30-day window) ==="
  echo ""

  # 1. Session signals from session-end.sh
  if [ -f "$SIGNALS_FILE" ] && [ -s "$SIGNALS_FILE" ]; then
    TOTAL_SESSIONS=$(wc -l < "$SIGNALS_FILE" | tr -d ' ')
    echo "-- Sessions: ${TOTAL_SESSIONS} total signals --"

    if command -v jq >/dev/null 2>&1; then
      if [ -n "$THIRTY_DAYS_AGO" ]; then
        RECENT=$(jq -c --arg since "$THIRTY_DAYS_AGO" \
          'select(.timestamp >= $since)' "$SIGNALS_FILE" 2>/dev/null || cat "$SIGNALS_FILE")
      else
        RECENT=$(cat "$SIGNALS_FILE")
      fi

      RECENT_COUNT=$(echo "$RECENT" | wc -l | tr -d ' ')
      echo "  Recent (30d): ${RECENT_COUNT} sessions"
      echo ""

      echo "-- Command Usage --"
      echo "$RECENT" | jq -r '.commands_used[]? // empty' 2>/dev/null \
        | sort | uniq -c | sort -rn | head -10 \
        | while read -r count cmd; do
            printf "  %3d  %s\n" "$count" "$cmd"
          done
      echo ""

      echo "-- Error Patterns --"
      echo "$RECENT" | jq -r '.error_patterns[]? | "\(.tool) \(.count)"' 2>/dev/null \
        | awk '{tools[$1]+=$2} END {for(t in tools) printf "  %3d  %s\n", tools[t], t}' \
        | sort -rn | head -5
      echo ""

      echo "-- Active Projects --"
      echo "$RECENT" | jq -r '.project // empty' 2>/dev/null \
        | sort | uniq -c | sort -rn | head -5 \
        | while read -r count proj; do
            printf "  %3d  %s\n" "$count" "$proj"
          done
      echo ""
    else
      echo "  (jq not available — skipping detailed analysis)"
      echo ""
    fi
  else
    echo "-- No signals collected yet --"
    echo "  Signals are captured by session-end.sh after each Claude session."
    echo "  File: ${SIGNALS_FILE}"
    echo ""
  fi

  # 2. Template drift across registered projects
  if [ -f "$PROJECTS_FILE" ]; then
    echo "-- Template Drift --"
    DRIFT_COUNT=0
    while IFS= read -r proj; do
      [ -z "$proj" ] && continue
      case "$proj" in \#*) continue ;; esac
      proj="${proj/#\~/$HOME}"
      [ ! -d "$proj" ] && continue

      drifts=""
      [ -f "$proj/.gitleaks.toml" ] && \
        ! diff -q "$HARNESS_DIR/templates/common/.gitleaks.toml" "$proj/.gitleaks.toml" >/dev/null 2>&1 && \
        drifts="${drifts} .gitleaks.toml"
      [ -f "$proj/lefthook.yml" ] && \
        drifts="${drifts} lefthook.yml(custom)"

      if [ -n "$drifts" ]; then
        echo "  $(basename "$proj"):${drifts}"
        DRIFT_COUNT=$((DRIFT_COUNT + 1))
      fi
    done < "$PROJECTS_FILE"
    if [ "$DRIFT_COUNT" -eq 0 ]; then
      echo "  No drift detected"
    elif [ "$DRIFT_COUNT" -ge 3 ]; then
      echo "  WARNING: ${DRIFT_COUNT} projects drifting — template revision candidate"
    fi
    echo ""
  fi

  # 3. Harness churn from git log
  echo "-- Harness Churn (recent changes) --"
  git -C "$HARNESS_DIR" log --oneline --since="30 days ago" -- templates/ hooks/ scripts/ 2>/dev/null \
    | head -10 \
    | sed 's/^/  /' || echo "  (no recent changes)"
  echo ""

  # 4. Watch activity
  if [ -f "$WATCH_LOG" ] && [ -s "$WATCH_LOG" ]; then
    echo "-- Watch Activity --"
    tail -5 "$WATCH_LOG" | jq -r '"\(.timestamp) \(.source) \(.action)"' 2>/dev/null \
      | sed 's/^/  /' || echo "  (parse error)"
    echo ""
  fi

  # 5. Previous cycle logs (for context, not for decisions)
  if [ -d "$CYCLES_DIR" ] && [ -n "$(ls -A "$CYCLES_DIR" 2>/dev/null)" ]; then
    echo "-- Recent Cycles --"
    ls -1t "$CYCLES_DIR"/*.md 2>/dev/null | head -3 | while read -r f; do
      echo "  $(basename "$f")"
    done
    echo ""
  fi

  echo "=== Internal analysis complete ==="
}

case "$ACTION" in
  --phase)
    PHASE="${1:-}"
    case "$PHASE" in
      internal) _phase_internal ;;
      *) echo "Unknown phase: ${PHASE}. Only 'internal' is supported." && exit 1 ;;
    esac
    ;;
  help|--help|-h)
    sed -n '2,14p' "$0" | sed 's/^# \?//'
    ;;
  *)
    echo "Unknown action: $ACTION"
    sed -n '2,14p' "$0" | sed 's/^# \?//'
    exit 1
    ;;
esac
