# Patient-level splits, locked at init

## The pattern

```python
# Wrong: stratified random split on slices/images
# Right: stratified random split on patient IDs, then expand to slices

from sklearn.model_selection import GroupShuffleSplit
splitter = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
train_idx, test_idx = next(splitter.split(X, y, groups=patient_ids))
```

For a train/val/test three-way split, apply `GroupShuffleSplit` twice (e.g., 80/20 then 80/20 on the train portion).

## Why patient-level

A single patient often contributes many slices, sessions, or augmented views. A slice-level random split puts the *same patient* in both train and test. The model then memorizes patient-specific signal (texture, scanner artifacts, anatomy) rather than learning the target.

The visible symptom: train AUC ≫ test AUC; test AUC drops further when a held-out site is added.

## Locking at init

Locked splits live under `data/splits/{train,val,test}/` (or a `MANIFEST.json` declaring them). `install.sh` scaffolds these once and stores checksums in `data/splits/MANIFEST.json`. The `test_set_guard.sh` hook blocks Reads of `data/splits/test/**` during Model Selection and Fine Tuning phases.

The `repro-seal` skill records each split's checksum in `repro_seal.json` so the analyst can verify the split hasn't drifted between sealing and finalization.

## Stratification keys

For binary classification, stratify on the label. For multi-class with imbalanced rare classes, stratify on the label AND any high-impact covariate (e.g., scanner or site) using `MultilabelStratifiedShuffleSplit` from `iterative-stratification`.
