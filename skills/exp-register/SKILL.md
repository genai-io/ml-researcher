---
name: exp-register
description: Create a new experiment directory under experiments/, scaffold its train.py / config.yaml / README.md, and create a git branch. Use when starting any new experiment (called by /exp new). Templates in references/.
allowed-tools: Read Write Edit Bash
---

# Steps

1. **Determine the experiment ID**: list `experiments/`, find the highest existing `EXP<NNN>_*` and increment. Format: `EXP001_baseline`, `EXP002_radiomics-l2`, etc.

2. **Determine parent**: read `research/progress.md` for the current best experiment ID. If none, this is the baseline; parent = none.

3. **Create the directory**:

   ```bash
   mkdir -p experiments/EXP<id>_<name>/{figures,artifacts}
   ```

4. **Seed `train.py`**: if parent exists, copy `experiments/<parent>/train.py`. Otherwise use the minimal stub in `references/train_py_template.md` — it follows the `<key>: <value>` metric-printing convention that `metric-grep` depends on.

5. **Seed `config.yaml`**: copy parent's, or create empty stub.

6. **Write `README.md`** using the template in `references/readme_template.md` (Created / Parent / Motivation / Primary metric / Hypothesis / Status / Reproduction sections).

7. **Create the git branch and switch**:

   ```bash
   git checkout -b mlr/exp/EXP<id>_<name>
   git add experiments/EXP<id>_<name>
   git commit -m "EXP<id>_<name>: register"
   ```

8. **Generate initial seal** via [[repro-seal]] (records the env at experiment birth).

9. **Append to ledger** via [[ledger-append]] (status=`registered`).

10. **Append to trial trace** via [[trial-log]].

11. **Return** the experiment ID and path. Tell the user what file to edit first.

# Hard rules

- Never overwrite an existing experiment directory.
- Branch name follows `mlr/exp/EXP<id>_<name>` consistently — hooks and ledger queries depend on this.
- Metric printing convention (`<key>: <value>` on its own line) is what `metric-grep` looks for. Stick to it.
- The initial repro-seal at step 8 may be `dirty: true` if the user has uncommitted work — that's expected at registration; re-seal after the first `keep`.

# Related

Pairs with [[ledger-append]], [[trial-log]], [[repro-seal]] (all called from step 8–10). The `/exp new` slash command invokes this skill.
