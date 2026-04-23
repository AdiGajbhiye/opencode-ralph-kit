---
description: Show recent Ralph loop logs
agent: build
subtask: false
---
Show recent Ralph loop log directories for the current repository.

Execution requirements:
- Resolve script path in this order:
  1) `$OPENCODE_CONFIG_DIR/scripts/run_ralph_status.sh`
  2) `~/.config/opencode-ralph/scripts/run_ralph_status.sh`
- Execute with `$1` as number of rows (default 20).

Return only:
- the listed log paths
- active run hint (when available)
- one-line recommendation on which run to inspect next
