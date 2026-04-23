#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROMPT_FILE="${OPENCODE_RALPH_SANITY_PROMPT_FILE:-$KIT_DIR/prompts/ralph_sanity.md}"
LOG_DIR="${OPENCODE_RALPH_SANITY_LOG_DIR:-.opencode-run-logs}"
LOG_FILE="$LOG_DIR/sanity-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$LOG_DIR"

if [[ ! -f "$PROMPT_FILE" ]]; then
  echo "Error: sanity prompt file not found: $PROMPT_FILE" >&2
  exit 1
fi

echo "Running Ralph sanity check"
echo "- prompt file: $PROMPT_FILE"
echo "- log file: $LOG_FILE"

opencode run "$(cat "$PROMPT_FILE")" | tee "$LOG_FILE"

echo "Sanity check log written to: $LOG_FILE"
