# 03 — Project Structure

A research project is a directory. The directory is the unit of reproducibility, the unit of agent configuration, and the unit of distribution.

## Standard layout

```
my-research/
├── README.md                        # main entry point
│
├── .san/                            # San persona + agents/commands/hooks (the "brain")
│   ├── settings.json                # "persona": "ml-researcher" + permissions, env, merged hooks
│   ├── personas/
│   │   └── ml-researcher/           # the installed persona
│   │       ├── system/              # identity.md, behavior.md, rules.md
│   │       ├── skills/              # persona-scoped skills
│   │       └── settings.json        # persona overlay (description/skills/agents/permissions)
│   ├── agents/                      # the 6 subagents (+ project overrides, optional)
│   ├── commands/                    # the 6 slash commands (+ project additions, optional)
│   └── hooks/                       # methodology hook scripts
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
│   ├── trial_trace.md
│   └── progress.md
│
├── research/                        # filled-in records for this project
│   ├── progress.md                  # current phase, next step, blockers
│   ├── data_understanding.md
│   ├── research_goal.md
│   ├── model_selection.md
│   ├── fine_tuning.md
│   ├── trial_trace.md           # full experiment audit log
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
| `.san/` | San persona, agents, commands, and hooks scoped to this project (installed by `install.sh`) | human (rare); installer |
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
├── .san/settings.json
├── respec/                  # full templates
├── research/progress.md     # at least progress
├── data/README.md
├── experiments/README.md
└── results/README.md
```

`papers/`, individual `research/*.md`, and `experiments/EXPxxx/` directories are created on demand by the corresponding agents.

## Why `.san/` (and not a custom `.mlr/`)

The config directory is San's convention: `.san/` at project scope (or `~/.san/` at user scope). `install.sh` writes the persona, agents, commands, and hooks there. There is no `.mlr/` — ml-researcher rides on San rather than introducing a new runtime, so it reuses San's directory convention.

The persona prompt is delivered as the four-part system files `personas/ml-researcher/system/{identity,behavior,rules}.md` (San fills the fourth part, `environment`, at runtime) — not as a single `CLAUDE.md`/`GEN.md`/`AGENTS.md` memory file as in the pre-pivot design.
