# Combining clinical + imaging features

Three fusion regimes for small-N medical projects.

## 1. Late fusion of scores (rad-research's canonical pattern)

- Train clinical-only model → produces `clinical_score`
- Train imaging-only model → produces `rad_score`
- Train a small linear / logistic on `(clinical_score, rad_score)` → final
- **Pros**: each component validates separately; small overfitting risk
- **Cons**: may underfit if clinical and imaging interact strongly

## 2. Mid fusion (concatenate features)

- Extract imaging features (e.g., from RadDINO penultimate layer)
- Concatenate with normalized clinical features
- Feed to a small MLP or TabPFN (TabPFNv2 handles up to ~10K rows × 500 features beautifully)
- **Pros**: captures interactions; few hyperparameters
- **Cons**: requires more samples; harder to validate components separately

## 3. Early fusion

Only viable with much larger samples (≥ 1k). Skip for small N.

## Picking among the three

| Sample regime | First try |
|---|---|
| n ≤ 200 | Late fusion |
| 200 < n ≤ 1000 | Late fusion; try mid fusion as ablation |
| n > 1000 | Mid fusion (TabPFN or MLP on concatenated features) |

For the tabular leg, see [[tabular-tabpfn-vs-xgboost]].

## What to report

For any fusion result:
- Component-only scores (clinical-only AUC, rad-only AUC) — readers want to know which leg carries the weight
- Fusion gain over best single component, with DeLong p-value
- Calibration of the fused model (often differs from either component)
