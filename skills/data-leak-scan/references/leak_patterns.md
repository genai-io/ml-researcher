# Data-leakage patterns — what the scanner looks for

## 1. Group leakage (most common)

**Symptom**: the same logical entity (patient, session, device, household) appears in both train and test splits.

**How the scanner detects**:
- Read `--groups <col>` from the features file.
- Intersect the set of groups in train with the set in test.
- If intersection is non-empty → BLOCK.

**Why it matters**: a single patient often contributes many samples (slices, sessions, augmented views). Random row-level splitting puts the *same patient* in both train and test; the model memorizes patient-specific signal and posts artificially high test metrics.

**Typical fix**: re-do splits with `GroupShuffleSplit(groups=patient_ids)` (see `medical-small-sample-transfer/references/splits.md`). Re-lock the splits via `init.sh`.

## 2. Temporal leakage

**Symptom**: train samples have timestamps *after* the earliest test sample's timestamp.

**How the scanner detects**:
- Read `--timestamp <col>`.
- For each split pair (train→test, train→val): find `max(train_timestamp)` and `min(test_timestamp)`.
- If `max(train) ≥ min(test)` → BLOCK (with overlap days reported).

**Why it matters**: when the task has temporal structure (disease progression, market data, sensor drift), training on the future predicts the past — but deployment runs forward in time. Random splitting gives an unrealistically optimistic estimate.

**Typical fix**: use `TimeSeriesSplit` instead of random; or define a strict train-cutoff date and force all test samples to be after it.

## 3. Proxy-label leakage

**Symptom**: a feature was computed using the label (or a near-tautology of the label).

**How the scanner detects**:
- Requires `--label-derivation-rules <path>` — a YAML mapping feature names to their derivation sources.
- For each feature, if any of its derivation sources include the label column → BLOCK with the suspect feature name.
- Without the rules file, this scan is *skipped* and reported as `"skipped"`, not silently passed.

Example rules file:

```yaml
features:
  tumor_volume_ml:
    derived_from: [mri_segmentation]
  tumor_grade_predicted:
    derived_from: [pathology_label]    # ← pathology_label IS the target → leak
  age_at_scan:
    derived_from: [acquisition_date, birth_date]
```

**Why it matters**: a model that "predicts" tumor grade from a feature that was computed from tumor grade is a tautology. Posting AUC=0.95 from this is meaningless.

**Typical fix**: re-derive the suspect feature using only sources that are present at inference time, OR drop the feature entirely. Document the change in `trial_trace.md`.

## 4. Split-rederivation leakage

**Symptom**: `data/splits/MANIFEST.json` (or the split CSV files) was modified after the initial `init.sh` lock.

**How the scanner detects**:
- Compare the manifest's stored hashes against the actual file checksums.
- If any split file's checksum differs → BLOCK.

**Why it matters**: re-randomizing splits during the project lets the user (consciously or not) re-roll until the test set looks favorable. The lock at init prevents this — but only if it's enforced.

**Typical fix**: investigate WHY the splits changed. If legitimate (new data arrived), call `init.sh --relock` to record the new state — but understand that any prior experiment is now incomparable. If illegitimate, restore the splits from git history.

## What the scanner does NOT catch

These leak patterns require domain knowledge the scanner lacks:

- **Information leakage through preprocessing**: normalizing features using train+test statistics together. Use the same train-fit transformer for test, never re-fit.
- **Identifier leakage through scanner / site / cohort**: not a group leak per se, but if all samples from one scanner are the same label, the model learns the scanner. Use stratification on scanner during split design.
- **Label propagation through nearest-neighbor or self-training**: if your test "labels" came from a model that was trained on something similar to your train set, the evaluation is circular.

These three require manual review — there's no purely mechanical detector.
