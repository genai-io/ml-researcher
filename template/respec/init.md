# Project Initialization Protocol

How to instantiate `respec/` templates into a concrete project, and how to keep state, iteration trace, and directory documentation up to date afterwards.

This file does NOT mandate fixed directory names beyond what `init.sh` already created. It does require: clear entry points, traceable references, and per-subdirectory state notes.

## 1. Project initialization

`init.sh` already produced this skeleton. To begin work:

1. Read `README.md` (project root) — confirm topic, current state, current results, existing directories.
2. Read `respec/respec.md` — confirm lifecycle and recording rules.
3. Verify project instance documents (`research/*.md`) are stubs ready for filling.
4. Fill in, in this order:
   - `research/data_understanding.md`
   - `research/research_goal.md`
   - `research/model_selection.md` (when entering Model Selection phase)
   - `research/fine_tuning.md` (when entering Fine Tuning phase)
   - `research/iteration_trace.md` (continuously, after each experiment)
   - `research/analysis_report.md` (when entering Analysis phase)
   - `research/progress.md` (continuously, at every state change)

## 2. Suggested instance structure

A research project needs five things:

1. **Entry**: where do humans (and future-you) start reading?
2. **Methodology**: what templates and rules govern the project?
3. **Research records**: what's the question, data, method, experiments, conclusion?
4. **Experiment artifacts**: what did each run produce?
5. **Result artifacts**: which figures/tables/reports were ultimately adopted?

Layout `init.sh` creates:

```
<project-root>/
  README.md
  CLAUDE.md (or GEN.md / AGENTS.md)
  .claude/ (or .gen/ / .codex/)

  respec/
    README.md  respec.md  init.md
    01_data_understanding.md  02_research_goal.md
    03_model_selection.md     04_fine_tuning.md
    05_analysis_report.md
    iteration_trace.md  progress.md

  research/
    progress.md  data_understanding.md  research_goal.md
    model_selection.md  fine_tuning.md  analysis_report.md
    iteration_trace.md

  data/
    README.md  raw/  derived/  splits/

  experiments/
    README.md  ledger.tsv
    EXPxxx_<name>/
      README.md  config.yaml  train.py
      run.log  metrics.json
      figures/  artifacts/

  results/
    README.md  figures/  tables/  reports/

  papers/
    README.md  shortlist.md  notes/
```

## 3. Update protocol

Whenever you continue work on this project:

```
1. Read root README.md
2. Read research/progress.md
3. Read research/iteration_trace.md (recent entries)
4. Read latest analysis_report.md or current best experiment if needed
5. Continue work
```

## 4. Update rules

| Change | Update required |
|---|---|
| New experiment | `research/iteration_trace.md`, `experiments/<exp_id>/README.md` |
| Current best changed | `research/iteration_trace.md`, `research/progress.md`, root `README.md`, possibly `research/analysis_report.md` and `results/README.md` |
| Phase completion or blocker | `research/progress.md` |
| Goal or metric change | `research/research_goal.md`, `research/progress.md`, root `README.md` |
| Data, label, or split change | `research/data_understanding.md`, `data/README.md`, possibly `research/progress.md` |
| Model route change | `research/model_selection.md`, `research/iteration_trace.md`, possibly `research/progress.md` |
| Tuning bound or final candidate change | `research/fine_tuning.md`, `research/iteration_trace.md` |
| Final figures, metrics, or conclusion change | `research/analysis_report.md`, `results/README.md`, root `README.md` |

## 5. Per-subdirectory README

Each major subdirectory has a brief `README.md` recording:

```markdown
# <Directory>

## Purpose
What lives here.

## Current Status
- Last updated:
- Current contents:
- Current best or active item:
- Known issues:

## Update Rule
When this README must be updated.
```

## 6. Stop and resume

Before ending a session, update at minimum:

1. `research/progress.md` — current phase, last action, next step, blockers.
2. `research/iteration_trace.md` — if any experiment was run.
3. `experiments/<exp_id>/README.md` — if artifacts changed.
4. `results/README.md` — if any artifact was promoted to conclusion-grade.
5. Root `README.md` — if current best result or main conclusion changed.

If incomplete, write a `Resume Notes` block in `progress.md` with: last action, files changed, results generated, not yet reviewed, next command.

## 7. Experiment completion checklist

After every experiment, before starting another:

- [ ] `experiments/<exp_id>/README.md` updated
- [ ] `research/iteration_trace.md` entry added
- [ ] `research/progress.md` updated if state changed
- [ ] `results/README.md` updated if any artifact promoted
- [ ] `research/analysis_report.md` updated if conclusion changed
- [ ] Root `README.md` updated if current best changed
- [ ] Data/method/goal docs updated if applicable

If an item is N/A, mark it explicitly — don't silently skip.
