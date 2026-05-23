# Critic enforcement for sandbox contamination

The `critic` subagent (and the `/audit` command) checks for sandbox-mode leakage with these rules. Each rule that triggers returns **BLOCK** unless noted otherwise.

## BLOCK rules

| # | Rule | Where to look |
|---|---|---|
| 1 | Any `[SANDBOX]` row in `experiments/ledger.tsv` is referenced by `research/analysis_report.md` | Grep ledger for `[SANDBOX]`, grep report for the matching exp_id |
| 2 | Any artifact under `results/` whose source experiment has a `.sandbox` marker | List `results/`, trace back to source exp by figure caption / table reference |
| 3 | Any `metrics.json` with `"sandbox_mode": true` cited as a final result | Grep `metrics.json` files for the flag, cross-reference the report |
| 4 | `/research report final` invoked while `.mlr-sandbox-mode` exists at project root | Check root for marker file |
| 5 | Current phase = Analysis Report AND `.mlr-sandbox-mode` is on AND audit scope is `report` or `current-best` | Phase from `research/progress.md`, marker from project root |

## WARN rules

| # | Rule | Why WARN not BLOCK |
|---|---|---|
| 1 | `.mlr-sandbox-mode` present but audit scope is general (not finalization-related) AND no sandbox artifact has leaked yet | Mode is on but hasn't caused damage yet — surface, don't block |

## What critic prints

```
BLOCK
1. Sandbox contamination at research/analysis_report.md:42 — references EXP004 which has .sandbox marker.
2. Sandbox contamination at results/figures/roc_main.png — source exp EXP004 is sandbox.
```

The user fixes (typically: `/sandbox off`, register the real exp, re-run, re-render, update report citations) and re-runs `/audit` until PASS.

## Hook companion

The `preflight` hook also runs while sandbox is on, but emits an advisory only:

> `[sandbox-mode] active — pre-flight checks are advisory only.`

Real pre-flight enforcement resumes after `/sandbox off`. The critic is what actually blocks at the report-finalization boundary.
