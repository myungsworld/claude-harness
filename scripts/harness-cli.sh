#!/usr/bin/env bash
# harness — CLI wrapper for claude-harness operations
#
# Usage:
#   harness <command> [args...]
#
# Commands:
#   install              Re-run global install (refresh hooks, commands, agents)
#   bootstrap [args...]  Apply harness templates to a project (pass-through)
#   audit [DIR]          Run compliance audit (default: cwd)
#   status               Show dashboard for all registered projects
#   register [DIR]       Register a project in ~/.claude-harness/projects (default: cwd)
#   watch [--status]     Check watch sources (default: show overdue)
#   evolve               Self-improvement cycle (runs /harness/evolve script helper)
#   update               Pull latest harness + global install + sync all projects
#   version              Show claude-harness version (latest tag + commit)
#   help                 Show this help

set -euo pipefail

# Resolve harness root from this script's location
SCRIPT_PATH="$0"
if [ -L "$0" ]; then
  SCRIPT_PATH="$(readlink "$0")"
  case "$SCRIPT_PATH" in
    /*) ;;
    *) SCRIPT_PATH="$(cd "$(dirname "$0")" && cd "$(dirname "$SCRIPT_PATH")" && pwd)/$(basename "$SCRIPT_PATH")" ;;
  esac
fi
HARNESS_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/.." && pwd)"

if [ ! -f "$HARNESS_ROOT/scripts/install.sh" ]; then
  echo "Cannot locate claude-harness root (expected: $HARNESS_ROOT/scripts/install.sh)"
  exit 1
fi

CMD="${1:-help}"
shift 2>/dev/null || true

case "$CMD" in
  install)
    exec "$HARNESS_ROOT/scripts/install.sh" "$@"
    ;;

  bootstrap)
    exec "$HARNESS_ROOT/scripts/bootstrap.sh" "$@"
    ;;

  audit)
    exec "$HARNESS_ROOT/scripts/audit.sh" "$@"
    ;;

  status)
    echo "Project Status"
    echo ""
    PROJECTS_FILE="$HOME/.claude-harness/projects"
    if [ ! -f "$PROJECTS_FILE" ]; then
      echo "No projects registered. Run: harness register /path/to/project"
      exit 1
    fi
    while IFS= read -r proj; do
      [ -z "$proj" ] && continue
      case "$proj" in \#*) continue ;; esac
      proj="${proj/#\~/$HOME}"
      if [ ! -d "$proj" ]; then
        printf "  x %-30s (not found)\n" "$(basename "$proj")"
        continue
      fi
      branch=$(git -C "$proj" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
      dirty=$(git -C "$proj" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
      last=$(git -C "$proj" log --oneline -1 2>/dev/null || echo "?")

      pass="ok"
      [ ! -f "$proj/.gitleaks.toml" ] && pass="--"
      [ ! -f "$proj/lefthook.yml" ] && pass="--"

      printf "  %s %-25s  branch:%-15s  dirty:%s  %s\n" "$pass" "$(basename "$proj")" "$branch" "$dirty" "$last"
    done < "$PROJECTS_FILE"
    ;;

  register)
    DIR="${1:-$(pwd)}"
    DIR="$(cd "$DIR" && pwd)"
    PROJECTS_FILE="$HOME/.claude-harness/projects"
    mkdir -p "$HOME/.claude-harness"
    if [ -f "$PROJECTS_FILE" ] && grep -qxF "$DIR" "$PROJECTS_FILE"; then
      echo "Already registered: $DIR"
    else
      echo "$DIR" >> "$PROJECTS_FILE"
      echo "Registered: $DIR"
    fi
    ;;

  watch)
    if [ "${1:-}" = "--status" ]; then
      exec "$HARNESS_ROOT/scripts/watch-check.sh" --status
    else
      exec "$HARNESS_ROOT/scripts/watch-check.sh" --check
    fi
    ;;

  evolve)
    # The full cycle is driven by the /harness/evolve slash command in Claude Code.
    # This CLI path only exposes the internal-signal helper for debugging / manual use.
    exec "$HARNESS_ROOT/scripts/evolve.sh" --phase internal
    ;;

  update)
    echo "harness update"
    echo ""
    if [ -n "$(git -C "$HARNESS_ROOT" status --porcelain 2>/dev/null)" ]; then
      echo "Harness working tree dirty — commit or stash first"
      git -C "$HARNESS_ROOT" status --short
      exit 1
    fi

    # 1. Fetch
    echo "-- Fetch --"
    if git -C "$HARNESS_ROOT" fetch --tags origin main 2>&1; then
      echo "  Fetched"
    else
      echo "  Fetch failed (network?) — continuing with local state"
    fi

    # 2. Pull (only if behind)
    LOCAL=$(git -C "$HARNESS_ROOT" rev-parse HEAD 2>/dev/null)
    REMOTE=$(git -C "$HARNESS_ROOT" rev-parse origin/main 2>/dev/null || echo "")
    if [ -z "$REMOTE" ] || [ "$LOCAL" = "$REMOTE" ]; then
      TAG=$(git -C "$HARNESS_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "untagged")
      echo "  Already up to date ($TAG)"
      exit 0
    fi

    BEHIND=$(git -C "$HARNESS_ROOT" rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
    if git -C "$HARNESS_ROOT" pull --ff-only origin main 2>&1; then
      echo "  Pulled (+${BEHIND} commits)"
    else
      echo "  ff-only pull failed — manual merge needed"
      exit 1
    fi

    # 3. Global install
    echo ""
    echo "-- Global assets --"
    "$HARNESS_ROOT/scripts/install.sh"

    # 4. Project sync (all registered projects)
    PROJECTS_FILE="$HOME/.claude-harness/projects"
    if [ -f "$PROJECTS_FILE" ]; then
      echo ""
      echo "-- Project sync --"
      while IFS= read -r proj; do
        [ -z "$proj" ] && continue
        case "$proj" in \#*) continue ;; esac
        proj="${proj/#\~/$HOME}"
        [ ! -d "$proj/.git" ] && continue
        if "$HARNESS_ROOT/scripts/bootstrap.sh" --sync "$proj" >/dev/null 2>&1; then
          echo "  ok $(basename "$proj")"
        else
          echo "  !! $(basename "$proj") — sync failed"
        fi
      done < "$PROJECTS_FILE"
    fi

    echo ""
    TAG=$(git -C "$HARNESS_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "untagged")
    echo "Update complete ($TAG)"
    ;;

  version)
    TAG=$(git -C "$HARNESS_ROOT" describe --tags --abbrev=0 2>/dev/null || echo "untagged")
    COMMIT=$(git -C "$HARNESS_ROOT" log --oneline -1 2>/dev/null || echo "?")
    echo "claude-harness $TAG ($COMMIT)"
    echo "  root: $HARNESS_ROOT"
    ;;

  help|-h|--help)
    sed -n '2,18p' "$0" | sed 's/^# \?//'
    ;;

  *)
    echo "Unknown command: $CMD"
    echo "Run 'harness help' for usage."
    exit 1
    ;;
esac
