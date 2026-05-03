# 06 — ML Tools

ml-researcher inherits the full gen-code tool set (`Read`, `Write`, `Edit`, `Bash`, `Glob`, `Grep`, `Agent`, `WebFetch`, `WebSearch`, etc.) and adds ML-domain tools below. Each tool is registered at startup in `cmd/mlr/main.go` and lives under `internal/ml/`.

## Literature

### `paper_search`

Search papers across HF Papers, arxiv, and Semantic Scholar.

**Inputs**: `query` (string, required), `year_min` (int), `limit` (int, default 10), `source` (one of `hf|arxiv|s2|all`, default `all`).

**Output**: list of `{paper_id, title, authors, year, abstract, source, url}`.

### `paper_read`

Fetch the body of a paper as markdown. Prefers ar5iv → arxiv HTML → arxiv PDF (last resort).

**Inputs**: `paper_id` (string), `sections` (optional list, default `["methodology", "experiments", "results"]` — abstract is intentionally not default).

**Output**: markdown content of requested sections, with figure/table references preserved.

### `citation_graph`

Traverse the citation graph from a seed paper.

**Inputs**: `seed_paper_id`, `direction` (`in|out|both`, default `out`), `depth` (int, default 1), `limit` (int, default 50).

**Output**: list of papers with citation context.

### `dataset_inspect`

Inspect a dataset's schema and basic stats. Supports HF Hub datasets and local files (csv, parquet, jsonl, image folders).

**Inputs**: `path_or_id`, `n_sample` (default 5).

**Output**: schema, row count, column types, missingness, sample rows, label distribution if a label column is declared.

## Experiment

### `experiment_register`

Create a new experiment under `experiments/EXPxxx_<name>/` and a corresponding git branch `mlr/exp/<id>`.

**Inputs**: `name` (short slug), `motivation` (free text), `parent_exp` (optional, defaults to current best).

**Output**: assigned experiment ID, paths created.

### `experiment_run`

Execute the experiment's `train.py` (or configured entry point) with output redirection and timeout.

**Inputs**: `exp_id`, `budget` (e.g. `5min`, `1h`, default project setting), `entry` (default `train.py`), `env` (extra environment vars).

**Output**: exit status, log path, wall-clock duration.

**Behavior**: stdout/stderr redirected to `experiments/EXPxxx/run.log`; never to the agent's tool result. The agent uses `metric_grep` afterwards to read what it needs.

### `metric_grep`

Extract metric lines from `run.log` with strict format.

**Inputs**: `exp_id`, `keys` (list of metric names, e.g. `["val_auc", "peak_vram_mb"]`).

**Output**: dict of `{key: value}` or empty if not found.

**Format contract**: the experiment's `train.py` must print metrics on lines starting with `<key>:` (e.g., `val_auc: 0.715`). This is enforced by the `experimenter` system prompt.

### `git_keep_or_reset`

Advance or reset the experiment branch based on the latest decision.

**Inputs**: `decision` (`keep|reset|crash`).

**Behavior**:
- `keep`: leave the latest commit; the branch advances.
- `reset`: `git reset --hard HEAD~1` on the experiment branch.
- `crash`: leave the commit but mark the run as crashed in the ledger.

### `ledger_append`

Append a row to `experiments/ledger.tsv`.

**Columns** (tab-separated):
```
exp_id  commit  primary_metric  metric_value  status  description
```

**Inputs**: all column values, plus optional secondary metrics as JSON in a final column.

## Methodology

### `phase_advance`

Advance the L3 lifecycle phase. Blocks if the gate's required records are missing (see [`04_methodology.md`](04_methodology.md) and [`08_hooks.md`](08_hooks.md)).

**Inputs**: `target_phase` (one of the 6 phases).

**Output**: success or list of missing requirements.

### `iteration_log`

Append an entry to `research/iteration_trace.md` with structured fields.

**Inputs**: `exp_id`, `motivation`, `change_summary`, `data_version`, `parameters` (dict), `result` (free text), `decision` (`accept|reject`), `next_step`.

### `checklist_verify`

Run pre-flight checks. Used as a manual or hook-triggered tool.

**Inputs**: `kind` (one of `pre_experiment`, `pre_phase_advance`, `pre_finalize`).

**Output**: list of `{check, passed, detail}`.

Pre-experiment checks (drawn from ml-intern):
- Dataset format matches training method
- `push_to_hub`/equivalent set if persisting
- Timeout justified vs estimated runtime
- Reference implementation cited
- Monitoring configured

### `bootstrap_ci`

Bootstrap confidence interval for a metric.

**Inputs**: `predictions` (array), `labels` (array), `metric` (e.g., `auc`, `accuracy`, `f1`), `n_iter` (default 1000), `alpha` (default 0.05).

**Output**: `{point, low, high, n_iter}`.

### `delong_test`

DeLong test for paired AUC comparison.

**Inputs**: `preds_a`, `preds_b`, `labels`.

**Output**: `{auc_a, auc_b, z, p}`.

### `figure_render`

Render a figure via a small Python helper script and write to `results/figures/` or `experiments/EXPxxx/figures/`.

**Inputs**: `kind` (`roc`, `calibration`, `confusion`, `learning_curve`, `comparison_bar`, ...), `data` (path or inline), `out_path`.

## Monitoring

### `train_monitor`

Stream-read `run.log` of a running experiment, classify lines, surface alerts.

**Inputs**: `exp_id`, `since` (timestamp or line offset), `signals` (default `["divergence", "overfitting", "oom", "nan"]`).

**Output**: list of `{ts, signal, line, severity}`.

Detection rules (drawn from ml-intern v3 prompt):
- divergence: loss increase > 2× over last N steps
- overfitting: train_metric improving while val_metric degrading
- oom: stderr contains `CUDA out of memory` / equivalent
- nan: any metric line with `nan` / `inf`

### `oom_recover`

Suggest the next OOM mitigation step. Implements the ml-intern ladder prescriptively:

1. Reduce `per_device_train_batch_size`, increase `gradient_accumulation_steps` proportionally.
2. Enable `gradient_checkpointing=True`.
3. Move to a larger GPU tier.

**Inputs**: `current_config` (dict), `attempt_history` (list of prior tries).

**Output**: `{recommended_change, justification}`. Rejects scope-changing fixes (e.g. SFT → LoRA) per the ml-intern rule.

## Tool permission classes (default)

| Tool | Default permission |
|---|---|
| `paper_search`, `paper_read`, `citation_graph`, `dataset_inspect` | auto-allow (read-only) |
| `experiment_register`, `experiment_run`, `metric_grep`, `ledger_append`, `iteration_log` | auto-allow (project-scoped) |
| `git_keep_or_reset`, `phase_advance` | ask (state-mutating) |
| `Write` to `data/raw/**` | hard-deny via hook |
| `Write` to `data/splits/test/**` during phases ∈ {Selection, Tuning} | hard-deny via hook |
| `figure_render`, `bootstrap_ci`, `delong_test` | auto-allow |
| `train_monitor`, `oom_recover` | auto-allow (read-only / advisory) |
