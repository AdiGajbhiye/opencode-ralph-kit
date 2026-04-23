#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/run_ralph_loop_budget.sh <goal>
  scripts/run_ralph_loop_budget.sh <max_iterations> <goal>

Examples:
  scripts/run_ralph_loop_budget.sh "Build MVP from docs/design.md"
  scripts/run_ralph_loop_budget.sh 20 "Implement billing reconciliation"

Fail-fast:
  Goal is mandatory. The script exits immediately when goal is missing.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

MAX_ITERS=50
GOAL=""

if [[ $# -eq 0 ]]; then
  echo "Error: goal is required." >&2
  usage >&2
  exit 1
fi

if [[ "$1" =~ ^[0-9]+$ ]]; then
  MAX_ITERS="$1"
  shift
fi

if ! [[ "$MAX_ITERS" =~ ^[0-9]+$ ]] || [[ "$MAX_ITERS" -lt 1 ]]; then
  echo "Error: max_iterations must be a positive integer." >&2
  exit 1
fi

GOAL="$*"
if [[ -z "${GOAL// }" ]]; then
  echo "Error: goal is required." >&2
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_ID="$(date +%Y%m%d-%H%M%S)-budget"

export DIFF_EVAL_GATE="${DIFF_EVAL_GATE:-1}"
export EVAL_ENFORCE_INVARIANT_EXPECTATIONS="${EVAL_ENFORCE_INVARIANT_EXPECTATIONS:-1}"
export EVAL_MAX_AVG_OPS_DELTA="${EVAL_MAX_AVG_OPS_DELTA:-0.2}"
export EVAL_MAX_P90_OPS_DELTA="${EVAL_MAX_P90_OPS_DELTA:-1.0}"
export EVAL_MAX_MAX_OPS_DELTA="${EVAL_MAX_MAX_OPS_DELTA:-2.0}"
export EVAL_MIN_INVARIANT_DELTA="${EVAL_MIN_INVARIANT_DELTA:-0.0}"
export EVAL_MAX_AMBIGUOUS_UNMATCHED_RATIO_DELTA="${EVAL_MAX_AMBIGUOUS_UNMATCHED_RATIO_DELTA:-0.0}"
export EVAL_MIN_MOVE_CANDIDATE_SCORE_DELTA="${EVAL_MIN_MOVE_CANDIDATE_SCORE_DELTA:-0.0}"

export OPENCODE_LOOP_CONTINUE="${OPENCODE_LOOP_CONTINUE:-0}"
export OPENCODE_LOOP_RETRY_CONTINUE="${OPENCODE_LOOP_RETRY_CONTINUE:-0}"
export OPENCODE_LOOP_MISSING_STATUS_RETRIES="${OPENCODE_LOOP_MISSING_STATUS_RETRIES:-1}"
export OPENCODE_LOOP_VALIDATE_CMD="${OPENCODE_LOOP_VALIDATE_CMD:-cargo test && make eval-gate-strict}"
export OPENCODE_LOOP_REQUIRE_CLEAN_TREE="${OPENCODE_LOOP_REQUIRE_CLEAN_TREE:-1}"
export OPENCODE_LOOP_ALLOW_DIRTY_ON_COMPLETE="${OPENCODE_LOOP_ALLOW_DIRTY_ON_COMPLETE:-0}"
export OPENCODE_LOOP_AUTOSTASH_ON_EXIT="${OPENCODE_LOOP_AUTOSTASH_ON_EXIT:-1}"
export OPENCODE_LOOP_AUTOSTASH_INCLUDE_UNTRACKED="${OPENCODE_LOOP_AUTOSTASH_INCLUDE_UNTRACKED:-1}"
export OPENCODE_LOOP_PROMPT_FILE="${OPENCODE_LOOP_PROMPT_FILE:-$KIT_DIR/prompts/ralph_budget.md}"
export OPENCODE_LOOP_LOG_DIR="${OPENCODE_LOOP_LOG_DIR:-.opencode-run-logs/$RUN_ID}"
export OPENCODE_LOOP_GOAL="${OPENCODE_LOOP_GOAL:-$GOAL}"

echo "Starting budget Ralph loop"
echo "- max iterations: $MAX_ITERS"
echo "- prompt file: $OPENCODE_LOOP_PROMPT_FILE"
echo "- log dir: $OPENCODE_LOOP_LOG_DIR"
echo "- validate command: $OPENCODE_LOOP_VALIDATE_CMD"
echo "- goal: $OPENCODE_LOOP_GOAL"

exec "$SCRIPT_DIR/run_ralph_loop.sh" "$MAX_ITERS"
