---
name: medical-small-sample-transfer
description: Recipe for medical imaging projects with 50-500 labeled cases. Routes to detailed sub-references for pretraining choice, patient-level splits, clinical+imaging fusion, and small-sample reporting. Use when the project is medical imaging with realistic small-N constraints.
---

# When to use

Medical imaging projects with:
- ≤ 500 labeled cases per class
- Patient-level (not slice-level) splits required
- Clinical/molecular tabular data alongside imaging
- Need for calibrated probabilities (clinical decision support)

This is the rad-research canonical regime.

# Decision tree

1. **Picking pretraining** (radiology, pathology, derma, ophth, generic) → `references/pretraining.md`
2. **Setting up splits** (patient-level, locked, GroupShuffleSplit pattern) → `references/splits.md`
3. **Combining clinical + imaging** (late / mid / early fusion) → `references/fusion.md`
4. **Writing the report** (AUC+CI, calibration, DeLong, Limits) → `references/reporting.md`

# Headline recipe (most projects start here)

1. Encoder: **RadDINO** for radiology; domain-specific foundation otherwise (see `pretraining.md`).
2. Splits: patient-level GroupShuffleSplit, locked at init (see `splits.md`).
3. Fusion: late fusion of `clinical_score` + `rad_score` via small logistic (see `fusion.md`).
4. Tabular leg: **TabPFNv2** for n ≤ 10k (see [[tabular-tabpfn-vs-xgboost]]).
5. Report with AUC + bootstrap CI + Brier + DeLong (`bootstrap-ci`, `calibration-check`, `delong-test`).

# Hard rules

- **Patient-level splits, always.** Slice-level random splits leak patients across train/test — most common small-sample bug.
- **Test set locked at project init.** Re-randomizing during experiments is a methodology violation; `test_set_guard.sh` hook also blocks reads during selection/tuning.
- **TabPFNv2 first for tabular** when n ≤ 10k. Do NOT default to deep nets.
- **Report calibration.** Brier alone is not enough — include reliability diagram via `calibration-check`.
- **Honest Limits section** in the report: small N, single-center, retrospective, label quality, calibration drift.

# Related skills

- [[tabular-tabpfn-vs-xgboost]] — tabular leg of late fusion
- [[bootstrap-ci]], [[delong-test]], [[calibration-check]] — reporting requirements
- [[model-recommend]] — query the registry for vetted picks
