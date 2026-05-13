# Template: Analysis Report

Convert the complete research process into an auditable conclusion.

## Executive summary

(2-3 sentences: what was studied, what was found, what's the next step.)

## 1. Data summary

- Sample units: `<n>`
- Splits: train `<n>` / val `<n>` / test `<n>` (locked)
- Label distribution: positive `<n>` / negative `<n>`
- QC findings: `<key issues + how addressed>`
- Limits at the data level: `<single-center? retrospective? labeling consistency?>`

## 2. Goal achievement

For each goal in `research_goal.md`:

| Goal | Target | Achieved | Verdict |
|---|---|---|---|
| `<goal>` | `<target>` | `<value>` | `<met/partial/missed>` |

No spin. State explicitly which targets were missed.

## 3. Model comparison

| Model | Val metric | Val CI | Test metric | Test CI | Notes |
|---|---|---|---|---|---|
| Baseline | `<v>` | `<low, high>` | `<v>` | `<low, high>` | |
| Candidate A | | | | | |

CIs computed via `bootstrap-ci` skill. Test set used **only** in this section.

## 4. Statistical tests

For each pairwise comparison declared in research_goal:

- **Pair**: <model A> vs <model B>
- **Test**: <DeLong / paired bootstrap / other>
- **Result**: <z, p, CI>
- **Verdict**: `<significantly better / trend toward / comparable>`

Use the language discipline from `prompts/ml_researcher.md`. Never write "outperforms" without a test.

## 5. Calibration

- Brier score: <value> per model
- Reliability diagram: `results/figures/<file>.png`
- Calibration risk: <e.g., "model is over-confident in the high-probability bin">

## 6. Negative results and ablations

What was tried that did NOT work, and what we learned. This section is mandatory — its absence is itself a methodology issue.

| Direction | What was tried | Why discarded | Lesson |
|---|---|---|---|
| `<direction>` | `<tried>` | `<reason>` | `<lesson>` |

## 7. Limits

A defensible report always has limits. Address each:

- Sample size and statistical power
- Generalization (single-center? single-modality? single-time?)
- Confounders not controlled
- Calibration on test (especially for clinical use)
- Label quality and inter-rater agreement
- Compute / methodology constraints

## 8. Conclusion

State plainly:
- What is supported by the evidence
- What is not supported
- What's the next step (more data? different method? deployment?)

## 9. References

- `research/research_goal.md` (locked at start)
- `experiments/ledger.tsv` (full audit trail)
- `research/trial_trace.md` (per-experiment rationale)
- `papers/shortlist.md` (literature)
- key paper IDs / URLs

## 10. Reproduction

```bash
# How to reproduce the headline result from raw data
git checkout <commit>
python experiments/<best_exp_id>/train.py > run.log 2>&1
grep "^val_auc:\|^test_auc:" run.log  # or whatever the metrics are
```
