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

A realistic project: predicting tumor purity from MRI in 270 GBM cases (small-N medical imaging — the regime where methodology matters most).

### Bootstrap

```bash
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "GBM tumor purity from MRI"
cd gbm-tumor-purity-from-mri
claude
```

The project is now self-contained: `respec/`, `research/` (stubs), `data/raw|derived|splits/`, `experiments/`, `results/`, `papers/`, `.claude/` with all subagents, skills, commands, hooks. Phase = `Data Understanding`.

### Phase 1 — Data Understanding

```
> /phase

Current phase: Data Understanding
Required to advance to Research Goal:
  ✗ research/data_understanding.md filled
  ✗ data/splits/ has at least one populated subdir
```

Drop your raw data into `data/raw/` (the `raw_data_guard` hook locks it from this point on). Then ask the agent to help fill `research/data_understanding.md`:

```
> Help me fill data_understanding.md. We have 270 GBM patients with
> pre-op MRI (T1-C, T2), clinical/molecular tabular features, and
> tumor purity labels. Threshold TP >= 60.8 % for the binary endpoint.
```

The agent reads `respec/01_data_understanding.md` and walks you through dataset inventory, sample unit (patient-level), label definition, and **patient-level** splits. The `experimenter` and `critic` agents will later block any slice-level leak.

### Phase 2 — Research Goal

```
> /phase advance
✓ Advanced to Research Goal.

> Help me draft research_goal.md. Primary endpoint: TP >= 60.8 %
> binary classification. Compare clinical-only, radiomics-only,
> combined fusion. Need calibration for clinical use.
```

The agent fills the template:

- Primary metric: `val_auc` (with bootstrap CI), Brier for calibration, sensitivity/specificity at a clinically motivated threshold
- Baseline: L2 logistic regression on clinical+VASARI features
- Success criteria: AUC ≥ 0.65 for clinical, ordering Combined > Clinical > Radiomics
- Required figures: ROC, calibration, comparison bar
- Risks: small N, single-center, label noise

### Phase 3 — Model Selection

Use the literature subagent and the model registry:

```
> /lit-search "small-sample radiomics combined with clinical features"

Spawning literature subagent…
Appended 5 papers to papers/shortlist.md.
Recommendation: late-fusion (clinical_score + rad_score) with linear
SVM is the strongest small-N pattern; use RadDINO or original GLCM
features for the radiomics encoder.

> What models should I consider for the radiomics arm?

Calling skill: model-recommend (task=medical_imaging, n_samples=270)
- microsoft/rad-dino — DINOv2-style radiology pretraining; fine-tune ≥100; verified 2026-04-20
- google/medsiglip-448 — multimodal medical CLIP; fine-tune ≥100; verified 2026-04-20
- google/medgemma-4b-pt — needs more data than encoder-only models
- nnUNet — segmentation, not applicable here

Recommendation: RadDINO for feature extraction; combine with TabPFNv2
on clinical features via late fusion.
```

Fill `research/model_selection.md` with the candidate matrix and shortlist:

| Scenario | Model family | Status |
|---|---|---|
| Clinical | L2 logistic | shortlisted (baseline) |
| Radiomics | RBF SVM on original GLCM | shortlisted |
| Radiomics | RadDINO + linear head | shortlisted |
| Combined | Late fusion → linear SVM | shortlisted |
| Combined | High-dim wavelet + auto-feature-selection | rejected (overfitting risk at N=270) |

### Phase 4 — Fine Tuning

Register and run experiments:

```
> /exp-new baseline-clinical-l2
✓ EXP001_baseline-clinical-l2 registered
  Branch: mlr/exp/EXP001_baseline-clinical-l2
  Edit: experiments/EXP001_baseline-clinical-l2/train.py

> /exp-loop --metric val_auc --budget 1min --max-iter 20

Spawning experimenter subagent…
[EXP001] Iter 1: lr=0.01 C=1.0 → val_auc=0.658 → keep
[EXP001] Iter 2: lr=0.01 C=0.1 → val_auc=0.661 → keep
[EXP001] Iter 3: lr=0.01 C=10  → val_auc=0.643 → discard (reset)
...
Done. Best val_auc=0.661 (commit a8c4e2d). Updated progress.md.
```

The L1 loop edits `train.py`, runs `python train.py > run.log 2>&1`, greps `val_auc:`, and `git keep` or `git reset --hard HEAD~1` based on whether the metric improved. Every iteration appends a row to `experiments/ledger.tsv`.

```
> /exp-new combined-linear-svm
> /exp-loop --metric val_auc --budget 5min
...
Done. Best val_auc=0.700 → new current best. Updated progress.md.
```

Try the rejected high-dim direction once anyway, to record it:

```
> /exp-new high-dim-wavelet
> /exp-loop --metric val_auc --budget 5min

Done. val_auc=0.757 on val, but the experimenter detected a likely
overfit (CV vs val gap > 0.05). Recorded in iteration_trace.md as
"reject — high-dim feature space exceeds N=270 stable regime."
```

### Phase 5 — Analysis Report

Try to peek at the test set and the hook blocks you:

```
> Read data/splits/test/labels.csv
✗ Blocked by test_set_guard hook.
  Reason: Test set is locked during "Fine Tuning" phase.
  Reading data/splits/test/** is blocked to prevent leakage.
  The test set unlocks in the Analysis Report phase.

> /phase advance
Spawning critic for audit…
critic verdict: PASS — baseline registered, splits patient-level,
no test-set reads in iteration_trace.
✓ Advanced to Analysis Report.
```

Now run the analyst:

```
> /report draft

Spawning analyst subagent…
- Reading research_goal.md, ledger.tsv, EXP00* metrics.json
- Computing test-set AUC + bootstrap 95% CI for each shortlisted model
- Running DeLong paired test: clinical vs combined → p=0.46 (n.s.)

Wrote research/analysis_report.md.

| Model      | Test AUC | 95% CI         | Brier |
| Clinical   | 0.661    | (0.513, 0.789) | 0.207 |
| Radiomics  | 0.637    | (0.495, 0.770) | 0.199 |
| Combined   | 0.700    | (0.565, 0.814) | 0.199 |

Conclusion: Combined model shows the highest test AUC point estimate
and meets the predicted ordering (Combined > Clinical > Radiomics).
DeLong test against clinical: p = 0.46 — language is "trend toward
improvement," not "significantly outperforms."

Spawning critic on the report…
critic verdict: PASS.
```

```
> /report finalize

Promoted figures to results/figures/ (roc.png, calibration.png,
comparison_bar.png). Promoted comparison table to results/tables/.
Wrote results/reports/final.md and updated root README.md with
current best.
```

### What the project looks like at the end

```
gbm-tumor-purity-from-mri/
├── README.md                   # current best summary
├── CLAUDE.md
├── .claude/                    # all subagents/skills/commands/hooks
├── respec/                     # methodology constitution
├── research/
│   ├── progress.md             # phase = Finalized
│   ├── data_understanding.md   # filled
│   ├── research_goal.md        # filled, locked
│   ├── model_selection.md      # filled with candidate matrix
│   ├── fine_tuning.md          # filled with parameter ranges
│   ├── iteration_trace.md      # 60+ iterations across 4 experiments
│   └── analysis_report.md      # finalized, critic PASS
├── data/{raw,derived,splits}   # test split locked since init
├── experiments/
│   ├── ledger.tsv              # 60+ rows; full audit trail
│   ├── EXP001_baseline-clinical-l2/
│   ├── EXP002_radiomics-rbf-svm/
│   ├── EXP003_combined-linear-svm/    # ← current best
│   └── EXP004_high-dim-wavelet/       # rejected, recorded
├── results/
│   ├── figures/{roc,calibration,comparison_bar}.png
│   ├── tables/comparison.csv
│   └── reports/final.md
├── papers/{shortlist.md, notes/}
└── scripts/                    # bootstrap_ci, delong_test, figure_render
```

The project is reproducible from `git clone` alone. Every metric in `analysis_report.md` traces back to a specific experiment commit. Every accept/reject decision is in `iteration_trace.md`. Test set was never read until the Analysis phase. No silent overfitting. No fabricated results.

That's the loop ml-researcher exists to make easy.

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

# Gen Code (API-key)
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
- [Gen Code](https://github.com/genai-io/gen-code) — Open-source AI agent CLI

## License

Apache License 2.0 — see [LICENSE](LICENSE).
