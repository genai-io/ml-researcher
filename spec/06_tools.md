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

Skills live in `skills/`. Each skill is its own directory containing a `SKILL.md` file — the standard Anthropic Skills layout. The directory name is the skill's slug; runtimes (Claude Code, Gen Code, Codex) discover skills by walking `skills/*/SKILL.md`.

```
skills/
├── model-recommend/SKILL.md             # query model_registry.yaml; return curated picks
├── medical-small-sample-transfer/SKILL.md
├── tabular-tabpfn-vs-xgboost/SKILL.md
├── oom-recovery-checklist/SKILL.md
│
├── exp-register/SKILL.md                # create experiments/EXPxxx/ + git branch
├── exp-run/SKILL.md                     # python train.py > run.log 2>&1; timeout
├── metric-grep/SKILL.md                 # grep "^<key>:" run.log
├── git-keep-or-reset/SKILL.md           # advance branch or revert
├── ledger-append/SKILL.md               # tab-separated append to ledger.tsv
│
├── phase-advance/SKILL.md               # check gate requirements; advance phase
├── checklist-verify/SKILL.md            # pre-flight: baseline, dataset format, ...
├── trial-log/SKILL.md                   # structured append to trial_trace.md
├── bootstrap-ci/SKILL.md                # invoke scripts/bootstrap_ci.py
├── delong-test/SKILL.md                 # invoke scripts/delong_test.py
├── train-monitor/SKILL.md               # tail run.log; classify divergence/oom/nan
├── figure-render/SKILL.md               # invoke scripts/figure_render.py
├── sandbox-mode/SKILL.md                # pipeline-scaffolding sandbox rules
│
├── dataset-inspect/SKILL.md             # schema / label distribution / split lock check
├── paper-search/SKILL.md                # arxiv / HF Papers / S2 / paperswithcode search
├── paper-read/SKILL.md                  # methodology + ablation extraction to notes/
├── citation-graph/SKILL.md              # traverse forward/backward citations from a seed
│
├── error-analysis/SKILL.md              # worst-K + slice + confusion deep-dive
├── calibration-check/SKILL.md           # Brier / ECE / reliability diagram
├── repro-seal/SKILL.md                  # env + code + data + seed snapshot per kept run
│
├── ablation-planner/SKILL.md            # reviewer-defensible ablation matrix
├── data-leak-scan/SKILL.md              # group / temporal / proxy-label / split-rederivation
├── hypothesis-ledger/SKILL.md           # first-class hypothesis ledger (RD-Agent pattern)
└── seed-sensitivity/SKILL.md            # N-seed metric distribution per config
```

Most skills follow the **progressive disclosure** pattern: a slim `SKILL.md` (40–80 lines: when-to-use, steps, hard rules, brief script contract) plus a sibling `references/` directory holding long templates, lookup tables, interpretation guides, and JSON schemas. The agent loads SKILL.md by default and Reads references only when the workflow needs them.

```
skills/<skill-name>/
├── SKILL.md                  # always loaded
├── references/               # loaded on demand
│   ├── <topic-a>.md
│   └── <topic-b>.md
└── (optional) scripts/       # if the skill wraps a non-shared script
```

Skills group conceptually into five domains:

- **ML knowledge** — `model-recommend`, `medical-small-sample-transfer`, `tabular-tabpfn-vs-xgboost`, `oom-recovery-checklist`
- **Experiment-loop mechanics** — `exp-register`, `exp-run`, `metric-grep`, `git-keep-or-reset`, `ledger-append`, `train-monitor`
- **Methodology and gates** — `phase-advance`, `checklist-verify`, `trial-log`, `sandbox-mode`, `repro-seal`, `data-leak-scan`, `hypothesis-ledger`
- **Analysis and figures** — `bootstrap-ci`, `delong-test`, `figure-render`, `error-analysis`, `calibration-check`, `ablation-planner`, `seed-sensitivity`
- **Retrieval and reading** — `dataset-inspect`, `paper-search`, `paper-read`, `citation-graph`

The directory layout stays flat because runtime skill discovery is one level deep. For frontmatter / archetype / progressive-disclosure conventions, see [`13_skill_and_agent_template.md`](13_skill_and_agent_template.md).

## Skill format

Standard runtime convention — markdown with YAML frontmatter:

```markdown
---
name: model-recommend
description: Recommend ML models from the registry given a task, n_samples, and modality
allowed-tools: Read Grep
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

`skills/bootstrap-ci/SKILL.md`:
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
| `paper_search` | skill `paper-search/SKILL.md` (uses `WebFetch` against arxiv / HF Papers / Semantic Scholar) |
| `paper_read` | skill `paper-read/SKILL.md` (uses `WebFetch` for ar5iv) |
| `citation_graph` | skill `citation-graph/SKILL.md` (uses `WebFetch` for Semantic Scholar) |
| `dataset_inspect` | skill `dataset-inspect/SKILL.md` (uses `Bash` + HF datasets) |
| `model_recommend` | skill `model-recommend/SKILL.md` (reads `data/model_registry.yaml`) |
| `experiment_register` | skill `exp-register/SKILL.md` |
| `experiment_run` | skill `exp-run/SKILL.md` |
| `metric_grep` | skill `metric-grep/SKILL.md` |
| `git_keep_or_reset` | skill `git-keep-or-reset/SKILL.md` |
| `ledger_append` | skill `ledger-append/SKILL.md` |
| `phase_advance` | skill `phase-advance/SKILL.md` (slash command also exists) |
| `trial_log` | skill `trial-log/SKILL.md` |
| `checklist_verify` | skill `checklist-verify/SKILL.md` |
| `bootstrap_ci` | skill `bootstrap-ci/SKILL.md` + `scripts/bootstrap_ci.py` |
| `delong_test` | skill `delong-test/SKILL.md` + `scripts/delong_test.py` |
| `figure_render` | skill `figure-render/SKILL.md` + `scripts/figure_render.py` |
| `train_monitor` | skill `train-monitor/SKILL.md` |
| `oom_recover` | skill `oom-recovery-checklist/SKILL.md` |

## Permissions

Skill execution uses the runtime's existing tools — so permission questions reduce to:

| Used inside skill | Permission concern |
|---|---|
| `Read` | always allowed (no risk) |
| `WebFetch` | usually allowed; runtime may prompt for unknown domains |
| `Bash` | gated by runtime's bash policy + project hooks |
| `Edit`, `Write` | gated by hooks (e.g., `data/raw/**` is hard-blocked; see [`08_hooks.md`](08_hooks.md)) |

There is no separate ml-researcher permission system. Hooks enforce methodology rules (no writing to raw data, test set locked during selection/tuning); the runtime enforces general safety.
