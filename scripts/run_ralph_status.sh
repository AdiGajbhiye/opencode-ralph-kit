#!/usr/bin/env bash
set -euo pipefail

LAST="${1:-20}"
if ! [[ "$LAST" =~ ^[0-9]+$ ]] || [[ "$LAST" -lt 1 ]]; then
  echo "Error: last must be a positive integer." >&2
  exit 1
fi

if [[ ! -d ".opencode-run-logs" ]]; then
  echo "No .opencode-run-logs directory found in current repository."
  exit 0
fi

echo "Recent Ralph loop logs in $(pwd):"
ls -1dt .opencode-run-logs/* 2>/dev/null | head -n "$LAST"
