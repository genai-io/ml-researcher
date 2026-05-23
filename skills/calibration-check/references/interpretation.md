# Calibration metric interpretation

## Brier score

| Brier | Reading |
|---|---|
| ≤ 0.10 | well-calibrated for most clinical use cases |
| 0.10 – 0.20 | acceptable but worth scaling for decision support |
| > 0.20 | report with a caveat; consider post-hoc calibration |

Brier is the mean squared error of predicted probability vs true label. Lower is better. It mixes calibration and refinement — a model that always predicts 0.5 has higher Brier than a perfectly-calibrated model that knows the right answer.

## Expected Calibration Error (ECE)

| ECE | Reading |
|---|---|
| ≤ 0.05 | calibrated |
| 0.05 – 0.10 | mild miscalibration |
| > 0.10 | substantial miscalibration; the reliability diagram likely shows a visible gap |

ECE is the average gap between predicted probability and observed frequency across bins, weighted by bin size. It directly measures calibration without the refinement penalty.

**Caveat**: ECE is bin-count-sensitive. Reporting ECE with `--bins 5` gives a different number than `--bins 10`. Always report the bin count alongside.

## Maximum Calibration Error (MCE)

The single worst bin's gap. Useful when *some* probability range matters more than the average (e.g., the high-confidence bin in clinical decision support — patients told they have 95% risk should actually have ~95% risk).

## Reading the reliability diagram

The reliability diagram is the source of truth. The Brier / ECE numbers are summaries; the diagram shows *where* the calibration is off.

- **On-diagonal**: well-calibrated for that probability range.
- **Below diagonal**: model is overconfident (predicts higher than true rate).
- **Above diagonal**: model is underconfident.

Typical patterns:
- **S-shape**: well-calibrated in mid-range, overconfident at extremes. Common; temperature scaling often fixes it.
- **Plateau at bottom**: model assigns very low probability to too many positives. May indicate threshold or class-imbalance issue.
- **Spike at 0.5**: model is uncertain everywhere. Usually means the features are not discriminative enough.

## When to apply post-hoc calibration

- **Temperature scaling** — first try. Single parameter, fits on val, never makes calibration worse.
- **Platt scaling** — sigmoid fit on val scores. Slightly more flexible than temperature.
- **Isotonic regression** — non-parametric. Most flexible but can overfit on small val sets (< 500).

For small N (< 500) prefer temperature scaling. For larger N, try isotonic. Always evaluate the post-hoc calibration on a held-out fold, not the fold used to fit it.

## What to report

In `analysis_report.md`'s Model Comparison section:

> Brier = 0.18 [0.15, 0.22], ECE = 0.06 [0.04, 0.09]. The reliability diagram shows mild overconfidence in the 0.7–0.9 predicted bin (true rate ~0.6).

If post-hoc calibration was applied, name the method and report metrics both before and after.
