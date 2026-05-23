---
name: oom-recovery-checklist
description: Step-by-step prescription for recovering from CUDA out-of-memory errors during training. Adapted from huggingface/ml-intern v3. Apply the ladder in order; never silently change scope. Deep code snippets in references/ladder_snippets.md.
---

# When to use

A training run hit CUDA OOM. Apply the ladder in order until memory fits.

# Hard rules

1. **Do not** silently switch SFT → LoRA — that's a different experiment.
2. **Do not** reduce `max_length` without user consent — changes what's being learned.
3. **Do not** skip eval — uninterpretable without it.
4. **Do not** remove dropout / weight decay to "free memory" — changes the recipe.

If a fix would change scope, **stop and tell the user**. Let them decide.

# The ladder (try in order)

| # | Step | Cost | Effect |
|---|---|---|---|
| 1 | Lower per-device batch, raise grad accumulation (keep effective batch identical) | none | peak memory ÷ N |
| 2 | Enable gradient checkpointing | ~20% slower step | activation memory −30 to −50% |
| 3 | Mixed precision (bf16 preferred over fp16) | none if Ampere+ | ~50% memory cut |
| 4 | Move to larger GPU | budget | depends |
| 5 | Activation offloading / FSDP / DeepSpeed (last resort) | high complexity | scales further |

Code snippets per step: `references/ladder_snippets.md`.
GPU sizing table (model size → recommended card): `references/gpu_sizing.md`.

# Things that do NOT affect memory

- **Learning rate** — do not change it as an OOM workaround.
- **Removing eval** — does not save train memory. If eval itself OOMs, reduce `per_device_eval_batch_size` independently or reduce `eval_steps` frequency, but keep eval.

# Audit trail (mandatory)

Append to `experiments/EXPxxx/README.md`:

```markdown
## OOM recovery
- Step N applied: <what changed>
- Date: <date>
```

So a reader can see exactly what changed and why.

# When to escalate

If steps 1–3 all applied and OOM persists on the same GPU, escalate to the user: the experiment needs a bigger machine. Do **not** downgrade the experiment to fit.
