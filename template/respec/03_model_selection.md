# Template: Model Selection

Compare data scenarios × model families laterally. Output is a shortlist of candidates entering Fine Tuning, plus a rejection log.

## Candidate matrix

| Scenario | Model family | Status | Reason |
|---|---|---|---|
| `<scenario>` | `<family>` | `<shortlisted/rejected/postponed>` | `<one-line reason>` |

Use the `model-recommend` skill (queries `data/model_registry.yaml`) before populating this matrix. For domain-specific guidance see `skills/ml/<domain>.md`.

## Shortlist (entering Fine Tuning)

| Rank | Model | Why | Expected metric (val) | Reference impl |
|---|---|---|---|---|
| 1 | `<model>` | `<why>` | `<expected>` | `<url>` |
| 2 | ... | | | |

## Rejection log (do not re-attempt without new evidence)

| Model | Reason rejected | Date | Evidence |
|---|---|---|---|
| `<model>` | `<reason>` | `<date>` | `<exp_id or paper>` |

## Decisions

- Inputs to keep across all candidates:
- Inputs to drop:
- Preprocessing pipeline (must be identical across candidates for fairness):
- Random seed handling:
- CV strategy (e.g., 5-fold patient-level for medical imaging):

## Risks at this stage

- Snooping risk on validation set: how mitigated
- Overfitting model selection: how mitigated (hold-out validation, CV, etc.)
- Compute / time budget per candidate:

## Outcome

After selection, transition to Fine Tuning by:
1. Running `/exp-new <baseline_or_first_shortlisted>` if not already.
2. Updating `research/progress.md` to phase = "Fine Tuning".
3. Verifying `phase-advance` skill returns no missing requirements.
