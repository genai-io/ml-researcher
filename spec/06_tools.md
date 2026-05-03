# 06 — Skills and Scripts

ml-researcher does not implement custom tools as Go code. Domain-specific behavior is delivered as **skills** (markdown files the agent loads on demand) and **scripts** (small Python helpers invoked from skills via Bash). The agent runtime (Claude Code, gen-code, Codex) already provides the primitive tools (Read, Write, Edit, Bash, Glob, Grep, Agent, WebFetch, WebSearch) — skills compose them into ML-domain workflows.

## Why skills, not custom tools

| | Custom tool (Go / MCP) | Skill (markdown) | Skill + Python script |
|---|---|---|---|
| Implementation cost | High (Go code, schema, daemon) | One markdown file | Markdown + small `.py` |
| Where it runs | Inside binary or external server | Inside the LLM's reasoning, using existing tools | Inside Bash, called by skill |
| Cross-runtime | Per-runtime port | Identical across runtimes | Identical across runtimes |
| Strict typing | Yes (JSON Schema) | No (LLM interprets markdown) | Loose (script's CLI/JSON) |
| Update friction | Rebuild binary or server | Edit markdown, save | Edit markdown or `.py` |
| Best for | Heavy compute, stateful APIs | Recipes, methodology, workflow steps | Statistical computation, plots |

Most of ml-researcher's "tools" are recipes: "to register an experiment, run these git commands and create these files." That's a skill. The few that need real computation (bootstrap CI, DeLong test, figure rendering) are skills + Python scripts.

## Skill organization

Skills live in `skills/` and are organized by domain:

```
skills/
├── ml/                              # ML domain knowledge
│   ├── model-recommend.md           # query model_registry.yaml; return curated picks
│   ├── medical-small-sample-transfer.md
│   ├── tabular-tabpfn-vs-xgboost.md
│   ├── vision-classification-fine-tune.md
│   ├── multimodal-vlm-finetune-siglip2.md
│   ├── seg-sam2-finetune.md
│   ├── nlp-classification-deberta-or-modernbert.md
│   ├── embeddings-mteb-pick.md
│   ├── image-gen-flux-lora.md
│   ├── asr-whisper-or-parakeet.md
│   ├── dpo-data-conversion.md
│   ├── grpo-rewards.md
│   └── oom-recovery-checklist.md
│
├── experiment/                      # L1/L2 loop mechanics
│   ├── exp-register.md              # create experiments/EXPxxx/ + git branch
│   ├── exp-run.md                   # python train.py > run.log 2>&1; timeout
│   ├── metric-grep.md               # grep "^<key>:" run.log
│   ├── git-keep-or-reset.md         # advance branch or revert
│   └── ledger-append.md             # tab-separated append to ledger.tsv
│
└── methodology/                     # L3 lifecycle and audit
    ├── phase-advance.md             # check gate requirements; advance phase
    ├── checklist-verify.md          # pre-flight: baseline, dataset format, ...
    ├── iteration-log.md             # structured append to iteration_trace.md
    ├── bootstrap-ci.md              # invoke scripts/bootstrap_ci.py
    ├── delong-test.md               # invoke scripts/delong_test.py
    ├── train-monitor.md             # tail run.log; classify divergence/oom/nan
    └── figure-render.md             # invoke scripts/figure_render.py
```

## Skill format

Standard runtime convention — markdown with YAML frontmatter:

```markdown
---
name: model-recommend
description: Recommend ML models from the registry given a task, n_samples, and modality
allowed-tools: Read, Grep
---

# When to use

User asks "what model should I use for X" or "which architectures are appropriate for <task> with <n_samples> data".

# Steps

1. Read `data/model_registry.yaml` (project root).
2. Filter entries:
   - `task` matches the user's task
   - `min_data.fine_tune` <= user's n_samples (if fine-tune mode)
   - any explicit constraint (license, modality, max_params)
3. Sort by relevance.
4. Format each candidate as one bullet: `{id}` — {pros[0]}; needs {min_data.fine_tune}+ samples; license: {license}; verified {last_verified}.
5. If `last_verified > 90 days ago`, prefix with `[STALE]`.

# Example

User: "I have 270 MRI cases for tumor purity prediction"
You: read registry → filter task=medical_imaging modality=vision min_data.fine_tune<=270 → return RadDINO, BiomedCLIP, MedGemma-4B with notes.
```

## Scripts (`scripts/`)

Small, single-purpose Python files. Each one is invoked by a skill via Bash with explicit CLI arguments. Output is JSON on stdout.

```
scripts/
├── bootstrap_ci.py
├── delong_test.py
├── figure_render.py
└── README.md
```

Conventions:
- One responsibility per script.
- CLI: `--input <path>` for files, `--out <path>` if saving, primary args positional.
- Output: a single line of JSON to stdout for parsable results; multi-line human text only for `--help`.
- Dependencies: standard scientific Python (numpy, scipy, scikit-learn, pandas, matplotlib). The user installs these; ml-researcher does not bundle them.

Example skill+script pair:

`skills/methodology/bootstrap-ci.md`:
```markdown
---
name: bootstrap-ci
description: Compute bootstrap confidence interval for a metric on (preds, labels) arrays
allowed-tools: Bash, Read
---
Run `python scripts/bootstrap_ci.py --preds <p> --labels <l> --metric <m> --n-iter 1000`.
The script prints a JSON line: {"point": ..., "low": ..., "high": ..., "n_iter": 1000}.
Parse it and report. If file paths are not absolute, resolve from project root.
```

`scripts/bootstrap_ci.py`:
```python
#!/usr/bin/env python3
import argparse, json, numpy as np
# ... small implementation, ~30 lines ...
print(json.dumps({"point": point, "low": lo, "high": hi, "n_iter": n_iter}))
```

## What about the things in earlier drafts called "tools"

The earlier draft of this document listed `paper_search`, `dataset_inspect`, `model_recommend`, `experiment_register`, etc. as Go-coded tools. They are now all skills:

| Earlier "tool" | Now |
|---|---|
| `paper_search` | skill `ml/paper-search.md` (uses `WebFetch` against arxiv / HF Papers / Semantic Scholar) |
| `paper_read` | skill `ml/paper-read.md` (uses `WebFetch` for ar5iv) |
| `citation_graph` | skill `ml/citation-graph.md` (uses `WebFetch` for Semantic Scholar) |
| `dataset_inspect` | skill `ml/dataset-inspect.md` (uses `Bash` + HF datasets) |
| `model_recommend` | skill `ml/model-recommend.md` (reads `data/model_registry.yaml`) |
| `experiment_register` | skill `experiment/exp-register.md` |
| `experiment_run` | skill `experiment/exp-run.md` |
| `metric_grep` | skill `experiment/metric-grep.md` |
| `git_keep_or_reset` | skill `experiment/git-keep-or-reset.md` |
| `ledger_append` | skill `experiment/ledger-append.md` |
| `phase_advance` | skill `methodology/phase-advance.md` (slash command also exists) |
| `iteration_log` | skill `methodology/iteration-log.md` |
| `checklist_verify` | skill `methodology/checklist-verify.md` |
| `bootstrap_ci` | skill `methodology/bootstrap-ci.md` + `scripts/bootstrap_ci.py` |
| `delong_test` | skill `methodology/delong-test.md` + `scripts/delong_test.py` |
| `figure_render` | skill `methodology/figure-render.md` + `scripts/figure_render.py` |
| `train_monitor` | skill `methodology/train-monitor.md` |
| `oom_recover` | skill `ml/oom-recovery-checklist.md` |

## Permissions

Skill execution uses the runtime's existing tools — so permission questions reduce to:

| Used inside skill | Permission concern |
|---|---|
| `Read` | always allowed (no risk) |
| `WebFetch` | usually allowed; runtime may prompt for unknown domains |
| `Bash` | gated by runtime's bash policy + project hooks |
| `Edit`, `Write` | gated by hooks (e.g., `data/raw/**` is hard-blocked; see [`08_hooks.md`](08_hooks.md)) |

There is no separate ml-researcher permission system. Hooks enforce methodology rules (no writing to raw data, test set locked during selection/tuning); the runtime enforces general safety.
