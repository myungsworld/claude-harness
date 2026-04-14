#!/usr/bin/env bash
# bootstrap.sh — Idempotent template application to projects
# Applies common + stack-specific templates. Safe to re-run.
#
# Usage:
#   ./scripts/bootstrap.sh --type go --base main /path/to/project
#   ./scripts/bootstrap.sh --sync /path/to/project          # Common files only
#   ./scripts/bootstrap.sh --dry-run --type node /tmp/test   # Preview
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
TEMPLATES="${HARNESS_DIR}/templates"

# ── Parse args ────────────────────────────────────────────
TYPE=""
BASE_BRANCH="main"
DRY_RUN=0
SYNC_ONLY=0
PROJECT_PATH=""

while [ $# -gt 0 ]; do
  case "$1" in
    --type)    TYPE="$2"; shift 2 ;;
    --base)    BASE_BRANCH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --sync)    SYNC_ONLY=1; shift ;;
    -*)        echo "Unknown flag: $1"; exit 1 ;;
    *)         PROJECT_PATH="$1"; shift ;;
  esac
done

PROJECT_PATH="${PROJECT_PATH:-.}"
PROJECT_PATH="$(cd "$PROJECT_PATH" 2>/dev/null && pwd -P || echo "$PROJECT_PATH")"
PROJECT_NAME="$(basename "$PROJECT_PATH")"
TODAY=$(date +%Y-%m-%d)

# ── Auto-detect type if not specified ─────────────────────
if [ -z "$TYPE" ]; then
  if [ -f "$PROJECT_PATH/go.mod" ]; then TYPE="go"
  elif [ -f "$PROJECT_PATH/Cargo.toml" ]; then TYPE="rust"
  elif [ -f "$PROJECT_PATH/pyproject.toml" ] || [ -f "$PROJECT_PATH/setup.py" ]; then TYPE="python"
  elif [ -f "$PROJECT_PATH/pubspec.yaml" ]; then TYPE="flutter"
  elif [ -f "$PROJECT_PATH/package.json" ]; then TYPE="node"
  else
    echo "Cannot auto-detect project type. Use --type {go|node|python|rust|flutter}"
    exit 1
  fi
  echo "Auto-detected type: ${TYPE}"
fi

echo "Bootstrapping: ${PROJECT_NAME} (${TYPE})"
echo "  Path: ${PROJECT_PATH}"
echo "  Base branch: ${BASE_BRANCH}"
[ "$DRY_RUN" = 1 ] && echo "  Mode: DRY RUN"
echo ""

# ── Helper: safe file apply ───────────────────────────────
apply_file() {
  local src="$1" dst="$2"

  if [ "$DRY_RUN" = 1 ]; then
    if [ -e "$dst" ]; then
      if cmp -s "$src" "$dst"; then
        echo "  = $dst (up to date)"
      else
        echo "  ~ $dst (would update)"
      fi
    else
      echo "  + $dst (would create)"
    fi
    return 0
  fi

  if [ -e "$dst" ]; then
    if cmp -s "$src" "$dst"; then
      echo "  = $dst (up to date)"
      return 0
    fi
    cp "$dst" "$dst.bak.$(date +%s)"
    echo "  ~ $dst (backup created)"
  else
    mkdir -p "$(dirname "$dst")"
    echo "  + $dst"
  fi
  cp "$src" "$dst"
}

# Template variable substitution
apply_template() {
  local src="$1" dst="$2"
  local tmpfile="/tmp/harness-tmpl-$$"

  sed \
    -e "s|{{PROJECT_NAME}}|${PROJECT_NAME}|g" \
    -e "s|{{BASE_BRANCH}}|${BASE_BRANCH}|g" \
    -e "s|{{TODAY}}|${TODAY}|g" \
    -e "s|{{TYPE}}|${TYPE}|g" \
    "$src" > "$tmpfile"

  apply_file "$tmpfile" "$dst"
  rm -f "$tmpfile"
}

# ── Apply common files ────────────────────────────────────
echo "Common files:"

# .gitleaks.toml
if [ -f "$TEMPLATES/common/.gitleaks.toml" ]; then
  apply_file "$TEMPLATES/common/.gitleaks.toml" "$PROJECT_PATH/.gitleaks.toml"
fi

# Security rules
if [ -f "$TEMPLATES/common/.claude/rules/security.md" ]; then
  mkdir -p "$PROJECT_PATH/.claude/rules" 2>/dev/null || true
  apply_file "$TEMPLATES/common/.claude/rules/security.md" "$PROJECT_PATH/.claude/rules/security.md"
fi

# .gitignore patch
if [ -f "$TEMPLATES/common/gitignore.patch" ]; then
  if [ -f "$PROJECT_PATH/.gitignore" ]; then
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      case "$line" in \#*) continue ;; esac
      if ! grep -qxF "$line" "$PROJECT_PATH/.gitignore" 2>/dev/null; then
        [ "$DRY_RUN" = 0 ] && echo "$line" >> "$PROJECT_PATH/.gitignore"
        echo "  + .gitignore: ${line}"
      fi
    done < "$TEMPLATES/common/gitignore.patch"
  fi
fi

# Doc templates (skip if exist — user-managed)
for tmpl in ARCHITECTURE.md DECISION.md; do
  src="$TEMPLATES/common/${tmpl}.tmpl"
  dst="$PROJECT_PATH/${tmpl}"
  if [ -f "$src" ] && [ ! -f "$dst" ]; then
    apply_template "$src" "$dst"
  elif [ -f "$dst" ]; then
    echo "  = $dst (user-managed, skipped)"
  fi
done

if [ "$SYNC_ONLY" = 1 ]; then
  echo ""
  echo "Sync complete (common files only)."
  exit 0
fi

# ── Apply stack-specific files ────────────────────────────
echo ""
echo "Stack-specific files (${TYPE}):"

STACK_DIR="$TEMPLATES/$TYPE"
if [ ! -d "$STACK_DIR" ]; then
  echo "  ! Template directory not found: $STACK_DIR"
  exit 1
fi

# lefthook.yml
if [ -f "$STACK_DIR/lefthook.yml" ]; then
  apply_file "$STACK_DIR/lefthook.yml" "$PROJECT_PATH/lefthook.yml"
fi

# AGENTS.md template
if [ -f "$STACK_DIR/AGENTS.md.tmpl" ]; then
  apply_template "$STACK_DIR/AGENTS.md.tmpl" "$PROJECT_PATH/AGENTS.md"
fi

# Stack-specific extras (e.g., .eslintrc.json for node)
for extra in "$STACK_DIR"/*; do
  bname=$(basename "$extra")
  case "$bname" in
    lefthook.yml|AGENTS.md.tmpl) continue ;;  # Already handled
    *.tmpl) apply_template "$extra" "$PROJECT_PATH/${bname%.tmpl}" ;;
    *) apply_file "$extra" "$PROJECT_PATH/$bname" ;;
  esac
done

# ── Post-bootstrap ────────────────────────────────────────
echo ""

if [ "$DRY_RUN" = 0 ]; then
  # Install lefthook if available
  if command -v lefthook >/dev/null 2>&1 && [ -f "$PROJECT_PATH/lefthook.yml" ]; then
    ( cd "$PROJECT_PATH" && lefthook install 2>/dev/null ) && echo "lefthook installed" || echo "lefthook install skipped"
  fi

  # Gitleaks smoke test
  if command -v gitleaks >/dev/null 2>&1 && [ -f "$PROJECT_PATH/.gitleaks.toml" ]; then
    if gitleaks detect --config "$PROJECT_PATH/.gitleaks.toml" --no-git --source "$PROJECT_PATH" --quiet 2>/dev/null; then
      echo "gitleaks: clean"
    else
      echo "gitleaks: findings detected — review before committing"
    fi
  fi
fi

echo ""
echo "Bootstrap complete: ${PROJECT_NAME} (${TYPE})"
