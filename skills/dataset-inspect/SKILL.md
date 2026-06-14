---
name: dataset-inspect
description: Inspect a dataset's schema, size, label distribution, missingness, and split protocol before recommending models or starting an experiment. Wraps scripts/dataset_inspect.py. Spawn whenever you're about to use a dataset you haven't profiled yet, or whenever modeler/literature needs to verify a candidate dataset's fit.
allowed-tools: Bash Read
---

# When to use

- Before `model-recommend`: modeler needs `min_data.fine_tune <= n_samples` and modality match.
- Before any new `exp-register` if the dataset path differs from the project's default `data/derived/`.
- When literature recommends a public dataset (HF Hub, paperswithcode) and you need to verify schema/license before adding it to `papers/shortlist.md`.

Do NOT use for the test split during selection/tuning phases — the hook will block test-set reads. Run dataset-inspect on train/val only until Analysis phase.

# Steps

1. **Identify the dataset target**. One of:
   - A local path: `data/raw/<name>/`, `data/derived/<name>.parquet`, or a manifest CSV
   - A HF Hub id: `org/dataset` (the script handles `datasets.load_dataset` lazily)
   - A directory of images + a label CSV (pass both)

2. **Pick the scope**. Default is `summary`. Use `--full` only when you need column-by-column distributions.

3. **Invoke**:

   ```bash
   python scripts/dataset_inspect.py \
     --target data/derived/clean.parquet \
     --groups patient_id \
     --label label \
     --scope summary
   ```

4. **The script prints one JSON object** to stdout, plus optional warnings to stderr:

   ```json
   {
     "n_rows": 270,
     "n_cols": 42,
     "modality": "tabular",
     "label_distribution": {"0": 168, "1": 102},
     "missingness": {"age": 0.0, "gleason": 0.04},
     "group_unit": "patient_id",
     "n_groups": 270,
     "splits_detected": ["train", "val"],
     "test_split_present": true,
     "test_split_locked": true,
     "schema_warnings": [],
     "license": "unknown"
   }
   ```

5. **Surface the summary to the agent**, plus any `schema_warnings`. Don't dump the JSON wholesale — pick the 3-5 fields relevant to the caller's question.

6. **If `test_split_locked` is false** and the phase is `Model Selection` or `Fine Tuning`, flag the issue and recommend re-locking the splits (re-record `data/splits/MANIFEST.json`) before any experiment.

# Hard rules

- Never read `data/splits/test/**` directly. The script's `test_split_locked` check uses file existence + checksum, not content.
- Never recompute splits as a side effect. The script is read-only.
- Default `--scope summary`. `--scope full` can dump per-column histograms; only use when the caller explicitly asks for distribution detail.
- If the dataset is on HF Hub and not cached locally, the script may fetch metadata only (no full download) unless `--download` is passed. Don't pass `--download` from this skill.

# Script contract

`scripts/dataset_inspect.py` accepts:

| Flag | Meaning | Default |
|---|---|---|
| `--target <path-or-hub-id>` | dataset path or `org/dataset` | required |
| `--label <col>` | label column name (CSV/parquet) | inferred |
| `--groups <col>` | group key for patient/session-level splits | none |
| `--scope <summary\|full>` | inspection depth | `summary` |
| `--download` | allow remote fetch | false |
| `--seed <n>` | RNG seed for sampled distributions | 42 |

Output: one JSON object on stdout. Schema warnings on stderr (one per line, prefixed `WARN:`).

Exit codes: `0` success, `2` schema violation (missing label column, ambiguous splits), `3` access denied (license / EULA).

# Related skills

See [[medical-small-sample-transfer]] for the "patient-level split" rule that this skill verifies via `--groups`. See [[model-recommend]] which depends on dataset-inspect's `modality` and `n_rows` outputs.
