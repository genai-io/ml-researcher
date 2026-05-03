# 04 — Methodology

The methodology is adapted from [rad-research's `respec/`](https://github.com/yanmxa/rad-research/tree/main/respec) with domain-specific terms (radiomics, DeLong, etc.) abstracted out.

## The fabrication problem

[MLR-Bench (NeurIPS 2025)](https://arxiv.org/abs/2505.19955) reports that *"current coding agents frequently (e.g., in 80% of the cases) produce fabricated or invalidated experimental results — posing a major barrier to scientific reliability."* This is the wall ml-researcher exists to break.

The methodology below is not academic ceremony. Every principle, gate, and hook is targeted at a specific failure mode that produces fabricated results in the wild: test-set leakage, missing baselines, mismatched figures vs metrics, silent dataset substitution, scope-creeping fixes that change the research claim. See [`11_related_projects.md`](11_related_projects.md) for the landscape survey and the cross-reference of mechanisms to threats.

## Core principles

These are enforced by the `critic` agent and by hooks. Violations should be visible in the conversation, not silent.

1. **Data before model** — define data sources, sample units, labels, splits, quality, and limits before designing models.
2. **Goal before optimization** — define research question, primary metric, baseline, required figures, and success criteria before running experiments.
3. **Test set isolation** — feature selection, preprocessing, threshold selection, model selection, and tuning must not use the locked test set.
4. **Baseline mandatory** — every claim of improvement is relative to a registered baseline.
5. **Experiment traceability** — every experiment records motivation, change diff, data version, parameters, results, figures, and accept/reject decision.
6. **Result consistency** — report, figures, prediction files, model files, and summary text come from the same experiment artifact.
7. **No fabricated results** — mocks, simulated labels, label corrections, sensitivity analyses, and exploratory experiments must be labeled as such.
8. **Simple-first** — under sample-size constraints, prefer robust, interpretable, calibrated models; complex models must justify their gain.
9. **Stoppable** — when added complexity only improves train/CV but degrades validation/test, record the overfitting risk and stop the direction.
10. **Independent progress record** — `progress.md` (or equivalent) records current phase, next step, blockers — separately from the methodology templates.

## Lifecycle stages (L3)

```
Data Understanding
  → Research Goal
  → Model Selection
  → Fine Tuning on Selected Models
  → Analysis Report
  → Goal Revision (if needed)
       → repeat necessary steps
```

| Stage | Main question | Output |
|---|---|---|
| Data Understanding | What data exists; are labels and splits reliable? | data inventory, label definitions, splits, QC, data limits |
| Research Goal | What must be proven; how is success judged? | research question, metrics, baseline, figure requirements, success criteria |
| Model Selection | Which data×model combinations enter tuning? | candidate routes, rejected routes, shortlisted models |
| Fine Tuning | How are shortlisted models optimized within fixed boundaries? | parameter ranges, tuning results, final candidates |
| Analysis Report | Does the evidence chain support the conclusion? | final metrics, figures, negative results, limits, conclusion |
| Goal Revision | Does the original goal still hold? | old goal, reason, new goal, scope of change |

## Cross-cutting records

`iteration_trace.md` and `progress.md` are not lifecycle stages. They are records that span all stages.

| Record | Scope | Answers | Updated when |
|---|---|---|---|
| `iteration_trace.md` | Experiment audit | Why was each experiment run? what changed? what happened? accepted? | After every meaningful experiment, tuning, sensitivity, or finalization |
| `progress.md` | Project state | Where are we; what's the current best; what's next; what's blocking? | When a phase completes, current best changes, conclusion changes, or a blocker appears |

`progress.md` references `iteration_trace.md` by experiment ID; it does not duplicate experiment detail.

## Stage transitions (gates)

Stage transitions are enforced by the `phase_advance` tool + hook. To advance a phase, the listed records must be present and non-empty. If not, the tool blocks with a checklist.

```
[Data Understanding] → [Research Goal]
  Required: research/data_understanding.md filled
  Optional: data/splits/* created if applicable

[Research Goal] → [Model Selection]
  Required: research/research_goal.md with primary metric defined
  Required: at least one baseline route declared

[Model Selection] → [Fine Tuning]
  Required: research/model_selection.md with shortlist
  Required: experiments/EXPxxx-baseline run and registered

[Fine Tuning] → [Analysis Report]
  Required: research/fine_tuning.md with parameter ranges
  Required: each shortlisted model has at least one tuning experiment

[Analysis Report] → [Goal Revision] (optional loop)
  Required: research/analysis_report.md with figures and statistical tests
```

## Per-stage templates (in `respec/`)

Each numbered file is a template, not a project record. The agent copies templates into `research/` and fills them.

| Template | Purpose |
|---|---|
| `01_data_understanding.md` | dataset inventory, dictionary, sample units, label definition, cohort split, QC, derived data policy |
| `02_research_goal.md` | user intent, primary research question, endpoints, model scenarios, metrics, success criteria, baseline, required figures, risks |
| `03_model_selection.md` | candidate data×model matrix, rejection log, shortlist |
| `04_fine_tuning.md` | per-shortlisted-model parameter ranges, search strategy, results |
| `05_analysis_report.md` | data summary, goal achievement, model comparison, calibration, statistical tests, limits, conclusions |

## Domain customization

The default `respec/` is **domain-neutral**. Domain-specific guidance lives in `.mlr/playbook.md`:

- For a radiomics project: small-sample guardrails, CV protocols, DeLong test, calibration.
- For an NLP fine-tuning project: format checks (SFT/DPO/GRPO), tokenizer compatibility, pre-flight from ml-intern.
- For an RL project: replay buffers, discount-rate baselines, reward hacking checks.

`playbook.md` is loaded into the agent's working context at session start. It is the user's lever for shaping how `mlr` interprets the methodology in this specific project.

## Stop and resume rule

Before ending a work session, the agent must update at minimum:

1. `research/progress.md` — phase, last action, next step, blockers.
2. `research/iteration_trace.md` — if any experiment was run.
3. `experiments/EXPxxx/README.md` — if artifacts changed.
4. `results/README.md` — if any artifact was promoted to conclusion-grade.
5. Root `README.md` — if the current best result or main conclusion changed.

If incomplete, write a `Resume Notes` block in `progress.md` with: last action, files changed, results generated, not yet reviewed, next command.
