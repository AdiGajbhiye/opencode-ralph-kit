Run one Ralph Loop iteration in small-patch mode.

Objectives:
- Optimize for speed of development and simplicity.
- Produce exactly one small, self-contained, meaningful patch.
- Prefer idiomatic defaults unless confidence is below 80%.
- If blocked by a major decision or low confidence, ask one targeted question.

Iteration protocol:
1) Read current status: README roadmap/status + git status/diff/recent commits.
2) Choose one micro-scope: top incomplete roadmap item + 3-6 bullet micro-plan with validation.
3) Implement minimal, explicit, idiomatic changes.
4) Validate: targeted tests first, then full test command for repository stack.
5) Update README/status only if milestone state meaningfully changed.
6) Commit exactly one concise commit focused on why.

Output format:
- selected micro-scope
- micro-plan executed
- files changed
- validation commands + key results
- README/status updates (if any)
- commit hash + message
- next recommended micro-scope

Guardrails:
- Do not introduce broad multi-feature changes.
- Avoid architecture changes unless required for correctness.
- Preserve project invariants and roundtrip correctness.

At the very end, print exactly one line:
LOOP_STATUS: CONTINUE
or
LOOP_STATUS: COMPLETE
or
LOOP_STATUS: BLOCKED
or
LOOP_STATUS: FAIL
