---
name: sandbox-mode
description: Activate, deactivate, and operate within "sandbox mode" — a sandboxed mode for validating the experiment pipeline with mock metrics, subset data, or fake predictions. Use when the user wants to scaffold an experiment loop end-to-end without paying real compute or before real data is ready.
---

# What sandbox mode is

A clearly-marked mode that **suspends methodology principle #7 (no fabrication) for development purposes**, while making it impossible for fabricated results to leak into the final report.

When sandbox mode is on, you may:

- Use a tiny subset of the data (first N patients, first 100 rows, etc.)
- Skip actual training and write a hand-crafted `metrics.json`
- Mock predictions to validate the figure renderer / ledger schema
- Run with `--epochs 1` / `--max-iter 2` to test the pipeline shape

When sandbox mode is on, you MUST:

- Mark every ledger row with `[SANDBOX]` prefix in the description
- Mark every trial_trace entry with `## [SANDBOX] EXP<id>...`
- Add `.sandbox` marker file inside `experiments/<exp_id>/`
- Add `"sandbox_mode": true` to `metrics.json` of that run

When sandbox mode is on, you MUST NOT:

- Promote any artifact to `results/`
- Run `/research report final` (it will block)
- Advance to Analysis Report with sandbox-mode rows still in the ledger
- Cite sandbox-mode metrics in `research/analysis_report.md`

# Activation

Sandbox mode is on iff `.mlr-sandbox-mode` exists at project root.

```bash
# Turn on
touch .mlr-sandbox-mode

# Turn off
rm .mlr-sandbox-mode

# Check status
[ -f .mlr-sandbox-mode ] && echo "ON" || echo "OFF"
```

The slash command `/sandbox on|off|status` wraps these.

The `sandbox_mode_banner` hook prepends a `<sandbox-mode>` banner to every user prompt while active, so the agent always knows. When the marker is absent the hook is a no-op (no shadow state injection).

# Promotion path (no magic)

There is no "promote sandbox run to real run" command. To make an sandbox-mode result authoritative:

1. `/sandbox off`
2. `/exp new <same-name-but-real>` — register a NEW experiment
3. Run it for real (real data, real training, real metrics)
4. Optionally delete the `[SANDBOX]` row from `experiments/ledger.tsv` to keep history clean

This is intentional: a sandbox run cannot become a real run by file rename. The pipeline must be rerun under non-sandbox conditions.

# When to use sandbox mode

Good cases:
- Building the project skeleton; the pipeline / figure renderer / ledger schema needs to be validated before real data lands
- Debugging a regression in the experimenter loop
- Demonstrating the workflow to a stakeholder before you have results
- Sanity-checking that `/research report draft` produces a structurally correct report given fake numbers

Bad cases:
- "I'll just mock the result for now and remember to fix it later" — DO NOT. Either fix it or note in `trial_trace.md` that this experiment is rejected as crashed.
- Generating expected publication figures from mock data to "see how it would look" — fine for an internal mockup, but the figures must NEVER end up in `results/figures/`.

# Critic enforcement

The `critic` subagent (and the `/audit` command) checks for sandbox-mode contamination:

- Any `[SANDBOX]` row referenced from `research/analysis_report.md` → BLOCK
- Any sandbox-mode artifact under `results/` → BLOCK
- Any `metrics.json` with `sandbox_mode: true` cited as a final result → BLOCK
- `/research report final` in a project with sandbox mode active → BLOCK

# Hook notice

When sandbox mode is on, the `preflight` hook still runs but emits a warning to stderr:

> `[sandbox-mode] active — pre-flight checks are advisory only.`

Real pre-flight enforcement resumes after `/sandbox off`.

# Recommended pattern

```
> /sandbox on
> /exp new mock-clinical-baseline   # leverage tiny data, write metrics by hand
> /train run --metric val_auc --budget 30s --max-iter 3   # smoke test the loop
... validate ledger, figures, /research report draft structure ...
> /sandbox off

> /exp new clinical-baseline   # register the REAL run
> /train run --metric val_auc --budget 5min --max-iter 50
```

You only "learn the pipeline shape" once, in sandbox mode. Real research starts after `/sandbox off`.
