---
name: error-analysis
description: Diagnose where a model fails — worst-K predictions, slice analysis (by subgroup / feature bin), and confusion-matrix deep-dive. Wraps scripts/error_analysis.py. Use after an experiment converges to decide whether the next trial should target a specific failure mode. Output template in references/output_template.md.
allowed-tools: Bash Read Write
---

# When to use

- After a kept trial, before the next trial — "where is the error concentrated?" beats "let's try LR=5e-5".
- When val metric plateaus for 3+ consecutive trials and the experimenter agent runs out of ideas.
- Before promoting metrics to `analysis_report.md`, to know what goes in Limits.

Do NOT use on the test set during Model Selection or Fine Tuning — the hook will block test-set reads; test-set error-analysis is part of the Analysis-phase report, not exploratory work.

# What it produces

Three files under `experiments/EXPxxx/error_analysis/`:

- `worst_k.csv` — top-K worst predictions by per-sample loss / confidence-margin
- `slices.json` — metric breakdown by subgroup
- `confusion.png` + `confusion.json` — row-normalized confusion plus top off-diagonal mass

Plus `error_analysis.md` — prose summary using the template in `references/output_template.md`.

# Steps

1. **Identify inputs** — predictions CSV (with `sample_id`, `pred`, optionally `pred_proba`), labels CSV, optional groups CSV (subgroup columns keyed by `sample_id`).

2. **Invoke**:

   ```bash
   python scripts/error_analysis.py \
     --preds experiments/EXP003_combined-linear-svm/predictions_val.csv \
     --labels data/splits/val/labels.csv \
     --groups data/derived/metadata.csv \
     --slice-by sex,age_band,scanner \
     --k 20 \
     --out experiments/EXP003_combined-linear-svm/error_analysis/
   ```

3. **Read the three outputs** for patterns:
   - `worst_k.csv` — always the same scanner? always the rare class?
   - `slices.json` — which slice has metric ≥ 0.05 worse than overall?
   - `confusion.json` — which off-diagonal cell holds the most mass?

4. **Write `error_analysis.md`** using the prose template in `references/output_template.md`. Append if file exists.

5. **Return to caller** a 2-3 sentence verdict: where error concentrates + one concrete next-trial suggestion.

# Hard rules

- `worst_k.csv` includes `sample_id`, not raw features. Don't leak sensitive content into agent context.
- Default `--k 20`. Don't exceed 100.
- Slice analysis requires `n ≥ 10` per slice to report a metric. Otherwise `[underpowered]`.
- Subgroup analyses on tiny slices (n < 5) are forbidden in `analysis_report.md` — Limits section only.
- Never reorder columns of predictions or write back into it.

# Script contract

`scripts/error_analysis.py`:

| Flag | Meaning | Default |
|---|---|---|
| `--preds <path>` | predictions CSV | required |
| `--labels <path>` | labels CSV | required |
| `--groups <path>` | metadata CSV (keyed by sample_id) | none |
| `--slice-by <list>` | comma-separated subgroup columns | none |
| `--k <n>` | worst-K count | 20 |
| `--metric <name>` | per-slice metric (`auc`, `accuracy`, `f1`) | `auc` |
| `--threshold <f>` | for confusion / accuracy | inferred |
| `--out <dir>` | output directory | `experiments/<exp_id>/error_analysis/` |

Output: writes files into `--out`. Prints one-line summary on stdout.

# Related

Pairs with [[calibration-check]] (calibration is one specific error mode). Pairs with [[bootstrap-ci]] for slice CIs. Experimenter agent uses error-analysis output to choose the next trial's hypothesis.
