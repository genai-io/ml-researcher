---
description: Start a tight L1 autoresearch-style loop on the current experiment. Edit → run → measure → keep-or-reset until budget exhausted.
---

Spawn the `experimenter` subagent to run a tight L1 optimization loop.

Argument parsing:
- `--metric <name>` (required) — the primary metric to optimize. Lower-is-better unless suffixed `:max`.
- `--budget <duration>` — per-run wall-clock budget. Default `5min`. Examples: `30s`, `5min`, `1h`.
- `--max-iter <n>` — optional iteration cap. Default unbounded.
- `--never-stop` — enforce "do not pause to ask" mode (default true for loop).

Default the experiment to the current branch's experiment if not specified.

Steps:

1. Verify the current git branch is an experiment branch (`mlr/exp/EXPxxx_*`). If not, error and ask the user to `/exp-new` first.

2. Verify the pre-flight checklist (use `checklist-verify` skill with `kind=pre_experiment`). If anything fails, surface the missing items and stop. **Do not start the loop with violations.**

3. Spawn the `experimenter` subagent with:
   - Working directory = `experiments/EXPxxx_<name>/`
   - Primary metric = `$METRIC`
   - Budget = `$BUDGET` per run
   - Max iter = `$MAX_ITER` if set
   - Never-stop = $NEVER_STOP
   - Reference to the loop protocol in `prompts/ml_researcher.md`

4. While the experimenter runs, do not interrupt unless the user does.

5. When the experimenter returns, report a summary:
   - Iterations run
   - Best metric and the diff that produced it
   - Status of the ledger
   - Update `research/progress.md` if the current best changed.

$ARGUMENTS
