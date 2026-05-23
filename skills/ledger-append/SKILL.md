---
name: ledger-append
description: Append a row to experiments/ledger.tsv with the current experiment's metric, status, and one-line description. The TSV is the project's machine-readable history. Schema and description examples in references/.
allowed-tools: Bash Read
---

# Schema (compact)

```
exp_id    commit    primary_metric    metric_value    status    description    secondary_metrics_json
```

Tab-separated. Status ∈ `registered | keep | discard | crash`. Full column documentation: `references/schema_detail.md`.

# Steps

1. Determine row values from current state:
   - `exp_id` from current branch (`git branch --show-current` → strip `mlr/exp/`)
   - `commit` from `git rev-parse --short HEAD` (or `"—"` for register/crash before commit)
   - `primary_metric` from `research/research_goal.md` or skill argument
   - `metric_value` from `metric-grep` output
   - `status` from skill argument
   - `description` from skill argument
   - `secondary_metrics_json` JSON-encoded dict of secondary metrics (or `{}`)

2. **Verify `experiments/ledger.tsv` exists.** If not, create it with the header row:

   ```
   exp_id	commit	primary_metric	metric_value	status	description	secondary_metrics_json
   ```

3. **Append the row**, tab-separated:

   ```bash
   printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
     "$exp_id" "$commit" "$primary_metric" "$metric_value" "$status" "$description" "$secondary_metrics_json" \
     >> experiments/ledger.tsv
   ```

4. **Do not commit ledger.tsv.** It's deliberately untracked (or in `.gitignore`) so each trial doesn't pollute the experiment branch's git history. The user can `git add` periodically if they want versioning.

# Description discipline

The description answers "what changed in this trial?" in one line. Good and bad examples: `references/description_examples.md`.

# Hard rules

- One row per trial. Never edit existing rows; append corrections as new rows.
- Tab-separated, literal tabs. Spaces will break downstream parsers.
- `secondary_metrics_json` must be valid JSON — use `{}` if empty, never an empty string.

# Related

Pairs with [[trial-log]] (human-readable companion). The `experimenter` agent calls ledger-append after each `metric-grep` to record the trial's outcome.
