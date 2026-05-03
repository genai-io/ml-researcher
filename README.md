# ML Researcher

<p align="center">
  <h1 align="center">< ML ✦ /></h1>
  <p align="center">
    <strong>Disciplined ML research and engineering, in your terminal.</strong>
  </p>
  <p align="center">
    <a href="https://github.com/genai-io/ml-researcher/releases"><img src="https://img.shields.io/github/v/release/genai-io/ml-researcher?style=flat-square" alt="Release"></a>
    <a href="https://goreportcard.com/report/github.com/genai-io/ml-researcher"><img src="https://goreportcard.com/badge/github.com/genai-io/ml-researcher?style=flat-square" alt="Go Report Card"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" alt="License"></a>
  </p>
</p>

`mlr` is a terminal AI agent purpose-built for machine learning research and engineering. It combines a rigorous research methodology, ML-domain tools, and overnight-grade automation — all anchored to a single project directory.

> **Status**: v0.1 spec phase. Implementation pending. See [`spec/`](spec/) for the project specification.

## Why

ML research suffers from two opposite failure modes:

- **Loose loops** — running experiments without an audit trail, picking the best test-set number, drifting away from the original goal.
- **Stiff frameworks** — drowning in MLOps boilerplate that doesn't help you actually answer the research question.

`mlr` is opinionated about discipline, but minimal about infrastructure. It encodes a three-layer loop model:

```
┌─────────────────────────────────────────────────────────────┐
│  L3 · Lifecycle Loop      (days/weeks)                      │
│   Data → Goal → Selection → Tuning → Report → Revision      │
├─────────────────────────────────────────────────────────────┤
│  L2 · Experiment Loop     (hours)                           │
│   Plan → Research → Sandbox → Submit → Monitor → Decide     │
├─────────────────────────────────────────────────────────────┤
│  L1 · Iteration Loop      (minutes)                         │
│   Edit → Run → Measure → Keep or Reset                      │
└─────────────────────────────────────────────────────────────┘
```

The agent always knows which loop it is in, and applies the corresponding discipline.

## Influences

`mlr` distills the essence of three projects:

| Source | What we take |
|---|---|
| [rad-research](https://github.com/yanmxa/rad-research) (methodology) | Lifecycle stages, `respec/` templates, iteration trace, progress records, methodology guardrails (test-set isolation, baseline mandatory, simple-first) |
| [huggingface/ml-intern](https://github.com/huggingface/ml-intern) (tools) | Paper search with citation graph, dataset inspection, pre-flight checklists, OOM recovery prescriptions, monitoring discipline |
| [karpathy/autoresearch](https://github.com/karpathy/autoresearch) (loop) | Single-file edit + git-as-ledger + TSV experiment log + fixed budget per run + never-stop autonomous mode |

## Project-Centric, Not User-Centric

Each research project is a single directory. **All configuration lives in the project**; there is no user-level (`~/.mlr/`) configuration. This is an intentional design choice:

- A research project is a sealed scientific record. Its inputs, methods, and outputs must be reproducible from the directory alone.
- No global state means no cross-contamination between projects.
- Cloning a research project is the same as cloning its agent configuration.

```
my-research/
├── README.md                  # project entry point
├── .mlr/                      # project-level agent config
├── respec/                    # methodology templates
├── research/                  # filled-in research records
├── data/                      # datasets (raw is immutable)
├── experiments/               # experiment artifacts + ledger.tsv
├── results/                   # final figures, tables, reports
└── papers/                    # literature shortlist + notes
```

## Built-in Agents

| Agent | Role |
|:------|:-----|
| **navigator** | Identifies the active loop layer and dispatches to specialists |
| **literature** | Paper search, citation-graph traversal, dataset discovery |
| **experimenter** | Runs the L1 edit-run-measure-keep loop |
| **analyst** | Produces analysis reports, statistical comparisons, figures |
| **critic** | Enforces methodology guardrails (no leakage, baseline present, test set locked) |

## Built-in Tools (beyond `gen-code` core)

- **Literature**: `paper_search`, `paper_read`, `citation_graph`, `dataset_inspect`
- **Experiment**: `experiment_register`, `experiment_run`, `metric_grep`, `git_keep_or_reset`, `ledger_append`
- **Methodology**: `phase_advance`, `iteration_log`, `checklist_verify`, `bootstrap_ci`, `delong_test`
- **Monitoring**: `train_monitor`, `oom_recover`

## Architecture

`mlr` is built on top of [`gen-code`](https://github.com/genai-io/gen-code) (Go, Bubble Tea TUI), included as a git submodule and compiled with the `nouserconfig` build tag. ML-specific tools, agents, and prompts live in this repo.

See [`spec/02_architecture.md`](spec/02_architecture.md) for details on the build and sync strategy.

## Installation

> Not yet published. The build path below assumes M1–M2 milestones are complete.

```bash
git clone --recurse-submodules https://github.com/genai-io/ml-researcher.git
cd ml-researcher
make build
./bin/mlr
```

## Usage

```bash
# Start a new research project
mkdir my-study && cd my-study
mlr init research --topic "tumor purity prediction from MRI"

# Open the TUI in an existing project
cd my-study
mlr

# Inside the TUI:
> /phase                                    # show current lifecycle stage
> /lit search "small-sample radiomics"      # literature triage
> /exp new baseline-logistic                # register a new experiment
> /exp loop --metric val_auc --budget 5min  # start an L1 loop
> /report                                   # draft analysis report
```

## Specification

Full project spec lives in [`spec/`](spec/):

- [`01_overview.md`](spec/01_overview.md) — Philosophy and the three-layer loop model
- [`02_architecture.md`](spec/02_architecture.md) — Relationship to `gen-code`, build & sync strategy
- [`03_project_structure.md`](spec/03_project_structure.md) — Research project directory layout
- [`04_methodology.md`](spec/04_methodology.md) — Lifecycle stages, records, guardrails
- [`05_agents.md`](spec/05_agents.md) — Built-in agents and their tool subsets
- [`06_tools.md`](spec/06_tools.md) — ML-specific tools
- [`07_commands.md`](spec/07_commands.md) — Slash commands
- [`08_hooks.md`](spec/08_hooks.md) — Methodology enforcement via hooks
- [`09_build.md`](spec/09_build.md) — Build tag strategy and submodule pinning
- [`10_milestones.md`](spec/10_milestones.md) — v0.1 implementation roadmap

## Related Projects

- [genai-io/gen-code](https://github.com/genai-io/gen-code) — Base agent (Go, terminal-native)
- [genai-io/spec](https://github.com/genai-io/spec) — GenX multi-agent system specification
- [genai-io/orchestrator](https://github.com/genai-io/orchestrator) — Agent lifecycle and coordination

## License

Apache License 2.0 — see [LICENSE](LICENSE).
