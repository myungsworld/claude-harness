#!/usr/bin/env bash
# regression-audit.sh — Audit all registered projects
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
PROJECTS_FILE="${HOME}/.claude-harness/projects"

if [ ! -f "$PROJECTS_FILE" ]; then
  echo "No projects registered. Run: make register P=/path/to/project"
  exit 0
fi

TOTAL=0
PASSED=0
FAILED=0

echo "Regression audit across registered projects"
echo "============================================"
echo ""

while IFS= read -r project; do
  [ -z "$project" ] && continue
  case "$project" in \#*) continue ;; esac
  project="${project/#\~/$HOME}"

  if [ ! -d "$project" ]; then
    echo "SKIP  ${project} (not found)"
    continue
  fi

  TOTAL=$((TOTAL + 1))
  echo "── $(basename "$project") ──"

  if bash "$HARNESS_DIR/scripts/audit.sh" "$project" 2>/dev/null; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
  fi
  echo ""
done < "$PROJECTS_FILE"

echo "============================================"
echo "Total: ${TOTAL} | Passed: ${PASSED} | Failed: ${FAILED}"
[ "$FAILED" -gt 0 ] && exit 1
exit 0
