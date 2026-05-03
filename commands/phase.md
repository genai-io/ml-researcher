---
description: Show the current L3 phase, the requirements to advance to the next phase, and how each requirement is met.
---

Show the user the current L3 lifecycle phase and what's needed to advance.

Steps:

1. Read `research/progress.md` to find the active phase.
2. Look up the phase's gate requirements (see `respec/respec.md` § Stage transitions).
3. For each requirement, verify whether it's met:
   - File exists and non-empty? → check existence + content
   - Specific section filled? → grep for required headings
   - Experiment registered? → check `experiments/ledger.tsv`
4. Report in this format:

```
Current phase: <phase>
Updated:       <date from progress.md>

Required to advance to <next phase>:
  ✓ <requirement>
  ✗ <requirement>  ← BLOCKS

Progress notes:
  <next-step from progress.md>

Blockers:
  <blockers from progress.md, or "None">
```

If no blockers, also tell the user how to advance: `/phase advance`.

If they pass `--advance` or `advance` as the argument, after reporting status, attempt the advancement: spawn the `critic` subagent for an audit, and if PASS, update `research/progress.md` to the new phase.

$ARGUMENTS
