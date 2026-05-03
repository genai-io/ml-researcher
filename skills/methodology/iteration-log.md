---
name: iteration-log
description: Append a structured entry to research/iteration_trace.md with motivation, change diff, parameters, results, decision, and next step. Used after every meaningful experiment.
allowed-tools: Read, Edit
---

# Entry format

Each entry is a section in `research/iteration_trace.md`:

```markdown
## EXP<id>_<name> — <date>

- **Motivation**: <why this experiment was run, in one sentence>
- **Change from parent (`<parent_exp>`)**: <one or two sentences describing the diff>
- **Data version**: <hash or path of the dataset version used>
- **Key parameters**: <model, lr, batch, optimizer, seed, ...>
- **Results**:
  - val_<metric>: <value> (CI: <low>, <high>)
  - test_<metric>: <value> (only if Analysis phase)
  - secondary: <key-value pairs>
- **Decision**: <accept | reject | needs-more-runs>
- **Reason**: <one sentence>
- **Next step**: <what's the next experiment OR "stop this direction">
```

# Steps

1. Read `research/iteration_trace.md`. If absent, create it with a header:
   ```markdown
   # Iteration Trace

   Append-only audit log of every meaningful experiment. Entries are reverse-chronological (newest at top? — choose the convention). Source of truth for "why was X done?".
   ```

2. Build the entry from inputs:
   - `exp_id`, `name`, `date` — required
   - `motivation` — required
   - `change_summary` — required, ≤ 2 sentences
   - `parent_exp` — required (or "none" for baseline)
   - `data_version` — required; record the git hash of `data/` or the manifest file path
   - `key_parameters` — at minimum: model name, lr, batch size, optimizer, random seed
   - `results` — primary metric (with CI if computed), secondary metrics if any
   - `decision` — `accept` / `reject` / `needs-more-runs`
   - `reason` — required, one sentence
   - `next_step` — required

3. Append the entry to the top of the existing file (after the header). New entries first, oldest last.

4. Verify the entry was added by reading the first 50 lines back.

# Discipline

- Every meaningful experiment gets an entry. "Meaningful" = registered + run + decided. Crashes-only without a decision can be skipped.
- Be honest about negative results. "Tried wavelet features; AUC dropped 0.05; stop this direction" is more valuable than silence.
- Cite the experiment ID in any other document that references this entry — the iteration trace is the audit source.

# Example

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
