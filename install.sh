#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${OPENCODE_RALPH_TARGET_DIR:-$HOME/.config/opencode-ralph}"
SHELL_RC_DEFAULT="$HOME/.zshrc"
SHELL_RC="${OPENCODE_RALPH_SHELL_RC:-$SHELL_RC_DEFAULT}"
WRITE_RC=0

if [[ "${1:-}" == "--write-shell-rc" ]]; then
  WRITE_RC=1
fi

mkdir -p "$(dirname "$TARGET_DIR")"
ln -sfn "$SCRIPT_DIR" "$TARGET_DIR"

echo "Installed opencode-ralph-kit symlink:"
echo "- $TARGET_DIR -> $SCRIPT_DIR"
echo
echo "Add this to your shell profile if missing:"
echo "export OPENCODE_CONFIG_DIR=\"$TARGET_DIR\""

if [[ "$WRITE_RC" -eq 1 ]]; then
  touch "$SHELL_RC"
  if ! grep -q "OPENCODE_CONFIG_DIR=\"$TARGET_DIR\"" "$SHELL_RC"; then
    printf '\nexport OPENCODE_CONFIG_DIR="%s"\n' "$TARGET_DIR" >> "$SHELL_RC"
    echo "Wrote export to $SHELL_RC"
  else
    echo "Export already present in $SHELL_RC"
  fi
fi

echo
echo "Next steps:"
echo "1) export OPENCODE_CONFIG_DIR=\"$TARGET_DIR\""
echo "2) restart shell"
echo "3) run opencode in any repository and use /ralph-budget"
