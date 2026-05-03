---
name: medical-small-sample-transfer
description: Recipe for medical imaging projects with 50-500 labeled cases. Covers patient-level splits, transfer-learning pretraining choices (RadDINO, MedSigLIP, BiomedCLIP, MedGemma), feature fusion with tabular clinical data, calibration, and small-sample reporting (DeLong, bootstrap CI). Use when the project is medical imaging with realistic small-N constraints.
---

# When to use

Medical imaging projects with:
- ≤ 500 labeled cases per class
- Patient-level (not slice-level) splits required
- Clinical/molecular data alongside imaging
- Need for calibrated probabilities (clinical decision support)

This is the rad-research canonical regime.

# Pretraining choice

For radiology imaging, prefer in this order:

1. **RadDINO** (`microsoft/rad-dino`) — DINOv2-style pretraining on chest X-ray and similar; strongest small-sample feature extractor for radiology. License: research-only (check for clinical use).
2. **MedSigLIP** (`google/medsiglip-...`) — multimodal medical CLIP-style. Good for image-text retrieval and classification.
3. **BiomedCLIP** (`microsoft/BiomedCLIP-PubMedBERT_256-vit_base_patch16_224`) — CLIP-style on PubMed images. Older but well-tested.
4. **MedGemma-4B / 27B** (`google/medgemma-...`, July 2025) — multimodal medical foundation models. Good for QA-style tasks.
5. **DINOv2 / DINOv3** (`facebook/dinov2-large` etc.) — generic foundation that often beats medical-specific on linear probe with very small N.
6. **nnU-Net v2** — for segmentation tasks specifically (not classification).

For non-radiology medical (pathology, dermatology, ophthalmology), substitute the domain's foundation: PathDINO, DERM-VFM, RetinaFM, etc. (verify via paper-search).

# Splits — patient-level, locked at init

```python
# Wrong: stratified random split on slices/images
# Right: stratified random split on patient IDs, then expand to slices

from sklearn.model_selection import GroupShuffleSplit
splitter = GroupShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
train_idx, test_idx = next(splitter.split(X, y, groups=patient_ids))
```

Lock the test set at project init. Do not re-randomize splits during experiments. The hook in `.claude/hooks/test_set_guard.sh` will block test-set reads during selection/tuning phases.

# Feature fusion (clinical + imaging)

Three regimes work for small N:

1. **Late fusion of scores** (rad-research's canonical pattern):
   - Train clinical-only model → produces `clinical_score`
   - Train imaging-only model → produces `rad_score`
   - Train a small linear/logistic on `(clinical_score, rad_score)` → final
   - Pros: each component validates separately; small overfitting risk
   - Cons: may underfit if clinical and imaging interact strongly

2. **Mid fusion** (concatenate features):
   - Extract imaging features (e.g., from RadDINO penultimate layer)
   - Concatenate with normalized clinical features
   - Feed to a small MLP or TabPFN (TabPFNv2 handles up to ~10K rows × 500 features beautifully)
   - Pros: captures interactions; few hyperparameters
   - Cons: requires more samples

3. **Early fusion** — only viable with much larger samples (≥ 1k). Skip for small N.

# Models for small-sample tabular (clinical/molecular features)

In order:
1. **TabPFNv2** (Nature 2024) — best up to ~10K rows; needs no tuning; calibrated by default.
2. **Logistic regression with L1/L2** — interpretable; works at n=50.
3. **CatBoost / XGBoost / LightGBM** — strong if n ≥ 500 with categorical features.
4. **TabICL** (2025) — top median rank in tabular benchmarks; in-context.

Avoid deep neural nets for tabular small-sample. They lose to TabPFN consistently.

# Reporting — what's required

For a defensible small-N medical paper:

- **AUC** with **bootstrap 95% CI** (not just point estimate).
- **Sensitivity / Specificity** at a clinically motivated threshold (NOT the threshold that maximizes accuracy on test).
- **Calibration** — Brier score + reliability diagram.
- **DeLong's test** for AUC comparisons.
- **Confidence interval overlap** for accuracy/F1 comparisons.
- Honest **limits** section: small N, single-center, retrospective, label quality, calibration drift.

Use the `bootstrap-ci` and `delong-test` skills.

# Common failures to avoid

- **Slice-level splits leaking patients across train/test** (most common small-sample bug).
- **Selecting threshold on test set** (then reporting Sens/Spec at it).
- **Training on test labels through tabular features** (e.g., MRI volume measurements that were used as labels).
- **Reporting train AUC alongside test AUC without CI** — looks impressive, says nothing.
- **Switching to deep nets when boosted trees / TabPFN already work** — expensive, not better, harder to interpret.

# Reference implementations

- nnU-Net: https://github.com/MIC-DKFZ/nnUNet
- MONAI: https://monai.io
- RadDINO: https://huggingface.co/microsoft/rad-dino
- TabPFNv2: https://github.com/PriorLabs/TabPFN
- DeLong test: scipy + the `delong-test` script in `scripts/`
