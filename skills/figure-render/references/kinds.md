# Supported figure kinds

| `kind` | Required inputs | Output | Per-kind flags |
|---|---|---|---|
| `roc` | predictions, labels, names | ROC curves with CI band | `--ci-bootstrap <n>` (default 1000) |
| `calibration` | predictions, labels | Reliability diagram + Brier in caption | `--bins <n>` (default 10) |
| `confusion` | predictions, labels, threshold | Row-normalized confusion matrix with counts | `--threshold <f>`, `--class-names <list>` |
| `learning_curve` | run.log | Train/val metric vs epoch/step | `--metric <name>`, `--smoothing <window>` |
| `comparison_bar` | metrics for ≥ 2 experiments | Bar chart with CI error bars | `--metric <name>`, `--sort <asc\|desc>` |

## Per-kind notes

### ROC

- Always include the CI band (bootstrap, default n=1000).
- For ≤ 4 models on one plot; if more, split into facets or pick a representative subset.
- Random baseline diagonal in dashed gray.

### Calibration

- Reliability bins + a histogram strip on the bottom showing sample count per bin.
- Brier score in figure caption (computed via [[calibration-check]] if not provided).
- For multi-class, use one subplot per class.

### Confusion

- Row-normalized (each row sums to 1) AND annotated with counts.
- Threshold must be specified for binary; default is 0.5 but say so in the caption.
- For multi-class, omit the threshold flag.

### Learning curve

- X-axis: step or epoch (script auto-detects).
- Y-axis: the metric in `run.log`.
- Optional smoothing window for noisy losses.
- Both train and val on one plot if both are logged.

### Comparison bar

- Default sort: descending by metric value (best on left).
- Error bars are CIs (bootstrap if predictions provided, propagated from metric file otherwise).
- If experiments have different splits, group on x-axis by split.

## When to use which

| Question | Right kind |
|---|---|
| "How do these models compare on discrimination?" | `roc` |
| "Are the probabilities trustworthy?" | `calibration` |
| "Which class is the model confused about?" | `confusion` |
| "Did the run converge cleanly?" | `learning_curve` |
| "Which experiment was best?" | `comparison_bar` |
