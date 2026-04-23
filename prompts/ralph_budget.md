Follow the Ralph loop protocol and run exactly one iteration in Time-Optimized Budget mode.

Mode:
- prioritize ambiguity reduction while keeping operational deltas within guard thresholds
- one measurable quality lever per iteration

Budget policy:
- report iteration budget as `i/N` and remaining each iteration
- force checkpoint every 2 iterations: continue, pivot, or close
- stop early on plateau: gain <1.0pp (ratio) or <2% relative for 2 consecutive iterations

Validation requirements:
- targeted tests first
- then full tests
- then strict eval gate (if present in repository)

Guard thresholds:
- avg_ops delta <= +0.2
- p90_ops delta <= +1.0
- max_ops delta <= +2.0
- invariant delta >= 0.0pp
- ambiguous unmatched ratio delta <= +0.0pp
- move candidate score delta >= +0.0

Required report sections:
- iteration budget status
- selected micro-scope
- micro-plan executed
- expected measurable gain and actual gain
- files changed
- validation commands and key outcomes
- README/status updates (if any)
- commit hash and message
- next recommended micro-scope

At the very end, print exactly one line:
LOOP_STATUS: CONTINUE
or
LOOP_STATUS: COMPLETE
or
LOOP_STATUS: BLOCKED
or
LOOP_STATUS: FAIL
