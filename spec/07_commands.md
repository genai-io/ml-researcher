# 07 — Slash Commands

Built-in slash commands. Each is a markdown file in `internal/commands/<name>.md` embedded into the binary; projects may override or add commands via `.mlr/commands/`.

## Project lifecycle

### `/init research --topic <topic>`

Initialize a new research project in the current directory.

**Effects**:
- Creates `.mlr/`, `respec/`, `research/`, `data/`, `experiments/`, `results/`, `papers/`.
- Copies methodology templates into `respec/`.
- Creates a stub `research/progress.md` and `research/data_understanding.md` to fill in.
- Creates `README.md` with the topic.
- Initializes git if not already a repo.

**Idempotent**: re-running on an existing project shows a diff and asks before overwriting.

### `/phase`

Show the current L3 phase and the requirements to advance.

**Output**:
```
Current phase: Model Selection
Required to advance to Fine Tuning:
  ✓ research/research_goal.md filled
  ✓ research/model_selection.md has shortlist
  ✗ experiments/EXP001-baseline registered  ← BLOCKS
  ✓ Latest progress.md updated within last 24h
```

### `/phase advance`

Attempt to advance to the next phase. Blocks with the same checklist if requirements are missing.

## Experimentation

### `/exp new <name>`

Register a new experiment. Calls `experiment_register` and creates a clean `train.py` from the parent experiment (or template if first).

### `/exp run [<exp_id>] [--budget <duration>]`

Run a single experiment. Defaults to the current branch's experiment if `exp_id` omitted.

### `/exp loop --metric <name> [--budget <per_run>] [--max-iter <n>]`

Start an L1 autoresearch-style loop. Spawns `experimenter` agent.

**Options**:
- `--metric` (required): primary metric name to optimize (lower-is-better unless suffixed with `:max`).
- `--budget`: per-run wall-clock budget. Default from `.mlr/settings.json`.
- `--max-iter`: optional iteration cap. Default unbounded (loop until interrupt).
- `--never-stop`: enforce autoresearch's "do not pause to ask" mode (default true for loop).

### `/exp list`

Show experiments with current status from `ledger.tsv`.

### `/exp compare <id1> <id2> [<id3>...] [--metric <name>]`

Multi-experiment comparison with bootstrap CIs and optional DeLong test.

## Literature

### `/lit search <query> [--year-min <yyyy>]`

Spawn `literature` agent to search and append to `papers/shortlist.md`.

### `/lit shortlist`

Show current `papers/shortlist.md`.

### `/lit read <paper_id>`

Fetch and add a per-paper note in `papers/notes/<paper_id>.md`.

## Reporting

### `/report draft`

Spawn `analyst` to draft `research/analysis_report.md` based on latest experiments.

### `/report finalize`

Promote selected experiment artifacts into `results/` and update root `README.md` with current best.

## Methodology

### `/checklist [<kind>]`

Run a pre-flight checklist. `kind` defaults to inferring from current state.

### `/critic [<scope>]`

Invoke the `critic` agent for an on-demand methodology audit. `scope` defaults to "current best experiment + latest progress".

## Project info

### `/state`

One-screen summary: phase, current best, recent experiments, blockers from `progress.md`.

### `/resume`

Read recovery files in order (root `README.md` → `progress.md` → `iteration_trace.md`) and report a "what to do next" plan. Used at the start of a session.

## Inheritance from gen-code

All gen-code built-in commands remain available unless explicitly disabled in `.mlr/commands/disabled.txt`.

## Custom commands

Projects can add commands in `.mlr/commands/<name>.md`. Each file is a markdown with optional YAML frontmatter:

```markdown
---
name: gbm-feature-extract
description: Extract radiomics features for the GBM cohort
arguments:
  - name: image_set
    enum: [t1c, t2, both]
---

Run the radiomics feature extraction pipeline:

```bash
python scripts/rad_pipeline.py extract --image-types Original --image-set $image_set
```

Verify output exists in `analysis/features/`.
```
