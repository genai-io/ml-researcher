---
description: Compare two or more experiments with bootstrap confidence intervals and (for AUC) DeLong's paired test.
---

Compare experiments statistically.

Argument parsing: `$ARGUMENTS` should contain two or more experiment IDs (e.g., `EXP001 EXP003 EXP005`). Optional `--metric <name>` (default: primary metric from `research/research_goal.md`). Optional `--split test|val` (default `val` during Selection/Tuning phases; `test` only in Analysis phase — guarded by hook).

Steps:

1. Resolve experiment IDs. Verify each `experiments/EXP*/metrics.json` exists.

2. For each experiment, read the predictions and labels file paths from `metrics.json`.

3. Compute bootstrap CI for each experiment using the `bootstrap-ci` skill.

4. If the metric is AUC and exactly two experiments are given, run paired DeLong test (`delong-test` skill).

5. If three or more experiments, do pairwise CI overlap analysis and surface significant pairs.

6. Render a comparison bar chart (`figure-render` skill, `kind=comparison_bar`) with error bars = CIs.

7. Print summary:

```
Comparison on val (val_auc):

Experiment              | Point  | 95% CI         |
EXP001_baseline         | 0.661  | (0.513, 0.789) |
EXP003_combined-linear  | 0.700  | (0.565, 0.814) |

DeLong (EXP001 vs EXP003): z=0.74, p=0.46. NOT significant.

Conclusion: Combined model shows numerical improvement over baseline,
but the difference is not statistically significant in this sample.
```

Use the language discipline from `prompts/ml_researcher.md`. Never write "significantly outperforms" when p > 0.05.

$ARGUMENTS
