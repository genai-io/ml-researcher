---
name: checklist-verify
description: Run a pre-flight checklist for a specific kind of action (pre-experiment, pre-phase-advance, pre-finalize). Returns PASS or a structured list of unmet items. Used by hooks and by /check.
allowed-tools: Read, Glob, Grep, Bash
---

# Checklists by kind

## kind=pre-experiment

Before any `experiment-run` invocation:

| # | Check | How to verify |
|---|---|---|
| 1 | Reference implementation cited this turn | grep recent conversation context for arxiv/github URLs |
| 2 | `dataset-inspect` was called | check whether the relevant dataset's path appears in recent tool outputs |
| 3 | Output destination set | look in `experiments/EXPxxx/config.yaml` for `output_dir`, `save_strategy`, `push_to_hub`, etc. |
| 4 | Timeout justified | the experiment-run skill's budget is ≥ 2 × estimated runtime |
| 5 | Run name follows convention | `<task>_<model>_lr<lr>_bs<bs>_<short-tag>` in the run name or experiment name |
| 6 | Baseline exists if claiming improvement | `bash <CFG>/hooks/checks.sh baseline-kept` (rule: row in `experiments/ledger.tsv` with `description` containing "baseline" AND `status=keep`) |

## kind=pre-phase-advance

Use the requirements from `phase-advance.md` for the current → next transition.

## kind=pre-finalize

Before promoting `research/analysis_report.md` to `results/`:

| # | Check | How to verify |
|---|---|---|
| 1 | Report has all required sections | grep for `## Data summary`, `## Goal achievement`, `## Model comparison`, `## Statistical tests`, `## Limits`, `## Conclusion` |
| 2 | Statistical claims have tests | for each "significantly" / "outperforms", verify a test result is in the same paragraph |
| 3 | Critic verdict is recent and PASS | look for last `/audit` invocation; require PASS within last 24h |
| 4 | Cited experiments exist | for each EXP referenced in the report, verify `experiments/EXP*/` exists and has metrics.json |
| 5 | Figures/tables come from the right experiment | verify file mtimes / cross-reference report citations |

# Output

Format:

```
Pre-flight (kind=pre-experiment):

  ✓ 1. Reference implementation cited (arxiv:2502.13138)
  ✓ 2. dataset-inspect called for data/derived/clean.csv
  ✗ 3. Output destination set — config.yaml lacks output_dir
  ✗ 4. Timeout justified — budget=5min but train.py estimate is ~12min
  ✓ 5. Run name follows convention
  ✓ 6. Baseline exists — EXP001_baseline status=keep

Result: FAIL (2 unmet)

To fix:
  - Set output_dir in experiments/EXP004/config.yaml
  - Increase --budget to at least 25min
```

If all pass:

```
Result: PASS — safe to /exp loop.
```

# Behavior in hooks

When called by the `preflight` PreToolUse hook (matcher `experiment-run`), this skill returns:

- exit 0 if PASS — tool execution proceeds
- exit 2 if FAIL — tool blocked; structured remediation list printed to stderr

When called manually via `/check`, the same logic but reported to the user.

# Source of truth for mechanical rules

The mechanical checks above (file existence, ledger row matching, current-experiment-dir grep) are also encoded in `<CFG>/hooks/checks.sh`. Both the `preflight` and `phase_gate` hooks shell out to that script. When a rule changes, edit `checks.sh` and update the corresponding row in this skill — the script is authoritative for what passes/fails; this skill explains *why* and *what to do about it*.
