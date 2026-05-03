---
name: exp-register
description: Create a new experiment directory under experiments/, scaffold its train.py / config.yaml / README.md, and create a git branch. Use when starting any new experiment (called by /exp-new).
allowed-tools: Read, Write, Edit, Bash
---

# Steps

1. **Determine the experiment ID**: list `experiments/`, find the highest existing `EXP<NNN>_*` and increment. Format: `EXP001_baseline`, `EXP002_radiomics-l2`, etc.

2. **Determine parent**:
   - Read `research/progress.md` for the current best experiment ID.
   - If none, this is the baseline. Parent = none.

3. **Create the directory**:

   ```bash
   mkdir -p experiments/EXP<id>_<name>/{figures,artifacts}
   ```

4. **Seed `train.py`**:
   - If parent exists, copy `experiments/<parent>/train.py` as the starting point.
   - Otherwise, create a minimal stub:

     ```python
     #!/usr/bin/env python3
     """EXP<id>: <one-line motivation>"""
     import argparse, json
     # TODO: import your model, dataset, metrics

     def main():
         # TODO: train and eval
         metrics = {"val_auc": 0.0}
         # Print metrics in the ml-researcher convention: one key per line
         for k, v in metrics.items():
             print(f"{k}: {v}")
         with open("metrics.json", "w") as f:
             json.dump(metrics, f, indent=2)

     if __name__ == "__main__":
         main()
     ```

5. **Seed `config.yaml`**: copy parent's, or create empty stub.

6. **Write `README.md`**:

   ```markdown
   # EXP<id>_<name>

   - Created: <today>
   - Parent: <parent or "none — baseline">
   - Motivation: <one-line motivation>
   - Primary metric: <metric from research_goal.md>
   - Hypothesis: <what should improve over parent>

   ## Status

   - Registered

   ## Reproduction

   ```bash
   cd experiments/EXP<id>_<name>
   python train.py > run.log 2>&1
   grep "^val_auc:" run.log  # or whatever the primary metric is
   ```
   ```

7. **Create the git branch and switch**:

   ```bash
   git checkout -b mlr/exp/EXP<id>_<name>
   git add experiments/EXP<id>_<name>
   git commit -m "EXP<id>_<name>: register"
   ```

8. **Append to ledger** (use `ledger-append` skill, status=`registered`).

9. **Append to iteration trace** (use `iteration-log` skill).

10. **Return** the experiment ID and path. Tell the user what file to edit first.

# Notes

- Never overwrite an existing experiment directory.
- The branch name follows `mlr/exp/EXP<id>_<name>` consistently — hooks and ledger queries depend on this.
- The metric printing convention (`<key>: <value>` on its own line) is what `metric-grep` looks for. Stick to it.
