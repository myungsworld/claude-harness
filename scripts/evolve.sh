#!/usr/bin/env bash
# evolve.sh — Self-improvement engine for claude-harness
#
# Combines internal signal analysis (bash) with external watch results
# (provided by Claude via WebSearch/WebFetch) to generate improvement proposals.
#
# Usage:
#   ./scripts/evolve.sh                          # Show help
#   ./scripts/evolve.sh --phase internal          # Analyze internal signals (30d)
#   ./scripts/evolve.sh --phase propose [FILE]    # Generate proposal from findings
#   ./scripts/evolve.sh --list                    # List pending proposals
#   ./scripts/evolve.sh --show <id>               # Show a specific proposal
#   ./scripts/evolve.sh --dismiss <id>            # Mark proposal as dismissed
#   ./scripts/evolve.sh --apply <id>              # Mark proposal as applied (human gate)

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
SIGNALS_FILE="${HARNESS_DIR}/watchlist/state/signals.jsonl"
PROPOSALS_DIR="${HARNESS_DIR}/watchlist/proposals"
WATCH_LOG="${HARNESS_DIR}/watchlist/state/watch-log.jsonl"
PROJECTS_FILE="${HOME}/.claude-harness/projects"
TODAY=$(date +%Y-%m-%d)
THIRTY_DAYS_AGO=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d "30 days ago" +%Y-%m-%d 2>/dev/null || echo "")

mkdir -p "$PROPOSALS_DIR" "$(dirname "$SIGNALS_FILE")"

ACTION="${1:-help}"
shift 2>/dev/null || true

# ── Phase: Internal Signal Analysis ──────────────────────
_phase_internal() {
  echo "=== Internal Signal Analysis (30-day window) ==="
  echo ""

  # 1. Signals from session-end.sh
  if [ -f "$SIGNALS_FILE" ] && [ -s "$SIGNALS_FILE" ]; then
    TOTAL_SESSIONS=$(wc -l < "$SIGNALS_FILE" | tr -d ' ')
    echo "-- Sessions: ${TOTAL_SESSIONS} total signals --"

    if command -v jq >/dev/null 2>&1; then
      # Filter to last 30 days if possible
      if [ -n "$THIRTY_DAYS_AGO" ]; then
        RECENT=$(jq -c --arg since "$THIRTY_DAYS_AGO" \
          'select(.timestamp >= $since)' "$SIGNALS_FILE" 2>/dev/null || cat "$SIGNALS_FILE")
      else
        RECENT=$(cat "$SIGNALS_FILE")
      fi

      RECENT_COUNT=$(echo "$RECENT" | wc -l | tr -d ' ')
      echo "  Recent (30d): ${RECENT_COUNT} sessions"
      echo ""

      # Command usage frequency
      echo "-- Command Usage --"
      echo "$RECENT" | jq -r '.commands_used[]? // empty' 2>/dev/null \
        | sort | uniq -c | sort -rn | head -10 \
        | while read -r count cmd; do
            printf "  %3d  %s\n" "$count" "$cmd"
          done
      USED_CMDS=$(echo "$RECENT" | jq -r '.commands_used[]? // empty' 2>/dev/null | sort -u)
      echo ""

      # Error patterns
      echo "-- Error Patterns --"
      echo "$RECENT" | jq -r '.error_patterns[]? | "\(.tool) \(.count)"' 2>/dev/null \
        | awk '{tools[$1]+=$2} END {for(t in tools) printf "  %3d  %s\n", tools[t], t}' \
        | sort -rn | head -5
      echo ""

      # Top projects
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

  # 2. Template drift (if projects registered)
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

  # 3. Harness churn (git log)
  echo "-- Harness Churn (recent changes) --"
  git -C "$HARNESS_DIR" log --oneline --since="30 days ago" -- templates/ hooks/ scripts/ 2>/dev/null \
    | head -10 \
    | sed 's/^/  /' || echo "  (no recent changes)"
  echo ""

  # 4. Watch log summary
  if [ -f "$WATCH_LOG" ] && [ -s "$WATCH_LOG" ]; then
    echo "-- Watch Activity --"
    tail -5 "$WATCH_LOG" | jq -r '"\(.timestamp) \(.source) \(.action)"' 2>/dev/null \
      | sed 's/^/  /' || echo "  (parse error)"
    echo ""
  fi

  echo "=== Internal analysis complete ==="
}

# ── Phase: Generate Proposal ─────────────────────────────
_phase_propose() {
  FINDINGS_FILE="${1:-}"
  PROPOSAL_ID="evolve-${TODAY}"
  PROPOSAL_FILE="${PROPOSALS_DIR}/${PROPOSAL_ID}.md"

  # Prevent duplicates
  if [ -f "$PROPOSAL_FILE" ]; then
    echo "Proposal already exists for today: ${PROPOSAL_FILE}"
    echo "To regenerate, remove it first: rm ${PROPOSAL_FILE}"
    exit 1
  fi

  # Read findings from file or stdin
  FINDINGS=""
  if [ -n "$FINDINGS_FILE" ] && [ -f "$FINDINGS_FILE" ]; then
    FINDINGS=$(cat "$FINDINGS_FILE")
  elif [ ! -t 0 ]; then
    FINDINGS=$(cat)
  fi

  cat > "$PROPOSAL_FILE" <<EOF
---
id: ${PROPOSAL_ID}
created_at: ${TODAY}
status: pending
sources: []
priority: medium
---

# Evolve Proposal: ${TODAY}

## Internal Signals

<!-- Paste or pipe internal analysis output here if not auto-populated -->
${FINDINGS:-_No findings provided. Run: evolve.sh --phase internal | evolve.sh --phase propose_}

## External Findings

<!-- Claude fills this section after WebSearch/WebFetch -->
_Pending external watch check._

## Proposed Changes

<!-- Specific file changes with diffs -->
1. (to be determined after analysis)

## Risk Assessment

- Affected projects: (list)
- Breaking: (yes/no)
- Rollback: revert this commit

## Decision

- [ ] **Apply** — implement the recommended changes
- [ ] **Defer** — revisit next cycle
- [ ] **Dismiss** — not relevant, no action needed

> Generated by evolve.sh on ${TODAY}
EOF

  echo "Proposal created: ${PROPOSAL_FILE}"
  echo "Next: review and fill in External Findings + Proposed Changes"

  # Log
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"source\":\"evolve\",\"action\":\"proposal_created\",\"proposal\":\"${PROPOSAL_ID}\"}" \
    >> "$WATCH_LOG" 2>/dev/null || true
}

# ── List proposals ───────────────────────────────────────
_list() {
  echo "Proposals in ${PROPOSALS_DIR}:"
  echo ""

  found=0
  for f in "$PROPOSALS_DIR"/*.md; do
    [ ! -f "$f" ] && continue
    [ "$(basename "$f")" = ".gitkeep" ] && continue
    found=$((found + 1))

    # Parse frontmatter
    id=$(sed -n 's/^id: *//p' "$f" | head -1)
    status=$(sed -n 's/^status: *//p' "$f" | head -1)
    created=$(sed -n 's/^created_at: *//p' "$f" | head -1)

    case "${status:-unknown}" in
      pending)  marker="[ ]" ;;
      applied)  marker="[x]" ;;
      dismissed) marker="[-]" ;;
      deferred) marker="[>]" ;;
      *)        marker="[?]" ;;
    esac

    printf "  %s %-35s %s  (%s)\n" "$marker" "${id:-$(basename "$f")}" "${created:-?}" "${status:-unknown}"
  done

  if [ "$found" -eq 0 ]; then
    echo "  (no proposals)"
  fi
}

# ── Show proposal ────────────────────────────────────────
_show() {
  TARGET="${1:-}"
  [ -z "$TARGET" ] && echo "Usage: evolve.sh --show <id>" && exit 1

  FILE="${PROPOSALS_DIR}/${TARGET}.md"
  [ ! -f "$FILE" ] && FILE=$(find "$PROPOSALS_DIR" -name "*${TARGET}*" -print -quit 2>/dev/null)
  [ -z "$FILE" ] || [ ! -f "$FILE" ] && echo "Proposal not found: ${TARGET}" && exit 1

  cat "$FILE"
}

# ── Update proposal status ───────────────────────────────
_update_status() {
  local new_status="$1"
  local target="${2:-}"
  [ -z "$target" ] && echo "Usage: evolve.sh --${new_status} <id>" && exit 1

  FILE="${PROPOSALS_DIR}/${target}.md"
  [ ! -f "$FILE" ] && FILE=$(find "$PROPOSALS_DIR" -name "*${target}*" -print -quit 2>/dev/null)
  [ -z "$FILE" ] || [ ! -f "$FILE" ] && echo "Proposal not found: ${target}" && exit 1

  if sed -i.bak "s/^status: .*/status: ${new_status}/" "$FILE" 2>/dev/null; then
    rm -f "${FILE}.bak"
    echo "Proposal ${target}: status -> ${new_status}"
    echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"source\":\"evolve\",\"action\":\"${new_status}\",\"proposal\":\"${target}\"}" \
      >> "$WATCH_LOG" 2>/dev/null || true
  else
    # macOS sed requires different syntax
    sed "s/^status: .*/status: ${new_status}/" "$FILE" > "${FILE}.tmp" && mv "${FILE}.tmp" "$FILE"
    echo "Proposal ${target}: status -> ${new_status}"
  fi
}

# ── Main ─────────────────────────────────────────────────
case "$ACTION" in
  --phase)
    PHASE="${1:-}"
    shift 2>/dev/null || true
    case "$PHASE" in
      internal) _phase_internal ;;
      propose)  _phase_propose "$@" ;;
      *)        echo "Unknown phase: ${PHASE}. Use: internal, propose" && exit 1 ;;
    esac
    ;;
  --list)    _list ;;
  --show)    _show "$@" ;;
  --dismiss) _update_status "dismissed" "$@" ;;
  --apply)   _update_status "applied" "$@" ;;
  --defer)   _update_status "deferred" "$@" ;;
  help|--help|-h)
    sed -n '2,14p' "$0" | sed 's/^# \?//'
    ;;
  *)
    echo "Unknown action: $ACTION"
    sed -n '2,14p' "$0" | sed 's/^# \?//'
    exit 1
    ;;
esac
