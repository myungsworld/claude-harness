#!/usr/bin/env bash
# install.sh — Global installation of claude-harness
# Creates symlinks in ~/.claude/ and registers hooks in settings.json.
# Safe to re-run (idempotent).
set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
CLAUDE_DIR="${HOME}/.claude"
HARNESS_HOME="${HOME}/.claude-harness"
SETTINGS="${CLAUDE_DIR}/settings.json"

DRY_RUN="${DRY_RUN:-0}"

_log() { echo "  $1"; }
_dry() { [ "$DRY_RUN" = "1" ] && echo "  [dry-run] $1" && return 0; return 1; }

echo "Installing claude-harness from: ${HARNESS_DIR}"
echo ""

# ── 1. Create directories ────────────────────────────────
for d in "$CLAUDE_DIR" "$HARNESS_HOME" "${CLAUDE_DIR}/hooks" "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents"; do
  if [ ! -d "$d" ]; then
    _dry "mkdir $d" || mkdir -p "$d"
    _log "+ $d"
  fi
done

# ── 2. Symlink commands ──────────────────────────────────
CMDS_SRC="${HARNESS_DIR}/commands/harness"
CMDS_DST="${CLAUDE_DIR}/commands/harness"

if [ -d "$CMDS_SRC" ]; then
  if [ -L "$CMDS_DST" ]; then
    CURRENT=$(readlink "$CMDS_DST" 2>/dev/null || echo "")
    if [ "$CURRENT" = "$CMDS_SRC" ]; then
      _log "commands/harness (already linked)"
    else
      _dry "relink commands/harness" || { rm "$CMDS_DST"; ln -s "$CMDS_SRC" "$CMDS_DST"; }
      _log "~ commands/harness (relinked)"
    fi
  elif [ -e "$CMDS_DST" ]; then
    _log "! commands/harness exists but is not a symlink — skipping"
  else
    _dry "symlink commands/harness" || ln -s "$CMDS_SRC" "$CMDS_DST"
    _log "+ commands/harness"
  fi
fi

# ── 3. Symlink hooks ─────────────────────────────────────
HOOKS_SRC="${HARNESS_DIR}/hooks"
HOOKS_DST="${CLAUDE_DIR}/hooks"

for hook_file in "$HOOKS_SRC"/*.sh; do
  [ ! -f "$hook_file" ] && continue
  bname=$(basename "$hook_file")
  dst="${HOOKS_DST}/${bname}"

  if [ -L "$dst" ]; then
    CURRENT=$(readlink "$dst" 2>/dev/null || echo "")
    if [ "$CURRENT" = "$hook_file" ]; then
      _log "hooks/${bname} (already linked)"
    else
      _dry "relink hooks/${bname}" || { rm "$dst"; ln -s "$hook_file" "$dst"; }
      _log "~ hooks/${bname} (relinked)"
    fi
  elif [ -e "$dst" ]; then
    _log "! hooks/${bname} exists — skipping (not a symlink)"
  else
    _dry "symlink hooks/${bname}" || ln -s "$hook_file" "$dst"
    _log "+ hooks/${bname}"
  fi
done

# ── 4. Symlink agents ────────────────────────────────────
AGENTS_SRC="${HARNESS_DIR}/agents"
AGENTS_DST="${CLAUDE_DIR}/agents"

if [ -d "$AGENTS_SRC" ]; then
  for agent_file in "$AGENTS_SRC"/*.md; do
    [ ! -f "$agent_file" ] && continue
    bname=$(basename "$agent_file")
    dst="${AGENTS_DST}/${bname}"

    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$agent_file" ]; then
      _log "agents/${bname} (already linked)"
    elif [ ! -e "$dst" ]; then
      _dry "symlink agents/${bname}" || ln -s "$agent_file" "$dst"
      _log "+ agents/${bname}"
    fi
  done
fi

# ── 5. Register hooks in settings.json ───────────────────
echo ""
echo "Registering hooks in settings.json..."

if ! command -v jq >/dev/null 2>&1; then
  echo "  ! jq not found — skipping settings.json registration"
  echo "    Install jq and re-run, or manually add hooks to ${SETTINGS}"
else
  [ ! -f "$SETTINGS" ] && echo '{}' > "$SETTINGS"

  # Build hook registrations
  # session-start.sh → SessionStart event
  # session-end.sh   → SessionEnd event
  HOOKS_JSON=$(cat <<'HOOKEOF'
[
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "bash HOOKS_DIR/session-start.sh",
        "event": "SessionStart"
      }
    ]
  },
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "bash HOOKS_DIR/session-end.sh",
        "event": "SessionEnd"
      }
    ]
  }
]
HOOKEOF
)

  # Replace placeholder with actual path
  HOOKS_JSON=$(echo "$HOOKS_JSON" | sed "s|HOOKS_DIR|${HOOKS_SRC}|g")

  if [ "$DRY_RUN" = "1" ]; then
    _dry "Would register hooks in settings.json"
  else
    # Merge hooks into settings.json, avoiding duplicates
    python3 -c "
import json, sys

settings_path = '$SETTINGS'
hooks_dir = '$HOOKS_SRC'

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get('hooks', [])
new_hooks = json.loads('''$HOOKS_JSON''')

# Check for existing harness hooks (avoid duplicates)
existing_cmds = set()
for h in hooks:
    for hk in h.get('hooks', []):
        existing_cmds.add(hk.get('command', ''))

added = 0
for nh in new_hooks:
    cmd = nh['hooks'][0]['command']
    if cmd not in existing_cmds:
        hooks.append(nh)
        added += 1
        print(f'  + {nh[\"hooks\"][0][\"event\"]}: {cmd}')
    else:
        print(f'  = {nh[\"hooks\"][0][\"event\"]}: already registered')

settings['hooks'] = hooks

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print(f'  {added} hook(s) added to settings.json')
" 2>/dev/null || echo "  ! Failed to register hooks in settings.json"
  fi
fi

# ── 6. Install CLI ───────────────────────────────────────
CLI_SRC="${HARNESS_DIR}/scripts/harness-cli.sh"
CLI_BIN_DIR="${HARNESS_HOME}/bin"
CLI_DST="${CLI_BIN_DIR}/harness"

if [ -f "$CLI_SRC" ]; then
  mkdir -p "$CLI_BIN_DIR"
  if [ -L "$CLI_DST" ] && [ "$(readlink "$CLI_DST")" = "$CLI_SRC" ]; then
    _log "bin/harness (already linked)"
  else
    _dry "symlink bin/harness" || { rm -f "$CLI_DST"; ln -s "$CLI_SRC" "$CLI_DST"; }
    _log "+ bin/harness -> harness-cli.sh"
  fi
fi

# ── 7. Create harness home config ────────────────────────
if [ ! -f "${HARNESS_HOME}/config" ]; then
  _dry "create ${HARNESS_HOME}/config" || cat > "${HARNESS_HOME}/config" <<CONFEOF
# claude-harness scope configuration
# Add parent directories whose children should be in harness scope.
# Example: SCOPE_PARENTS=("\$HOME/projects" "\$HOME/work")
SCOPE_PARENTS=()
CONFEOF
  _log "+ ${HARNESS_HOME}/config (edit to set scope)"
fi

# ── 8. Summary ────────────────────────────────────────────
echo ""
echo "Installation complete!"
echo ""
echo "CLI:"
if echo "$PATH" | tr ':' '\n' | grep -qxF "$CLI_BIN_DIR" 2>/dev/null; then
  echo "  harness command is available"
else
  echo "  Add to your shell profile:  export PATH=\"${CLI_BIN_DIR}:\$PATH\""
  echo "  Then run: harness help"
fi
echo ""
echo "Next steps:"
echo "  1. Edit ${HARNESS_HOME}/config to set SCOPE_PARENTS"
echo "  2. Register projects: harness register /path/to/project"
echo "  3. Bootstrap a project: harness bootstrap --type node /path/to/project"
echo "  4. Run self-improvement: /harness/evolve"
echo ""
echo "Watch system:"
echo "  - Sources defined in: ${HARNESS_DIR}/watchlist/watchlist.yaml"
echo "  - Auto-checks on session start for overdue sources"
echo "  - Status: harness watch --status"
