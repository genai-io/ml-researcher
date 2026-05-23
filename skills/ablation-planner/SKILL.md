---
name: ablation-planner
description: Design a reviewer-defensible ablation matrix from a claim. Given "method X improves metric M by Δ", produce the minimal set of ablation experiments that isolate which components carry the gain. Use before promoting a claim to research/analysis_report.md, or when planning the Fine Tuning phase's structured experiments. Templates in references/matrix_template.md.
---

# When to use

- Before writing any claim of the form "X works because of Y" — what experiments would actually distinguish that from "X works *despite* Y"?
- After a promising Fine Tuning result, before declaring it final: which components carry the gain?
- During Model Selection, to scope a defensible comparison structure for the analysis report.

Do NOT use to enumerate every possible variation. The point is the *minimum* set of ablations that earn the claim.

# What it produces

A markdown table appended to `research/ablation_plan.md` (or per-experiment `experiments/EXPxxx/ablation_plan.md`) using the template in `references/matrix_template.md`. Each row is one ablation experiment with:

- The component being removed / replaced
- The expected metric direction if the component matters
- The actual experiment ID once run (or `[pending]`)
- The actual delta and decision

# Steps

1. **Restate the claim**. One sentence: "Method M improves metric K by Δ on dataset D vs baseline B." If you can't restate it, the claim isn't precise enough to plan ablations for — push back to the user.

2. **Decompose M into components**. What are the moving parts? E.g., for a fusion model:
   - Imaging encoder choice
   - Tabular branch choice
   - Fusion layer (late / mid)
   - Loss function
   - Training schedule
   - Augmentation

3. **For each component, design one ablation** that removes / replaces it while holding everything else constant. The ablation's expected outcome:
   - Component is load-bearing → removing it should drop the metric back toward baseline
   - Component is decorative → removing it should preserve the metric

4. **Prioritize**. You usually can't run all ablations. Rank by:
   - **Reviewer skepticism** — which component will a reviewer doubt the most?
   - **Cost** — fast ablations first (changing a hyperparameter > swapping an encoder)
   - **Information gain** — ablations whose outcome you genuinely don't know

5. **Write the matrix** to `ablation_plan.md` using the template. Mark all rows `[pending]`.

6. **Register the planned ablations as experiments** (via `exp-register`) and run them via the experimenter. Update each row with the actual EXP id and result.

7. **Cross-check before report**. Every "X improves because Y" claim in `analysis_report.md` should map to at least one completed row in the ablation matrix.

# Hard rules

- **One variable per ablation.** Two changes at once is uninterpretable.
- **Hold everything else constant.** Same splits, same seed, same training budget. Otherwise you can't attribute the metric delta.
- **Pre-register expected direction.** Writing "expect K to drop ≥ 0.05" before running prevents post-hoc rationalization.
- **Negative ablations count.** If removing a component does NOT drop the metric, that's a finding — record it; the component was decorative.
- **Ablation experiments need baselines too.** The ablation row's `status` in the ledger should reach `keep` or `discard` like any other trial.

# Cost guidance

| Number of ablations | When this is appropriate |
|---|---|
| 1-2 | Small project, single-component claim ("LoRA target modules"). |
| 3-5 | Typical Fine Tuning phase, multi-component method. |
| 6-10 | Method paper, novel architecture with several novel pieces. |
| 11+ | You're padding. Re-prioritize. |

# Related

- [[exp-register]] — each ablation becomes its own EXP id.
- [[hypothesis-ledger]] — record the pre-registered expected direction here, before running.
- [[error-analysis]] — after an ablation drops the metric, error-analysis tells you *which* samples broke.
