---
description: Run Ralph sanity health check
agent: build
subtask: true
---
Run the Ralph sanity check for the current repository.

Execution requirements:
- Resolve script path in this order:
  1) `$OPENCODE_CONFIG_DIR/scripts/run_ralph_sanity.sh`
  2) `~/.config/opencode-ralph/scripts/run_ralph_sanity.sh`
- Execute once and summarize only key outcomes.

Return only:
- health status (green/yellow/red)
- top 3 risks
- maintenance recommendation
- log file path
