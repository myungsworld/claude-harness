#!/usr/bin/env bash
# audit.sh — Compliance check for a project against harness standards
# Reports PASS/WARN/FAIL for each check.
#
# Usage:
#   ./scripts/audit.sh [/path/to/project]
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
PROJECT_PATH="${1:-.}"
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd -P)"
PROJECT_NAME="$(basename "$PROJECT_PATH")"

PASS=0
WARN=0
FAIL=0

_pass() { echo "  PASS  $1"; PASS=$((PASS + 1)); }
_warn() { echo "  WARN  $1"; WARN=$((WARN + 1)); }
_fail() { echo "  FAIL  $1"; FAIL=$((FAIL + 1)); }

echo "Auditing: ${PROJECT_NAME}"
echo "  Path: ${PROJECT_PATH}"
echo ""

# ── Git repo ──────────────────────────────────────────────
if [ -d "$PROJECT_PATH/.git" ]; then
  _pass "Git repository"
else
  _fail "Not a git repository"
fi

# ── Type detection ────────────────────────────────────────
TYPE="unknown"
if [ -f "$PROJECT_PATH/go.mod" ]; then TYPE="go"
elif [ -f "$PROJECT_PATH/Cargo.toml" ]; then TYPE="rust"
elif [ -f "$PROJECT_PATH/pyproject.toml" ] || [ -f "$PROJECT_PATH/setup.py" ]; then TYPE="python"
elif [ -f "$PROJECT_PATH/pubspec.yaml" ]; then TYPE="flutter"
elif [ -f "$PROJECT_PATH/package.json" ]; then TYPE="node"
fi
echo "  Type: ${TYPE}"
echo ""

# ── Standard files ────────────────────────────────────────
echo "Standard files:"

# .gitleaks.toml
if [ -f "$PROJECT_PATH/.gitleaks.toml" ]; then
  if [ -f "$HARNESS_DIR/templates/common/.gitleaks.toml" ]; then
    if cmp -s "$PROJECT_PATH/.gitleaks.toml" "$HARNESS_DIR/templates/common/.gitleaks.toml"; then
      _pass ".gitleaks.toml (matches template)"
    else
      _warn ".gitleaks.toml (drifted from template)"
    fi
  else
    _pass ".gitleaks.toml (present)"
  fi
else
  _fail ".gitleaks.toml missing"
fi

# lefthook.yml
if [ -f "$PROJECT_PATH/lefthook.yml" ]; then
  _pass "lefthook.yml"
else
  _warn "lefthook.yml missing"
fi

# AGENTS.md
if [ -f "$PROJECT_PATH/AGENTS.md" ]; then
  _pass "AGENTS.md"
else
  _warn "AGENTS.md missing"
fi

# ARCHITECTURE.md
if [ -f "$PROJECT_PATH/ARCHITECTURE.md" ]; then
  _pass "ARCHITECTURE.md"
else
  _warn "ARCHITECTURE.md missing"
fi

# DECISION.md
if [ -f "$PROJECT_PATH/DECISION.md" ]; then
  _pass "DECISION.md"
else
  _warn "DECISION.md missing"
fi

# Security rules
if [ -f "$PROJECT_PATH/.claude/rules/security.md" ]; then
  _pass ".claude/rules/security.md"
else
  _warn ".claude/rules/security.md missing"
fi

# ── Stack-specific checks ────────────────────────────────
echo ""
echo "Stack checks (${TYPE}):"

if [ "$TYPE" != "unknown" ] && [ -f "$PROJECT_PATH/lefthook.yml" ]; then
  # Check for selective-test pattern
  if grep -q "findRelatedTests\|--findRelatedTests\|--changed\|-p.*changed" "$PROJECT_PATH/lefthook.yml" 2>/dev/null; then
    _pass "Selective test in lefthook.yml"
  else
    _warn "No selective test pattern in lefthook.yml"
  fi
fi

# ── Summary ───────────────────────────────────────────────
echo ""
TOTAL=$((PASS + WARN + FAIL))
echo "Result: ${PASS} pass / ${WARN} warn / ${FAIL} fail (${TOTAL} checks)"

if [ "$FAIL" -gt 0 ]; then
  echo "  Run: ./scripts/bootstrap.sh --type ${TYPE} ${PROJECT_PATH}"
  exit 1
elif [ "$WARN" -gt 0 ]; then
  exit 0
else
  echo "  All checks passed!"
  exit 0
fi
