---
name: expect-mode
description: Activate, deactivate, and operate within "expect mode" — a sandboxed mode for validating the experiment pipeline with mock metrics, subset data, or fake predictions. Use when the user wants to scaffold an experiment loop end-to-end without paying real compute or before real data is ready.
---

# What expect mode is

A clearly-marked mode that **suspends methodology principle #7 (no fabrication) for development purposes**, while making it impossible for fabricated results to leak into the final report.

When expect mode is on, you may:

- Use a tiny subset of the data (first N patients, first 100 rows, etc.)
- Skip actual training and write a hand-crafted `metrics.json`
- Mock predictions to validate the figure renderer / ledger schema
- Run with `--epochs 1` / `--max-iter 2` to test the pipeline shape

When expect mode is on, you MUST:

- Mark every ledger row with `[EXPECT]` prefix in the description
- Mark every iteration_trace entry with `## [EXPECT] EXP<id>...`
- Add `.expect` marker file inside `experiments/<exp_id>/`
- Add `"expect_mode": true` to `metrics.json` of that run

When expect mode is on, you MUST NOT:

- Promote any artifact to `results/`
- Run `/report final` (it will block)
- Advance to Analysis Report with expect-mode rows still in the ledger
- Cite expect-mode metrics in `research/analysis_report.md`

# Activation

Expect mode is on iff `.mlr-expect-mode` exists at project root.

```bash
# Turn on
touch .mlr-expect-mode

# Turn off
rm .mlr-expect-mode

# Check status
[ -f .mlr-expect-mode ] && echo "ON" || echo "OFF"
```

The slash command `/expect on|off|status` wraps these.

The `inject_state` hook prepends a `<expect-mode>` banner to every user prompt while active, so the agent always knows.

# Promotion path (no magic)

There is no "promote expect run to real run" command. To make an expect-mode result authoritative:

1. `/expect off`
2. `/exp new <same-name-but-real>` — register a NEW experiment
3. Run it for real (real data, real training, real metrics)
4. Optionally delete the `[EXPECT]` row from `experiments/ledger.tsv` to keep history clean

This is intentional: an expect run cannot become a real run by file rename. The pipeline must be rerun under non-expect conditions.

# When to use expect mode

Good cases:
- Building the project skeleton; the pipeline / figure renderer / ledger schema needs to be validated before real data lands
- Debugging a regression in the experimenter loop
- Demonstrating the workflow to a stakeholder before you have results
- Sanity-checking that `/report draft` produces a structurally correct report given fake numbers

Bad cases:
- "I'll just mock the result for now and remember to fix it later" — DO NOT. Either fix it or note in `iteration_trace.md` that this experiment is rejected as crashed.
- Generating expected publication figures from mock data to "see how it would look" — fine for an internal mockup, but the figures must NEVER end up in `results/figures/`.

# Critic enforcement

The `critic` subagent (and the `/audit` command) checks for expect-mode contamination:

- Any `[EXPECT]` row referenced from `research/analysis_report.md` → BLOCK
- Any expect-mode artifact under `results/` → BLOCK
- Any `metrics.json` with `expect_mode: true` cited as a final result → BLOCK
- `/report final` in a project with expect mode active → BLOCK

# Hook notice

When expect mode is on, the `preflight` hook still runs but emits a warning to stderr:

> `[expect-mode] active — pre-flight checks are advisory only.`

Real pre-flight enforcement resumes after `/expect off`.

# Recommended pattern

```
> /expect on
> /exp new mock-clinical-baseline   # leverage tiny data, write metrics by hand
> /exp loop --metric val_auc --budget 30s --max-iter 3   # smoke test the loop
... validate ledger, figures, /report draft structure ...
> /expect off

> /exp new clinical-baseline   # register the REAL run
> /exp loop --metric val_auc --budget 5min --max-iter 50
```

You only "learn the pipeline shape" once, in expect mode. Real research starts after `/expect off`.
