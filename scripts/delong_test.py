#!/usr/bin/env python3
"""
DeLong's test for paired AUC comparison between two models on the same dataset.

Output: a single JSON line on stdout:
  {"auc_a": <float>, "auc_b": <float>, "z": <float>, "p": <float>}

Usage:
  python delong_test.py --preds-a a.csv --preds-b b.csv --labels labels.csv

The two prediction files must have the same number of rows, in the same order,
corresponding to the same samples (paired design).

Implementation note: this uses the fast DeLong algorithm of Sun & Xu (2014),
which is O(n log n) and handles tied scores correctly.
"""
import argparse
import json
import sys

import numpy as np
import pandas as pd
from scipy.stats import norm


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


def _midrank(x: np.ndarray) -> np.ndarray:
    """Mid-ranks (handles ties)."""
    j = np.argsort(x)
    z = np.empty_like(j, dtype=float)
    n = len(x)
    i = 0
    while i < n:
        k = i
        while k < n and x[j[k]] == x[j[i]]:
            k += 1
        # ranks are 1-based in DeLong; midrank for ties
        avg = (i + k - 1) / 2.0 + 1
        z[j[i:k]] = avg
        i = k
    return z


def _fast_delong(predictions_sorted_transposed: np.ndarray, label_1_count: int):
    """Fast DeLong (Sun & Xu 2014). Returns AUC vector, covariance matrix."""
    m = label_1_count
    n = predictions_sorted_transposed.shape[1] - m
    k = predictions_sorted_transposed.shape[0]

    tx = np.empty((k, m), dtype=float)
    ty = np.empty((k, n), dtype=float)
    tz = np.empty((k, m + n), dtype=float)
    for r in range(k):
        tx[r, :] = _midrank(predictions_sorted_transposed[r, :m])
        ty[r, :] = _midrank(predictions_sorted_transposed[r, m:])
        tz[r, :] = _midrank(predictions_sorted_transposed[r, :])

    aucs = tz[:, :m].sum(axis=1) / m / n - (m + 1.0) / 2.0 / n
    v01 = (tz[:, :m] - tx) / n
    v10 = 1.0 - (tz[:, m:] - ty) / m
    sx = np.cov(v01)
    sy = np.cov(v10)
    if sx.ndim == 0:
        sx = sx.reshape(1, 1)
        sy = sy.reshape(1, 1)
    delongcov = sx / m + sy / n
    return aucs, delongcov


def _delong(labels: np.ndarray, preds_a: np.ndarray, preds_b: np.ndarray):
    order = (-labels).argsort()  # positives first
    labels_sorted = labels[order]
    preds = np.vstack((preds_a[order], preds_b[order]))
    m = int(labels_sorted.sum())
    aucs, cov = _fast_delong(preds, m)
    diff = aucs[0] - aucs[1]
    var = cov[0, 0] + cov[1, 1] - 2 * cov[0, 1]
    if var <= 0:
        return float(aucs[0]), float(aucs[1]), 0.0, 1.0
    z = diff / np.sqrt(var)
    p = 2 * (1 - norm.cdf(abs(z)))
    return float(aucs[0]), float(aucs[1]), float(z), float(p)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--preds-a", required=True)
    ap.add_argument("--preds-b", required=True)
    ap.add_argument("--labels", required=True)
    args = ap.parse_args()

    a = _read_array(args.preds_a, "pred")
    b = _read_array(args.preds_b, "pred")
    y = _read_array(args.labels, "label").astype(int)

    if not (len(a) == len(b) == len(y)):
        print(
            f"error: lengths differ — preds_a={len(a)}, preds_b={len(b)}, labels={len(y)}",
            file=sys.stderr,
        )
        return 2

    auc_a, auc_b, z, p = _delong(y, a, b)
    print(json.dumps({
        "auc_a": round(auc_a, 4),
        "auc_b": round(auc_b, 4),
        "z": round(z, 3),
        "p": round(p, 4),
    }))
    return 0


if __name__ == "__main__":
    sys.exit(main())
