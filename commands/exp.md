---
description: Manage experiments. Subcommands: new <name>, loop --metric ... --budget ..., list, compare <id1> <id2>.
---

Parse `$ARGUMENTS` as `<subcommand> [args...]`. If no subcommand, print usage.

# Usage

```
/exp new <name> [motivation]
/exp loop [--metric <name>] [--budget <duration>] [--max-iter <n>]
/exp list [--filter <status>]
/exp compare <id1> <id2> [<id3>...] [--metric <name>] [--split val|test]
```

---

# Subcommand: new

Register a new experiment.

Steps:

1. Compute next experiment ID by listing `experiments/`. Format `EXP<NNN>_<name>` (3-digit zero-padded).
2. Determine motivation: from $ARGUMENTS rest if provided, else ask user one short question.
3. Determine parent: current best from `research/progress.md`, else "none" (this is the baseline).
4. Use the `experiment-register` skill to scaffold:
   - `experiments/EXPxxx_<name>/{README.md, train.py, config.yaml, figures/, artifacts/}`
   - copy parent's train.py if a parent exists
5. Create branch `mlr/exp/EXPxxx_<name>`, switch to it.
6. Append a row to `experiments/ledger.tsv` (`ledger-append` skill, status=`registered`).
7. Append an entry to `research/iteration_trace.md` (`iteration-log` skill).
8. Tell the user what file to edit first.

---

# Subcommand: loop

Spawn the `experimenter` subagent to run a tight L1 autoresearch-style loop on the current experiment.

1. Verify current branch matches `mlr/exp/EXP*_*`. Otherwise: error and tell the user to `/exp new` first.
2. Run the `checklist-verify` skill with `kind=pre_experiment`. If anything fails, surface and stop.
3. Spawn `experimenter` subagent with:
   - working directory = `experiments/<exp_id>/`
   - primary metric = `--metric` (required) or look up `research/research_goal.md`
   - per-run budget = `--budget` (default 5min)
   - max iterations = `--max-iter` (default unbounded)
   - never-stop = true (autoresearch loop discipline)
4. Do not interrupt the loop unless the user does.
5. When the experimenter returns, summarize: iterations run, best metric, what changed at the best, ledger row count. Update `research/progress.md` if current best changed.

---

# Subcommand: list

Show experiments from the ledger.

1. Read `experiments/ledger.tsv`.
2. Read each `experiments/EXPxxx_*/README.md` for description if not in ledger.
3. Print as a table with columns: ID, Metric, Value, Status, Description. Mark current best with `← CURRENT BEST`.
4. If `--filter <status>` was passed, only show rows matching that status.

---

# Subcommand: compare

Multi-experiment comparison with statistical tests.

1. Resolve experiment IDs from $ARGUMENTS. Verify each `experiments/<id>/metrics.json` exists.
2. For each, read predictions and labels paths.
3. Compute bootstrap CI per experiment via `bootstrap-ci` skill.
4. If exactly two AUC experiments: run paired DeLong test via `delong-test` skill.
5. If three or more: pairwise CI overlap analysis.
6. Render comparison bar chart via `figure-render` skill (`kind=comparison_bar`, error bars = CIs).
7. Print comparison table + tests.

Use the language discipline from `CLAUDE.md` / `GEN.md`: "trend toward" for non-significant, "significantly better" only with passed test.

If `--split test` is requested, the test_set_guard hook will block during Selection/Tuning phases.

$ARGUMENTS
