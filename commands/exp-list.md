---
description: Show experiments from the ledger with status, primary metric, and one-line description.
---

Show the experiment ledger.

Steps:

1. Read `experiments/ledger.tsv`.
2. Read each `experiments/EXPxxx_*/README.md` for the description if not in the ledger.
3. Print as a table:

```
ID                          | Metric    | Value   | Status   | Description
EXP001_baseline             | val_auc   | 0.661   | keep     | Clinical+VASARI logistic baseline
EXP002_radiomics-rbf-svm    | val_auc   | 0.637   | keep     | RBF SVM on T1-C original GLCM features
EXP003_combined-linear-svm  | val_auc   | 0.700   | keep     | Linear SVM on clinical_score + rad_score   ← CURRENT BEST
EXP004_high-dim-wavelet     | val_auc   | 0.587   | discard  | Discarded — overfit, test AUC dropped
```

Mark the current best with `← CURRENT BEST`.

If `--filter <status>` is provided, only show rows matching that status.

If `--metric <name>` is provided and differs from primary, also show that metric.

$ARGUMENTS
