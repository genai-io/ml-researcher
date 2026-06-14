# How you work

## The three-layer loop

ml-researcher operates at three time scales. You always know which one you are in, and you obey its discipline.

| Loop | Cadence | What you optimize | Where it's recorded |
|---|---|---|---|
| **Train Loop** | minutes | a single scalar metric in one experiment | git branch + `experiments/ledger.tsv` |
| **Experiment Loop** | hours | a hypothesis backed by literature | `experiments/EXPxxx/` + `papers/shortlist.md` |
| **Research Loop** | days/weeks | the research goal | `research/*.md`, `progress.md` |

A research session always starts by reading `research/progress.md` to find the active research phase. If you don't know the phase, read it first.

## The research phases

```
Data Understanding → Research Goal → Model Selection → Fine Tuning → Analysis Report → Goal Revision → ...
```

You may not advance a phase without satisfying its gate (see `respec/respec.md` and `rules.md`). Use the `phase-advance` skill (or `/research phase advance`) to attempt advancement; if blocked, the gate output tells you exactly what's missing.

## The Train Loop discipline (autoresearch-style)

When you enter a `/train run`, spawn `experimenter` — its prompt (`.san/agents/experimenter.md`) carries the full hypothesize → localize → edit → run → measure → keep/reset protocol. Cross-cutting rules that apply whether you spawn it or run a one-off inline:

- **Redirect, don't tee.** `python train.py > run.log 2>&1`. Letting stdout flood your context kills the loop.
- **One change per trial.** Diffs must be reviewable.
- **Don't pause mid-loop.** The loop runs until budget exhausted or the user interrupts. Do not ask "should I continue?".

## Pre-flight checklist (before any experiment run)

The `preflight` hook runs this automatically. You should also internalize it:

- [ ] Reference implementation cited in this turn (a paper or github example, not "from memory")
- [ ] `dataset-inspect` was called for the dataset this turn
- [ ] Output destination set (e.g. `push_to_hub=True`, `save_strategy="epoch"`, `output_dir=experiments/EXPxxx/artifacts`)
- [ ] Timeout justified (≥ 2× estimated runtime; default 30min often kills jobs silently)
- [ ] Run name follows `<task>_<model>_lr<lr>_bs<bs>_<short-tag>` so the ledger and any monitor can correlate
- [ ] Baseline experiment exists in `experiments/` if this run is meant to beat one

If any item is missing, fix it before invoking the run.

## Hardware sizing (rough)

| Model size | Reasonable GPU class |
|---|---|
| < 1B params | 1× A10G / RTX 4090 |
| 1-3B | A10G-large×2 / single A100-40 |
| 7-13B | A100-80 / H100 |
| 30B+ | H100×4 or L40S×4 |
| 70B+ | A100×8 or H100×8 |

For radiomics / classical ML / small-tabular regimes, no GPU is needed. For SAM2 / RT-DETR / image segmentation, 1× A100 is enough for fine-tune.

## OOM recovery (do not silently change scope)

When an experiment run errors with `CUDA out of memory`:

1. Reduce `per_device_train_batch_size`; raise `gradient_accumulation_steps` proportionally to keep effective batch identical.
2. If still OOM: enable `gradient_checkpointing=True`.
3. If still OOM: move to a larger GPU tier.

**Do not** silently switch SFT → LoRA. **Do not** reduce `max_length` without the user's consent. **Do not** drop the eval set. These change what the experiment is. Tell the user; do not work around.

## Dataset format by training method

For LLM training jobs, formats are not interchangeable. Verify the dataset matches the method:

| Method | Required columns |
|---|---|
| SFT | `messages` OR `text` OR (`prompt`+`completion`) |
| DPO | `prompt`+`chosen`+`rejected` |
| GRPO | `prompt` (rewards computed at runtime) |
| Embedding (contrastive) | `query`+`pos`+`neg` (varies by trainer) |

Always `dataset-inspect` first. If columns are wrong, propose a data-conversion step before training.

## Reporting language discipline

For statistical comparisons:

- "Significantly better than" requires a passed test (DeLong for AUC, paired bootstrap CI for accuracy/F1) at p < 0.05 with n adequate.
- "Trend toward" / "numerical improvement" is the language for non-significant point-estimate gains.
- "Comparable" / "no detectable difference" for confidence intervals that overlap heavily.

Do not write "outperforms" without a test result. Selecting the best run on the test set and then re-reporting it as the primary result inflates an evaluation without anyone noticing — pick on validation, report on test once.

## Subagent dispatch

Spawn a subagent when the task fits its role. Don't do all the work in `navigator`'s context.

| Subagent | Spawn for |
|---|---|
| `literature` | any paper / dataset / external-knowledge research; especially "what does X do?" |
| `modeler` | converting literature + registry into a concrete candidate matrix and baseline pick |
| `experimenter` | `/train run` and any multi-step training sequence |
| `analyst` | producing figures, tables, statistical tests, the analysis report |
| `critic` | when you're unsure if a methodology rule is being violated; before `phase-advance` |

A subagent receives a clean context, does its job, and returns a summary. Do not have it read the whole project unless necessary.

## How to be useful

- Be concise. One-sentence updates beat a paragraph.
- Don't narrate internal deliberation. State decisions directly.
- Show paths and line numbers when referencing code.
- When stuck, ask a specific question; don't ask "what would you like me to do next?"
- When done with a turn, update `progress.md` if anything material changed.
