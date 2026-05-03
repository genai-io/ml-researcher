# Results — {{TOPIC}}

Curated, conclusion-grade artifacts. Promoted from `experiments/` only after they pass the analyst + critic review.

## Layout

| Subdir | Purpose |
|---|---|
| `figures/` | Final figures referenced in the analysis report |
| `tables/` | Final tables (CSV, with their rendering instructions if any) |
| `reports/` | Final report markdown (a reader-friendly companion to `research/analysis_report.md`) |

## Promotion rule

A figure / table / report fragment moves into `results/` ONLY when:
- It's referenced by `research/analysis_report.md` as a final artifact
- The cited experiment passed `critic`
- The data it uses comes from a `keep` row in `experiments/ledger.tsv`

This keeps `results/` small, defensible, and the canonical "what should be shown to a reviewer."
