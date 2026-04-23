---
description: Run budgeted Ralph loop
agent: build
subtask: true
---
Run a budgeted Ralph loop in the current repository.

Arguments:
- `$1` = max iterations (default `12`)

Execution requirements:
- Resolve script path in this order:
  1) `$OPENCODE_CONFIG_DIR/scripts/run_ralph_loop_budget.sh`
  2) `~/.config/opencode-ralph/scripts/run_ralph_loop_budget.sh`
- Execute with iterations from `$1` (or default 12).
- Sanity cadence: every 3 iterations run sanity check and include findings in operator summary.
- Keep output concise; do not paste full command logs.

Return only:
- exit code
- final LOOP_STATUS
- completed iterations count
- log directory path
- checkpoint decision (continue/pivot/close)
