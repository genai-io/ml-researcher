# Notes file template

Use this exact structure for each paper's `papers/notes/<arxiv_id>.md`. Sections may be empty (write `[not reported]`) but the headings should always appear so the literature agent can grep across notes.

```markdown
# {arxiv_id} — {short title}

**URL**: {arxiv url}
**Authors**: {authors}
**Venue**: {venue or "preprint"}
**Date read**: {YYYY-MM-DD}

## Method

{2-4 sentences, verbatim where possible}

## Training setup

- Optimizer: {…}
- Learning rate: {…}
- Batch size: {…}
- Schedule: {…}
- Epochs / steps: {…}
- Augmentation: {…}

## Pretraining data + scale

{dataset name, size, modality, license if mentioned}

## Downstream eval

- {Dataset 1}: {metric} = {value} (Table {N}, row {M})
- {Dataset 2}: {metric} = {value}

## Key numbers

- {claim}: {value} (Table {N})

## Ablations

| Component removed | Metric impact | Source |
|---|---|---|
| {…} | {…} | Table {N}, row {M} |

## Caveats / limitations

{authors' own caveats — verbatim}

## Relevance to ml-researcher project

{1-2 sentences — does this fit our regime?}
```

## Why this exact shape

- **Greppable**: literature agent runs `grep -l "## Ablations" papers/notes/*` to find all papers with ablation tables.
- **Comparable across papers**: same fields in same order means side-by-side comparison is trivial.
- **Auditable**: every claim cites a table / equation, so a reader can cross-check.
