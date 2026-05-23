# Description discipline — examples

## Good descriptions (one informative line)

- `Lowered LR to 5e-5 from 1e-4`
- `Added gradient checkpointing to fit batch=32 on A10G`
- `Switched to RBF SVM from logistic; AUC 0.65 → 0.72`
- `Combined clinical+rad scores via linear SVM`
- `Added wavelet feature extraction (Original + Wavelet image types)`
- `Discarded — test AUC dropped despite higher train AUC (overfit)`
- `OOM at step 5 with bs=64; should drop to bs=16`

## Bad descriptions

- `Changed train.py` — uninformative
- `Fixed bug` — what bug?
- `Improved model` — vague; what was the change?
- `EXP003 v2` — versioning belongs in exp_id, not description
- A multi-line paragraph — this is a TSV row; newlines break parsers

## The "what changed" test

A good description lets a future reader answer: *"if I bisected my way to this trial, what would I expect to be different from the parent?"*. If you can't answer that from the description alone, rewrite it.

## When the trial is a discard or crash

Still write a substantive description. "Discarded" alone is wasted space; "Discarded — test AUC dropped 0.10; classic high-dim overfit" tells the next experimenter what NOT to try again.

## Cross-reference

The trial-log entry in `research/trial_trace.md` carries the long-form story. The ledger description is its TSV-friendly summary. Keep them consistent — when the trial-log says "rejected because test AUC dropped", the ledger description should say the same in shorter form.
