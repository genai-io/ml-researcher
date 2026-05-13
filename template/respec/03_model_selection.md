# Template: Model Selection

Compare data scenarios × model families laterally. Output is a shortlist of candidates entering Fine Tuning, plus a rejection log.

## Literature consulted

Every candidate in the matrix below must trace to at least one of: a paper from the literature shortlist, a curated entry in `data/model_registry.yaml`, or an explicit "domain default" reasoning step. The point is to make the audit trail explicit — the critic should be able to ask "why this model?" and find an answer in this section, not in chat history.

| Source | Citation / registry id | Used for which candidate(s) | Relevance |
|---|---|---|---|
| `<paper / repo / registry>` | `<arxiv id / hf id / file>` | `<model name>` | `<one-line why this is a relevant precedent>` |

Run `/exp paper search "<query>"` (which delegates to the `literature` subagent) and `model-recommend` (which queries `data/model_registry.yaml`) before populating this table and the matrix below. If a candidate has no precedent of any kind, justify why it deserves the slot anyway in the matrix's "Reason" column.

## Candidate matrix

| Scenario | Model family | Status | Reason |
|---|---|---|---|
| `<scenario>` | `<family>` | `<shortlisted/rejected/postponed>` | `<one-line reason>` |

For domain-specific guidance see `skills/<domain>/SKILL.md` (e.g. `skills/medical-small-sample-transfer/SKILL.md`, `skills/tabular-tabpfn-vs-xgboost/SKILL.md`). Each row's "Reason" should reference one or more entries in the *Literature consulted* table above.

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
1. Running `/exp new <baseline_or_first_shortlisted>` if not already.
2. Updating `research/progress.md` to phase = "Fine Tuning".
3. Verifying `phase-advance` skill returns no missing requirements.
