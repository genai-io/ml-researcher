# Hypothesis-ledger entry format

Use this exact structure for each entry in `research/hypothesis_ledger.md`. New entries at the top (newest first).

```markdown
## HYP<NNN> — <short title>

- **Statement**: <falsifiable claim in one sentence>
- **Mechanism**: <why we expect this — the causal model>
- **Prediction**: <direction + magnitude — pre-registered>
- **Test design**: <how a trial would falsify this>
- **Registered**: <YYYY-MM-DD>
- **Status**: open | supported | refuted | mixed | superseded

### Evidence

| Date | Trial / EXP | Observation | Verdict |
|---|---|---|---|
| YYYY-MM-DD | EXP012 | val_auc dropped 0.04 when component removed | supports |
| YYYY-MM-DD | EXP015 | val_auc unchanged on second dataset | refutes |

### Decision (when closing)

- **Closed**: <YYYY-MM-DD>
- **Final verdict**: supported | refuted | mixed
- **Rationale**: <one sentence>
- **Successor**: HYP<NNN+M> (if a refined hypothesis takes its place)
```

## Field meanings

| Field | Required | Notes |
|---|---|---|
| Statement | yes | Falsifiable. "Method M improves metric K by Δ on dataset D because Z." |
| Mechanism | yes | The causal story. "X works because Y" — what's Y? |
| Prediction | yes | Direction + magnitude. "K increases by ≥ 0.05". Vague predictions can't be falsified. |
| Test design | yes | What experiment would refute this? If you can't answer, the hypothesis isn't testable. |
| Registered | yes | The date the hypothesis was *first* added. Pre-registration anchor. |
| Status | yes | `open` initially. Flip only when evidence justifies. |
| Evidence | grows | Append a row each time a trial provides evidence. Never edit prior rows. |
| Decision | on close | Filled when status flips to `supported` / `refuted` / `mixed`. |

## Worked example

```markdown
## HYP012 — RadDINO is load-bearing in our fusion model

- **Statement**: Using RadDINO as the imaging encoder (vs generic DINOv2) is responsible for ≥ 0.05 AUC improvement in our late-fusion model.
- **Mechanism**: RadDINO was pretrained on chest X-ray; the radiology-specific features should transfer better to small MRI cohort than generic DINOv2 features.
- **Prediction**: val_auc drops by 0.05 – 0.10 when RadDINO is swapped for `facebook/dinov2-large`.
- **Test design**: register an ablation EXP that replaces only the encoder, holding splits / seed / fusion / tabular branch constant.
- **Registered**: 2026-05-18
- **Status**: supported

### Evidence

| Date | Trial / EXP | Observation | Verdict |
|---|---|---|---|
| 2026-05-20 | EXP012 | val_auc 0.71 → 0.65 with DINOv2 replacement | supports |
| 2026-05-21 | EXP013 (re-run with seed=43) | val_auc 0.70 → 0.66 with DINOv2 replacement | supports |

### Decision

- **Closed**: 2026-05-21
- **Final verdict**: supported
- **Rationale**: Two independent seeds show the predicted drop within the predicted range; report can cite RadDINO as load-bearing.
- **Successor**: none
```

## Anti-patterns

- "Statement: LoRA helps" — not falsifiable.
- Editing "Prediction" after seeing the first trial's result — defeats pre-registration.
- Status = `supported` with one evidence row — single trial is not enough to close.
- Skipping `Mechanism` because "we just want to see if it works" — that's hyperparameter tuning, not a hypothesis. Use the trial-log instead.
