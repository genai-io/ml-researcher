---
name: phase-advance
description: Check whether the current L3 phase's gate requirements are met, and (if --confirm) advance to the next phase. Updates research/progress.md.
allowed-tools: Read, Edit, Glob, Grep
---

# Phase order

```
Data Understanding → Research Goal → Model Selection → Fine Tuning → Analysis Report → (Goal Revision loop)
```

# Gate requirements per phase

To advance FROM the listed phase, these must be present:

## From "Data Understanding" → "Research Goal"
- `research/data_understanding.md` exists, non-empty, with sections: Dataset Inventory, Sample Unit, Label Definition, Cohort and Split, QC.
- `data/splits/` has at least one of `train/`, `val/`, `test/` populated (or a manifest CSV declaring them).

## From "Research Goal" → "Model Selection"
- `research/research_goal.md` exists, non-empty, with: Primary Research Question, Endpoints (≥1), Metrics (primary metric named), Success Criteria, Baseline declared (textual — "which model is fair to compare against and why"; the baseline experiment is registered and run *during* Model Selection, not before).

## From "Model Selection" → "Fine Tuning"
- `research/model_selection.md` exists, non-empty, with a shortlist of ≥1 model and ≥1 rejection.
- The baseline experiment is registered and kept: `bash <CFG>/hooks/checks.sh baseline-kept` returns 0 — i.e., a row in `experiments/ledger.tsv` whose description contains "baseline" with `status=keep`. The same rule is applied by the `preflight` hook before any subsequent experiment run, so improvement claims always have a comparator. Non-baseline shortlisted candidates are *registered* at the start of Fine Tuning via `/exp new` — they don't need kept runs at this gate.

## From "Fine Tuning" → "Analysis Report"
- `research/fine_tuning.md` exists, non-empty, with parameter ranges per shortlisted model.
- Each shortlisted model has at least 5 keep+discard rows in the ledger.

## From "Analysis Report" → done (or Goal Revision)
- `research/analysis_report.md` exists, non-empty, with Conclusion and Limits sections.
- `results/` is non-empty (figures, tables, or report artifact).

# Steps

1. **Read current phase** from `research/progress.md`.

2. **Look up gate requirements** from the table above for `current → next`.

3. **Check each requirement** systematically. For file-existence checks, use `ls`/`Glob`. For section presence, `Grep` for required headings (e.g., `^## Dataset Inventory`).

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

If the user explicitly requests Goal Revision (after Analysis Report), copy the current `research_goal.md` to `research/goal_revision_<date>.md` first to preserve history, then allow editing the live `research_goal.md`. Note in `progress.md` that revision is in progress.
