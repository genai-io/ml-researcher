---
name: delong-test
description: DeLong's test for paired AUC comparison between two models on the same dataset. Wraps scripts/delong_test.py.
allowed-tools: Bash, Read
---

# When to use

Compare two AUC values measured on the same set of samples (paired design). Examples:
- Baseline model vs combined model on the validation set
- Single-modality model vs fusion model on test set (Analysis phase only)

DeLong is paired and accounts for the correlation between predictions on the same samples. **Do not use unpaired tests** for this comparison.

# Steps

1. **Identify both models' predictions and the shared labels**:
   - `preds_a`: experiments/EXPxxx_a/predictions_<split>.csv
   - `preds_b`: experiments/EXPxxx_b/predictions_<split>.csv
   - `labels`: data/splits/<split>/labels.csv

2. **Verify pairing**: the two prediction files must have the same number of rows AND correspond to the same sample order. The script will error if not.

3. **Invoke**:

   ```bash
   python scripts/delong_test.py \
     --preds-a experiments/EXP001_baseline/predictions_val.csv \
     --preds-b experiments/EXP003_combined-linear-svm/predictions_val.csv \
     --labels data/splits/val/labels.csv
   ```

4. **The script prints one JSON line**:

   ```json
   {"auc_a": 0.661, "auc_b": 0.700, "z": 0.74, "p": 0.46}
   ```

5. **Report**:

   ```
   AUC_A = 0.661 (EXP001_baseline)
   AUC_B = 0.700 (EXP003_combined-linear-svm)
   DeLong z = 0.74, p = 0.46 → NOT significant at α=0.05
   ```

6. **Interpret with discipline**:
   - p < 0.05 → "significantly better" / "DeLong p=<value>"
   - p > 0.05 → "trend toward higher AUC; not statistically significant" — never "outperforms"
   - The point estimate ordering can flip when more data is added; small N produces wide CIs

# Hard rules

- Test set use only allowed in Analysis phase (hook will block otherwise).
- Both prediction files must have the same number of rows in the same order.
- Report the test result IN THE SAME PARAGRAPH as the AUC claim. Don't bury it in an appendix.

# Script contract

`scripts/delong_test.py` accepts:

| Flag | Meaning | Default |
|---|---|---|
| `--preds-a <path>` | model A predictions CSV | required |
| `--preds-b <path>` | model B predictions CSV | required |
| `--labels <path>` | labels CSV (paired with both prediction sets) | required |

Output: one JSON line: `{"auc_a": ..., "auc_b": ..., "z": ..., "p": ...}`.
