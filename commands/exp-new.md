---
description: Register a new experiment under experiments/EXPxxx_<name>/ with motivation, config, and a fresh git branch.
---

Register a new experiment.

Arguments: `$ARGUMENTS` should be the experiment name (a short slug). If the user provided motivation as a longer phrase, use it; otherwise ask.

Steps:

1. Compute the next experiment ID by looking at `experiments/`. Format `EXP<3-digit-zero-padded>_<name>`. Examples: `EXP001_baseline`, `EXP002_radiomics-l2`.

2. Determine motivation:
   - If `$ARGUMENTS` includes a description after the slug, use it.
   - Otherwise ask the user one short question: "Motivation for this experiment?"

3. Determine parent experiment:
   - If there's a current best experiment in `research/progress.md`, use it as parent.
   - Otherwise, this is the baseline (parent = none).

4. Create the directory and starter files via the `experiment-register` skill:
   - `experiments/EXPxxx_<name>/README.md` with motivation, parent, expected metric.
   - `experiments/EXPxxx_<name>/train.py` (copy from parent if exists, else use template).
   - `experiments/EXPxxx_<name>/config.yaml` (copy from parent if exists).
   - Empty `experiments/EXPxxx_<name>/figures/` and `artifacts/`.

5. Create a git branch: `mlr/exp/EXPxxx_<name>`. Switch to it.

6. Append a row to `experiments/ledger.tsv` with `status=registered` and the motivation.

7. Append an entry to `research/iteration_trace.md` (use `iteration-log` skill).

8. Tell the user the experiment is registered and what file to edit first (usually `train.py`).
