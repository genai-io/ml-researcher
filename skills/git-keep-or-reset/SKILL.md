---
name: git-keep-or-reset
description: After an experiment iteration, advance the experiment branch (keep) or revert to the previous commit (reset). The git branch IS the audit trail of what improved.
allowed-tools: Bash
---

# Inputs

`decision` — one of `keep`, `reset`, `crash`.

# Behavior

## keep

The most recent commit on the experiment branch is the new state. Do nothing — the branch advances naturally.

```bash
# verify we're on an mlr/exp/* branch
git branch --show-current  # should match mlr/exp/EXP*_*
# log the keep
echo "→ kept commit $(git rev-parse --short HEAD)"
```

## reset

Revert to the previous commit. The change just made was discarded.

```bash
git reset --hard HEAD~1
echo "→ reset to $(git rev-parse --short HEAD)"
```

## crash

Same as reset, but record `status=crash` in the ledger so the user/analyst can see how many iterations crashed vs were merely worse.

```bash
git reset --hard HEAD~1
echo "→ reset (crash) to $(git rev-parse --short HEAD)"
```

# Hard rules

- Only operate on `mlr/exp/EXP*_*` branches. If on `main` or any other branch, refuse.
- Never `git reset --hard` past the experiment-register commit. If a reset would land on `main`, refuse and tell the user.
- The branch's tip after the loop ends represents the "best so far" within the experiment. The ledger.tsv records the full history of attempts.

# Why git-as-ledger

A branch with sequential keep-commits is a self-documenting record of what improved. Combined with `experiments/ledger.tsv` (which records every attempt including discards), you can:

- Bisect to find which change introduced a regression.
- Replay the experiment history end-to-end.
- See diff between current best and any prior state with `git diff`.

This is the discipline from karpathy/autoresearch — git is the state machine.
