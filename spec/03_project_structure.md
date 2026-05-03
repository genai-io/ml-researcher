# 03 — Project Structure

A research project is a directory. The directory is the unit of reproducibility, the unit of agent configuration, and the unit of distribution.

## Standard layout

```
my-research/
├── README.md                        # main entry point
│
├── .mlr/                            # project agent config
│   ├── settings.json                # permissions, env, hooks
│   ├── agents/                      # project-specific agent overrides (optional)
│   ├── commands/                    # project-specific slash commands (optional)
│   ├── mcp.json                     # project MCP servers (optional)
│   └── playbook.md                  # domain-specific decisions, rationale, conventions
│
├── respec/                          # methodology templates (copied at init)
│   ├── README.md
│   ├── respec.md                    # lifecycle + principles
│   ├── init.md                      # initialization protocol
│   ├── 01_data_understanding.md
│   ├── 02_research_goal.md
│   ├── 03_model_selection.md
│   ├── 04_fine_tuning.md
│   ├── 05_analysis_report.md
│   ├── iteration_trace.md
│   └── progress.md
│
├── research/                        # filled-in records for this project
│   ├── progress.md                  # current phase, next step, blockers
│   ├── data_understanding.md
│   ├── research_goal.md
│   ├── model_selection.md
│   ├── fine_tuning.md
│   ├── iteration_trace.md           # full experiment audit log
│   └── analysis_report.md
│
├── data/
│   ├── README.md                    # data contract: what's here, how to update
│   ├── raw/                         # immutable; protected by hook
│   ├── derived/                     # cleaned, encoded, feature-extracted
│   └── splits/                      # train/val/test (test set locked)
│
├── experiments/
│   ├── README.md
│   ├── ledger.tsv                   # machine-readable run log
│   └── EXP001_<short-name>/
│       ├── README.md
│       ├── config.yaml
│       ├── train.py                 # the editable file (autoresearch convention)
│       ├── run.log
│       ├── metrics.json
│       ├── figures/
│       └── artifacts/
│
├── results/                         # conclusion-grade artifacts
│   ├── README.md
│   ├── figures/
│   ├── tables/
│   └── reports/
│
└── papers/
    ├── README.md
    ├── shortlist.md                 # papers under active consideration
    └── notes/
        └── <paper_id>.md            # per-paper notes
```

## Directory semantics

| Directory | What lives here | Who writes |
|---|---|---|
| `README.md` | Project entry, current state, key results, navigation | agent + human |
| `.mlr/` | Agent configuration scoped to this project | human (rare); agent (during init) |
| `respec/` | Methodology templates; do not fill with project results | template; copied at init |
| `research/` | Project-instantiated methodology records | agent + human |
| `data/raw/` | Original data; never modified | human; protected by hook |
| `data/derived/` | Cleaned/processed datasets | scripts; agent |
| `data/splits/` | Locked train/val/test partitions | scripts at init; never re-randomized |
| `experiments/` | One subdir per experiment with full reproduction artifacts | agent (experimenter) |
| `experiments/ledger.tsv` | Append-only TSV: commit, metric, status, description | agent (ledger_append tool) |
| `results/` | Curated subset of experiment outputs adopted as conclusions | agent (analyst) |
| `papers/` | Literature shortlist and reading notes | agent (literature) |

## File-level invariants

These are enforced by hooks (see [`08_hooks.md`](08_hooks.md)):

| Invariant | Enforcement |
|---|---|
| `data/raw/` is immutable after init | `PreToolUse` hook on `Write`/`Edit` blocks any path under `data/raw/` |
| `data/splits/test/*` is read-only during selection/tuning | `PreToolUse` hook checks active phase; blocks if phase ∈ {Selection, Tuning} |
| Every experiment has a `README.md` | `PostToolUse` on `experiment_register` verifies file exists |
| `ledger.tsv` columns are stable | `PostToolUse` on `ledger_append` validates header |
| `progress.md` updated when phase advances | `PostToolUse` on `phase_advance` checks file mtime |

## Minimal viable project

Not every directory is required at init. The minimum is:

```
my-research/
├── README.md
├── .mlr/settings.json
├── respec/                  # full templates
├── research/progress.md     # at least progress
├── data/README.md
├── experiments/README.md
└── results/README.md
```

`papers/`, individual `research/*.md`, and `experiments/EXPxxx/` directories are created on demand by the corresponding agents.

## Why `.mlr/` and not `.gen/`

ml-researcher's binary loader is configured to read `.mlr/` as the project config root. This avoids confusion when both `mlr` and `gen` are installed and a user runs the wrong one in the wrong directory. The internal config schema is identical to `.gen/` — only the directory name differs.

A future `mlr` may also accept `.gen/` as a fallback if `.mlr/` is absent, to ease migration. This is not part of v0.1.
