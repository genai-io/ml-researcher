---
name: tabular-tabpfn-vs-xgboost
description: Decide between TabPFNv2 and gradient-boosted trees (XGBoost / LightGBM / CatBoost) for tabular ML. TabPFNv2 is best up to ~10K rows × 500 features with no tuning; gradient-boosted dominates beyond that. Code snippets in references/snippets.md.
---

# When to use

Tabular classification or regression. You need to pick between TabPFNv2 and the boosted-tree family.

# Decision tree

```
n_rows ≤ 10,000 AND n_features ≤ 500
   └─ TabPFNv2          (no tuning needed; calibrated by default)

n_rows > 10,000 OR n_features > 500
   ├─ Many categorical features high-cardinality
   │     └─ CatBoost     (handles categoricals natively)
   ├─ Tabular + time-series leakage concern
   │     └─ LightGBM with TimeSeriesSplit
   └─ Otherwise
         └─ XGBoost      (default workhorse)

n_rows > 100K AND dense numeric AND want DL interpretability tooling
   └─ FT-Transformer or SAINT

Cross-table generalization (different schemas at train vs deploy)
   └─ CARTE (graph-based, 2024)
```

# Why TabPFNv2 wins for small N

- **Trained once, used in-context**: no per-task gradient steps; fits 50–10000 rows in seconds.
- **Calibrated by default**: probabilities usable for clinical decision support out of the box.
- **No hyperparameter search**: avoids the "tune until test set is fitted" anti-pattern.
- **Robust to label noise** in the small-N regime where boosted trees overfit.

Limitations:
- Hard cap around 10K rows × 500 features.
- Training distribution is synthetic; severe class imbalance or long tails may underperform.
- Inference cost grows with table size (effectively kNN in feature space).

# Code snippets

Copy-pasteable setup for each model: `references/snippets.md`.

# Common mistakes

- Tuning XGBoost on test set. Use validation only.
- LightGBM on extremely small N (< 200 rows) — overfits hard. Use TabPFN or logistic instead.
- Forgetting `random_state` / `random_seed` — irreproducible.
- Mixing categorical encoding (one-hot vs label) without documenting.
- Reporting train AUC. Always val + test, with CI ([[bootstrap-ci]]).

# When combining with imaging

Late fusion: image encoder (e.g., RadDINO) → `rad_score`, tabular → `tab_score`, linear / logistic on `(rad_score, tab_score)`. See [[medical-small-sample-transfer]] (`references/fusion.md`) for the full recipe.
