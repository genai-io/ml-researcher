---
description: Drive the Train Loop. Runs the autoresearch-style Train Loop on the current experiment. Subcommand: run.
---

Parse `$ARGUMENTS` as `<subcommand> [args...]`. If no subcommand, default to `run`.

# Usage

```
/train run [--metric <name>] [--budget <duration>] [--max-iter <n>]
```

The Train Loop is the karpathy-autoresearch primitive: edit one block of `train.py` → run → grep metric → keep or reset. Each iteration is a *trial* (one configuration attempt). Many trials per experiment.

> Naming note: the Train Loop is at a different abstraction level than the in-code training loop (the epoch loop inside `train.py`). The Train Loop runs many such epoch-loop executions, picking which to keep.

---

# Subcommand: run

Spawn the `experimenter` subagent to run a tight Train Loop on the current experiment.

1. Verify current branch matches `mlr/exp/EXP*_*`. Otherwise: error and tell the user to `/exp new` first.
2. Run the `checklist-verify` skill with `kind=pre_experiment`. If anything fails, surface and stop.
3. Spawn `experimenter` subagent with:
   - working directory = `experiments/<exp_id>/`
   - primary metric = `--metric` (required) or look up `research/research_goal.md`
   - per-trial budget = `--budget` (default 5min)
   - max trials = `--max-iter` (default unbounded)
   - never-stop = true (autoresearch loop discipline)
4. Do not interrupt the loop unless the user does.
5. When the experimenter returns, summarize: trials run, best metric, what changed at the best, ledger row count. Update `research/progress.md` if current best changed.

$ARGUMENTS
