# 12 — Knowledge Integration

A central design question for ml-researcher: **how does the agent act with the depth of a senior ML engineer, when the underlying LLM hallucinates model names, gets hyperparameters wrong, and is months behind on the API surface?**

This document covers the techniques used by serious ML/agent projects in 2025-2026, surveys what's possible, and lays out ml-researcher's chosen integration design.

## Section 1 — Techniques in current practice

### 1.1 Curated system prompts as playbooks

The canonical specimen is `huggingface/ml-intern`'s `agent/prompts/system_prompt_v3.yaml`. It is an opinionated playbook, not a persona. It encodes:

- A **mandatory three-phase workflow** ("Research → Plan & Validate → Implement")
- An **anti-pattern list** (hallucinated imports, wrong trainer arguments, wrong dataset format, default 30-min timeout, missing `push_to_hub`, scope-changing OOM fixes)
- A **hardware sizing table** (1-3B → `a10g-largex2`, 7-13B → `a100-large`, 30B+ → `l40sx4`/`a100x4`, 70B+ → `a100x8`)
- An **OOM minimal-change prescription** (lower batch + raise grad accumulation; enable `gradient_checkpointing`; then upgrade GPU tier — never silently switch SFT→LoRA)
- **Dataset format rules per training method** (SFT → `messages` / `text` / `prompt+completion`; DPO → `prompt+chosen+rejected`; GRPO → `prompt`)
- **Mandatory monitoring** (Trackio, alert taxonomy ERROR/WARN/INFO with numeric thresholds)

The framing line is the epistemic stance:

> "Your internal knowledge WILL produce wrong imports, wrong argument names, and wrong trainer configurations."

AIDE and Sakana keep their persona prompts much smaller — they rely on tree search and metric feedback rather than baked-in rules.

### 1.2 Tool-mediated knowledge

Instead of asking the LLM "what model should I use?", the agent calls a tool. ml-intern exposes `model_search`, `dataset_search`, `hub_repo_details`, `hf_inspect_dataset`, `explore_hf_docs`, `fetch_hf_docs`, `github_find_examples`, `github_read_file`. The system prompt forbids recommending a model without first calling `hub_repo_details`, or using a dataset without `hf_inspect_dataset`. The deeper the domain, the more "ask the LLM" gets replaced with "call the tool".

AIDE takes the orthogonal route — execution feedback as ground truth: the runner returns metrics, search prunes bad branches.

### 1.3 Reference implementation libraries

Stable canonical training repos that the agent retrieves rather than synthesizes from scratch:

- HuggingFace `transformers/examples/`
- `trl` SFT/DPO/GRPO examples
- `huggingface/pytorch-image-models` (timm — `train.py`/`validate.py`, 32K+ stars)
- Lightning AI Bolts
- Recipes from the timm and transformers blog series

ml-intern's `github_find_examples` tool is built specifically to find these before writing code. The pattern is **"copy a working script and adapt"**, not "synthesize from scratch".

### 1.4 RAG over papers / docs

ml-intern's `hf_papers` tool exposes `citation_graph`, `read_paper`, `snippet_search`, `find_datasets`. The system prompt instructs: "read methodology sections (not abstracts)" and "crawl citation graphs for recent downstream work." Production-grade community MCP servers extend this:

- Official **HuggingFace MCP Server** (`huggingface.co/docs/hub/agents-mcp`) — read-only models / datasets / spaces / papers / collections
- `blazickjp/arxiv-mcp-server`
- `huangxinping/huggingface-daily-paper-mcp`
- `ScienceAIHub/PaperMCP` ("32 unified tools" across arXiv / HF / Google Scholar / OpenReview / DBLP / PapersWithCode)

### 1.5 Knowledge bases as structured data

The hardware sizing table and dataset-format-by-method table in ml-intern's prompt are **structured tables embedded in prose**. Outside agents, structured knowledge exists scattered across:

- paperswithcode benchmark JSON
- HF Hub `model-index` metadata
- MTEB leaderboard JSON
- timm's `results-*.csv` (per-model ImageNet eval)

**Gap finding**: no public agent ships a comprehensive structured `model_registry.yaml` with pros/cons + typical hyperparameters per architecture. This appears to be an unfilled gap in the landscape and is the highest-leverage thing ml-researcher can ship — see Section 3 Proposal 4.

### 1.6 Skill / playbook files

`mudler/universal-ml-intern` is built around `SKILLS` + `AGENTS.md` — recipe markdown files the agent loads on demand. Anthropic Skills, Claude Code skills, and the gen-code skill registry use the same pattern: markdown with frontmatter, description triggers loading, body is the recipe. Examples in active use elsewhere: "small-sample medical imaging with transfer learning", "fine-tune SigLIP2 for retrieval", "DPO data format conversion."

This is the most **scalable** technique — adding a new domain is one PR adding a markdown file.

### 1.7 MCP servers as ML data sources

MCP is the way to remove platform-switching friction. As of 2026, ML-relevant servers cover Hub data (HF official), papers (arxiv-mcp-server, PaperMCP), benchmarks, and Kaggle (community shims). HF's own blog post "MCP for Research" positions MCP as the integration layer.

### 1.8 Fine-tuned domain LLMs vs prompting

**No widely-adopted "ML-engineer LLM" exists** as of 2026. The closest are general code-RL models (DeepSeek R1, Qwen3-Coder) plus benchmarks like MLE-Bench, METR RE-Bench, Weco's internal Kaggle Bench. AIDE's headline result on MLE-Bench (3× medals over second place) was achieved by **prompting + tree search**, not fine-tuning.

Community consensus: **prompting + tools beats domain fine-tuning** for this use case, because the field moves faster than fine-tunes can ship. ml-researcher follows this consensus and does NOT propose to fine-tune a domain LLM.

### 1.9 Live updates

ml-intern's explicit answer: *"Your training data is outdated. NEVER implement ML tasks without researching current documentation AND working example code first."* Operationally: every recommendation goes through a doc/paper RAG call; the system prompt itself is versioned (`v1`, `v2`, `v3`) and updated as the ecosystem evolves.

For ml-researcher: the structured `model_registry.yaml` (§1.5) needs a freshness mechanism — `last_verified` date per entry, and a scheduled job (or `/loop` skill) to re-verify against HF Hub and paperswithcode.

## Section 2 — Model Taxonomy Reference Card (2025-2026)

This is the seed content for `model_registry.yaml`. Format: model — typical n_samples; failure modes; SOTA tracker.

### Vision recognition

**Classification**: `timm/vit_large_patch14_dinov2.lvd142m`, DINOv3 ViT/ConvNeXt (timm ≥1.0.20), `timm/eva02_large`, ConvNeXtV2-Large, EfficientNetV2-L, Swin-V2-L, BeiT-v2-L, MobileNetV4 (mobile/edge).

- Data: ≥10k labeled images for fine-tune; ≥1M for from-scratch; linear-probe DINOv2 with 100-1000 imgs/class
- Failures: domain shift on medical / satellite; label noise crashes ViT > CNN
- SOTA: paperswithcode ImageNet, timm `results-*.csv`, HF leaderboards

**Detection**: RT-DETR / RT-DETRv2 (53.0 AP @ 114 FPS T4), YOLOv12, RF-DETR, Grounding DINO (open-vocab).

- Data: ≥5k boxes/class
- Failures: small-object recall, class imbalance
- SOTA: COCO benchmarks on paperswithcode, Roboflow blog

**Segmentation**: SAM2 (`facebook/sam2-hiera-large`), Mask2Former (`facebook/mask2former-swin-large-coco-panoptic`), SegFormer-B5, OneFormer, nnU-Net (medical), VISTA3D (3D medical, CVPR 2025).

- Data: SAM2 zero-shot to ~50 imgs fine-tune; nnU-Net ≥40 cases
- Failures: small organs, prompt sensitivity
- SOTA: MedSegBench, COCO panoptic

### Multimodal fusion

**Vision-language**: `google/siglip2-so400m-patch14-384` (SigLIP2 — encoder of choice for Qwen3-VL/Gemma 3), CLIP ViT-L/14, Qwen2.5-VL-7B/72B, InternVL3-8B/78B, LLaVA-OneVision, Idefics3, Llama-3.2-Vision.

- Data: ≥100k pairs for contrastive; ≥10k for instruction tuning
- Failures: OCR + numeric reasoning, long-context video, vision-token length blowup
- SOTA: HF VLM leaderboard, MMMU/MathVista/DocVQA on paperswithcode

**Vision+tabular, audio+text**: no single dominant open recipe. Usual approach: project a CLIP/SigLIP image embedding + a tabular embedding (FT-Transformer or TabPFN) into a shared MLP head, late fusion. *Needs verification per domain.*

### Medical imaging (small-sample / transfer / federated)

MedGemma-4B/27B (Google, July 2025), MedSigLIP, BiomedCLIP, RadDINO, CheXagent, nnU-Net v2, SAM2-UNet / MedSAM2 / SSL-MedSAM2 (segmentation, MICCAI 2025), TotalSegmentator (CT, 100+ structures), MONAI bundles, VISTA3D.

- Data: 50-500 labeled cases is the realistic regime; pretrain on ImageNet/DINOv2, fine-tune
- Failures: site/scanner shift, class imbalance with rare findings, leakage from patient-level splits, calibration
- SOTA: MedSegBench, OpenMIBOOD (OOD), MICCAI challenge leaderboards, Grand-Challenge.org

This domain matches the rad-research GBM project canonically — so it's the highest priority skill set for ml-researcher v0.1 examples.

### Tabular ML

**Small-sample**: TabPFNv2 (Nature 2024, best up to ~10k samples; row+column attention).
**Foundation/in-context**: TabICL (top median rank in 2025 benchmarks), TabM.
**Gradient-boosted**: CatBoost, XGBoost, LightGBM (still strong on >10k rows, categorical-heavy).
**DL-on-tabular**: SAINT, FT-Transformer, CARTE (graph rep, cross-table).
**Time-series**: Chronos (Amazon), Moirai, TimesFM (Google) for foundation forecasting; PatchTST, N-BEATS, TFT for from-scratch.

- Data: TabPFNv2 sweet spot ≤10k rows, ≤500 features; XGBoost dominates >100k rows
- Failures: leakage from improper time-splits, high-cardinality categoricals, target leakage
- SOTA: TabArena, AutoML Benchmark, Kaggle leaderboards

### NLP

**Classification / NER**: DeBERTa-v3-large, ModernBERT, GLiNER (`urchade/gliner_large-v2.1` — generalist NER, 90M variant beats UniNER-13B). Data: 1k-10k labeled.

**Summarization**: BART-large (best on dialogue / Samsum), PEGASUS (best on CNN/DM news), Long-T5, Llama-3.1-8B-Instruct + LoRA for instruct-style.

**Retrieval / embeddings (MTEB top open-weight)**: Qwen3-Embedding-8B, BGE-M3, BGE-large-en-v1.5, E5-large-v2, mxbai-embed-large-v1, Jina v3/v5, Stella, gte-Qwen2.

**Generation / instruct (open)**: Llama-3.1/3.3, Qwen3, DeepSeek-V3/R1, Mistral-Small/Large, Gemma-3.

### Generative

**Image**: FLUX.1-dev / FLUX.1-schnell / FLUX.2 (Black Forest Labs, Nov 2025), Stable Diffusion 3.5, SDXL (still strong for LoRA ecosystem), Stable Cascade.

- Data: ≥10 imgs for LoRA, ≥1k for full fine-tune
- Failures: text rendering (SDXL), anatomy, license traps
- SOTA: artificialanalysis.ai image leaderboard, lmarena image arena

**Audio**: Whisper-large-v3 / Whisper-turbo (multilingual ASR), NVIDIA Parakeet-v2 (English; 6.05% WER, RTFx 3386), WavLM (speaker), HuBERT, MusicGen, Stable Audio Open, Bark.

- Failures: noisy-domain WER (Whisper jumps to 29.8%), code-switching, speaker diarization

**Text**: same instruct models as NLP, plus DPO/GRPO post-training via TRL.

## Section 3 — ml-researcher's chosen design

Five concrete proposals, each a specific file or feature in the ml-researcher repo.

### Proposal 1 — `internal/prompts/ml_researcher_v1.yaml`

System prompt structured after ml-intern v3, mirroring its sections:

- Persona + epistemic stance ("internal knowledge unreliable; tools and citations primary")
- Three-phase workflow: Research → Plan & Validate → Implement
- Anti-pattern list (curated to ml-researcher's domain — methodology violations, leakage, baseline-skipping, fabricated metrics)
- Hardware sizing table (per-domain: vision, NLP, multimodal)
- OOM recovery prescription (ml-intern's ladder, verbatim, with attribution)
- Dataset format rules per training method
- Pre-flight checklist before any `experiment_run`
- Attention/library guidance (Hub kernels over pip flash-attn, etc.)
- Versioned — `_v1`, `_v2` so churn shows in git history

The framing line is borrowed verbatim:

> "Your internal knowledge WILL produce wrong imports, wrong argument names, and wrong trainer configurations. Always verify with `dataset_inspect`, `model_recommend`, `paper_search`, or `github_find_examples` before recommending an approach."

### Proposal 2 — Three first-class ML tools

These replace LLM recall with curated/live answers. All of them are listed in [`06_tools.md`](06_tools.md); the new addition is `model_recommend`:

- **`model_recommend(task, n_samples, modality, constraints)`** — JSON-backed registry returns 5-10 candidates with pros/cons, typical hyperparameters, license, and `last_verified` date. Backed by `internal/data/model_registry.yaml`.
- **`paper_search(query, traverse_citations=true)`** — arXiv + HF Papers + Semantic Scholar via MCP. Methodology-section extraction, not abstracts.
- **`dataset_inspect(repo_id_or_path)`** — schema + columns + size + split + license. Mandatory before suggesting any training script.

Mirror ml-intern's tool list: `hf_inspect_dataset`, `hub_repo_details`, `github_find_examples`, `fetch_hf_docs`. Wire them as MCP servers (the official HF MCP + arxiv-mcp-server + a local model-registry MCP) so they refresh independently of binary releases.

### Proposal 3 — ML-domain skills

Recipe-shaped `SKILL.md` files (under `skills/<name>/SKILL.md`) with frontmatter description for trigger-based loading. Initial set, mapped to Section 2 domains:

- `vision-classification-fine-tune/`
- `object-detection-rt-detr/`
- `seg-sam2-finetune/`
- `medical-small-sample-transfer/`  ← rad-research's domain
- `multimodal-vlm-finetune-siglip2/`
- `tabular-tabpfn-vs-xgboost/`
- `nlp-classification-deberta-or-modernbert/`
- `embeddings-mteb-pick/`
- `summarize-bart-pegasus/`
- `image-gen-flux-lora/`
- `asr-whisper-or-parakeet/`
- `dpo-data-conversion/`
- `grpo-rewards/`
- `oom-recovery-checklist/`

Each skill names 5-10 specific HF model IDs (version-pinned), expected data size, common pitfalls, and a reference implementation link. Format follows the standard Anthropic Skills contract (`SKILL.md` with `name`/`description` frontmatter).

### Proposal 4 — `internal/data/model_registry.yaml`

Embedded structured knowledge — the gap nobody has filled (§1.5). Schema:

```yaml
- id: timm/vit_large_patch14_dinov2.lvd142m
  task: image_classification
  modality: vision
  params: 304M
  license: apache-2.0
  min_data:
    fine_tune: 10000
    linear_probe: 100
  recommended_hparams:
    lr: 1e-4
    batch_size: 64
    epochs: 30
    optimizer: adamw
    weight_decay: 0.05
  pros:
    - strong linear-probe with little data
    - robust to label noise
  cons:
    - higher memory than CNN counterparts
  failure_modes:
    - domain shift on medical / satellite
    - long-tail classes need re-weighting
  sota_tracker: https://paperswithcode.com/sota/image-classification-on-imagenet
  reference_impl: https://huggingface.co/docs/timm/training_script
  last_verified: 2026-04-15
```

`model_recommend` reads this. A scheduled re-verification job (using ml-researcher's own `cron` system) updates `last_verified`. The agent surfaces the date so the user knows freshness.

### Proposal 5 — Pre-flight checklist hook

Adopt the ml-intern style as a `PreToolUse` hook on `experiment_run` — already in [`08_hooks.md`](08_hooks.md) §3. Concrete items the hook enforces:

- Reference implementation cited in current conversation context
- `dataset_inspect` was called for the dataset this turn
- `push_to_hub=True` (or equivalent persistence) and a destination set
- Timeout ≥ estimated runtime × 2
- Monitoring configured (run name follows `<task>_<model>_lr<lr>_bs<bs>` convention)
- Baseline experiment exists in `experiments/` if this is a "improvement" claim

Block with a structured remediation list when any item fails. This is what makes the playbook **enforced**, not aspirational — the difference between a chatbot and a senior engineer.

## Domain customization via `playbook.md`

The default `internal/prompts/ml_researcher_v1.yaml` is domain-neutral. Project-specific guidance lives in `.mlr/playbook.md`, loaded into the agent's working context at session start. Examples:

- **Radiomics / small-sample medical**: small-N guardrails, patient-level splits, calibration, DeLong test, RBF-SVM vs logistic for clinical fusion (rad-research's domain).
- **NLP fine-tuning**: format checks (SFT/DPO/GRPO), tokenizer compatibility, ml-intern's pre-flight verbatim.
- **RL**: replay buffer, discount-rate baselines, reward hacking checks.

Each `playbook.md` is the user's lever for shaping how `mlr` interprets the methodology in this specific project.

## Open questions for v0.2

| Question | Notes |
|---|---|
| Live update cadence for `model_registry.yaml` | Quarterly auto-refresh; pinned reproducibility per project? |
| Model-registry MCP server | Local-only or shareable across projects? |
| Skill file inheritance | Per-project skills extend or override built-ins? |
| Domain `playbook.md` library | Maintained centrally or distributed as plugins? |
| Hook for unverified model recommendations | Block recommendations from `model_recommend` if `last_verified > 90d`? |
