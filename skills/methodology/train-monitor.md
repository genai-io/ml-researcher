---
name: train-monitor
description: Stream-read a running experiment's run.log and classify lines into divergence / overfitting / OOM / NaN signals. Use when /exp-loop or /exp-run is in flight.
allowed-tools: Bash, Read
---

# Detection rules

These are pattern-based and lossy. They surface concerning lines for the agent to act on; they do NOT make decisions autonomously.

## divergence
- Train loss has increased > 2× over the last 50 steps.
- Pattern: parse "loss: <number>" lines; compare windowed averages.

## overfitting
- Train metric is improving while validation metric is degrading.
- Pattern: parse "train_<m>: ..." and "val_<m>: ..." lines; check trend signs.

## oom
- stderr contains `CUDA out of memory`, `OutOfMemoryError`, `RuntimeError: CUDA error: out of memory`.

## nan
- Any metric line contains `nan`, `inf`, or `-inf`.

## stalled
- No new "step:" or "epoch:" line in the last 5 minutes (compare timestamps in the log).

# Steps

1. **Identify the log**: `experiments/EXPxxx_*/run.log` of the actively-running experiment.

2. **Tail since last check**: read from the last position you stopped at (or from start if first call).

3. **Apply detection rules** to the new lines.

4. **Surface alerts** to the calling agent:

   ```
   [WARN] divergence detected at step 240: loss 2.15 → 4.83 over last 50 steps
   [ERROR] OOM detected at step 312: CUDA out of memory tried to allocate 1.5 GB
   ```

5. **Suggest action** (the agent decides whether to act):
   - divergence → suggest LR reduction (× 0.1) and reset the latest commit
   - overfitting → suggest early stopping or regularization
   - oom → invoke `oom-recovery-checklist` skill
   - nan → suggest gradient clipping; reset the run

# Hard rules

- Never tail the entire log into the agent context. Surface only the matched lines + a one-sentence interpretation.
- Don't kill the running process. Surface the alert; the agent or user decides.
- Don't apply fixes silently. The agent applies them via `Edit` and `git commit` like any other iteration.

# Adapted from

ml-intern's monitoring discipline (`agent/prompts/system_prompt_v3.yaml`):
> "Trackio alerts: ERROR (training crashed / nan), WARN (loss diverging / val degrading), INFO (run completed normally). Never suppress alerts."
