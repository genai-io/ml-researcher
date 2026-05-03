---
name: ledger-append
description: Append a row to experiments/ledger.tsv with the current experiment's metric, status, and one-line description. The TSV is the project's machine-readable history.
allowed-tools: Bash, Read
---

# Schema

`experiments/ledger.tsv` has these columns (tab-separated):

```
exp_id    commit    primary_metric    metric_value    status    description    secondary_metrics_json
```

| Column | Type | Notes |
|---|---|---|
| `exp_id` | string | e.g., `EXP003_combined-linear-svm` |
| `commit` | string | short sha of the iteration's commit (or "—" for register/crash before commit) |
| `primary_metric` | string | name of the primary metric, e.g., `val_auc` |
| `metric_value` | float or "—" | the metric on this iteration; "—" if crash |
| `status` | string | `registered` \| `keep` \| `discard` \| `crash` |
| `description` | string | one-line summary of what changed in this iteration |
| `secondary_metrics_json` | string | JSON dict of secondary metrics; "{}" if none |

# Steps

1. Determine the row values from current state:
   - `exp_id` from current branch name (`git branch --show-current` → strip `mlr/exp/`)
   - `commit` from `git rev-parse --short HEAD` (or "—")
   - `primary_metric` from `research/research_goal.md` or skill argument
   - `metric_value` from `metric-grep` output
   - `status` from skill argument
   - `description` from skill argument
   - `secondary_metrics_json` JSON-encoded dict of secondary metrics (or `{}`)

2. Verify `experiments/ledger.tsv` exists. If not, create it with the header row.

3. Append the row, **tab-separated**, with newline.

   ```bash
   printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
     "$exp_id" "$commit" "$primary_metric" "$metric_value" "$status" "$description" "$secondary_metrics_json" \
     >> experiments/ledger.tsv
   ```

4. **Do not commit ledger.tsv**. It's deliberately untracked (or in `.gitignore`) so each iteration doesn't pollute the experiment branch's git history. If the user wants ledger versioning, they can `git add` periodically.

# Header

If creating the file:

```
exp_id	commit	primary_metric	metric_value	status	description	secondary_metrics_json
```

Note the literal tabs.

# Description discipline

The description should answer "what changed in this iteration?" in one line. Examples:

- `"Lowered LR to 5e-5 from 1e-4"`
- `"Added gradient checkpointing to fit batch=32 on A10G"`
- `"Switched to RBF SVM from logistic; AUC 0.65 → 0.72"`
- `"Combined clinical+rad scores via linear SVM"`
- `"Discarded — test AUC dropped despite higher train AUC (overfit)"`

NOT:
- `"Changed train.py"` (uninformative)
- `"Fixed bug"` (what bug?)
- a multi-line paragraph (this is a TSV row)
