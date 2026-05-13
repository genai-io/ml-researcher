---
name: figure-render
description: Render a publication-quality figure via scripts/figure_render.py. Supports ROC, calibration, confusion, learning-curve, and comparison-bar plots.
allowed-tools: Bash, Read
---

# Supported figure kinds

| `kind` | Required inputs | Output |
|---|---|---|
| `roc` | predictions, labels, model_name(s) | ROC curves with CI band |
| `calibration` | predictions, labels | Reliability diagram + Brier in caption |
| `confusion` | predictions, labels, threshold | Row-normalized confusion matrix with counts |
| `learning_curve` | run.log | Train/val metric vs epoch/step |
| `comparison_bar` | metrics for ≥2 experiments | Bar chart with CI error bars |

# Steps

1. **Determine `kind`** from the user's request or context.

2. **Build the command** with appropriate inputs:

   ```bash
   python scripts/figure_render.py \
     --kind roc \
     --preds experiments/EXP001_baseline/predictions_val.csv \
     --preds experiments/EXP003_combined-linear-svm/predictions_val.csv \
     --labels data/splits/val/labels.csv \
     --names baseline combined \
     --out results/figures/roc_baseline_vs_combined.png
   ```

3. **Verify the output file** was created.

4. **If part of the analysis report**, also note the figure in `research/analysis_report.md`'s Required Figures section.

# Conventions

- Output PNG at 200dpi or higher.
- Sans-serif font (matplotlib default works).
- Color-blind-friendly palette: `tab10` or `viridis`.
- Error bars are CIs (computed via bootstrap), not std-dev.
- Title: descriptive but concise, e.g., "ROC, validation set, n=54".
- Legend: short labels (model names without paths).
- For comparison_bar: order experiments by metric value descending.

# Script contract

`scripts/figure_render.py` accepts (per kind, varies):

| Flag | Meaning |
|---|---|
| `--kind <name>` | one of the listed kinds |
| `--preds <path>` (repeatable) | predictions CSV(s) |
| `--labels <path>` | labels CSV |
| `--names <name>` (repeatable) | display names |
| `--metric <name>` | for comparison_bar |
| `--threshold <f>` | for confusion |
| `--out <path>` | output PNG path |

The script may grow flags per `kind`; consult its `--help`.

# When figures live where

- `experiments/EXPxxx_*/figures/` — exploratory figures specific to one experiment.
- `results/figures/` — only conclusion-grade figures referenced in the analysis report.

Don't pollute `results/` with WIP figures.
