# Tabular model setup — copy-pasteable snippets

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

## LightGBM (time-series with TimeSeriesSplit)

```python
import lightgbm as lgb
from sklearn.model_selection import TimeSeriesSplit

splits = TimeSeriesSplit(n_splits=5)
for train_idx, val_idx in splits.split(X):
    model = lgb.LGBMClassifier(
        n_estimators=500,
        learning_rate=0.05,
        num_leaves=31,
        random_state=42,
    )
    model.fit(
        X.iloc[train_idx], y.iloc[train_idx],
        eval_set=[(X.iloc[val_idx], y.iloc[val_idx])],
        callbacks=[lgb.early_stopping(50)],
    )
```
