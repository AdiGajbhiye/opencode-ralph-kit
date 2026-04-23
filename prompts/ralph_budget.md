Follow the Ralph loop protocol and run exactly one iteration in budget mode.

Mode:
- optimize for meaningful forward progress on the user goal
- each iteration must be one logical, self-contained, substantial work package
- avoid tiny patch fragmentation unless a hard blocker forces it

Iteration policy:
- report iteration budget as `i/N` and remaining each iteration
- checkpoint every 2 iterations with a clear decision: continue, pivot, or close
- stop early only when the goal is complete, clearly blocked, or risks outweigh progress

Validation requirements:
- run validations that fit this repository and the changes made
- prefer targeted checks first, then broader checks when available
- if full validation cannot run, explain exactly what was run and what risk remains

Required report sections:
- iteration budget status
- selected work package
- implementation plan executed
- expected outcome and actual outcome
- files changed
- validation commands and key outcomes
- project status updates (README/roadmap/changelog, if any)
- commit hash and message
- next recommended work package

At the very end, print exactly one line:
LOOP_STATUS: CONTINUE
or
LOOP_STATUS: COMPLETE
or
LOOP_STATUS: BLOCKED
or
LOOP_STATUS: FAIL
