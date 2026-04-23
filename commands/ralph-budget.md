---
description: Run budgeted Ralph loop
agent: build
subtask: true
---
Run a budgeted Ralph loop in the current repository.

Arguments:
- Required: goal text in `$ARGUMENTS`
- Optional: begin with an integer max iteration count
  - Example: `/ralph-budget 20 Build MVP from docs/design.md`
  - Example: `/ralph-budget Build MVP from docs/design.md`

Fail-fast policy:
- If goal text is missing, stop immediately and return:
  - `ERROR: Goal is required. Usage: /ralph-budget [max_iterations] <goal>`
- Do not run any scripts when goal is missing.

Execution requirements:
- Resolve script path in this order:
  1) `$OPENCODE_CONFIG_DIR/scripts/run_ralph_loop_budget.sh`
  2) `~/.config/opencode-ralph/scripts/run_ralph_loop_budget.sh`
- Pass all user arguments through to the script exactly.
- Sanity cadence: every 3 iterations run sanity check and include findings in operator summary.
- Keep output concise; do not paste full command logs.

Return only:
- exit code
- final LOOP_STATUS
- completed iterations count
- log directory path
- checkpoint decision (continue/pivot/close)
