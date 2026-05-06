# ML Researcher

<p align="center">
  <h1 align="center">< ML ✦ /></h1>
  <p align="center">
    <strong>Disciplined ML research and engineering, in your terminal.</strong>
  </p>
  <p align="center">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" alt="License"></a>
    <a href="spec/"><img src="https://img.shields.io/badge/status-v0.1-orange?style=flat-square" alt="Status"></a>
  </p>
</p>

ml-researcher bootstraps a self-contained ML research project — pre-loaded with subagents, skills, slash commands, hooks, an ML model registry, and methodology templates. Default runtime is [Gen Code](https://github.com/genai-io/gen-code); Claude Code and Codex are supported via `--runtime`.

> **Status**: v0.1 — content under construction. Spec is locked in [`spec/`](spec/).

---

## Install

You don't install ml-researcher globally. You install it **into a research project**. The project then carries everything it needs and works on any machine with the chosen runtime.

### Path A — start a fresh project (creates a new directory)

```bash
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "GBM tumor purity"

cd gbm-tumor-purity
gen     # or: claude / codex
```

The slug `gbm-tumor-purity` is auto-derived from the topic.

### Path B — initialize the current directory

```bash
cd ~/my-existing-research

curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "GBM tumor purity" --in-place

gen
```

`--in-place` skips the new-directory creation; methodology templates land alongside whatever's already there. Useful when you have raw data or partial code already.

### Runtime selection

```bash
# Default (recommended): Gen Code
init.sh "topic"

# Claude Code (subscription billing)
init.sh "topic" --runtime claude

# Codex (best-effort)
init.sh "topic" --runtime codex
```

The runtime determines where the persona is delivered:

| Runtime | Persona location | Channel |
|---|---|---|
| **Gen Code** *(default)* | `.gen/identities/ml-researcher.md` + `.gen/settings.json: {"identity": "ml-researcher"}` | identity slot 0 (system prompt) |
| **Claude Code** | `CLAUDE.md` (project root) | system-reminder (project memory) |
| **Codex** | `AGENTS.md` (project root) | system-reminder (project memory) |

Gen Code has a [first-class identity slot](https://github.com/genai-io/gen-code/blob/main/docs/system-prompt.md) — separate from project memory. ml-researcher's prompt is persona-shaped, so it slots in cleanly without polluting project memory.

---

## What you get

After init, the project layout:

```
<project>/
├── README.md, <CLAUDE.md|GEN.md|AGENTS.md as applicable>
├── .git/                        # initialized with first commit
├── .<claude|gen|codex>/
│   ├── settings.json            # hooks + (gen) identity activation
│   ├── identities/              # gen only — the persona file
│   ├── agents/                  # 5 subagents
│   ├── skills/                  # ~16 skills (ml/, experiment/, methodology/)
│   ├── commands/                # 6 slash commands
│   └── hooks/                   # 7 methodology hook scripts
├── respec/                      # methodology constitution (10 principles, 5 phases)
├── research/                    # progress.md + filled stubs per phase
├── data/{raw,derived,splits}/   # raw is locked; test split locks during Selection/Tuning
├── experiments/
│   ├── ledger.tsv               # full audit trail
│   └── EXP*/                    # one dir per experiment
├── results/{figures,tables,reports}/
├── papers/
├── data/model_registry.yaml     # 18-entry curated ML knowledge base
└── scripts/                     # bootstrap_ci.py, delong_test.py, figure_render.py
```

---

## The research lifecycle

Every project flows through five phases. **Each phase is gated** — the agent (and hooks) prevent advancement until requirements are met.

```
[Bootstrap]
    │
    ▼
1. Data Understanding → 2. Research Goal → 3. Model Selection
                                              │
                                              ▼
                          5. Analysis Report ← 4. Fine Tuning
                                                  │
                                                  └─→ (loop within phase 4)
```

Six unified slash commands cover the whole lifecycle:

| Command | Purpose |
|---|---|
| `/phase` | Show current phase + advance requirements; `/phase advance` to transition |
| `/exp` | `new <name>`, `loop`, `list`, `compare` — manage experiments |
| `/lit` | `search <query>`, `list`, `read <id>` — literature triage |
| `/report` | `draft`, `final` — produce analysis report |
| `/check` | Run pre-flight checklist |
| `/audit` | Spawn critic for methodology audit |

---

## Workflow walkthrough

A realistic small-N project. Five phases; concrete commands at each.

### Phase 0 — Bootstrap (before the agent)

Drop your raw data into `data/raw/` (after init, this directory is **locked** by the `raw_data_guard` hook — you can't accidentally modify it during research).

```bash
cp -r ~/downloads/gbm-mri-cohort/* gbm-tumor-purity/data/raw/
cd gbm-tumor-purity && gen
```

### Phase 1 — Data Understanding

Goal: write `research/data_understanding.md` so any reader can answer *what data is this, what does it support, what doesn't it*.

```
> /phase
Current: Data Understanding
To advance: research/data_understanding.md filled, data/splits/ populated.

> Help me fill data_understanding.md. 270 patients, pre-op MRI (T1-C, T2),
> clinical features, tumor purity labels (TP ≥ 60.8% binary).
```

The agent walks the template, enforcing **patient-level splits** (not slice-level — patient leakage is the most common small-sample bug) and **locking the test split** before any model is trained.

When ready: `/phase advance`.

### Phase 2 — Research Goal

Goal: write `research/research_goal.md` so the question, success criteria, and statistical reporting language are committed before any modeling begins.

```
> /phase advance
✓ Now in Research Goal.

> Help me draft research_goal.md. Primary endpoint TP ≥ 60.8%; compare
> clinical-only vs radiomics-only vs combined; need calibration for clinical use.
```

The agent fills:
- Primary metric (e.g., `val_auc` + bootstrap CI)
- Baseline (the simplest defensible model)
- Success criteria (minimum / target / model ordering)
- Required figures & tables
- Risks (small N, label noise, leakage paths)

`/phase advance` when ready.

### Phase 3 — Model Selection

Goal: write `research/model_selection.md` with a candidate matrix, shortlist, and rejection log.

```
> /lit search "small-sample radiomics + clinical fusion"

Literature subagent appended 5 papers to papers/shortlist.md.
Recommendation: late-fusion (clinical_score + rad_score) is the
strongest small-N pattern.

> Which radiomics encoders fit n=270?

→ model-recommend skill consults data/model_registry.yaml:
  - microsoft/rad-dino       — fine-tune ≥100 samples; verified 2026-04-20
  - google/medsiglip-448     — fine-tune ≥100 samples; verified 2026-04-20
  - google/medgemma-4b-pt    — needs more data than encoder-only models
```

Fill `research/model_selection.md`, then **register and run the baseline** before advancing — `/phase advance` to Fine Tuning is gated on `baseline-kept` (no improvement claims without a comparator):

```
> /exp new baseline-clinical-l2
✓ EXP001 registered, branch mlr/exp/EXP001_baseline-clinical-l2

> /exp loop --metric val_auc --budget 1min --max-iter 20
[EXP001] iter 1: C=1.0  → 0.658 keep
[EXP001] iter 2: C=0.1  → 0.661 keep
[EXP001] iter 3: C=10   → 0.643 discard (git reset)
...
Best val_auc=0.661.
```

`/phase advance` now passes — baseline is in the ledger with `status=keep`.

### Phase 4 — Fine Tuning

Goal: explore the rest of the shortlist within fixed bounds. The L1 autoresearch loop runs many iterations; each is git-committed.

```
> /exp new combined-linear-svm
✓ EXP002 registered, branch mlr/exp/EXP002_combined-linear-svm

> /exp loop --metric val_auc --budget 5min
Best val_auc=0.700 → new current best.
```

For each iteration the experimenter subagent:
1. Edits `train.py` with one change
2. Runs `python train.py > run.log 2>&1` (no tee — output redirection only)
3. Greps the metric line
4. Advances or resets git based on whether it improved
5. Appends to `experiments/ledger.tsv`

The **test set is locked** during this phase. The hook will block any read of `data/splits/test/`.

```
> Read data/splits/test/labels.csv
✗ Blocked: Test set is locked during "Fine Tuning" phase.
```

When candidates have settled: compare them on validation:

```
> /exp compare EXP001 EXP003
EXP001 val_auc: 0.661 (CI 0.513–0.789)
EXP003 val_auc: 0.700 (CI 0.565–0.814)
DeLong (val): p=0.46 — trend toward improvement, not significant.
```

### Phase 5 — Analysis Report

Advancing to Analysis **unlocks the test set** for the first and only time:

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

Combined is highest by point estimate; DeLong p=0.46 → report language
is "trend toward improvement," not "significantly outperforms."

> /audit report
critic verdict: PASS.

> /report final
Promoted figures to results/figures/, tables to results/tables/.
Updated results/README.md with the finalized summary.
```

Done. Every metric traces to a specific commit. Every accept/reject is in `research/iteration_trace.md`. The test set was untouched until Analysis. The project is reproducible from `git clone` alone.

---

## Three-layer loop discipline

ml-researcher applies different discipline at three time scales:

```
L3 · Lifecycle Loop      (days/weeks)
     Data → Goal → Selection → Tuning → Report → Revision
L2 · Experiment Loop     (hours)
     Plan → Research → Sandbox → Submit → Monitor → Decide
L1 · Iteration Loop      (minutes)
     Edit → Run → Measure → Keep or Reset
```

The agent always knows which loop is active. See [`spec/01_overview.md`](spec/01_overview.md).

---

## Built-in components

| Subagents | Role |
|---|---|
| **navigator** | Top-level dispatcher; advances L3 |
| **literature** | Paper search, citation graph, dataset discovery |
| **experimenter** | Runs the L1 edit-run-measure-keep loop |
| **analyst** | Produces analysis reports, statistical comparisons |
| **critic** | Methodology audit (no leakage, baseline present, locked test set) |

Plus 16 skills (ml-domain, experiment, methodology), a 18-entry model registry, 7 hooks (raw-data lock, test-set guard, pre-flight, phase gate, trace append, state injection, stop reminder), and 3 Python helpers (bootstrap CI, DeLong test, figure renderer).

---

## Influences

| Source | What ml-researcher takes |
|---|---|
| [huggingface/ml-intern](https://github.com/huggingface/ml-intern) | ML-domain expertise as opinionated system prompt; pre-flight checklists; hardware sizing; OOM recovery |
| [karpathy/autoresearch](https://github.com/karpathy/autoresearch) | Single-file edit + git-as-ledger + TSV experiment log + fixed-budget loop |

---

## Specification

Full design lives in [`spec/`](spec/) — see [`spec/README.md`](spec/README.md) for the reading order, locked v0.1 decisions, and the influence map.

---

## Related

- [Gen Code](https://github.com/genai-io/gen-code) — Open-source AI agent CLI (default runtime)
- [genai-io/spec](https://github.com/genai-io/spec) — GenAI Foundry spec

## License

Apache License 2.0 — see [LICENSE](LICENSE).
