---
name: sandbox-mode
description: Activate, deactivate, and operate within "sandbox mode" — a clearly marked mode for validating the experiment pipeline with mock metrics, subset data, or fake predictions. Use when scaffolding an experiment loop end-to-end without paying real compute, or before real data is ready. Detail in references/.
---

# What sandbox mode is

A clearly-marked mode that **suspends methodology principle #7 (no fabrication) for development purposes**, while making it impossible for fabricated results to leak into the final report.

# When to use

Good cases:
- Building the project skeleton before real data lands
- Debugging a regression in the experimenter loop
- Demonstrating the workflow to a stakeholder before you have results
- Sanity-checking that `/research report draft` produces a structurally correct report given fake numbers

Bad cases:
- "I'll mock the result for now and fix it later" — DO NOT. Either fix it or record as crashed.
- Generating expected publication figures from mock data to "see how it would look" — OK for internal mockup, but figures must NEVER end up in `results/figures/`.

# Activation

Sandbox is on iff `.mlr-sandbox-mode` exists at project root.

```bash
touch .mlr-sandbox-mode     # turn on
rm .mlr-sandbox-mode        # turn off
[ -f .mlr-sandbox-mode ] && echo ON || echo OFF
```

The `/sandbox on|off|status` slash command wraps these. The `sandbox_mode_banner` hook prepends a `<sandbox-mode>` banner to every prompt while active; when the marker is absent the hook is a no-op (no shadow state injection).

# While ON you MUST

- Mark every ledger row with `[SANDBOX]` prefix in the description
- Mark every trial_trace entry with `## [SANDBOX] EXP<id>...`
- Add `.sandbox` marker file inside `experiments/<exp_id>/`
- Add `"sandbox_mode": true` to that run's `metrics.json`

# While ON you MUST NOT

- Promote any artifact to `results/`
- Run `/research report final` (it will block)
- Advance to Analysis Report with sandbox rows still in the ledger
- Cite sandbox-mode metrics in `research/analysis_report.md`

# Promotion is not a rename

There is no "promote sandbox run to real run" command. To make a sandbox-mode result authoritative, run a NEW experiment for real after `/sandbox off`. Full procedure: `references/promotion.md`.

# Critic enforcement

Critic checks for `[SANDBOX]` contamination at finalize time and blocks if leakage is detected. Exact rules: `references/critic_rules.md`.

# Recommended pattern

```
> /sandbox on
> /exp new mock-clinical-baseline
> /train run --metric val_auc --budget 30s --max-iter 3
... validate ledger, figures, /research report draft structure ...
> /sandbox off

> /exp new clinical-baseline
> /train run --metric val_auc --budget 5min --max-iter 50
```

You only learn the pipeline shape once, in sandbox mode. Real research starts after `/sandbox off`.
