# opencode-ralph-kit

Portable OpenCode setup for running Ralph loops with strong guardrails:

- small-patch looping with strict `LOOP_STATUS` contract
- budget mode with validation gates
- clean-worktree checks before/after iterations
- auto-stash on exit for cleaner recovery
- optional sanity pass for architecture/test health drift

## What this gives you

- Global slash commands:
  - `/ralph-loop`
  - `/ralph-budget`
  - `/ralph-sanity`
  - `/ralph-status`
  - `/ralph-init`
- Global prompts in `prompts/`
- Loop drivers in `scripts/`

## Install

1) Clone this repo on any machine:

```bash
git clone https://github.com/<your-user>/opencode-ralph-kit.git ~/projects-running/opencode-ralph-kit
```

2) Run installer:

```bash
cd ~/projects-running/opencode-ralph-kit
./install.sh
```

3) Add this once to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export OPENCODE_CONFIG_DIR="$HOME/.config/opencode-ralph"
```

4) Reload shell and start OpenCode:

```bash
source ~/.zshrc
opencode .
```

## Usage

- One iteration:

```text
/ralph-loop
```

- Budgeted run (goal required):

```text
/ralph-budget Build MVP from docs/design.md
```

- Budgeted run with explicit iterations + goal:

```text
/ralph-budget 20 Build MVP from docs/design.md
```

- Manual health check:

```text
/ralph-sanity
```

- Recent loop logs:

```text
/ralph-status
```

## Notes

- Main logs are written inside the target repository under `.opencode-run-logs/`.
- `/ralph-budget` is configured as a subtask command to reduce main-thread context pollution.
- `/ralph-budget` fails fast if no goal is provided.
- `/ralph-status` is non-subtask so it can be run while `/ralph-budget` is in progress.
- `/ralph-status` shows an active run hint using `.opencode-run-logs/<run>/run-state.env`.
- Use `/ralph-init` in a new project to scaffold local Ralph loop docs.
