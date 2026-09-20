#!/usr/bin/env bash
# Install chinese-novelist as a user-level Cursor / Claude Code skill.
# Usage: ./scripts/install-global.sh
set -euo pipefail

SKILL_NAME="chinese-novelist"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$ROOT/SKILL.md" ]]; then
  echo "error: SKILL.md not found at $ROOT" >&2
  exit 1
fi

dest_dir() {
  mkdir -p "$1"
  echo "$1/$SKILL_NAME"
}

install_into() {
  local dest="$1"
  mkdir -p "$(dirname "$dest")"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$ROOT/SKILL.md" "$ROOT/references" "$ROOT/scripts" "$dest/"
  if [[ ! -f "$dest/SKILL.md" ]]; then
    echo "error: failed to install $dest" >&2
    exit 1
  fi
  echo "installed: $dest"
}

CURSOR_DEST="$(dest_dir "${HOME}/.cursor/skills")"
install_into "$CURSOR_DEST"

CLAUDE_HOME="${HOME}/.claude/skills"
mkdir -p "$CLAUDE_HOME"
install_into "$(dest_dir "$CLAUDE_HOME")"

echo
echo "chinese-novelist is installed globally."
echo "Next:"
echo "  1. Open any project in Cursor (a new empty project is fine)."
echo "  2. Start a new Agent chat so skills are rediscovered."
echo "  3. Type /chinese-novelist or 用 chinese-novelist 帮我写一部小说"
echo
echo "Novels will be written to that project's ./chinese-novelist/ folder."
