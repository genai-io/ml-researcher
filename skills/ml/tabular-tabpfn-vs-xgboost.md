---
name: tabular-tabpfn-vs-xgboost
description: Decide between TabPFNv2 and gradient-boosted trees (XGBoost / LightGBM / CatBoost) for tabular ML. TabPFNv2 is best up to ~10K rows × 500 features with no tuning; gradient-boosted dominates beyond that. Use when the user has a tabular classification or regression task.
---

# Decision tree

```
n_rows ≤ 10,000 AND n_features ≤ 500
   └─ TabPFNv2          (no tuning needed; calibrated)

n_rows > 10,000 OR n_features > 500
   ├─ Many categorical features high-cardinality
   │     └─ CatBoost     (handles categoricals natively)
   ├─ Tabular + time-series leakage concern
   │     └─ LightGBM with careful CV (TimeSeriesSplit)
   └─ Otherwise
         └─ XGBoost      (default workhorse)
```

If sample size > 100K AND features are dense/numeric AND you want deep-learning interpretability tooling → **FT-Transformer** or **SAINT** are competitive.

If you need *cross-table generalization* (different schemas at train vs deploy) → **CARTE** (graph-based, 2024).

# Why TabPFNv2 wins for small N

- **Trained once, used in-context**: no per-task gradient steps; the model fits 50-10000 rows in seconds.
- **Calibrated by default**: probabilities are usable for clinical decision support out of the box.
- **No hyperparameter search**: avoids the "tune until test set is fitted" anti-pattern.
- **Robust to label noise** in the small-N regime where boosted trees overfit.

Limitations:
- Hard cap around 10K rows × 500 features.
- Training distribution is synthetic; real distributions with severe class imbalance or long tails may underperform.
- Inference cost grows with table size (it's effectively kNN in feature space at inference).

# Setup snippets

## TabPFNv2

```python
# uv add tabpfn
from tabpfn import TabPFNClassifier
clf = TabPFNClassifier(device='cuda')
clf.fit(X_train, y_train)
proba = clf.predict_proba(X_test)
```

That's it. No hyperparameters to tune.

## XGBoost (small-medium tabular)

```python
import xgboost as xgb

model = xgb.XGBClassifier(
    n_estimators=500,
    max_depth=6,
    learning_rate=0.05,
    subsample=0.8,
    colsample_bytree=0.8,
    eval_metric='auc',
    early_stopping_rounds=50,
    random_state=42,
)
model.fit(X_train, y_train, eval_set=[(X_val, y_val)], verbose=False)
```

## CatBoost (categorical-heavy)

```python
from catboost import CatBoostClassifier

cat_features = ['sex', 'race', 'site']  # name them
model = CatBoostClassifier(
    iterations=2000,
    depth=6,
    learning_rate=0.03,
    eval_metric='AUC',
    early_stopping_rounds=100,
    cat_features=cat_features,
    random_seed=42,
    verbose=0,
)
model.fit(X_train, y_train, eval_set=(X_val, y_val))
```

# Common mistakes

- Tuning XGBoost on test set. Use validation only.
- Using LightGBM on extremely small N (< 200 rows) — overfits hard. Use TabPFN or logistic instead.
- Forgetting `random_state` — your "AUC=0.74" is irreproducible.
- Mixing categorical encoding (one-hot vs label) without documenting.
- Reporting train AUC. Always report val + test, with CI.

# When to combine with imaging

For radiomics / multimodal fusion, the right pattern is usually:
- Imaging encoder (e.g., RadDINO) → `rad_score`
- Tabular features → TabPFN or XGBoost → `tab_score`
- Late fusion: linear / logistic on `(rad_score, tab_score)`

See `skills/ml/medical-small-sample-transfer.md` for the full recipe.
