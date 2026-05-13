---
description: Run the appropriate pre-flight checklist for the current state. Auto-detects kind (pre-experiment, pre-phase-advance, pre-finalize).
---

Run a pre-flight checklist.

Argument parsing:
- `$ARGUMENTS` may be `pre-experiment`, `pre-phase-advance`, or `pre-finalize`.
- If empty, infer from current state:
  - On an `mlr/exp/*` branch with uncommitted changes → `pre-experiment`
  - `progress.md` says "ready to advance" or recent activity is filling stage docs → `pre-phase-advance`
  - User just ran `/train run` and current-best changed → `pre-finalize`

Use the `checklist-verify` skill with the matching `kind`.

Output format:

```
Pre-flight checklist (kind=<kind>):
  ✓ <check> — <how it was verified>
  ✗ <check> — <what's missing>

Result: <PASS|FAIL>
```

If FAIL, list each unmet check on its own line with the specific remediation.

If PASS, state what action is now safe to take (e.g., "safe to /train run" or "safe to /research phase advance").

$ARGUMENTS
