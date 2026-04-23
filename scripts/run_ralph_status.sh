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

shopt -s nullglob
log_dirs=(.opencode-run-logs/*)
shopt -u nullglob

if [[ "${#log_dirs[@]}" -eq 0 ]]; then
  echo "No Ralph loop logs found in .opencode-run-logs yet."
  exit 0
fi

IFS=$'\n' log_dirs=( $(ls -1dt "${log_dirs[@]}") )
unset IFS

echo "Recent Ralph loop logs in $(pwd):"
count=0
for dir in "${log_dirs[@]}"; do
  echo "$dir"
  count=$((count + 1))
  if [[ "$count" -ge "$LAST" ]]; then
    break
  fi
done

latest_dir="${log_dirs[0]}"
state_file="$latest_dir/run-state.env"
latest_iter_log=""

shopt -s nullglob
iter_logs=("$latest_dir"/iter-*.log)
shopt -u nullglob
if [[ "${#iter_logs[@]}" -gt 0 ]]; then
  IFS=$'\n' iter_logs=( $(ls -1t "${iter_logs[@]}") )
  unset IFS
  latest_iter_log="${iter_logs[0]}"
fi

if [[ -f "$state_file" ]]; then
  phase=""
  current_iter=""
  max_iters=""
  last_status=""
  updated_at=""
  while IFS='=' read -r key value; do
    case "$key" in
      phase) phase="$value" ;;
      current_iter) current_iter="$value" ;;
      max_iters) max_iters="$value" ;;
      last_status) last_status="$value" ;;
      updated_at) updated_at="$value" ;;
    esac
  done < "$state_file"

  if [[ "$phase" == "running" || "$phase" == "starting" ]]; then
    echo "Active run hint: $latest_dir (phase=$phase iter=${current_iter:-?}/${max_iters:-?} updated=${updated_at:-unknown})"
  else
    echo "Latest run state: $latest_dir (phase=${phase:-unknown} last_status=${last_status:-none} updated=${updated_at:-unknown})"
  fi
else
  echo "Latest run state: unavailable (no run-state.env in $latest_dir)"
fi

if [[ -n "$latest_iter_log" ]]; then
  echo "Recommendation: inspect $latest_iter_log next"
else
  echo "Recommendation: inspect $latest_dir next"
fi
