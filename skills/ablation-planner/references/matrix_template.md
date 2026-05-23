# Ablation matrix template

Use this exact structure for `research/ablation_plan.md` (or per-experiment `experiments/<exp_id>/ablation_plan.md`).

```markdown
# Ablation plan — <claim restated in one sentence>

**Anchor experiment**: EXP<id>_<name> (the result this ablation defends)
**Primary metric**: <metric>
**Baseline reference**: EXP<id>_baseline (metric value = X)
**Plan written**: <YYYY-MM-DD>

## Matrix

| # | Component ablated | Modification | Expected Δ if load-bearing | Actual EXP | Actual Δ | Status |
|---|---|---|---|---|---|---|
| 1 | Imaging encoder | RadDINO → DINOv2 generic | -0.04 to -0.08 | EXP012 | -0.06 | confirms load-bearing |
| 2 | Late fusion linear | linear → mean-of-scores | -0.02 to -0.05 | EXP013 | -0.01 | decorative |
| 3 | Augmentation policy | full → none | -0.03 to -0.06 | [pending] | — | — |
| 4 | Class weighting | balanced → uniform | -0.02 to -0.04 | [pending] | — | — |

## Decisions

- **Component 1 confirmed load-bearing** — the report will claim RadDINO is necessary; cite Δ=-0.06 from EXP012.
- **Component 2 decorative** — the report will NOT claim the linear-fusion choice matters; mean-of-scores would have done equally well. Honest down-revision.
- **Components 3, 4 pending** — block the report until run.
```

## Why this exact shape

- **Pre-registered expected direction** — recording the expected Δ before the run prevents "post-hoc story" rationalization. If the actual matches the expected, that's evidence; if it doesn't, that's also evidence (and more interesting).
- **Per-row decision** — the status column forces an explicit verdict. "Pending" rows that linger indicate planning debt.
- **One row per ablation** — keeps the matrix scannable. If you have >10 rows, split into a second plan or re-prioritize.

## Anti-patterns

- A 30-row matrix with "expected Δ" left blank — that's wishlist, not a plan.
- Updating "expected Δ" after seeing "actual Δ" to make them match — defeats the purpose.
- Marking a row `confirms load-bearing` when actual Δ is within noise — be explicit about effect sizes vs noise floor (typically 1 SE of the metric's bootstrap CI).
