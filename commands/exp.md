---
description: Manage experiments (Experiment Loop). Subcommands: new <name>, list, compare <id1> <id2>, paper search|read|list.
---

Parse `$ARGUMENTS` as `<subcommand> [args...]`. If no subcommand, print usage.

The Experiment Loop owns *one EXPxxx direction* end-to-end: pick a direction, register it, gather literature, run trials (`/train run`), then decide. To kick off the autoresearch Train Loop inside the current experiment, use `/train run` (not part of this namespace).

# Usage

```
/exp new <name> [motivation]
/exp list [--filter <status>]
/exp compare <id1> <id2> [<id3>...] [--metric <name>] [--split val|test]
/exp paper search <query> [--year-min <yyyy>] [--limit <n>]
/exp paper list
/exp paper read <paper-id>
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
7. Append an entry to `research/trial_trace.md` (`trial-log` skill).
8. Tell the user what file to edit first, then suggest `/train run` to start the autoresearch loop.

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

---

# Subcommand: paper

Literature triage. Delegates to the `literature` subagent.

## paper search (`/exp paper search <query>`)

1. Read `research/research_goal.md` for the project's data regime, task, and constraints. Pass as context to the subagent.
2. Spawn `literature` subagent with:
   - query = $ARGUMENTS rest
   - constraints from research_goal
   - output destination = `papers/shortlist.md` (append) and `papers/notes/<id>.md` (one per paper)
   - limit = `--limit` (default 5)
3. When the subagent returns, surface the top 3 candidates with one-line relevance plus the recommendation.

## paper list (`/exp paper list`)

Show the current literature shortlist.

1. Read `papers/shortlist.md`.
2. Print active entries grouped by section (Active / Rejected).
3. For each entry, show: paper ID, title, one-line relevance.

## paper read (`/exp paper read <paper-id>`)

Fetch and notebook a single paper.

1. Take paper ID (arxiv ID, HuggingFace papers ID, or DOI) from $ARGUMENTS.
2. Use the `paper-read` skill (or WebFetch on ar5iv) to fetch the methodology / experiments / results sections.
3. Write structured notes to `papers/notes/<paper-id>.md`.
4. Surface the key methodology (model, dataset, metric, headline claim) to the user.

$ARGUMENTS
