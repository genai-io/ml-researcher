---
description: Show the current L3 phase and what's needed to advance. Subcommand `advance` attempts the transition.
---

Show current state, or advance the phase.

Argument parsing: `$ARGUMENTS` may be empty (show), or `advance` (attempt transition).

# Show (default)

1. Read `research/progress.md` to find the active phase.
2. Look up gate requirements (see `respec/respec.md` § Stage transitions).
3. For each requirement, verify whether it's met (file exists & non-empty, required sections present, experiment registered, etc.).
4. Report:

```
Current phase: <phase>
Updated:       <date from progress.md>

Required to advance to <next>:
  ✓ <requirement>
  ✗ <requirement>  ← BLOCKS

Progress notes:
  <next-step from progress.md>

Blockers:
  <blockers from progress.md, or "None">
```

If no blockers, also tell the user: `/phase advance`.

# advance

After running the show steps, attempt the transition:

1. Spawn the `critic` subagent for an audit.
2. If critic returns PASS or WARN: update `research/progress.md` to set phase to `<next>` and append a phase-transition entry.
3. If critic returns BLOCK: surface the issues; do NOT advance.

$ARGUMENTS
