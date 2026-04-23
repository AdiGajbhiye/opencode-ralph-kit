#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${OPENCODE_RALPH_TARGET_DIR:-$HOME/.config/opencode-ralph}"
SHELL_RC_DEFAULT="$HOME/.zshrc"
SHELL_RC="${OPENCODE_RALPH_SHELL_RC:-$SHELL_RC_DEFAULT}"
OPENCODE_GLOBAL_CONFIG="${OPENCODE_GLOBAL_CONFIG:-$HOME/.config/opencode/opencode.json}"
WRITE_RC=0
WRITE_PERMISSIONS=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --write-shell-rc             Write OPENCODE_CONFIG_DIR export into shell rc file
  --write-opencode-permissions Write allowlist rules into ~/.config/opencode/opencode.json
  -h, --help                   Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --write-shell-rc)
      WRITE_RC=1
      ;;
    --write-opencode-permissions)
      WRITE_PERMISSIONS=1
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

write_opencode_permissions() {
  local config_file="$1"
  local target_dir="$2"

  mkdir -p "$(dirname "$config_file")"

  python3 - "$config_file" "$target_dir" <<'PY'
import json
import os
import sys

config_file = os.path.expanduser(sys.argv[1])
target_dir = os.path.expanduser(sys.argv[2]).rstrip("/")
changed = []

if os.path.exists(config_file) and os.path.getsize(config_file) > 0:
    with open(config_file, "r", encoding="utf-8") as f:
        try:
            config = json.load(f)
        except json.JSONDecodeError as e:
            print(f"Error: {config_file} is not valid JSON: {e}", file=sys.stderr)
            sys.exit(1)
else:
    config = {}

if not isinstance(config, dict):
    print(f"Error: {config_file} must contain a JSON object at top level.", file=sys.stderr)
    sys.exit(1)

permission = config.get("permission")
if permission is None:
    permission = {}
    config["permission"] = permission
    changed.append("created permission object")
elif isinstance(permission, str):
    permission = {"*": permission}
    config["permission"] = permission
    changed.append("converted permission string to object")
elif not isinstance(permission, dict):
    print("Error: permission must be an object or string.", file=sys.stderr)
    sys.exit(1)

def ensure_rule(tool_name, pattern, value):
    tool_rules = permission.get(tool_name)
    if tool_rules is None:
        tool_rules = {}
        permission[tool_name] = tool_rules
        changed.append(f"created permission.{tool_name} object")
    elif isinstance(tool_rules, str):
        tool_rules = {"*": tool_rules}
        permission[tool_name] = tool_rules
        changed.append(f"converted permission.{tool_name} string to object")
    elif not isinstance(tool_rules, dict):
        print(f"Error: permission.{tool_name} must be an object or string.", file=sys.stderr)
        sys.exit(1)

    if tool_rules.get(pattern) != value:
        tool_rules[pattern] = value
        changed.append(f"set permission.{tool_name}[{pattern}]={value}")

ensure_rule("external_directory", f"{target_dir}/**", "allow")
ensure_rule("bash", f"{target_dir}/scripts/run_ralph_*.sh*", "allow")

for tool in ("read", "glob", "grep"):
    ensure_rule(tool, ".opencode-run-logs/**", "allow")
    ensure_rule(tool, "**/.opencode-run-logs/**", "allow")

with open(config_file, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)
    f.write("\n")

if changed:
    print(f"Updated {config_file}:")
    for item in changed:
        print(f"- {item}")
else:
    print(f"No permission changes needed in {config_file}.")
PY
}

mkdir -p "$(dirname "$TARGET_DIR")"
ln -sfn "$SCRIPT_DIR" "$TARGET_DIR"

echo "Installed opencode-ralph-kit symlink:"
echo "- $TARGET_DIR -> $SCRIPT_DIR"
echo
echo "Add this to your shell profile if missing:"
echo "export OPENCODE_CONFIG_DIR=\"$TARGET_DIR\""

if [[ "$WRITE_RC" -eq 1 ]]; then
  touch "$SHELL_RC"
  if ! grep -q "OPENCODE_CONFIG_DIR=\"$TARGET_DIR\"" "$SHELL_RC"; then
    printf '\nexport OPENCODE_CONFIG_DIR="%s"\n' "$TARGET_DIR" >> "$SHELL_RC"
    echo "Wrote export to $SHELL_RC"
  else
    echo "Export already present in $SHELL_RC"
  fi
fi

if [[ "$WRITE_PERMISSIONS" -eq 1 ]]; then
  write_opencode_permissions "$OPENCODE_GLOBAL_CONFIG" "$TARGET_DIR"
fi

echo
echo "Next steps:"
echo "1) export OPENCODE_CONFIG_DIR=\"$TARGET_DIR\""
echo "2) restart shell"
echo "3) run opencode in any repository and use /ralph-budget"
