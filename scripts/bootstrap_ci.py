#!/usr/bin/env python3
"""
Bootstrap confidence interval for a metric on (predictions, labels) arrays.

Output: a single JSON line on stdout:
  {"point": <float>, "low": <float>, "high": <float>, "n_iter": <int>, "metric": <str>}

Usage:
  python bootstrap_ci.py --preds preds.csv --labels labels.csv --metric auc --n-iter 1000

Inputs:
  --preds     CSV with one column of probabilities, OR a column named 'pred'
  --labels    CSV with one column of 0/1 labels, OR a column named 'label'
  --metric    auc | accuracy | f1 | brier  (default: auc)
  --n-iter    bootstrap iterations (default: 1000)
  --alpha     significance level (default: 0.05)
  --seed      RNG seed (default: 42)
"""
import argparse
import json
import sys

import numpy as np
import pandas as pd


def _read_array(path: str, preferred_col: str) -> np.ndarray:
    df = pd.read_csv(path)
    if preferred_col in df.columns:
        return df[preferred_col].to_numpy()
    if df.shape[1] == 1:
        return df.iloc[:, 0].to_numpy()
    raise ValueError(
        f"{path}: expected one column or a column named '{preferred_col}', "
        f"got columns {list(df.columns)}"
    )


def _metric(y_true: np.ndarray, y_pred: np.ndarray, name: str) -> float:
    if name == "auc":
        from sklearn.metrics import roc_auc_score
        return float(roc_auc_score(y_true, y_pred))
    if name == "accuracy":
        from sklearn.metrics import accuracy_score
        y_hat = (y_pred >= 0.5).astype(int)
        return float(accuracy_score(y_true, y_hat))
    if name == "f1":
        from sklearn.metrics import f1_score
        y_hat = (y_pred >= 0.5).astype(int)
        return float(f1_score(y_true, y_hat))
    if name == "brier":
        from sklearn.metrics import brier_score_loss
        return float(brier_score_loss(y_true, y_pred))
    raise ValueError(f"unknown metric: {name}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--preds", required=True)
    ap.add_argument("--labels", required=True)
    ap.add_argument("--metric", default="auc", choices=["auc", "accuracy", "f1", "brier"])
    ap.add_argument("--n-iter", type=int, default=1000)
    ap.add_argument("--alpha", type=float, default=0.05)
    ap.add_argument("--seed", type=int, default=42)
    args = ap.parse_args()

    y_pred = _read_array(args.preds, "pred")
    y_true = _read_array(args.labels, "label")
    if len(y_pred) != len(y_true):
        print(f"error: preds ({len(y_pred)}) and labels ({len(y_true)}) length mismatch", file=sys.stderr)
        return 2

    point = _metric(y_true, y_pred, args.metric)

    rng = np.random.default_rng(args.seed)
    n = len(y_true)
    boots = np.empty(args.n_iter, dtype=float)
    for i in range(args.n_iter):
        idx = rng.integers(0, n, size=n)
        try:
            boots[i] = _metric(y_true[idx], y_pred[idx], args.metric)
        except ValueError:
            # all-one-class bootstrap sample → AUC undefined; resample
            boots[i] = np.nan

    boots = boots[~np.isnan(boots)]
    lo = float(np.quantile(boots, args.alpha / 2))
    hi = float(np.quantile(boots, 1 - args.alpha / 2))

    print(json.dumps({
        "point": round(point, 4),
        "low": round(lo, 4),
        "high": round(hi, 4),
        "n_iter": int(len(boots)),
        "metric": args.metric,
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
