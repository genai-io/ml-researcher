# Template: Fine Tuning on Selected Models

Limited, bounded optimization within shortlisted models. To switch model families, return to Model Selection — do not search without bounds.

## Shortlist recap

(copy from `03_model_selection.md` shortlist)

| Rank | Model | Why |
|---|---|---|
| 1 | `<model>` | `<why>` |

## Per-model parameter ranges

| Model | Parameter | Range | Search strategy | Notes |
|---|---|---|---|---|
| `<model>` | `<param>` | `<range>` | `<grid/random/bayesian>` | `<notes>` |

Recommend: random search for small grids; bayesian for >10 parameters; grid for 2-3 critical parameters.

## Per-model compute budget

| Model | Max iterations | Wall-clock budget per run | Notes |
|---|---|---|---|
| `<model>` | `<n>` | `<duration>` | `<notes>` |

## Tuning protocol

1. Use validation split only.
2. Random seed fixed for reproducibility.
3. Early stopping enabled where applicable.
4. Each tuning iteration is registered as an experiment via `/exp-new` and tracked in `experiments/ledger.tsv`.
5. The L1 loop (`/exp-loop`) automates this end-to-end.

## Final candidates

After tuning, fill in:

| Model | Final parameters | Val metric | CI | Decision |
|---|---|---|---|---|
| `<model>` | `<params>` | `<value>` | `<low, high>` | `<advance to Analysis / drop>` |

## Stop conditions

Stop tuning a model when:
- Improvement plateau over 5+ consecutive iterations
- Train metric improving but val degrading (overfitting; record in iteration_trace)
- Wall-clock budget exhausted

## Outcome

Promote final candidates to Analysis Report. Update `research/progress.md` with phase transition.
