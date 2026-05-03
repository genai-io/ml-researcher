# {{TOPIC}}

Last updated: {{DATE}}
ml-researcher: {{ML_VERSION}}

This is the project root. Update this README every time the research plan, current best result, or main conclusion changes.

## Current state

This project investigates **{{TOPIC}}**. The methodology and templates live in `respec/`; current research records live in `research/`; experiment artifacts in `experiments/`; final figures and tables in `results/`.

Current phase: **Data Understanding**.

## Navigation

- Methodology: [`respec/respec.md`](respec/respec.md)
- Initialization protocol: [`respec/init.md`](respec/init.md)
- Project progress: [`research/progress.md`](research/progress.md)
- Data understanding: [`research/data_understanding.md`](research/data_understanding.md)
- Research goal: [`research/research_goal.md`](research/research_goal.md)
- Model selection: [`research/model_selection.md`](research/model_selection.md)
- Fine tuning: [`research/fine_tuning.md`](research/fine_tuning.md)
- Iteration trace: [`research/iteration_trace.md`](research/iteration_trace.md)
- Analysis report: [`research/analysis_report.md`](research/analysis_report.md)
- Experiments: [`experiments/README.md`](experiments/README.md)
- Results: [`results/README.md`](results/README.md)
- Literature shortlist: [`papers/shortlist.md`](papers/shortlist.md)

## How to work in this project

```
claude   # or `gen` / `codex` depending on runtime
> /phase                 # see what's needed to advance the phase
> /lit-search "<query>"  # delegate literature triage
> /exp-new <name>        # register an experiment
> /exp-loop --metric <m> # autoresearch-style iteration loop
> /report draft          # produce analysis report draft
```

System prompt and methodology guardrails are loaded from this directory automatically.

## Update rules

- Every new experiment, model change, figure update, or conclusion change must update `research/progress.md` first.
- Methodology guardrails in [`respec/respec.md`](respec/respec.md) are non-negotiable.
- Do not modify `data/raw/`. All transformations land in `data/derived/`.
- Do not read `data/splits/test/` during Model Selection or Fine Tuning phases (the test-set-guard hook will block).
