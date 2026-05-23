# Seed-sensitivity — interpreting the distribution

## Two CIs, two meanings

- **Normal CI** (`ci_normal_95`): assumes the N seed values are roughly Gaussian. Tight, easy to communicate. Use as headline.
- **Quantile CI** (`ci_quantile_95`): just the actual min / max (for N=5) or 2.5/97.5 percentiles (for N=40+). Doesn't assume Gaussianity. Use to sanity-check.

If the two CIs disagree substantially, the seed distribution isn't Gaussian — usually means N=5 isn't enough seeds or there's a heavy tail (some seeds diverged). Increase `--n-seeds` to 10+ and re-check.

## Relative std as a stability signal

The std-to-mean ratio (relative std) tells you how to read the result:

| Relative std | Reading | What to do |
|---|---|---|
| < 0.02 | Very robust. Most seeds land near the mean. | Cite mean as headline; report std for completeness. |
| 0.02 – 0.05 | Typical for small-N ML. Some seed variance, but the trend is real. | Report mean ± std. Use the lower bound for "conservative" claims. |
| 0.05 – 0.10 | Notable seed sensitivity. Worth investigating *why*. | Run N=10+ to better characterize. Check for instability in training (loss spikes, NaN). |
| > 0.10 | High instability. The point estimate is not trustworthy. | Investigate root cause before reporting any single-seed result. Likely: too little data, too high LR, or numerical issue. |

## Comparing two models under seed variance

If model A and model B were each run under N seeds and you want to claim "A > B":

1. Compute the mean of A and B.
2. Compute the per-seed paired difference (if A and B used the *same* set of seeds): `diff_i = A_i - B_i`.
3. The mean of `diff` is the headline; the std of `diff` is the noise.
4. If `|mean(diff)| > 2 × std(diff)` AND the sign is consistent across most seeds → "A consistently outperforms B".
5. If `mean(diff) ≈ 0` or sign flips between seeds → "A and B are statistically comparable; the apparent difference at any one seed is noise".

This is more informative than comparing the marginal distributions of A and B, because paired comparison removes a lot of shared variance.

## When seed sensitivity exposes a real bug

A high relative std (> 0.10) often points to a real issue, not just "this model is unstable":

- **Initialization-sensitive layer**: a randomly-initialized projection head dominates the output. Fix: initialize with smaller scale, or fix the seed of that specific layer.
- **Numerical instability**: some seeds hit NaN or near-singular conditions. Fix: add gradient clipping, lower LR, or check fp16 / bf16 handling.
- **Class imbalance + small N**: minority class ends up with 0 samples in some splits. Fix: stratified splits (with `groups=` if patient-level).
- **Tokenizer / preprocessing nondeterminism**: not just `seed=42` matters — also `torch.backends.cudnn.deterministic`, dataloader worker seeds, etc. The `repro-seal` skill records these.

Don't paper over a high-variance result by averaging more seeds. Find the cause first.

## What to put in the report

In `analysis_report.md`'s Model Comparison section:

> EXP003 (combined linear SVM): val_auc 0.70 ± 0.015 across 5 seeds (range [0.68, 0.72]). Seed sensitivity is small relative to the gap vs baseline (Δ = 0.04, see DeLong p = 0.03), so the improvement is robust to initialization.

In the Limits section:

> Seed sensitivity was characterized on val only; test-set seed sensitivity was not measured (single test run per experiment). Future work should report seed distribution on test for confidence intervals that include initialization uncertainty.
