# Research Spec — Methodology

`respec` is the research specification: research methodology, lifecycle, stage boundaries, recording rules, and iteration principles.

This file is the methodology constitution. It is **not** a project record (project records live in `research/`). It is **not** a template to fill in (templates are `01_*.md` through `05_*.md`).

## 1. Core principles

These are non-negotiable. The ml_researcher.md system prompt enforces them; the critic subagent audits them; hooks block the most common violations.

1. **Data before model.** Define data sources, sample units, labels, splits, quality, and limits before designing models.
2. **Goal before optimization.** Define the research question, primary metric, baseline, required figures, and success criteria before running experiments.
3. **Test set isolation.** Feature selection, preprocessing, threshold selection, model selection, and tuning must not use the locked test set.
4. **Baseline mandatory.** Every research project has a baseline. Improvement claims are relative to it.
5. **Experiment traceability.** Every experiment records motivation, change, data version, parameters, results, figures, and accept/reject decision.
6. **Result consistency.** Reports, figures, prediction files, model files, and summary text come from the same experiment artifact.
7. **No fabricated results.** Mocks, simulated labels, and exploratory experiments are explicitly labeled as such.
8. **Simple-first.** Under sample-size constraints, prefer robust, interpretable, calibrated models. Complex models must justify their gain on a held-out set, not on training/CV.
9. **Stoppable.** When added complexity raises train/CV but lowers val/test, record the overfitting risk and stop the direction.
10. **Independent progress record.** `progress.md` records current phase, next step, and blockers separately from the methodology templates.

## 2. Research lifecycle

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

## 3. Cross-cutting records

`iteration_trace.md` and `progress.md` are **not** lifecycle stages — they are records that span all stages.

| Record | Scope | Answers | Updated when |
|---|---|---|---|
| `iteration_trace.md` | Experiment audit | Why was each experiment run? what changed? results? accepted? | After every meaningful experiment, tuning, sensitivity, or finalization |
| `progress.md` | Project state | Where are we; what's the current best; what's next; what's blocking? | When a phase completes, current best changes, conclusion changes, or a blocker appears |

`progress.md` references `iteration_trace.md` by experiment ID; it does not duplicate experiment detail.

## 4. Phase boundaries

### Data Understanding

Only answer data questions. Do not pre-select complex models. Define data sources, sample units, labels, splits, missing-value handling, outliers, leakage risks, and data limits.

### Research Goal

Convert user intent and data capability into actionable goals. Define primary research question, primary endpoint, primary metric, baseline, success criteria, required figures, and the boundary between exploratory and confirmatory work.

### Model Selection

Compare "data scenarios × model families" laterally. Output is candidate routes, rejected routes, and a shortlist — **not** final-best parameters.

### Fine Tuning

Limited longitudinal optimization within shortlisted models. To switch model families, return to Model Selection rather than search without bounds.

### Iteration Trace

Not a lifecycle stage; an experiment audit log. Each entry: experiment ID, motivation, diff vs parent, data version, parameters, results, figures, decision, next step.

### Progress

Not a lifecycle stage; a project state log. Records current phase, current best experiment, main conclusion, next step, blockers — references `iteration_trace.md` by ID.

### Analysis Report

Convert the full research process into auditable conclusions. Includes data understanding, goal achievement, model selection, tuning trajectory, final metrics, statistical comparisons, figure index, limits, and recommendations.

### Goal Revision

When data quality, sample size, model performance, or business goals don't support the original goal, return to Research Goal. Revisions preserve old goal, reason, new goal, and scope of change — never overwrite history.
