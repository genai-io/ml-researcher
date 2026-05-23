# Phase gate requirements

To advance FROM the listed phase, these must be present.

## From "Data Understanding" → "Research Goal"

- `research/data_understanding.md` exists, non-empty, with sections:
  - `## Dataset Inventory`
  - `## Sample Unit`
  - `## Label Definition`
  - `## Cohort and Split`
  - `## QC`
- `data/splits/` has at least one of `train/`, `val/`, `test/` populated (or a manifest CSV declaring them).

## From "Research Goal" → "Model Selection"

- `research/research_goal.md` exists, non-empty, with:
  - Primary Research Question
  - Endpoints (≥ 1)
  - Metrics (primary metric named)
  - Success Criteria
  - Baseline declared (textual — "which model is fair to compare against and why")

The baseline experiment itself is registered and run *during* Model Selection, not before.

## From "Model Selection" → "Fine Tuning"

- `research/model_selection.md` exists, non-empty, with a shortlist of ≥ 1 model and ≥ 1 rejection.
- Baseline experiment kept: `bash <CFG>/hooks/checks.sh baseline-kept` returns 0 — i.e., a row in `experiments/ledger.tsv` whose description contains "baseline" with `status=keep`.

The same rule applies to subsequent runs via the `preflight` hook, so improvement claims always have a comparator. Non-baseline shortlisted candidates are registered at the start of Fine Tuning via `/exp new` — they don't need kept runs at this gate.

## From "Fine Tuning" → "Analysis Report"

- `research/fine_tuning.md` exists, non-empty, with parameter ranges per shortlisted model.
- Each shortlisted model has at least 5 keep+discard rows in the ledger.

## From "Analysis Report" → done (or Goal Revision)

- `research/analysis_report.md` exists, non-empty, with `## Conclusion` and `## Limits` sections.
- `results/` is non-empty (figures, tables, or report artifact).

## Source of truth

The shell rules in `<CFG>/hooks/checks.sh` are the *mechanical* source of truth. This document explains *why* the rule exists. When a rule changes, edit `checks.sh` AND this document.
