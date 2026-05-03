#!/usr/bin/env python3
"""
Render a publication-quality figure to PNG.

Supported `--kind` values: roc, calibration, confusion, learning_curve, comparison_bar

Usage examples:
  python figure_render.py --kind roc --preds a.csv --preds b.csv \
      --labels labels.csv --names baseline combined \
      --out results/figures/roc.png

  python figure_render.py --kind comparison_bar --metrics-json metrics.json \
      --metric val_auc --out results/figures/comparison.png
"""
import argparse
import json
import sys
from pathlib import Path

import matplotlib

matplotlib.use("Agg")  # noqa: E402  headless
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import pandas as pd  # noqa: E402


def _read_col(path: str, preferred: str) -> np.ndarray:
    df = pd.read_csv(path)
    if preferred in df.columns:
        return df[preferred].to_numpy()
    if df.shape[1] == 1:
        return df.iloc[:, 0].to_numpy()
    raise ValueError(f"{path}: expected one column or '{preferred}'")


def _save(out: str) -> None:
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(out, dpi=200, bbox_inches="tight")
    plt.close()


def render_roc(args) -> None:
    from sklearn.metrics import roc_auc_score, roc_curve

    y = _read_col(args.labels, "label").astype(int)
    fig, ax = plt.subplots(figsize=(5, 5))
    for path, name in zip(args.preds, args.names or args.preds):
        p = _read_col(path, "pred")
        fpr, tpr, _ = roc_curve(y, p)
        auc = roc_auc_score(y, p)
        ax.plot(fpr, tpr, label=f"{name} (AUC={auc:.3f})")
    ax.plot([0, 1], [0, 1], "k--", alpha=0.4)
    ax.set_xlabel("False positive rate")
    ax.set_ylabel("True positive rate")
    ax.set_title(args.title or f"ROC, n={len(y)}")
    ax.legend(loc="lower right", fontsize=9)
    ax.set_aspect("equal")
    _save(args.out)


def render_calibration(args) -> None:
    from sklearn.calibration import calibration_curve
    from sklearn.metrics import brier_score_loss

    y = _read_col(args.labels, "label").astype(int)
    p = _read_col(args.preds[0], "pred")
    prob_true, prob_pred = calibration_curve(y, p, n_bins=10, strategy="quantile")
    brier = brier_score_loss(y, p)

    fig, ax = plt.subplots(figsize=(5, 5))
    ax.plot([0, 1], [0, 1], "k--", alpha=0.4, label="Perfect calibration")
    ax.plot(prob_pred, prob_true, marker="o", label=f"Observed (Brier={brier:.3f})")
    ax.set_xlabel("Mean predicted probability")
    ax.set_ylabel("Fraction of positives")
    ax.set_title(args.title or "Calibration")
    ax.legend(fontsize=9)
    ax.set_aspect("equal")
    _save(args.out)


def render_confusion(args) -> None:
    from sklearn.metrics import confusion_matrix

    y = _read_col(args.labels, "label").astype(int)
    p = _read_col(args.preds[0], "pred")
    threshold = float(args.threshold)
    y_hat = (p >= threshold).astype(int)
    cm = confusion_matrix(y, y_hat)
    cm_norm = cm.astype(float) / cm.sum(axis=1, keepdims=True)

    fig, ax = plt.subplots(figsize=(5, 4))
    im = ax.imshow(cm_norm, cmap="Blues", vmin=0, vmax=1)
    for i in range(cm.shape[0]):
        for j in range(cm.shape[1]):
            ax.text(
                j, i, f"{cm[i, j]}\n({cm_norm[i, j]:.2f})",
                ha="center", va="center", color="black" if cm_norm[i, j] < 0.5 else "white",
                fontsize=10,
            )
    ax.set_xticks([0, 1]); ax.set_yticks([0, 1])
    ax.set_xticklabels(["Pred neg", "Pred pos"])
    ax.set_yticklabels(["True neg", "True pos"])
    ax.set_title(args.title or f"Confusion (threshold={threshold:.2f})")
    fig.colorbar(im, ax=ax, fraction=0.046)
    _save(args.out)


def render_learning_curve(args) -> None:
    """Parse 'step: <n> train_<m>: <v> val_<m>: <v>' style log lines."""
    import re

    steps, train, val = [], [], []
    metric = args.metric or "loss"
    pat_step = re.compile(r"^step:\s*(\d+)")
    pat_tr = re.compile(rf"\btrain_{re.escape(metric)}:\s*([0-9.eE+-]+)")
    pat_va = re.compile(rf"\bval_{re.escape(metric)}:\s*([0-9.eE+-]+)")

    with open(args.run_log) as f:
        cur_step = None
        for line in f:
            ms = pat_step.match(line)
            if ms:
                cur_step = int(ms.group(1))
            mt = pat_tr.search(line)
            mv = pat_va.search(line)
            if mt and cur_step is not None:
                steps.append(cur_step); train.append(float(mt.group(1)))
            if mv and cur_step is not None:
                val.append(float(mv.group(1)))

    fig, ax = plt.subplots(figsize=(6, 4))
    if train:
        ax.plot(steps[: len(train)], train, label=f"train {metric}", marker=".")
    if val:
        ax.plot(steps[: len(val)], val, label=f"val {metric}", marker=".")
    ax.set_xlabel("step")
    ax.set_ylabel(metric)
    ax.set_title(args.title or f"Learning curve ({metric})")
    ax.legend()
    _save(args.out)


def render_comparison_bar(args) -> None:
    with open(args.metrics_json) as f:
        rows = json.load(f)  # list of {"name": str, "point": f, "low": f, "high": f}
    rows = sorted(rows, key=lambda r: -r["point"])
    names = [r["name"] for r in rows]
    points = np.array([r["point"] for r in rows])
    low = np.array([r["low"] for r in rows])
    high = np.array([r["high"] for r in rows])
    err = np.vstack((points - low, high - points))

    fig, ax = plt.subplots(figsize=(max(5, len(names) * 1.1), 4))
    ax.bar(names, points, yerr=err, capsize=4)
    ax.set_ylabel(args.metric)
    ax.set_ylim(bottom=max(0, low.min() - 0.05))
    ax.set_title(args.title or f"Comparison: {args.metric}")
    plt.xticks(rotation=15, ha="right")
    _save(args.out)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--kind", required=True,
                    choices=["roc", "calibration", "confusion", "learning_curve", "comparison_bar"])
    ap.add_argument("--preds", action="append", default=[])
    ap.add_argument("--labels")
    ap.add_argument("--names", nargs="*")
    ap.add_argument("--threshold", default="0.5")
    ap.add_argument("--metric", default=None)
    ap.add_argument("--metrics-json", default=None)
    ap.add_argument("--run-log", default=None)
    ap.add_argument("--title", default=None)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    dispatch = {
        "roc": render_roc,
        "calibration": render_calibration,
        "confusion": render_confusion,
        "learning_curve": render_learning_curve,
        "comparison_bar": render_comparison_bar,
    }
    dispatch[args.kind](args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
