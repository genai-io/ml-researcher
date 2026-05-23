# README.md template for an experiment

Seed `experiments/EXP<id>_<name>/README.md` with this structure. Sections may be empty at registration (filled as the experiment progresses) but the headings should always appear.

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

## OOM recovery (only fill if applicable)

- Step N applied: <change>
- Date: <date>
```

## Section meanings

- **Created / Parent** — provenance. Parent links to the EXP id that this one branched from.
- **Motivation** — one sentence. "Test wavelet features", "Try LoRA on top of EXP003", etc.
- **Primary metric** — must match the one in `research/research_goal.md`. Inconsistency here triggers critic warnings.
- **Hypothesis** — what specifically should change vs parent. The experimenter loop reads this to ground its first trial.
- **Status** — `Registered` → `Running` → `Kept (best so far)` or `Discarded`. Update as the experiment progresses.
- **Reproduction** — the exact command the analyst / external reader uses to re-run. Keep current.
- **OOM recovery** — only fill if the experiment hit OOM and you applied `oom-recovery-checklist`. Empty otherwise.
