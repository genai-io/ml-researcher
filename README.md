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

ml-researcher is a methodology + agent toolkit for machine learning research projects. It bootstraps a self-contained research project directory pre-loaded with subagents, skills, slash commands, hooks, an ML model registry, and methodology templates — all driven by Claude Code, Gen Code, or Codex.

> **Status**: v0.1 — content under construction. Spec is locked in [`spec/`](spec/).

## Two commands, end-to-end

```bash
# 1. Bootstrap a new research project (anywhere)
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "GBM tumor purity"

# 2. Start the agent
cd gbm-tumor-purity && claude

# Inside the agent:
> /phase                                       # show phase + advance requirements
> /lit search "small-sample radiomics"         # delegate literature triage
> /exp new baseline-logistic                   # register an experiment
> /exp loop --metric val_auc --budget 5min     # autoresearch-style optimization
> /report draft                                # draft analysis report
```

Six unified commands cover the whole lifecycle: `/phase`, `/exp`, `/lit`, `/report`, `/check`, `/audit`. Each takes subcommands (e.g. `/exp new`, `/exp loop`, `/exp list`, `/exp compare`) so the surface stays small and discoverable.

No global install. No `~/.claude/plugins/` dependency. The project carries its own copy of the agent runtime files in `.claude/`, so it works on any machine with Claude Code installed.

## What `init.sh` produces

A self-contained research project, ready to run:

```
gbm-tumor-purity/
├── README.md                 # filled with topic, date, current phase
├── CLAUDE.md                 # ml-researcher system prompt
├── .claude/                  # agents/skills/commands/hooks (auto-loaded by Claude Code)
├── respec/                   # methodology templates
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

## Example: end-to-end lifecycle walkthrough

A realistic project — small-N medical imaging, the regime where methodology matters most. Predicting tumor purity from MRI in 270 GBM cases.

```bash
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "GBM tumor purity"
cd gbm-tumor-purity && claude
```

Five L3 phases: each is **gated** — you can't advance until requirements are met.

### 1. Data Understanding

```
> /phase
Current: Data Understanding
To advance: research/data_understanding.md filled, data/splits/ populated.

> Help me fill data_understanding.md. 270 patients, pre-op MRI (T1-C, T2),
> clinical features, tumor purity labels (TP ≥ 60.8% binary).
```

The agent walks the template, enforcing **patient-level splits** (not slice-level) and locking the test split.

### 2. Research Goal

```
> /phase advance
✓ Now in Research Goal.

> Primary endpoint TP ≥ 60.8% binary; compare clinical / radiomics
> / combined; need calibration for clinical use.
```

Fills `research_goal.md`: primary metric `val_auc` + bootstrap CI, baseline = L2 logistic, success criteria, required figures (ROC + calibration + comparison_bar).

### 3. Model Selection

```
> /lit search "small-sample radiomics + clinical fusion"

Literature subagent appended 5 papers to papers/shortlist.md.
Recommendation: late-fusion (clinical_score + rad_score) is the
strongest small-N pattern.

> Which radiomics encoders fit n=270?

→ model-recommend skill on data/model_registry.yaml
  - microsoft/rad-dino  — fine-tune ≥100; verified 2026-04-20
  - google/medsiglip    — fine-tune ≥100; verified 2026-04-20
  - google/medgemma-4b  — needs more data than encoder-only
```

Fills `model_selection.md`. Rejects high-dim wavelet (overfitting risk at N=270).

### 4. Fine Tuning

```
> /exp new baseline-clinical-l2
✓ EXP001 registered, branch mlr/exp/EXP001_baseline-clinical-l2

> /exp loop --metric val_auc --budget 1min --max-iter 20
[EXP001] iter 1: C=1.0  → 0.658 keep
[EXP001] iter 2: C=0.1  → 0.661 keep
[EXP001] iter 3: C=10   → 0.643 discard (git reset)
...
Best val_auc=0.661.

> /exp new combined-linear-svm
> /exp loop --metric val_auc
Best val_auc=0.700 → new current best.
```

The L1 loop edits `train.py`, runs `python train.py > run.log 2>&1`, greps `val_auc:`, advances or resets git. Every attempt appends to `experiments/ledger.tsv`.

### 5. Analysis Report

The test set is **locked** by the `test_set_guard` hook during Selection/Tuning. Try to peek:

```
> Read data/splits/test/labels.csv
✗ Blocked by test_set_guard. Test set locked during Fine Tuning phase.
```

Advance (which unlocks it for reporting):

```
> /phase advance
Spawning critic for audit…
PASS — baseline registered, splits patient-level, no test-set reads.
✓ Advanced to Analysis Report.

> /report draft
analyst subagent computing test AUC + bootstrap CI per model, DeLong
paired test (clinical vs combined): p=0.46.

| Model      | Test AUC | 95% CI         |
| Clinical   | 0.661    | (0.513, 0.789) |
| Radiomics  | 0.637    | (0.495, 0.770) |
| Combined   | 0.700    | (0.565, 0.814) |

Combined point estimate is highest; DeLong p=0.46 means the report
language is "trend toward improvement," not "significantly outperforms."

> /report final
Promoted figures to results/figures/, tables to results/tables/.
Updated root README.md with current best.
```

### What ends up on disk

```
gbm-tumor-purity/
├── README.md, CLAUDE.md, .claude/
├── respec/                       # methodology constitution
├── research/{progress, data_understanding, research_goal,
│            model_selection, fine_tuning,
│            iteration_trace, analysis_report}.md
├── data/{raw,derived,splits}/    # test split locked since init
├── experiments/
│   ├── ledger.tsv                # full audit trail of every iteration
│   ├── EXP001_baseline-clinical-l2/
│   ├── EXP002_radiomics-rbf-svm/
│   ├── EXP003_combined-linear-svm/    ← current best
│   └── EXP004_high-dim-wavelet/       (rejected, recorded)
├── results/{figures,tables,reports}/
├── papers/{shortlist.md, notes/}
└── scripts/, .git/
```

Reproducible from `git clone` alone. Every metric traces to a specific commit. Every accept/reject is in `iteration_trace.md`. Test set untouched until Analysis. That's the loop ml-researcher exists to make easy.

## Influences

| Source | What ml-researcher takes |
|---|---|
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

# Gen Code — installs as a first-class identity (Channel A persona slot),
# not project memory. Sets .gen/settings.json: {"identity": "ml-researcher"}.
init.sh "topic" --runtime gen

# Codex (best-effort) — uses AGENTS.md project memory
init.sh "topic" --runtime codex

# Initialize in current directory (don't create new dir)
init.sh "topic" --in-place

# Pin to a specific ml-researcher version
init.sh "topic" --ref v0.1.0
```

How the persona is delivered per runtime:

| Runtime | Persona location | Channel |
|---|---|---|
| Claude Code | `CLAUDE.md` (project root) | system-reminder (project memory) |
| Gen Code | `.gen/identities/ml-researcher.md` + `.gen/settings.json` | identity slot 0 (system prompt) |
| Codex | `AGENTS.md` (project root) | system-reminder (project memory) |

For Gen Code, the identity slot is the [first-class persona channel](https://github.com/genai-io/gen-code/blob/main/docs/system-prompt.md) — separate from project memory. ml-researcher's prompt **is** a persona (epistemic stance + methodology), so it slots in cleanly without polluting GEN.md.

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
- [Gen Code](https://github.com/genai-io/gen-code) — Open-source AI agent CLI

## License

Apache License 2.0 — see [LICENSE](LICENSE).
