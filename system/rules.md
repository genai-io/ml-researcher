# Research hygiene (non-negotiable gates)

These gates exist for one reason: so the result is **credible and reproducible** — something a reviewer, a collaborator, or you-in-six-months can trust. They are research hygiene, not bureaucracy. Hooks enforce them, and so do you: if a hook fails first, the run blocks; if you check proactively, you save a turn.

1. **Data before model.** No model proposal until `research/data_understanding.md` has the dataset inventory, sample unit, label definition, splits, and QC.
2. **Goal before optimization.** No experiment until `research/research_goal.md` has the primary metric, baseline, and success criteria.
3. **Test-set isolation.** During Model Selection and Fine Tuning, `data/splits/test/**` is not readable for any purpose other than reporting in Analysis. Do not "peek." Do not run `metric-grep` on test predictions for selection. Selecting on the test set is how an evaluation gets quietly inflated.
4. **Baseline mandatory.** No improvement claim without a registered baseline experiment in `experiments/`. The first experiment in any project is the baseline.
5. **Result consistency.** Reported metrics, figures, model files, and prediction files must come from the same `experiments/EXPxxx/` directory. Do not mix and match.
6. **Label exploratory artifacts.** Mocks, simulated labels, subset/dev runs, and pipeline-scaffolding shortcuts are labeled as such in `trial_trace.md`; they inform engineering but never count as evidence. (See Sandbox mode below.)
7. **Simple-first.** Under sample-size constraints (< 1000 rows), prefer linear / logistic / TabPFN / XGBoost over deep nets. Complex models must justify their gain on a held-out set, not on training/CV.
8. **Stoppable.** When added complexity raises train/CV but lowers val/test, record the overfitting risk in `trial_trace.md` and stop the direction. Do not optimize the metric you are about to overfit.

## Phase gate

You may not advance a research phase until its gate is satisfied. Attempt advancement with the `phase-advance` skill (or `/research phase advance`); the gate output names exactly what's missing. Before advancing, spawn `critic` for an audit — proceed only on PASS.

## Sandbox mode (pipeline-scaffolding sandbox)

When the user wants to validate the experiment loop with mock metrics or a tiny data subset — e.g. to sanity-check the ledger, figure renderer, or report structure before paying real compute — they activate **sandbox mode**.

Detection: the `sandbox_mode_banner` hook surfaces `<sandbox-mode rows="N">ACTIVE…</sandbox-mode>` on every prompt whenever `.mlr-sandbox-mode` exists at project root. When the banner is absent, sandbox mode is off — read `research/progress.md` directly for phase, current best, and next step.

When sandbox mode is active:

- It **is** OK to: mock metrics, subset data, skip real training, hand-write `metrics.json`.
- It **is not** OK to: omit `[SANDBOX]` from new ledger rows; cite a sandbox-mode result in the analysis report; promote anything to `results/`.
- Required tags on every new artifact: `[SANDBOX]` prefix in the ledger description; `## [SANDBOX]` heading in `trial_trace`; a `.sandbox` marker file in `experiments/<exp_id>/`; `"sandbox_mode": true` in `metrics.json`.

The `critic` and `/research report final` will refuse to advance while sandbox mode contaminates final output. There is no "promote" — to make a sandbox run real, disable the mode and re-register a new experiment.

See `skills/sandbox-mode/SKILL.md` for the full contract.
