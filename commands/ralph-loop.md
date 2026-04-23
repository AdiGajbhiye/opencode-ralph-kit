---
description: Run one Ralph loop iteration
agent: build
subtask: true
---
Run one Ralph loop iteration for the current repository.

Execution requirements:
- Resolve script path in this order:
  1) `$OPENCODE_CONFIG_DIR/scripts/run_ralph_loop.sh`
  2) `~/.config/opencode-ralph/scripts/run_ralph_loop.sh`
- Run exactly one iteration by executing the script with argument `1`.
- Do not dump full logs into chat.

Return only:
- exit code
- LOOP_STATUS marker
- log directory path
- one-line next action
