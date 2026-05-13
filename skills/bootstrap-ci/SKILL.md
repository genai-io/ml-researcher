---
name: bootstrap-ci
description: Compute bootstrap 95% confidence interval for a metric on (predictions, labels) arrays. Wraps scripts/bootstrap_ci.py.
allowed-tools: Bash, Read
---

# Steps

1. **Locate the predictions and labels files** — typically `experiments/EXPxxx_*/predictions.csv` and `data/splits/<split>/labels.csv`. The agent's caller usually provides these paths.

2. **Determine the metric** — auc, accuracy, f1, brier (for calibration). From the user's question or from `research/research_goal.md`'s primary metric.

3. **Invoke the script**:

   ```bash
   python scripts/bootstrap_ci.py \
     --preds experiments/EXP003_combined-linear-svm/predictions.csv \
     --labels data/splits/val/labels.csv \
     --metric auc \
     --n-iter 1000 \
     --alpha 0.05
   ```

4. **The script prints one JSON line to stdout**:

   ```json
   {"point": 0.700, "low": 0.565, "high": 0.814, "n_iter": 1000, "metric": "auc"}
   ```

5. **Parse the JSON** and report to the caller. Format:

   ```
   AUC = 0.700, 95% CI [0.565, 0.814] (n=1000 bootstrap iterations)
   ```

# Hard rules

- The script seeds randomness with `--seed` (default 42). Reproducibility is mandatory.
- Default `n-iter=1000`. For tighter CIs the user can request more, but 1000 is sufficient for most reporting.
- Bootstrap CI is **not** the same as a hypothesis test. For pairwise comparison of AUCs use `delong-test`, not bootstrap CI overlap (CIs can overlap when DeLong is significant and vice versa).

# Script contract

`scripts/bootstrap_ci.py` accepts:

| Flag | Meaning | Default |
|---|---|---|
| `--preds <path>` | predictions CSV (one column of probabilities OR a column named `pred`) | required |
| `--labels <path>` | labels CSV (one column of 0/1 OR a column named `label`) | required |
| `--metric <name>` | `auc`, `accuracy`, `f1`, `brier` | `auc` |
| `--n-iter <n>` | bootstrap iterations | 1000 |
| `--alpha <f>` | significance level | 0.05 |
| `--seed <n>` | RNG seed | 42 |

Output: one JSON line on stdout.

If the script fails, the agent surfaces the stderr and does NOT proceed with reporting "no CI computed."
