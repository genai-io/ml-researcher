# Template: Research Goal

Convert user intent, data capability, and constraints into a concrete, verifiable, stoppable research goal.

## User Intent

- User goal:
- Domain motivation:
- Desired model behavior:
- Desired evidence level:
- Constraints (timeline, compute, license, deployment):

## Primary Research Question

`<one sentence primary research question>`

## Endpoints

| Endpoint | Type | Definition | Role | Notes |
|---|---|---|---|---|
| `<endpoint>` | `<binary/regression/survival/etc>` | `<definition>` | `<primary/secondary>` | `<notes>` |

## Model Scenarios

| Scenario | Input Data | Expected Role | Expected Performance Relationship |
|---|---|---|---|
| Baseline | `<minimal inputs>` | Reference | `<rule>` |
| Single modality A | `<inputs>` | Compare modality value | `<rule>` |
| Single modality B | `<inputs>` | Compare modality value | `<rule>` |
| Fusion | `<combined inputs>` | Test incremental value | `<expected best or not>` |

## Metrics

| Metric | Role | Computed On | Decision Use |
|---|---|---|---|
| `<metric>` | `<primary/secondary>` | `<train/cv/validation/test>` | `<selection/reporting>` |

Recommended:
- Discrimination: AUC, accuracy, balanced accuracy, F1, sensitivity, specificity
- Calibration: Brier score, calibration curve
- Statistical comparison: confidence interval, paired test (DeLong for AUC), bootstrap, permutation

## Success Criteria

- Minimum acceptable result:
- Target result:
- Model ordering expectation:
- Calibration requirement:
- Complexity limit:
- Interpretability requirement:
- Required sensitivity/specificity threshold (clinical / business):

## Baseline Requirement

- Baseline model:
- Why this baseline is fair:
- What improvement must be shown:
- Whether baseline is only a reference, or a candidate final model:

## Required Figures and Tables

| Type | Name | Purpose | Required for Final Report |
|---|---|---|---|
| Figure | `<figure>` | `<purpose>` | `<yes/no>` |
| Table | `<table>` | `<purpose>` | `<yes/no>` |

## Risks and Guardrails

- Data leakage risks:
- Small sample risks:
- Overfitting risks:
- Label quality risks:
- Confounding risks:
- Reporting guardrails (language discipline; statistical claims):

## Next Steps

1. Complete data understanding.
2. Define baseline.
3. Select candidate method families.
4. Run initial experiments.
5. Review whether goals need adjustment.
