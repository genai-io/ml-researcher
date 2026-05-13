---
name: metric-grep
description: Extract metric values from run.log using the convention "<key>: <value>" lines. Returns a dict. Used after every experiment run.
allowed-tools: Bash, Read
---

# Convention

Train scripts print metrics in this format, one per line:

```
val_auc: 0.715
val_brier: 0.183
peak_vram_mb: 6240
duration_seconds: 142
```

Anything else in the log is ignored by this skill.

# Steps

1. **Identify the log file**: `experiments/EXPxxx_*/run.log` (relative to project root).

2. **Identify the keys to grep**: from arguments, or default to:
   - The primary metric from `research/research_goal.md`
   - Common companions: `peak_vram_mb`, `duration_seconds`, `train_loss` (if present)

3. **Grep each key**:

   ```bash
   for key in val_auc peak_vram_mb duration_seconds; do
     grep -m1 "^$key:" run.log
   done
   ```

4. **Parse the output** into a dict:

   ```json
   {"val_auc": 0.715, "peak_vram_mb": 6240, "duration_seconds": 142}
   ```

5. **If a required metric is missing** (the run probably crashed):
   - Read the last 50 lines of `run.log` (use `tail -n 50`)
   - Surface those lines to the calling agent as diagnostic context
   - Return `{}` for the metrics

6. **Return** the dict to the calling agent.

# Hard rules

- Use `grep -m1` (first match) so re-printed metrics from validation cycles don't override the final value.
- Never read the entire run.log into the agent context. Tail at most 50 lines.
- Don't try to parse free-form messages like "Training complete!" — only the structured `key: value` lines.

# If the convention isn't followed

If `train.py` doesn't print metrics in the convention, the agent should ask the user to update `train.py` to follow it. Don't try to extract metrics from progress bars or logger messages — that path leads to silent bugs.

The `exp-register` skill's `train.py` template uses the right convention. Use it.
