# ML Researcher

<p align="center">
  <h1 align="center">< ML ✦ /></h1>
  <p align="center">
    <strong>Disciplined ML research and engineering, as a San persona.</strong>
  </p>
  <p align="center">
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" alt="License"></a>
    <a href="spec/"><img src="https://img.shields.io/badge/status-v0.1-orange?style=flat-square" alt="Status"></a>
  </p>
</p>

`ml-researcher` is a [San](https://github.com/genai-io/san) **persona** — a switchable bundle of system prompt + skills + config that gives San the brain and discipline of a careful ML research engineer. It carries six specialist subagents, a curated model registry, methodology skills, and load-bearing research-hygiene hooks. The installer can also scaffold a complete research project around the persona.

> **Status**: v0.1. Spec is locked in [`spec/`](spec/).

---

## What's inside

This repo **is** the persona — its files sit at the root, and the installers copy them into `.san/personas/ml-researcher/`:

```
system/
  identity.md     # who:  an ML research engineer + epistemic stance ("verify, don't recall")
  behavior.md     # how:  the three-loop model, Train-Loop discipline, subagent dispatch, operational know-how
  rules.md        # rules: the non-negotiable methodology gates (research hygiene)
skills/           # 28 skills (ml-domain · experiment · methodology), each skills/<name>/SKILL.md
settings.json     # persona overlay — description + active skills + agent allow-list + permissions

agents/           # 6 subagents      -> installed to .san/agents/
commands/         # 6 slash commands -> installed to .san/commands/
hooks/            # methodology hooks -> installed to .san/hooks/ + merged into .san/settings.json
template/ data/ scripts/   # project skeleton + model_registry.yaml + python helpers (used when scaffolding)

install.sh · install.ps1 · uninstall.sh · uninstall.ps1   # tooling (not copied into the persona)
```

Unlike a minimal persona, ml-researcher ships a **`rules.md`** — for this persona the methodology gates (data-before-model, locked test set, mandatory baseline) *are* the product. San's built-in safety / tool / git rules stay in force underneath; ml-researcher's permissions only tighten, never loosen them.

---

## Install

**macOS / Linux** — project scope by default; `--user` installs to `~/.san`:

```bash
# Persona only (use it in an existing project)
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh | bash

# Persona + scaffold a fresh research project for a topic
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh \
  | bash -s -- "GBM tumor purity"

# User scope (persona available everywhere; no project scaffold)
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh | bash -s -- --user
```

**Windows (PowerShell 5.1+)**

```powershell
irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.ps1 | iex
# with options (scriptblock form):
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.ps1))) -Topic "GBM tumor purity"
```

The installer copies the persona into `.san/personas/ml-researcher`, installs the agents/commands/hooks, merges the methodology hooks into the target `settings.json`, and enables the persona by setting `"persona": "ml-researcher"` (other keys preserved). Both scripts also run from a local checkout: `./install.sh ["<topic>"] [--user|--dir PATH] [--no-scaffold]`.

Then run `san` in that directory and the persona is active. Switch by hand anytime:

```
/persona ml-researcher    # activate
/persona default          # back to built-in San
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/uninstall.sh | bash
# Windows: irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/uninstall.ps1 | iex
```

Removes the persona and the files it owns, and drops the selection if it pointed at this persona. It does **not** delete a scaffolded research project — that's your work.

### Requirements

- [San](https://github.com/genai-io/san) — the agent CLI.
- `git` (remote install) and `python3` (safe `settings.json` merge on macOS/Linux; Windows uses native PowerShell JSON).

> **Legacy:** the old `init.sh "<topic>" --runtime claude|gen|codex` bootstrapper has been **removed** — San is the runtime now. Use `install.sh` (above); pass a `<topic>` to scaffold a project.

---

## The three loops

ml-researcher applies different discipline at three **nested** time scales — the outer one advances when the inner ones close.

```
Research Loop      ·  days/weeks  ·  the whole project
│  Data Understanding → Research Goal → Model Selection
│  → Fine Tuning → Analysis Report
│
└─ Experiment Loop ·  hours       ·  one EXPxxx direction
   │  Plan → Paper / Modeler → Sandbox → Submit → Monitor → Decide
   │
   └─ Train Loop   ·  minutes     ·  = karpathy autoresearch
         Hypothesize → Edit → Run → Measure → Keep / Reset
```

**Each Research-Loop phase is gated** — the persona (and hooks) prevent advancement until requirements are met. Six slash commands map onto the three layers:

| Loop | Commands |
|---|---|
| **Research** | `/research phase` (navigate phases) · `/research report` (analysis report) |
| **Experiment** | `/exp new` · `/exp list` · `/exp compare` · `/exp paper` (literature) |
| **Train** | `/train run` (kick off autoresearch) |
| cross-layer | `/preflight` (pre-flight) · `/audit` (methodology audit) |

See [`spec/01_overview.md`](spec/01_overview.md) for the failure modes and guardrails per loop.

---

## Workflow walkthrough

A realistic small-N project. Five phases; concrete commands at each.

### Phase 0 — Bootstrap

Scaffold and enter the project, then drop your raw data into `data/raw/` (locked by the `raw_data_guard` hook — you can't accidentally modify it during research).

```bash
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh \
  | bash -s -- "GBM tumor purity"
cp -r ~/downloads/gbm-mri-cohort/* data/raw/
san
```

### Phase 1 — Data Understanding

Goal: write `research/data_understanding.md` so any reader can answer *what data is this, what does it support, what doesn't it*.

```
> /research phase
Current: Data Understanding
To advance: research/data_understanding.md filled, data/splits/ populated.

> Help me fill data_understanding.md. 270 patients, pre-op MRI (T1-C, T2),
> clinical features, tumor purity labels (TP ≥ 60.8% binary).
```

The persona walks the template, enforcing **patient-level splits** (not slice-level — patient leakage is the most common small-sample bug) and **locking the test split** before any model is trained.

When ready: `/research phase advance`.

### Phase 2 — Research Goal

Goal: write `research/research_goal.md` so the question, success criteria, and statistical reporting language are committed before any modeling begins.

```
> /research phase advance
✓ Now in Research Goal.

> Help me draft research_goal.md. Primary endpoint TP ≥ 60.8%; compare
> clinical-only vs radiomics-only vs combined; need calibration for clinical use.
```

It fills: primary metric (e.g., `val_auc` + bootstrap CI), baseline (the simplest defensible model), success criteria, required figures & tables, and risks (small N, label noise, leakage paths). `/research phase advance` when ready.

### Phase 3 — Model Selection

Goal: write `research/model_selection.md` with a candidate matrix, shortlist, and rejection log.

```
> /exp paper search "small-sample radiomics + clinical fusion"

literature subagent appended 5 papers to papers/shortlist.md.
Recommendation: late-fusion (clinical_score + rad_score) is the
strongest small-N pattern.

> Which radiomics encoders fit n=270?

→ model-recommend skill consults data/model_registry.yaml:
  - microsoft/rad-dino       — fine-tune ≥100 samples; verified 2026-04-20
  - google/medsiglip-448     — fine-tune ≥100 samples; verified 2026-04-20
  - google/medgemma-4b-pt    — needs more data than encoder-only models
```

Fill `research/model_selection.md`, then **register and run the baseline** before advancing — advancing to Fine Tuning is gated on `baseline-kept` (no improvement claims without a comparator):

```
> /exp new baseline-clinical-l2
✓ EXP001 registered, branch mlr/exp/EXP001_baseline-clinical-l2

> /train run --metric val_auc --budget 1min --max-iter 20
[EXP001] iter 1: C=1.0  → 0.658 keep
[EXP001] iter 2: C=0.1  → 0.661 keep
[EXP001] iter 3: C=10   → 0.643 discard (git reset)
...
Best val_auc=0.661.
```

`/research phase advance` now passes — baseline is in the ledger with `status=keep`.

### Phase 4 — Fine Tuning

Goal: explore the rest of the shortlist within fixed bounds. The Train Loop (autoresearch) runs many trials; each is git-committed.

```
> /exp new combined-linear-svm
✓ EXP002 registered, branch mlr/exp/EXP002_combined-linear-svm

> /train run --metric val_auc --budget 5min
Best val_auc=0.700 → new current best.
```

The **test set is locked** during this phase. The hook blocks any read of `data/splits/test/`.

```
> Read data/splits/test/labels.csv
✗ Blocked: Test set is locked during "Fine Tuning" phase.
```

When candidates have settled, compare them on validation:

```
> /exp compare EXP001 EXP003
EXP001 val_auc: 0.661 (CI 0.513–0.789)
EXP003 val_auc: 0.700 (CI 0.565–0.814)
DeLong (val): p=0.46 — trend toward improvement, not significant.
```

### Phase 5 — Analysis Report

Advancing to Analysis **unlocks the test set** for the first and only time:

```
> /research phase advance
Spawning critic for audit…
PASS — baseline registered, splits patient-level, no test-set reads.
✓ Advanced to Analysis Report.

> /research report draft
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

> /research report final
Promoted figures to results/figures/, tables to results/tables/.
Updated results/README.md with the finalized summary.
```

Done. Every metric traces to a specific commit. Every accept/reject is in `research/trial_trace.md`. The test set was untouched until Analysis. The project is reproducible from `git clone` alone.

---

## Built-in components

Six subagents, each owning a specific loop level:

| Subagent | Loop | Role |
|---|---|---|
| **navigator** | Research | Top-level dispatcher; advances phases |
| **literature** | Experiment | Paper / citation-graph / dataset discovery — *what exists* |
| **modeler** | Experiment | Candidate model matrix + rejection log — *what to actually try* |
| **experimenter** | Train | Runs the autoresearch loop |
| **analyst** | Research | Analysis report + statistical tests |
| **critic** | cross-layer | Methodology audit (no leakage, baseline present, locked test set) |

Plus 28 skills (ml-domain · experiment · methodology — each a standard `skills/<name>/SKILL.md`), an 18-entry model registry, 8 methodology hooks (raw-data lock, test-set guard, pre-flight, phase gate, trace append, sandbox banner, stop reminder), and 3 Python helpers (bootstrap CI, DeLong test, figure renderer).

---

## Influences

| Source | What ml-researcher takes |
|---|---|
| [huggingface/ml-intern](https://github.com/huggingface/ml-intern) | ML-domain expertise as opinionated system prompt; pre-flight checklists; hardware sizing; OOM recovery |
| [karpathy/autoresearch](https://github.com/karpathy/autoresearch) | Single-file edit + git-as-ledger + TSV experiment log + fixed-budget loop |

---

## Specification

Full design lives in [`spec/`](spec/) — see [`spec/README.md`](spec/README.md) for the reading order, locked v0.1 decisions, and the influence map.

## Related

- [San](https://github.com/genai-io/san) — the agent CLI this persona runs on. See its [persona concept](https://github.com/genai-io/san/blob/main/docs/concepts/persona.md).
- [social-creator](https://github.com/genai-io/social-creator) — sibling San persona (idea → social-media content); the structural template this repo mirrors.
- [genai-io/spec](https://github.com/genai-io/spec) — GenAI Foundry spec.

## License

Apache License 2.0 — see [LICENSE](LICENSE).
