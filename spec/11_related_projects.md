# 11 — Related Projects

A landscape of ML research / engineering agents in 2025-2026, with what each gets right, where it falls short, and what ml-researcher takes from each. The two main reference points (`huggingface/ml-intern`, `karpathy/autoresearch`) are covered in [`01_overview.md`](01_overview.md); this document expands the field.

## Comparison table

| Project | Positioning | Loop structure | Knowledge encoding | Best idea to steal |
|---|---|---|---|---|
| [AIDE](https://github.com/WecoAI/aideml) (Weco AI) | Tree-search ML engineering agent that won o1's MLE-bench medals | Default 20-step solution-tree search; each script is a node, edits are edges; metric prunes | Pure prompting; no RAG, no skill files | Solution tree as audit artifact + HTML visualization |
| [AI-Scientist v1/v2](https://github.com/SakanaAI/AI-Scientist) (Sakana) | End-to-end research → LaTeX paper | v1: linear ideation→impl→write; v2: BFTS with experiment-manager agent | v1: hand-authored templates (NanoGPT, diffusion, grokking); v2: free-form topic markdown | Experiment-manager agent decides which BFTS nodes to expand/prune |
| [MLE-bench](https://github.com/openai/mle-bench) (OpenAI) | 75 Kaggle MLE tasks + reference scaffolds (AIDE, MLAB, OpenHands, dummy) | Per-agent loops; harness enforces wall-clock + hidden test-labels via sysbox | None at benchmark layer; lives in agents | Test-set firewall + dummy verifier ("prove you cannot read holdout labels") |
| [MLE-Agent](https://github.com/MLSysOps/MLE-agent) (MLSysOps) | "Pairing engineer" CLI with live ArXiv + PapersWithCode RAG | Parse → retrieve SOTA → generate → debug; chat-or-autonomous | ArXiv + PWC retrieval at plan time; "Code RAG" function zoo | RAG over papers and code at *plan formation*, not execution |
| [AutoML-Agent](https://github.com/DeepAuto-AI/automl-agent) (DeepAuto, ICML'25) | Multi-agent full-pipeline AutoML across 6 modalities | Planner → parallel sub-task agents → multi-stage verifier | Retrieval-augmented planning library; LoRA-tuned Prompt Agent on Mixtral-8x7B | Multi-stage verification gates between plan / code / result |
| [RD-Agent](https://github.com/microsoft/RD-Agent) (Microsoft Research) | R&D copilot; flagship quant variant RD-Agent(Q) | Hypothesis → code → backtest → interpret loop with explicit hypothesis storage | Hypothesis ledger as first-class artifact | Hypothesis ledger separate from code/run logs |
| [MLR-Bench](https://arxiv.org/abs/2505.19955) (NeurIPS'25) | Benchmark + LLM-judge for 201 ML research tasks | n/a (benchmark) | n/a | The headline finding (see below) |
| [PaperBench](https://openai.com/index/paperbench/) (OpenAI, ICML'25) | Reproduce 20 ICML 2024 Spotlight/Oral papers | n/a (benchmark) | 8,316 hierarchical rubric items | Hierarchical rubrics for paper reproduction |
| [ML-Agent](https://github.com/MASWorks/ML-Agent) | RL-trained 7B agent (Qwen2.5-7B base) on ML tasks | Exploration FT → step-wise RL → unified reward | Domain RL fine-tuning | (Mostly cautionary — see "fine-tuning vs prompting" below) |

## Per-project details

### AIDE — Weco AI

> "LLM-driven agent that writes, evaluates and improves machine-learning code"

The agent that gave OpenAI's o1-preview its MLE-bench medals. Default budget `agent.steps=20`. Pattern: draft → debug → improve, with each Python script as a tree node. Survivor is `best_solution.py`; tree saved as HTML.

**Lesson**: a solution tree is a good *artifact format* for ML agents. Linear chat history isn't enough — you want every attempt and its score visible. ml-researcher's `experiments/EXPxxx/` per-experiment directories already encode this; consider adding a tree visualization on top of `experiments/ledger.tsv`.

### AI Scientist v1 / v2 — Sakana AI

v1 is a tightly-templated pipeline: ideation → implementation → analysis → writing. v2 (`AI-Scientist-v2`) drops human templates and does **best-first tree search (BFTS)** parameterized by `num_workers`, `steps`, `max_debug_depth`, `debug_prob`, coordinated by an **experiment-manager agent**.

> "removes reliance on human-authored templates, generalizes across Machine Learning (ML) domains, and employs a progressive agentic tree search"

The experiment-manager-agent pattern is worth stealing: a separate role that decides *which* experimental directions to expand vs prune, distinct from the worker that actually runs experiments. ml-researcher's `navigator` agent plays this role at the Research Loop level, with `experimenter` doing the Train Loop-level work.

**Caution**: v1 ships a critical safety warning — *"This codebase will execute LLM-written code. There are various risks and challenges associated with this autonomy."* ml-researcher's hooks + permission system address this.

### MLE-bench + reference agents — OpenAI

The benchmark itself is a curated set of 75 Kaggle competitions. The contribution that matters for ml-researcher is the **isolation pattern**:

- **Sysbox runtime** by default for AIDE/MLAB/dummy agents
- **Hidden test labels** — the "private" data is sealed at the harness level
- **Dummy verifier** — *"the dummy agent checks that it can't read the 'private' data; this includes the labels of the test set"*

The dummy-verifier pattern is the single most useful idea here: a precondition agent that **proves it cannot see eval labels** before any LLM call runs. ml-researcher should adopt this as a hook — see [§ Research-rigor mechanisms](#research-rigor-mechanisms) below.

Headline result: o1-preview + AIDE = bronze in **16.9%** of competitions. For context, that's ~3× the linear-agent baseline.

### MLE-Agent — MLSysOps

CLI agent with three integrations that matter:

- **ArXiv RAG** at plan formation time
- **Papers-with-Code retrieval** for SOTA recipes
- **"Code RAG" function zoo** so the agent grabs proven snippets instead of synthesizing

Stalled at `0.4.2` (Oct 2024); the design is sound but the project hasn't tracked the field. The take-home: **citations belong in the plan, not in the code afterwards**. ml-researcher's `literature` agent + `paper_search`/`citation_graph` tools encode this; the gap is a discipline rule that says *plan must cite before code starts*.

### AutoML-Agent — DeepAuto-AI (ICML 2025)

Multi-agent: Agent Manager orchestrates Prompt → Data → Model → Operation agents. The novel contribution is **multi-stage verification**: separate verifier role that can fail any stage (plan, code, results). Retrieval-augmented planning ranks candidate plans before any are executed.

ml-researcher's `critic` agent corresponds to this verifier role, but our current spec runs `critic` only at phase boundaries. AutoML-Agent's design suggests running it more granularly — between plan and code, between code and result publication.

### RD-Agent — Microsoft Research

The flagship variant `RD-Agent(Q)` is for quant trading research. Headline: *"<\$10 cost, ~2× ARR vs benchmark factor libraries with 70% fewer factors."* The architecture is a hypothesis → code → backtest → interpret loop with a **first-class hypothesis ledger** separate from the code repository.

ml-researcher's `research/trial_trace.md` already plays this role conceptually but is more general (it covers experiments, not hypotheses). Consider adding a `research/hypotheses.md` as a separate artifact, with each hypothesis ID linkable from `trial_trace.md` entries.

### MLR-Bench — NeurIPS 2025

Benchmark of 201 workshop-paper tasks across NeurIPS / ICLR / ICML, plus an `MLR-Judge` LLM rubric reviewer. The findings that matter for ml-researcher's positioning:

> "current coding agents frequently (e.g., in 80% of the cases) produce fabricated or invalidated experimental results — posing a major barrier to scientific reliability."

> "a primary weakness is their inability to propose technically sound methods … markedly low scores in Soundness."

ml-researcher reads this as empirical motivation: research rigor needs to be *load-bearing in the workflow itself*, not a review-time check. The mission framing is "help researchers do credible work," not "catch agents that cheat."

### PaperBench — OpenAI ICML 2025

20 ICML 2024 Spotlight/Oral papers; agents must reproduce the headline result. **8,316 hierarchical rubric items** co-developed with the paper authors; an LLM judge benchmarked separately. Best score: Claude 3.5 Sonnet with open scaffolding = **21.0%**, still below ML PhD humans.

The hierarchical rubric methodology is borrowable for `analyst` agent's report grading. Not in v0.1 scope but worth recording.

### ML-Agent — MASWorks

First serious attempt at **RL-fine-tuning a 7B agent** on ML tasks: Exploration-Enriched Fine-Tuning → step-wise RL → Unified Reward. Claims to beat 671B DeepSeek-R1 on MLAgentBench/MLEBench held-out tasks. Checkpoints "to be released."

We do **not** propose to fine-tune our own ML LLM (see [`12_knowledge_integration.md`](12_knowledge_integration.md) §1.8) — the field moves faster than fine-tunes can ship, and prompting + tools beats fine-tuning for this use case in the current evidence.

## Research-rigor mechanisms

The central design challenge is **making rigor cheap enough that researchers actually do it** — load-bearing guardrails that run inside the workflow, not a review pass tacked on at the end. ml-researcher's mechanisms:

| Mechanism | Where it lives | Research-quality risk addressed |
|---|---|---|
| Test-set lock during selection/tuning | [`08_hooks.md`](08_hooks.md) #2 | Test peeking that inflates evaluation |
| Pre-flight checklist hook | [`08_hooks.md`](08_hooks.md) #3 | Wrong dataset format, wrong arguments, missing baseline |
| Iteration trace + ledger | [`04_methodology.md`](04_methodology.md), [`06_tools.md`](06_tools.md) | Drift between reported metrics and what actually ran |
| `critic` agent | [`05_agents.md`](05_agents.md) | Methodology drift, baseline missing |
| Locked splits at init | [`03_project_structure.md`](03_project_structure.md) | Re-randomized splits hiding overfitting |
| Result-consistency principle | [`04_methodology.md`](04_methodology.md) #6 | Mismatched figures vs reported metrics |

To strengthen this further, ml-researcher should adopt MLE-bench's **dummy-verifier** pattern in v0.2:

> Before any `experiment_run`, an isolated verifier agent attempts to read `data/splits/test/labels.*` from within the experiment's working directory. If it succeeds, the experiment is blocked.

This is a stronger guarantee than a hook regex match. Tracked as a v0.2 candidate in [`10_milestones.md`](10_milestones.md).

## Gaps in the landscape that ml-researcher uniquely fills

Three gaps are visible after this survey, and ml-researcher addresses each:

1. **Research-rigor mechanisms as load-bearing workflow components**, not a post-hoc review pass. No surveyed agent (AIDE, AI-Scientist, MLE-Agent, AutoML-Agent, RD-Agent) bakes in a test-set lock + baseline-mandatory + dummy-verifier precondition into the actual workflow. ml-researcher does — see [`04_methodology.md`](04_methodology.md) and [`08_hooks.md`](08_hooks.md).

2. **Skill-file ML expertise + plan-time RAG, instead of either bare prompts or hand-written templates.** AIDE has nothing; AI-Scientist v1 has rigid templates; v2 has nothing; MLE-Agent has retrieval but no curated skills; AutoML-Agent buries knowledge in a LoRA. ml-researcher encodes methodology as skill files exposed via Skill / ToolSearch *and* does live ArXiv/PWC retrieval at plan formation — see [`12_knowledge_integration.md`](12_knowledge_integration.md).

3. **A clean `literature` ↔ `modeler` split for the Selection phase.** Existing agents either fold "what techniques exist" and "what to actually try" into one ideation step (AI-Scientist v2, AIDE, MLE-Agent), or buy it via an opaque retrieval-augmented LoRA (AutoML-Agent). ml-researcher's separate `modeler` subagent owns the candidate matrix + rejection log + baseline pick in `research/model_selection.md`, while `literature` stays read-heavy. See [`05_agents.md`](05_agents.md).

4. **An auditable solution tree spanning experiments AND text artifacts.** AIDE has a code tree; AI-Scientist v2 has an experiment-run tree; neither integrates a research-log / hypothesis ledger / human-readable rationale per node. ml-researcher's per-experiment `EXPxxx/README.md` + `trial_trace.md` + `progress.md` triple, linked by experiment ID, is the integration nothing in the landscape offers.

## What we explicitly do NOT do

| Idea | Why we skip it (for v0.1) |
|---|---|
| Domain-fine-tuned LLM (à la ML-Agent) | Field churn outpaces fine-tunes; maintenance cost dominates |
| Auto-paper-writing (à la AI Scientist) | Dangerous given 80% fabrication finding; humans approve final reports |
| Sysbox / Docker isolation by default (à la MLE-bench) | Adds setup friction; revisit in v0.2 once core loop is proven |
| BFTS over experiment directions (à la AI Scientist v2) | Out of scope for v0.1; navigator does linear stage progression |
| Multi-modal AutoML (à la AutoML-Agent) | We do not ship a model zoo or auto-pipeline; we provide tools and discipline |

## Sources

- [WecoAI/aideml](https://github.com/WecoAI/aideml), [paper](https://arxiv.org/abs/2502.13138)
- [SakanaAI/AI-Scientist](https://github.com/SakanaAI/AI-Scientist), [v2](https://github.com/SakanaAI/AI-Scientist-v2)
- [openai/mle-bench](https://github.com/openai/mle-bench), [paper](https://arxiv.org/abs/2410.07095)
- [MLSysOps/MLE-agent](https://github.com/MLSysOps/MLE-agent)
- [DeepAuto-AI/automl-agent](https://github.com/DeepAuto-AI/automl-agent)
- [microsoft/RD-Agent](https://github.com/microsoft/RD-Agent)
- [MLR-Bench paper](https://arxiv.org/abs/2505.19955)
- [PaperBench (OpenAI)](https://openai.com/index/paperbench/), [paper](https://arxiv.org/abs/2504.01848)
- [MASWorks/ML-Agent](https://github.com/MASWorks/ML-Agent)
