---
name: exp-run
description: Execute the current experiment's train.py with output redirection and timeout. Always redirect to run.log; never tee. Used in the L1 loop and for one-off runs.
allowed-tools: Bash
---

# Steps

1. **Verify location**: ensure the current working directory is `experiments/EXPxxx_*/` or that the experiment id is given. If not, fail with a message asking the user to specify.

2. **Verify pre-flight** (if not already verified this turn): use `checklist-verify` skill with `kind=pre_experiment`. Block if it fails.

3. **Determine budget**: from arguments, default `5min`. Convert to seconds.

4. **Run with redirection** (the key rule — never tee):

   ```bash
   cd experiments/EXPxxx_*
   timeout <budget_seconds> python train.py > run.log 2>&1
   echo "exit: $?" >> run.log
   ```

5. **Report exit status to the agent** (single line, not the full log):

   ```
   ✓ EXP<id> ran for <duration>; exit=<code>
   ```

   or

   ```
   ✗ EXP<id> crashed after <duration>; exit=<code>; tail of run.log:
   <last 20 lines of run.log via tail -n 20>
   ```

6. **DO NOT** print the full run.log to the agent context. The agent uses `metric-grep` afterwards to read what's needed.

# Hard rules

- Never `tee`. Output goes to file only.
- Never run with `--verbose` flags that would re-flood the log.
- If the run crashes, tail 20 lines for diagnostic context — but use that for the agent's decision, do NOT loop on tail-and-ask.
- Respect the timeout. If a run exceeds it, treat as a failure and `git_keep_or_reset reset`.

# Why "no tee"

In an autoresearch-style loop, the agent runs ~50 experiments per hour. Even 100 lines of stdout per run × 50 = 5000 lines of text in the agent context, which:
- Wastes the context window
- Makes the agent slower per turn
- Hides the actual decision (the metric line)

The metric-grep convention solves this: the agent only needs the metric, not the loss curve.
