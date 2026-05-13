# {{TOPIC}}

Last updated: {{DATE}}
ml-researcher: {{ML_VERSION}}

This is the project root. It is project description — what this project investigates, where to find things, how to run it. **Live state lives in [`research/progress.md`](research/progress.md)** (current phase, current best, blockers, next step). Don't mirror that state here — the README would rot silently.

## What this is

This project investigates **{{TOPIC}}**. The methodology and templates live in `respec/`; current research records live in `research/`; experiment artifacts in `experiments/`; final figures and tables in `results/`. For the live phase, current best, and blockers, read [`research/progress.md`](research/progress.md).

## Navigation

- Methodology: [`respec/respec.md`](respec/respec.md)
- Initialization protocol: [`respec/init.md`](respec/init.md)
- Project progress: [`research/progress.md`](research/progress.md)
- Data understanding: [`research/data_understanding.md`](research/data_understanding.md)
- Research goal: [`research/research_goal.md`](research/research_goal.md)
- Model selection: [`research/model_selection.md`](research/model_selection.md)
- Fine tuning: [`research/fine_tuning.md`](research/fine_tuning.md)
- Iteration trace: [`research/trial_trace.md`](research/trial_trace.md)
- Analysis report: [`research/analysis_report.md`](research/analysis_report.md)
- Experiments: [`experiments/README.md`](experiments/README.md)
- Results: [`results/README.md`](results/README.md)
- Literature shortlist: [`papers/shortlist.md`](papers/shortlist.md)

## How to work in this project

```
claude   # or `gen` / `codex` depending on runtime
> /research phase                 # see what's needed to advance the phase
> /exp paper search "<query>"  # delegate literature triage
> /exp new <name>        # register an experiment
> /train run --metric <m> # autoresearch-style Train Loop
> /research report draft          # produce analysis report draft
```

System prompt and methodology guardrails are loaded from this directory automatically.

## Update rules

- Every new experiment, model change, figure update, or conclusion change must update `research/progress.md` first.
- Methodology guardrails in [`respec/respec.md`](respec/respec.md) are non-negotiable.
- Do not modify `data/raw/`. All transformations land in `data/derived/`.
- Do not read `data/splits/test/` during Model Selection or Fine Tuning phases (the test-set-guard hook will block).
