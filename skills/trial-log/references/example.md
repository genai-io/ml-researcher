# Trial-log — worked example

```markdown
## EXP004_high-dim-wavelet — 2026-04-29

- **Motivation**: Test whether high-dimensional wavelet radiomics features improve over the original-only baseline.
- **Change from parent (`EXP003_combined-linear-svm`)**: Added wavelet feature extraction (Original + Wavelet image types) before feature selection.
- **Data version**: features_cache_2026-04-25.parquet
- **Key parameters**: T1-C only, bin width 25, AUC-driven feature selection (top 80, corr ≤ 0.90), Combined linear SVM, seed=42.
- **Results**:
  - val_auc: 0.757 (CI: 0.612, 0.870)
  - test_auc: 0.587 (CI: 0.443, 0.728) ← test set lookup happened in Analysis phase only
- **Decision**: reject
- **Reason**: Test AUC dropped 0.10 from EXP003 despite higher train+CV AUC. Classic small-sample overfit on high-dim wavelet features.
- **Next step**: Stay with EXP003 as best. Do not re-attempt high-dim radiomics in this project.
```

## What this example demonstrates

- **Honest negative result.** Test AUC dropped — recorded plainly, not hidden behind "needs more runs".
- **Specific reason.** "Classic small-sample overfit on high-dim wavelet features" — actionable for the next experimenter.
- **Concrete next step.** "Do not re-attempt high-dim radiomics in this project" — closes a branch of the search tree.
- **Parent linkage.** Cites `EXP003_combined-linear-svm`, so the analyst can trace the lineage.
- **Data version anchored.** A future reader can find the exact features cache used.
