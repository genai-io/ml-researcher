---
name: phase-advance
description: Check whether the current research phase's gate requirements are met, and (if --confirm) advance to the next phase. Updates research/progress.md. Per-phase gate requirements in references/gate_requirements.md.
allowed-tools: Read Edit Glob Grep
---

# Phase order

```
Data Understanding → Research Goal → Model Selection → Fine Tuning → Analysis Report → (Goal Revision loop)
```

# Gate requirements

For the full per-transition requirement table see `references/gate_requirements.md`. The mechanical rules also live in `<CFG>/hooks/checks.sh`, which is authoritative — this skill explains *why* and *what to do*.

# Steps

1. **Read current phase** from `research/progress.md`.

2. **Look up gate requirements** for `current → next` (see references).

3. **Check each requirement** systematically:
   - File-existence checks: `ls` / `Glob`
   - Section presence: `Grep` for required headings (e.g., `^## Dataset Inventory`)
   - Ledger / experiment state: shell out to `<CFG>/hooks/checks.sh` for the canonical rules

4. **Build report**:

   ```
   Current phase: <current>
   Target phase:  <next>

   Required to advance:
     ✓ <requirement> (verified at <evidence>)
     ✗ <requirement> ← BLOCKS

   Blockers from progress.md: <list or none>
   ```

5. **If `--confirm` and all checks pass**:
   - Spawn `critic` subagent for a final audit (scope=`current-best`).
   - If critic returns PASS or WARN: update `research/progress.md` to set phase to `<next>` and append a phase-transition entry.
   - If critic returns BLOCK: surface the issues; do NOT advance.

6. **If `--confirm` and any check fails**: do NOT advance. Surface the failures.

# Goal Revision loop

If the user explicitly requests Goal Revision (after Analysis Report), copy `research/research_goal.md` to `research/goal_revision_<date>.md` first to preserve history, then allow editing the live `research_goal.md`. Note in `progress.md` that revision is in progress.

# Related

The `critic` agent runs at the gate before advancement. The `checklist-verify` skill runs `kind=pre-phase-advance` against the same rules.
