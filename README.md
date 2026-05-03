# ML Researcher

<p align="center">
  <h1 align="center">< ML ✦ /></h1>
  <p align="center">
    <strong>Disciplined ML research and engineering, in your terminal.</strong>
  </p>
  <p align="center">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" alt="License"></a>
    <a href="spec/"><img src="https://img.shields.io/badge/status-v0.1%20spec-orange?style=flat-square" alt="Status"></a>
  </p>
</p>

ml-researcher is a methodology + agent toolkit for machine learning research projects. It bootstraps a self-contained research project directory pre-loaded with subagents, skills, slash commands, hooks, an ML model registry, and methodology templates — all driven by Claude Code, gen-code, or Codex.

> **Status**: v0.1 — content under construction. Spec is locked in [`spec/`](spec/).

## Two commands, end-to-end

```bash
# 1. Bootstrap a new research project (anywhere)
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "GBM tumor purity"

# 2. Start the agent
cd gbm-tumor-purity && claude

# Inside the agent:
> /phase                                     # see current phase + advance requirements
> /lit-search "small-sample radiomics"       # delegate literature triage
> /exp-new baseline-logistic                 # register a new experiment
> /exp-loop --metric val_auc --budget 5min   # autoresearch-style optimization
> /report                                    # draft analysis report
```

No global install. No `~/.claude/plugins/` dependency. The project carries its own copy of the agent runtime files in `.claude/`, so it works on any machine with Claude Code installed.

## What `init.sh` produces

A self-contained research project, ready to run:

```
gbm-tumor-purity/
├── README.md                 # filled with topic, date, current phase
├── CLAUDE.md                 # ml-researcher system prompt
├── .claude/                  # agents/skills/commands/hooks (auto-loaded by Claude Code)
├── respec/                   # methodology templates (rad-research-derived)
├── research/                 # progress.md, data_understanding.md, ... (stubs)
├── data/
│   ├── model_registry.yaml   # structured ML knowledge base
│   ├── raw/  derived/  splits/
├── experiments/
│   ├── README.md
│   └── ledger.tsv
├── results/, papers/
├── scripts/                  # Python helpers (bootstrap_ci, delong_test, ...)
└── .git/                     # initialized with first commit
```

Move it to another machine, `git clone`, `claude` — it works.

## Three-layer loop model

ml-researcher applies different discipline at three time scales:

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

The agent always knows which loop is active and applies the corresponding discipline. See [`spec/01_overview.md`](spec/01_overview.md).

## Influences

| Source | What ml-researcher takes |
|---|---|
| [rad-research](https://github.com/yanmxa/rad-research) | Lifecycle stages; `respec/` templates; iteration trace; methodology guardrails (test-set isolation, baseline mandatory, simple-first) |
| [huggingface/ml-intern](https://github.com/huggingface/ml-intern) | ML-domain expertise as opinionated system prompt; pre-flight checklists; hardware sizing; OOM recovery |
| [karpathy/autoresearch](https://github.com/karpathy/autoresearch) | Single-file edit + git-as-ledger + TSV experiment log + fixed-budget loop |

## Built-in subagents

| Agent | Role |
|---|---|
| **navigator** | Identifies the active loop layer; advances L3 |
| **literature** | Paper search, citation graph, dataset discovery |
| **experimenter** | Runs the L1 edit-run-measure-keep loop |
| **analyst** | Produces analysis reports, statistical comparisons |
| **critic** | Methodology audit (no leakage, baseline present, locked test set) |

## Multi-runtime support

```bash
# Default: Claude Code (subscription billing)
init.sh "topic"

# gen-code (API-key)
init.sh "topic" --runtime gen

# Codex (best-effort)
init.sh "topic" --runtime codex

# Initialize in current directory (don't create new dir)
init.sh "topic" --in-place

# Pin to a specific ml-researcher version
init.sh "topic" --ref v0.1.0
```

## Specification

Full design is in [`spec/`](spec/):

- [`spec/01_overview.md`](spec/01_overview.md) — Philosophy and three-layer loop
- [`spec/02_architecture.md`](spec/02_architecture.md) — Zero-install model; `init.sh` end-to-end
- [`spec/03_project_structure.md`](spec/03_project_structure.md) — Research project layout
- [`spec/04_methodology.md`](spec/04_methodology.md) — Lifecycle, records, guardrails
- [`spec/05_agents.md`](spec/05_agents.md), [`06_tools.md`](spec/06_tools.md), [`07_commands.md`](spec/07_commands.md), [`08_hooks.md`](spec/08_hooks.md)
- [`spec/09_packaging.md`](spec/09_packaging.md) — Install model
- [`spec/10_milestones.md`](spec/10_milestones.md) — v0.1 roadmap
- [`spec/11_related_projects.md`](spec/11_related_projects.md) — Landscape survey
- [`spec/12_knowledge_integration.md`](spec/12_knowledge_integration.md) — How ML domain expertise is embedded
- [`spec/TODO.md`](spec/TODO.md) — Deferred work

## Related Projects

- [genai-io/spec](https://github.com/genai-io/spec) — GenAI Foundry spec
- [genai-io/gen-code](https://github.com/genai-io/gen-code) — Open-source AI agent CLI
- [yanmxa/rad-research](https://github.com/yanmxa/rad-research) — Reference research project (radiomics)

## License

Apache License 2.0 — see [LICENSE](LICENSE).
