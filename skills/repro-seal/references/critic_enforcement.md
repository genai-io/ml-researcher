# Critic enforcement of repro-seal

When the critic agent runs `kind=pre-finalize`, these rules apply to every experiment cited in `research/analysis_report.md`. Failures return **BLOCK**.

## Required-presence rules

| # | Rule |
|---|---|
| 1 | `experiments/<exp_id>/repro_seal.json` exists |
| 2 | Seal's `dirty` field is `false` |
| 3 | Seal's `data.splits_locked` is `true` |
| 4 | Seal's `git_sha` is reachable from `main` or a tag (i.e., not orphaned by rebase) |

## Phase-consistency rules

| # | Rule |
|---|---|
| 5 | If `data.splits.test` is non-null AND the experiment is NOT from Analysis phase → BLOCK (the run touched test before Analysis) |
| 6 | If the experiment is Analysis-phase AND `data.splits.test` is null → WARN (test was somehow not part of the seal) |

## Drift rules (when running `--verify`)

| # | Rule |
|---|---|
| 7 | Any drift in `data.splits.*` → BLOCK (data changed since the seal — metrics invalidated) |
| 8 | Drift in `python.version` major.minor → BLOCK (different interpreter) |
| 9 | Drift in `cuda.version` major → WARN (numerical results may differ slightly) |
| 10 | Drift in `packages.*` for a load-bearing package (torch, numpy, scikit-learn, transformers) → WARN |

## What critic prints

```
BLOCK
1. EXP003: no repro_seal.json at experiments/EXP003_combined-linear-svm/.
2. EXP004: seal has dirty=true. Re-seal after committing.
3. EXP005: data.splits.val drift detected — sha256:1b22... → sha256:8f44...
```

The user fixes (re-seal, commit, or investigate the data drift) and re-runs `/audit` until PASS.

## What's NOT enforced

The seal is a *snapshot*, not a *re-run*. Critic does not actually re-execute the experiment — it only verifies that the snapshot is internally consistent and that the recorded state matches the current state. Full re-execution is the user's responsibility when reproducibility is questioned.
