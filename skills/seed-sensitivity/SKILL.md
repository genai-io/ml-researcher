---
name: seed-sensitivity
description: Run the same training config under N different random seeds and report the metric distribution rather than a point estimate. Wraps scripts/seed_sensitivity.py. Use when a single-seed metric appears in research/analysis_report.md, when comparing two methods whose CIs overlap, or when the user asks "is this real or did we get lucky with seed=42?". Interpretation in references/interpretation.md.
allowed-tools: Bash Read Write
---

# When to use

- Before promoting any single-seed result to `analysis_report.md`. A point estimate from one seed is not a defensible claim when sample sizes are small.
- When comparing two candidates whose bootstrap CIs overlap — seed sensitivity tells you whether the gap is robust or just one favorable draw.
- When the user says "is this real or did we get lucky?" — that's literally the question this skill answers.

Do NOT use to inflate confidence in an over-fit model. If the issue is overfitting on too little data, seed-sensitivity will produce a wide distribution AND a high mean — both should be reported, neither one alone.

# What it produces

Under the experiment dir or a new `experiments/EXPxxx/seed_runs/` subdir:

- `seed_runs/run_seed<N>.json` per seed — full metrics from that run
- `seed_summary.json` — aggregated:

  ```json
  {
    "n_seeds": 5,
    "seeds": [42, 43, 44, 45, 46],
    "primary_metric": "val_auc",
    "values": [0.711, 0.694, 0.722, 0.683, 0.707],
    "mean": 0.703,
    "std": 0.015,
    "min": 0.683,
    "max": 0.722,
    "ci_normal_95": [0.673, 0.734],
    "ci_quantile_95": [0.683, 0.722]
  }
  ```

- `seed_distribution.png` — strip plot of the N values with mean line

# Steps

1. **Identify the base experiment** — current dir or `--exp-id`. The base must have been registered and have a working `train.py`.

2. **Choose N seeds**. Default `--n-seeds 5`. Use 3 if compute-bound, 10 if you really need the distribution detail.

3. **Invoke**:

   ```bash
   python scripts/seed_sensitivity.py \
     --exp-id EXP003_combined-linear-svm \
     --n-seeds 5 \
     --seeds 42,43,44,45,46 \
     --metric val_auc
   ```

4. **The script** runs `train.py --seed <s>` for each seed, redirecting each output to its own `run.log`, then aggregates the metric values via `metric-grep` and writes `seed_summary.json`.

5. **Report to caller** in one paragraph:

   > val_auc across 5 seeds: mean 0.70 (95% normal CI [0.67, 0.73]; quantile range [0.68, 0.72]). The seed variance is small (std=0.015), so the point estimate is robust.

6. **Update the trial-log entry** for the base experiment with `seed_sensitivity: n=5, mean=0.70, std=0.015`.

# Hard rules

- **Same config, only seed varies.** The script enforces this — it does NOT vary hyperparameters across the N runs. If you want hyperparameter sweep, use a different skill (not part of v0.1).
- **Report both mean AND distribution.** "mean=0.70" alone hides whether the std is 0.005 or 0.05 — those are very different stories.
- **Use ≥ 3 seeds.** N=1 is just one run. N=2 is the wrong number (range is dominated by which 2 you picked). Default is 5.
- **Cite both CI types** when relevant. The normal CI assumes Gaussianity; the quantile CI doesn't. Disagreement between the two is informative.
- **Seed-sensitivity is per-trial, not per-experiment.** If you change the model, re-run seed sensitivity for the new model. Old N=5 doesn't transfer.

# Interpreting the result

See `references/interpretation.md` for the full guide. Short version:

| Std / mean | Reading |
|---|---|
| < 0.02 (relative) | very robust; cite the mean as the headline |
| 0.02 – 0.05 | typical for small-N ML; report mean ± std |
| > 0.05 | high seed sensitivity; investigate (overfitting, unstable training, too-small N) |

# Script contract

`scripts/seed_sensitivity.py`:

| Flag | Meaning | Default |
|---|---|---|
| `--exp-id <id>` | base experiment (must have working train.py) | required |
| `--n-seeds <n>` | number of seeds to run | 5 |
| `--seeds <list>` | explicit seed values (comma-separated) | `42,43,44,45,46` (capped at `--n-seeds`) |
| `--metric <name>` | primary metric to aggregate | from research_goal.md |
| `--budget-per-seed <duration>` | per-run timeout | inherits from `exp-run` default (5min) |

Output: writes `seed_runs/*` and `seed_summary.json`. Prints one-line summary on stdout.

# Related

Pairs with [[bootstrap-ci]] — seed-sensitivity captures *model* uncertainty (which depends on initialization and stochastic training); bootstrap-ci captures *sample* uncertainty (which depends on the held-out set). Both are needed for a defensible report. Pairs with [[ablation-planner]] when the ablation's effect size is close to the seed-sensitivity std — that's evidence the ablation is within noise.
