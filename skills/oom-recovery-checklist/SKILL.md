---
name: oom-recovery-checklist
description: Step-by-step prescription for recovering from CUDA out-of-memory errors during training. Adapted from huggingface/ml-intern v3. Use when the user's training job hits OOM. Never silently change scope.
---

# Hard rules

1. **Do not** silently switch SFT → LoRA. That's a different experiment.
2. **Do not** reduce `max_length` without user consent. That changes what's being learned.
3. **Do not** skip eval. Without eval the experiment is uninterpretable.
4. **Do not** remove dropout / weight decay to "free memory." It changes the recipe.

If you would change scope, **stop and tell the user**. Let them decide.

# The ladder (try in order)

## Step 1: Lower per-device batch, raise grad accumulation

Keep effective batch identical:

```python
# Before
per_device_train_batch_size = 16
gradient_accumulation_steps = 1
# Effective batch = 16

# After
per_device_train_batch_size = 4
gradient_accumulation_steps = 4
# Effective batch = 16, peak memory ÷ 4
```

Verify the effective batch is unchanged. If you can't keep it identical (e.g., it doesn't divide), document the change in `trial_trace.md` — this is a recipe change.

## Step 2: Enable gradient checkpointing

```python
training_args.gradient_checkpointing = True
# In some trainers: model.gradient_checkpointing_enable()
```

Cuts activation memory ~30-50% at cost of ~20% slower step. Free win if you have wall-clock budget.

## Step 3: Mixed precision (bf16 preferred)

```python
training_args.bf16 = True   # if Ampere+ GPU
# Or fp16 if older. Avoid fp16 unless required — bf16 is more numerically stable.
```

If already on bf16, this isn't an option.

## Step 4: Move to a larger GPU

| Model size | Likely OK on |
|---|---|
| 7B SFT | A100-40GB, H100, A100-80GB |
| 13B SFT | A100-80GB, H100 |
| 30B SFT | H100, A100×2 with FSDP |
| 70B SFT | A100×4-8 with FSDP, H100×4 |

If the project's compute is fixed (e.g., single A10G), tell the user the experiment needs a bigger machine, don't downgrade the experiment.

## Step 5 (last resort): Activation offloading / FSDP / DeepSpeed

These are real tools but introduce complexity. Don't reach for them unless step 1-4 are exhausted AND the larger machine is unavailable.

# What about reducing learning rate?

LR doesn't affect memory. Don't change it as an OOM workaround.

# What about removing eval?

Eval is part of the experiment. Removing it makes the run uninterpretable — you can't compare against the baseline. If eval itself causes OOM (e.g., long-context eval data), reduce `per_device_eval_batch_size` independently or reduce `eval_steps` frequency, but keep eval.

# Audit trail

Append to `experiments/EXPxxx/README.md`:

```markdown
## OOM recovery
- Step 1 applied: per_device_batch 16 → 4, grad_accum 1 → 4 (effective batch unchanged)
- Step 2 applied: gradient_checkpointing=True
- Date: <date>
```

So a reader can see what changed and why.
