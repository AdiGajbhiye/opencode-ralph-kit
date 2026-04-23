---
description: Scaffold repo-local Ralph loop files
agent: build
subtask: true
---
Initialize Ralph loop setup in the current repository.

Tasks:
1) Ensure `AGENTS.md` exists with small-patch iteration rules.
2) Ensure `loops/opencode_ralph_loop.md` exists and is referenced from project config if present.
3) Add a minimal README section with loop usage if missing.
4) Do not overwrite existing files blindly; preserve local conventions.

Return only:
- files created or updated
- any skipped files with reason
- next command to run (`/ralph-budget` recommended)
