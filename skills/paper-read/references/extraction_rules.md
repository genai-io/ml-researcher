# Extraction rules — verbatim quoting style

## Numbers and metrics

- **Verbatim**, with the same number of significant digits as the paper.
- If the paper reports `73.2`, do not write `73.2%` or `73` or `0.732` — write `73.2`.
- Always cite the source: `(Table 2, row 4)` or `(Section 4.3)`.

## Equations

- Cite as `(Eq. N)` matching the paper's numbering.
- If reproducing an equation in the notes, use the paper's exact symbols. Do not rename variables.
- If the equation is too long for a notes line, write `(Eq. N — see paper §X)`.

## Hyperparameters

- Copy the exact symbol the paper uses (`lr`, `α`, `learning_rate`, `step_size`).
- Include units when present (`8 GPUs`, `2048 sequence length`).
- If a hyperparameter is described qualitatively ("a small learning rate"), write `[qualitative: small]` — don't invent a number.

## Section attributions

When summarizing a method:
- "The authors propose X" — fine for a single sentence summary
- "The method achieves Y" — requires a table or figure citation
- "X works better than Y" — requires the paper's exact comparison + significance claim

## Forbidden moves

- Writing a number that "looks right" because similar papers report it.
- Combining results across tables to compute a derived metric.
- Translating units (e.g., paper says `1e-4`, do not write `0.0001`).
- Summarizing an ablation as "minimal impact" if the paper doesn't say so.

## When you cannot extract

Use these explicit markers in the notes:

| Marker | Meaning |
|---|---|
| `[not reported]` | the paper does not state this value |
| `[unreadable]` | the PDF parser failed for this section |
| `[ambiguous]` | the paper states it but the meaning is unclear |
| `[needs verification]` | the value appears but the source citation is broken |

These markers are searchable, so the literature agent can revisit them later.
