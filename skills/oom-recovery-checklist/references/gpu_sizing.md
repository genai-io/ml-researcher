# GPU sizing — model size → recommended card

For SFT (full fine-tune) of common LLM / VLM sizes:

| Model size | Likely OK on |
|---|---|
| 1B – 3B SFT | A10G-24GB, A100-40GB, H100, A100-80GB |
| 7B SFT | A100-40GB (with grad-ckpt + bf16), A100-80GB, H100 |
| 13B SFT | A100-80GB, H100 |
| 30B SFT | H100, A100×2 with FSDP |
| 70B SFT | A100×4-8 with FSDP, H100×4 |

For LoRA / QLoRA fine-tunes, divide by ~2-4× — but if the user wanted full SFT, switching to LoRA without consent is a scope change.

For inference-only with bf16:
- 7B: A10G-24GB
- 13B: A100-40GB
- 30B: A100-80GB
- 70B: 2× A100-80GB

These are rules of thumb. Activation memory varies with context length, batch, and architecture (e.g., MoE models are spikier). Verify with `nvidia-smi` after the first 50 steps.
