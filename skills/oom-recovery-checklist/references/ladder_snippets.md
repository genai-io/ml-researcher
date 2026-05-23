# OOM ladder — code snippets

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

## Step 5: FSDP / DeepSpeed

Don't reach for these unless steps 1-4 are exhausted AND the larger machine is unavailable. They introduce real maintenance complexity.

```python
# FSDP (HuggingFace Trainer)
training_args.fsdp = "full_shard auto_wrap"
training_args.fsdp_transformer_layer_cls_to_wrap = "LlamaDecoderLayer"
```

Inspect the FSDP wrap policy carefully — wrong wrapping can give worse memory usage than no FSDP at all.
