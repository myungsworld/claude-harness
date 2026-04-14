#!/usr/bin/env bash
# _scope.sh — Shared scope gate for all harness hooks.
# Sourced, not executed. Defines harness_in_scope() returning 0 (in) or 1 (out).
#
# Scope rules (OR):
#   1. cwd is under any path listed in SCOPE_PARENTS (~/.claude-harness/config)
#   2. cwd matches any line in ~/.claude-harness/projects (absolute paths)
#
# If both are empty/missing → NOT in scope (strict opt-in).
#
# Usage:
#   source "$(dirname "$0")/_scope.sh"
#   harness_in_scope || exit 0

HARNESS_HOME="${HOME}/.claude-harness"

_harness_resolve() {
  local p="$1"
  [ -z "$p" ] && return 1
  p="${p/#\~/$HOME}"
  if [ -d "$p" ]; then
    ( cd "$p" 2>/dev/null && pwd -P ) || printf '%s' "$p"
  else
    printf '%s' "$p"
  fi
}

harness_in_scope() {
  local cwd
  cwd=$(pwd -P 2>/dev/null) || return 1
  [ -z "$cwd" ] && return 1

  # Rule 1: SCOPE_PARENTS from config
  local config="${HARNESS_HOME}/config"
  if [ -f "$config" ]; then
    # shellcheck disable=SC1090
    SCOPE_PARENTS=()
    . "$config" 2>/dev/null || true
    local parent resolved
    for parent in "${SCOPE_PARENTS[@]:-}"; do
      [ -z "$parent" ] && continue
      resolved=$(_harness_resolve "$parent")
      case "$cwd" in
        "$resolved"|"$resolved"/*) return 0 ;;
      esac
    done
  fi

  # Rule 2: explicit registry
  local projects="${HARNESS_HOME}/projects"
  if [ -f "$projects" ]; then
    local line resolved
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      case "$line" in \#*) continue ;; esac
      resolved=$(_harness_resolve "$line")
      case "$cwd" in
        "$resolved"|"$resolved"/*) return 0 ;;
      esac
    done < "$projects"
  fi

  return 1
}

# Resolve harness repo root from this script's location
_harness_find_root() {
  local dir
  dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd -P)"
  if [ -f "$dir/watchlist/watchlist.yaml" ]; then
    printf '%s' "$dir"
  elif [ -L "${HARNESS_HOME}/hooks/_scope.sh" ]; then
    dir="$(readlink "${HARNESS_HOME}/hooks/_scope.sh" | sed 's|/hooks/_scope\.sh$||')"
    printf '%s' "$dir"
  fi
}

HARNESS_ROOT="$(_harness_find_root)"
