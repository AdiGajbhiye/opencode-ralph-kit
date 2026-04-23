#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/run_ralph_loop.sh [max_iterations]

Runs Ralph loop iterations through opencode run.

Environment variables:
  OPENCODE_LOOP_PROMPT_FILE            Prompt file path
  OPENCODE_LOOP_LOG_DIR                Log directory (default: .opencode-run-logs/<timestamp>-ralph)
  OPENCODE_LOOP_CONTINUE               Continue previous session: 1|0 (default: 0)
  OPENCODE_LOOP_RETRY_CONTINUE         Continue mode on marker retry: 1|0 (default: 0)
  OPENCODE_LOOP_MISSING_STATUS_RETRIES Retries when LOOP_STATUS is missing (default: 1)
  OPENCODE_LOOP_VALIDATE_CMD           Optional post-iteration validation command
  OPENCODE_LOOP_REQUIRE_CLEAN_TREE     Enforce clean tree pre/post iteration: 1|0 (default: 1)
  OPENCODE_LOOP_ALLOW_DIRTY_PATHS      Colon-separated paths allowed dirty with clean-tree checks
  OPENCODE_LOOP_ALLOW_DIRTY_ON_COMPLETE Allow dirty tree on COMPLETE: 1|0 (default: 0)
  OPENCODE_LOOP_AUTOSTASH_ON_EXIT      Auto-stash dirty tree on exit: 1|0 (default: 1)
  OPENCODE_LOOP_AUTOSTASH_INCLUDE_UNTRACKED Include untracked files in auto-stash: 1|0 (default: 1)

Exit codes:
  0  completed or max iterations reached
  2  blocked
  3  fail
  4  missing/invalid LOOP_STATUS marker
  5  validation failed
  6  clean-tree check failed
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

MAX_ITERS="${1:-100}"
if ! [[ "$MAX_ITERS" =~ ^[0-9]+$ ]] || [[ "$MAX_ITERS" -lt 1 ]]; then
  echo "Error: max_iterations must be a positive integer." >&2
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

OPENCODE_LOOP_PROMPT_FILE="${OPENCODE_LOOP_PROMPT_FILE:-$KIT_DIR/prompts/ralph_loop.md}"
OPENCODE_LOOP_LOG_DIR="${OPENCODE_LOOP_LOG_DIR:-.opencode-run-logs/$(date +%Y%m%d-%H%M%S)-ralph}"
OPENCODE_LOOP_CONTINUE="${OPENCODE_LOOP_CONTINUE:-0}"
OPENCODE_LOOP_RETRY_CONTINUE="${OPENCODE_LOOP_RETRY_CONTINUE:-0}"
OPENCODE_LOOP_MISSING_STATUS_RETRIES="${OPENCODE_LOOP_MISSING_STATUS_RETRIES:-1}"
OPENCODE_LOOP_VALIDATE_CMD="${OPENCODE_LOOP_VALIDATE_CMD:-}"
OPENCODE_LOOP_REQUIRE_CLEAN_TREE="${OPENCODE_LOOP_REQUIRE_CLEAN_TREE:-1}"
OPENCODE_LOOP_ALLOW_DIRTY_PATHS_RAW="${OPENCODE_LOOP_ALLOW_DIRTY_PATHS:-}"
OPENCODE_LOOP_ALLOW_DIRTY_ON_COMPLETE="${OPENCODE_LOOP_ALLOW_DIRTY_ON_COMPLETE:-0}"
OPENCODE_LOOP_AUTOSTASH_ON_EXIT="${OPENCODE_LOOP_AUTOSTASH_ON_EXIT:-1}"
OPENCODE_LOOP_AUTOSTASH_INCLUDE_UNTRACKED="${OPENCODE_LOOP_AUTOSTASH_INCLUDE_UNTRACKED:-1}"

if [[ ! -f "$OPENCODE_LOOP_PROMPT_FILE" ]]; then
  echo "Error: prompt file not found: $OPENCODE_LOOP_PROMPT_FILE" >&2
  exit 1
fi

mkdir -p "$OPENCODE_LOOP_LOG_DIR"

ALLOW_DIRTY_PATHS=()
if [[ -n "$OPENCODE_LOOP_ALLOW_DIRTY_PATHS_RAW" ]]; then
  IFS=':' read -r -a ALLOW_DIRTY_PATHS <<< "$OPENCODE_LOOP_ALLOW_DIRTY_PATHS_RAW"
fi

is_allowed_dirty_path() {
  local path="$1"
  local allowed

  for allowed in "${ALLOW_DIRTY_PATHS[@]-}"; do
    if [[ -z "$allowed" ]]; then
      continue
    fi
    if [[ "$path" == "$allowed" || "$path" == "$allowed/"* ]]; then
      return 0
    fi
  done
  return 1
}

run_clean_tree_check() {
  local stage="$1"
  local output_file="$2"
  local line status path
  local dirty_lines=()

  if [[ "$OPENCODE_LOOP_REQUIRE_CLEAN_TREE" != "1" ]]; then
    return 0
  fi

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    status="${line:0:2}"
    path="${line:3}"
    if is_allowed_dirty_path "$path"; then
      continue
    fi
    dirty_lines+=("$status $path")
  done < <(git status --porcelain)

  if [[ "${#dirty_lines[@]}" -eq 0 ]]; then
    return 0
  fi

  {
    echo "Clean-tree check failed at stage: $stage"
    echo "Dirty paths:"
    for line in "${dirty_lines[@]}"; do
      echo "$line"
    done
  } | tee "$output_file"

  return 1
}

run_complete_clean_tree_check() {
  local output_file="$1"
  local dirty

  if [[ "$OPENCODE_LOOP_REQUIRE_CLEAN_TREE" != "1" || "$OPENCODE_LOOP_ALLOW_DIRTY_ON_COMPLETE" == "1" ]]; then
    return 0
  fi

  dirty="$(git status --porcelain)"
  if [[ -z "$dirty" ]]; then
    return 0
  fi

  {
    echo "Completion clean-tree check failed"
    echo "Dirty paths:"
    echo "$dirty"
  } | tee "$output_file"

  return 1
}

auto_stash_dirty_tree_if_needed() {
  local exit_code="$1"
  local dirty stash_msg

  if [[ "$OPENCODE_LOOP_AUTOSTASH_ON_EXIT" != "1" ]]; then
    return 0
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  dirty="$(git status --porcelain)"
  if [[ -z "$dirty" ]]; then
    return 0
  fi

  stash_msg="opencode-ralph-autostash exit=${exit_code} $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ "$OPENCODE_LOOP_AUTOSTASH_INCLUDE_UNTRACKED" == "1" ]]; then
    git stash push -u -m "$stash_msg" >/dev/null || true
  else
    git stash push -m "$stash_msg" >/dev/null || true
  fi

  echo "Auto-stashed dirty working tree (exit=$exit_code). Recover with: git stash pop" >&2
}

on_exit() {
  local exit_code=$?
  set +e
  auto_stash_dirty_tree_if_needed "$exit_code"
}
trap on_exit EXIT

load_prompt() {
  cat "$OPENCODE_LOOP_PROMPT_FILE"
}

retry_prompt() {
  cat <<'EOF'
Follow the Ralph loop protocol and run exactly one iteration.

IMPORTANT: print exactly one LOOP_STATUS marker on the last line:
LOOP_STATUS: CONTINUE
or LOOP_STATUS: COMPLETE
or LOOP_STATUS: BLOCKED
or LOOP_STATUS: FAIL
EOF
}

extract_status_line() {
  local file="$1"
  awk '/LOOP_STATUS: (CONTINUE|COMPLETE|BLOCKED|FAIL)/ { line=$0 } END { if (line) print line }' "$file"
}

run_opencode_iteration() {
  local prompt="$1"
  local continue_mode="$2"
  local output_file="$3"

  if [[ "$continue_mode" == "1" ]]; then
    opencode run --continue "$prompt" | tee "$output_file"
  else
    opencode run "$prompt" | tee "$output_file"
  fi
}

run_validation() {
  local iteration="$1"
  local output_file="$2"

  if [[ -z "$OPENCODE_LOOP_VALIDATE_CMD" ]]; then
    return 0
  fi

  echo "Running validation after iteration $iteration: $OPENCODE_LOOP_VALIDATE_CMD"
  if bash -lc "$OPENCODE_LOOP_VALIDATE_CMD" | tee "$output_file"; then
    return 0
  fi

  echo "Validation failed after iteration $iteration" >&2
  return 1
}

PROMPT_CONTENT="$(load_prompt)"

for i in $(seq 1 "$MAX_ITERS"); do
  echo "=== Ralph iteration $i/$MAX_ITERS ==="

  if ! run_clean_tree_check "pre-iteration-$i" "$OPENCODE_LOOP_LOG_DIR/iter-$i-clean-pre.log"; then
    exit 6
  fi

  status_line=""
  iteration_prompt="$PROMPT_CONTENT"
  iteration_prompt+=$'\n\nRuntime budget context:\n'
  iteration_prompt+="- Driver iteration budget: $i/$MAX_ITERS (remaining: $((MAX_ITERS - i)))"

  for attempt in $(seq 1 $((OPENCODE_LOOP_MISSING_STATUS_RETRIES + 1))); do
    attempt_log="$OPENCODE_LOOP_LOG_DIR/iter-$i-attempt-$attempt.log"
    if [[ "$attempt" -eq 1 ]]; then
      run_opencode_iteration "$iteration_prompt" "$OPENCODE_LOOP_CONTINUE" "$attempt_log"
    else
      echo "Retrying iteration $i for missing LOOP_STATUS marker (attempt $attempt)."
      run_opencode_iteration "$(retry_prompt)" "$OPENCODE_LOOP_RETRY_CONTINUE" "$attempt_log"
    fi

    status_line="$(extract_status_line "$attempt_log")"
    if [[ -n "$status_line" ]]; then
      cp "$attempt_log" "$OPENCODE_LOOP_LOG_DIR/iter-$i.log"
      break
    fi
  done

  case "$status_line" in
    *"LOOP_STATUS: CONTINUE"*)
      run_validation "$i" "$OPENCODE_LOOP_LOG_DIR/iter-$i-validate.log" || exit 5
      run_clean_tree_check "post-iteration-$i" "$OPENCODE_LOOP_LOG_DIR/iter-$i-clean-post.log" || exit 6
      echo "Iteration $i complete: CONTINUE"
      ;;
    *"LOOP_STATUS: COMPLETE"*)
      run_validation "$i" "$OPENCODE_LOOP_LOG_DIR/iter-$i-validate.log" || exit 5
      run_complete_clean_tree_check "$OPENCODE_LOOP_LOG_DIR/iter-$i-clean-complete.log" || exit 6
      echo "Loop completed at iteration $i"
      exit 0
      ;;
    *"LOOP_STATUS: BLOCKED"*)
      echo "Loop blocked at iteration $i"
      exit 2
      ;;
    *"LOOP_STATUS: FAIL"*)
      echo "Loop failed at iteration $i"
      exit 3
      ;;
    *)
      echo "No valid LOOP_STATUS marker found for iteration $i" >&2
      exit 4
      ;;
  esac
done

echo "Reached max iterations ($MAX_ITERS) without terminal status"
exit 0
