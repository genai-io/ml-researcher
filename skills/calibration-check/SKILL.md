---
name: calibration-check
description: Compute calibration metrics (Brier score, ECE, MCE) and render a reliability diagram for a binary or multi-class classifier's predicted probabilities. Wraps scripts/calibration_check.py. Mandatory for any classification result in research/analysis_report.md. Interpretation tables in references/interpretation.md.
allowed-tools: Bash Read Write
---

# When to use

- Before promoting any classification metric to `analysis_report.md` — calibration is a required reporting axis for clinical / decision-support use cases.
- During Fine Tuning when AUC is good but probabilities look suspicious (clustered at 0/1, or stuck at 0.5).
- After any post-hoc step (temperature scaling / Platt / isotonic) to verify the scaling actually improved calibration.

Do NOT use on regression outputs. Do NOT touch the test split until Analysis phase.

# What it produces

Under the experiment dir (or `results/figures/` if invoked by analyst):

- `calibration.json` — Brier / ECE / MCE point estimates and bootstrap CIs
- `reliability_diagram.png` — reliability plot with CIs + bin-count histogram on bottom axis

# Steps

1. **Identify inputs** — predictions CSV with `pred_proba` (binary) or per-class columns (multi-class); labels CSV with integer labels.

2. **Choose bins**. Default `--bins 10` (quantile). For n < 100, use `--bins 5`. Stick to one convention per project — ECE is bin-count-sensitive.

3. **Invoke**:

   ```bash
   python scripts/calibration_check.py \
     --preds experiments/EXP003_combined-linear-svm/predictions_val.csv \
     --labels data/splits/val/labels.csv \
     --bins 10 \
     --bootstrap 1000 \
     --out experiments/EXP003_combined-linear-svm/calibration/
   ```

4. **Parse `calibration.json`** and report to caller in one paragraph (point + CI for Brier and ECE, plus one sentence reading the reliability diagram). Interpretation guidance: `references/interpretation.md`.

5. **Update `metrics.json`** of the experiment with `brier`, `ece`, `mce` as secondary metrics. Don't overwrite the primary.

# Hard rules

- Brier is on **raw probabilities**, not post-threshold predictions. If only hard labels are in `predictions.csv`, calibration-check cannot run — surface the issue.
- For multi-class: report **per-class Brier** plus overall (mean per-class). Don't average ECE across classes silently.
- Always include bootstrap CIs. Point ECE=0.05 with CI [0.01, 0.12] tells a different story than 0.05 with [0.04, 0.06].
- For post-hoc-calibrated models, the JSON must record `"post_hoc_method": "temperature" | "platt" | "isotonic" | null`.

# Script contract

`scripts/calibration_check.py`:

| Flag | Meaning | Default |
|---|---|---|
| `--preds <path>` | predictions CSV with `pred_proba` or per-class columns | required |
| `--labels <path>` | labels CSV | required |
| `--bins <n>` | reliability bins | 10 |
| `--bin-strategy <equal\|quantile>` | bin edges | `quantile` |
| `--bootstrap <n>` | bootstrap iterations for CIs | 1000 |
| `--post-hoc <method>` | optional `temperature\|platt\|isotonic` to fit on val | none |
| `--seed <n>` | RNG seed | 42 |
| `--out <dir>` | output directory | `<exp_dir>/calibration/` |

Output: writes `calibration.json` and `reliability_diagram.png`. Stdout: one-line JSON summary.

# Related

Pairs with [[bootstrap-ci]] for metric CIs. Pairs with [[figure-render]] (`--kind calibration` for standalone figure). Analyst must run calibration-check before any classification result lands in the report.
