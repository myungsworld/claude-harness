#!/usr/bin/env bash
# snapshot-diff.sh — Compare a new snapshot with the previous baseline.
#
# Emits the unified diff on stdout (empty stdout = no change) and updates the
# stored baseline to the new content. The /harness/evolve conversation reads
# this diff and decides whether to treat it as a finding.
#
# Usage:
#   ./scripts/snapshot-diff.sh <source-id> <new-snapshot-file>
#
# Exit codes:
#   0  — diff emitted (changes present) OR baseline created OR no change
#   1  — bad arguments
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
SNAPSHOTS="${HARNESS_DIR}/watchlist/snapshots"
WATCH_LOG="${HARNESS_DIR}/watchlist/state/watch-log.jsonl"

SOURCE_ID="${1:-}"
NEW_SNAPSHOT="${2:-}"

if [ -z "$SOURCE_ID" ] || [ -z "$NEW_SNAPSHOT" ] || [ ! -f "$NEW_SNAPSHOT" ]; then
  echo "Usage: snapshot-diff.sh <source-id> <new-snapshot-file>" >&2
  exit 1
fi

mkdir -p "$SNAPSHOTS" "$(dirname "$WATCH_LOG")"

PREV_SNAPSHOT="${SNAPSHOTS}/${SOURCE_ID}.latest.md"

_log() {
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"source\":\"${SOURCE_ID}\",\"action\":\"${1}\"}" \
    >> "$WATCH_LOG" 2>/dev/null || true
}

# First observation → establish baseline, emit nothing.
if [ ! -f "$PREV_SNAPSHOT" ]; then
  cp "$NEW_SNAPSHOT" "$PREV_SNAPSHOT"
  echo "baseline established: ${PREV_SNAPSHOT}" >&2
  _log "baseline"
  exit 0
fi

DIFF_OUTPUT=$(diff -u "$PREV_SNAPSHOT" "$NEW_SNAPSHOT" 2>/dev/null || true)

if [ -z "$DIFF_OUTPUT" ]; then
  echo "no change: ${SOURCE_ID}" >&2
  _log "no_change"
  exit 0
fi

# Update baseline and emit diff on stdout for the conversation to consume.
cp "$NEW_SNAPSHOT" "$PREV_SNAPSHOT"
_log "diff_emitted"
printf '%s\n' "$DIFF_OUTPUT"
