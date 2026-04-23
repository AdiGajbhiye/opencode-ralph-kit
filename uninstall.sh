#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${OPENCODE_RALPH_TARGET_DIR:-$HOME/.config/opencode-ralph}"
SHELL_RC_DEFAULT="$HOME/.zshrc"
SHELL_RC="${OPENCODE_RALPH_SHELL_RC:-$SHELL_RC_DEFAULT}"
OPENCODE_GLOBAL_CONFIG="${OPENCODE_GLOBAL_CONFIG:-$HOME/.config/opencode/opencode.json}"
REMOVE_RC=0
REMOVE_PERMISSIONS=0

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  --remove-shell-rc             Remove OPENCODE_CONFIG_DIR export from shell rc file
  --remove-opencode-permissions Remove Ralph allowlist rules from ~/.config/opencode/opencode.json
  -h, --help                    Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove-shell-rc)
      REMOVE_RC=1
      ;;
    --remove-opencode-permissions)
      REMOVE_PERMISSIONS=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

remove_shell_rc_export() {
  local shell_rc="$1"
  local target_dir="$2"
  local escaped line

  if [[ ! -f "$shell_rc" ]]; then
    echo "Shell rc not found, skipping: $shell_rc"
    return 0
  fi

  line="export OPENCODE_CONFIG_DIR=\"$target_dir\""
  escaped="$(printf '%s\n' "$line" | sed 's/[.[\*^$(){}+?|/]/\\&/g')"

  if grep -q "^$escaped$" "$shell_rc"; then
    python3 - "$shell_rc" "$line" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
line = sys.argv[2]
content = path.read_text(encoding="utf-8")
lines = content.splitlines()
new_lines = [item for item in lines if item.strip() != line]

if new_lines:
    path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
else:
    path.write_text("", encoding="utf-8")
PY
    echo "Removed OPENCODE_CONFIG_DIR export from $shell_rc"
  else
    echo "No matching OPENCODE_CONFIG_DIR export found in $shell_rc"
  fi
}

remove_opencode_permissions() {
  local config_file="$1"
  local target_dir="$2"

  if [[ ! -f "$config_file" ]]; then
    echo "Global OpenCode config not found, skipping: $config_file"
    return 0
  fi

  python3 - "$config_file" "$target_dir" <<'PY'
import json
import os
import sys

config_file = os.path.expanduser(sys.argv[1])
target_dir = os.path.expanduser(sys.argv[2]).rstrip("/")

with open(config_file, "r", encoding="utf-8") as f:
    try:
        config = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: {config_file} is not valid JSON: {e}", file=sys.stderr)
        sys.exit(1)

if not isinstance(config, dict):
    print(f"Error: {config_file} must contain a JSON object at top level.", file=sys.stderr)
    sys.exit(1)

permission = config.get("permission")
if permission is None:
    print(f"No permission section found in {config_file}.")
    sys.exit(0)

if isinstance(permission, str):
    print("permission is a string; no Ralph-specific rules to remove.")
    sys.exit(0)

if not isinstance(permission, dict):
    print("Error: permission must be an object or string.", file=sys.stderr)
    sys.exit(1)

changed = []

def delete_rule(tool_name, pattern):
    tool_rules = permission.get(tool_name)
    if not isinstance(tool_rules, dict):
        return
    if pattern in tool_rules:
        del tool_rules[pattern]
        changed.append(f"removed permission.{tool_name}[{pattern}]")
    if len(tool_rules) == 0:
        del permission[tool_name]
        changed.append(f"removed empty permission.{tool_name}")

delete_rule("external_directory", f"{target_dir}/**")
delete_rule("bash", f"{target_dir}/scripts/run_ralph_*.sh*")
for tool in ("read", "glob", "grep"):
    delete_rule(tool, ".opencode-run-logs/**")
    delete_rule(tool, "**/.opencode-run-logs/**")

if len(permission) == 0:
    del config["permission"]
    changed.append("removed empty permission object")

with open(config_file, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

if changed:
    print(f"Updated {config_file}:")
    for item in changed:
        print(f"- {item}")
else:
    print(f"No Ralph permission rules found in {config_file}.")
PY
}

if [[ -L "$TARGET_DIR" ]]; then
  rm -f "$TARGET_DIR"
  echo "Removed symlink: $TARGET_DIR"
elif [[ -e "$TARGET_DIR" ]]; then
  echo "Not removing $TARGET_DIR because it is not a symlink."
else
  echo "No symlink found at $TARGET_DIR"
fi

if [[ "$REMOVE_RC" -eq 1 ]]; then
  remove_shell_rc_export "$SHELL_RC" "$TARGET_DIR"
fi

if [[ "$REMOVE_PERMISSIONS" -eq 1 ]]; then
  remove_opencode_permissions "$OPENCODE_GLOBAL_CONFIG" "$TARGET_DIR"
fi

echo
echo "Uninstall complete."
