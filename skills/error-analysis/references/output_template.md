# Error-analysis prose template

Use this exact structure for `experiments/<exp_id>/error_analysis/error_analysis.md`. The downstream consumers (analyst, future you) grep these headings.

```markdown
## EXP<id> error analysis — <date>

### Worst-K summary

- Total errors: N (out of M val samples; metric = X)
- Top failure pattern: <one sentence, e.g., "rare class (label=1) predicted as majority in 12/20 worst cases">
- Concentration: <where the worst cases live — e.g., "8/20 from scanner=GE">

### Slice breakdown

| Slice | n | metric | Δ vs overall |
|---|---|---|---|
| sex=F | 132 | 0.71 | -0.04 |
| sex=M | 138 | 0.78 | +0.03 |
| scanner=GE | 80 | 0.62 | **-0.13** |

Underpowered slices (n < 10): <list>

### Confusion concentration

Top off-diagonal mass: <which class confused with which, at what threshold>

### Next-trial suggestion

<one sentence — e.g., "Add scanner-aware augmentation; GE scanner cohort is the dominant failure mode">
```

## Why these sections

- **Worst-K** answers "which samples failed?" — concrete enough for the experimenter to investigate.
- **Slice breakdown** answers "are failures concentrated in a subgroup?" — the input that turns "improve overall AUC" into "fix the GE scanner cohort".
- **Confusion concentration** answers "which kind of error?" — relevant when the metric is class-dependent.
- **Next-trial suggestion** is what the experimenter agent reads to pick its next hypothesis. One concrete sentence, not three options.
