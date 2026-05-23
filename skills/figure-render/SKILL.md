---
name: figure-render
description: Render a publication-quality figure via scripts/figure_render.py. Supports ROC, calibration, confusion, learning-curve, and comparison-bar plots. Per-kind input/output table in references/kinds.md.
allowed-tools: Bash Read
---

# When to use

Produce conclusion-grade figures for the analysis report, or exploratory figures inside an experiment directory. Analyst is the main caller; experimenter may use it for learning-curve diagnostics.

# Steps

1. **Determine `kind`** from the user's request or context. Supported: `roc`, `calibration`, `confusion`, `learning_curve`, `comparison_bar`. Full input/output per kind: `references/kinds.md`.

2. **Build the command**:

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
- Title: descriptive but concise — `"ROC, validation set, n=54"`.
- Legend: short labels (model names without paths).
- For `comparison_bar`: order experiments by metric value descending.

# Where figures live

- `experiments/EXPxxx_*/figures/` — exploratory figures specific to one experiment.
- `results/figures/` — only conclusion-grade figures referenced in the analysis report.

Don't pollute `results/` with WIP figures.

# Script contract

`scripts/figure_render.py` accepts shared and per-kind flags. The script may grow flags per `kind`; consult its `--help`.

Common flags:

| Flag | Meaning |
|---|---|
| `--kind <name>` | one of the supported kinds |
| `--preds <path>` (repeatable) | predictions CSV(s) |
| `--labels <path>` | labels CSV |
| `--names <name>` (repeatable) | display names |
| `--out <path>` | output PNG path |

# Related

Pairs with [[calibration-check]] for `--kind calibration` (calibration-check also computes the metric; figure-render only renders). The analyst agent calls figure-render for every figure in `analysis_report.md`.
