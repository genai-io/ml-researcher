# Ledger schema — full column documentation

`experiments/ledger.tsv` columns, tab-separated:

| Column | Type | Notes |
|---|---|---|
| `exp_id` | string | e.g., `EXP003_combined-linear-svm` |
| `commit` | string | short sha of the trial's commit (or `"—"` for register / crash before commit) |
| `primary_metric` | string | name of the primary metric, e.g., `val_auc` |
| `metric_value` | float or `"—"` | the metric on this trial; `"—"` if crash |
| `status` | enum | `registered` \| `keep` \| `discard` \| `crash` |
| `description` | string | one-line summary of what changed in this trial |
| `secondary_metrics_json` | string | JSON dict of secondary metrics; `"{}"` if none |

## Status meanings

| Status | When | Effect |
|---|---|---|
| `registered` | At `/exp new` time | Row exists but no trial run yet |
| `keep` | After a trial improved the primary metric | The commit advances the experiment branch |
| `discard` | After a trial equal-or-worse than parent | Branch resets to parent |
| `crash` | After a trial errored out | Branch resets to parent; trial reason recorded in description |

## Examples

```
exp_id	commit	primary_metric	metric_value	status	description	secondary_metrics_json
EXP001_baseline	—	val_auc	—	registered	Logistic regression on clinical features only	{}
EXP001_baseline	a3f1b2c	val_auc	0.661	keep	Initial baseline; logistic + L2; seed=42	{"brier": 0.221, "duration_seconds": 8}
EXP002_radiomics-l2	b1c2d3e	val_auc	0.683	keep	Added 80 selected radiomics features	{"brier": 0.205, "duration_seconds": 124}
EXP002_radiomics-l2	c4d5e6f	val_auc	0.671	discard	Tried RBF SVM; worse than linear; reverting	{}
EXP002_radiomics-l2	—	val_auc	—	crash	OOM at step 5 with bs=64; should drop to bs=16	{}
```

## Why TSV and not CSV / JSON

- TSV survives shell pipelines (`cut -f`, `grep`, `awk`) without quoting headaches.
- Append-only writes are atomic line writes.
- Spreadsheet apps still open it.
- JSON-encoded `secondary_metrics_json` gives structure to the variable-shape column without inflating the schema.
