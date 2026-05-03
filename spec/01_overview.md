# 01 — Overview

## Why ml-researcher exists

ML research suffers from two opposite failure modes:

- **Loose loops** — running experiments without an audit trail; picking the best test-set number; drifting away from the original goal; "tuning until something works."
- **Stiff frameworks** — drowning in MLOps boilerplate (DAG runners, registries, dashboards) that doesn't help answer the research question. The framework becomes the work.

ml-researcher is opinionated about **discipline**, but minimal about **infrastructure**. It does not ship a training framework, a metric server, or a model registry. It encodes a methodology and provides ML-domain tools that let an LLM agent run that methodology disciplinedly.

## The thesis

> The core of ML research is closing the chain *hypothesis → experiment → evidence → decision* on multiple time scales, with strict rules for each scale.

ml-researcher operationalizes this thesis as a three-layer loop model.

## Three-Layer Loop Model

```
┌──────────────────────────────────────────────────────────────────┐
│  L3 · Lifecycle Loop    (days/weeks)                              │
│   Data Understanding → Research Goal → Model Selection            │
│   → Fine Tuning → Analysis Report → Goal Revision                 │
│                                                                   │
│   Records: research/, progress.md, iteration_trace.md             │
│   Driver: human review at phase boundaries                        │
│   Source: rad-research                                            │
├──────────────────────────────────────────────────────────────────┤
│  L2 · Experiment Loop   (hours)                                   │
│   Plan → Research → Sandbox dev → Submit job → Monitor → Decide   │
│                                                                   │
│   Records: experiments/EXPxxx/, papers/shortlist.md               │
│   Driver: pre-flight checklist + monitoring discipline            │
│   Source: huggingface/ml-intern                                   │
├──────────────────────────────────────────────────────────────────┤
│  L1 · Iteration Loop    (minutes)                                 │
│   Edit code → Run → Grep metric → Keep (advance) or Reset         │
│                                                                   │
│   Records: git branch + experiments/ledger.tsv                    │
│   Driver: scalar metric + fixed time budget                       │
│   Source: karpathy/autoresearch                                   │
└──────────────────────────────────────────────────────────────────┘
```

L1 is nested inside L2 is nested inside L3. The agent always knows which loop is active and applies the corresponding discipline. Crossing a layer boundary is itself a recorded decision.

## Why this layering matters

Each loop has different failure modes and therefore different guardrails:

| Loop | Primary failure mode | Primary guardrail |
|---|---|---|
| L1 | running forever on a worse branch; flooding context with logs | git keep-or-reset; redirect-not-tee |
| L2 | broken job that wastes hours; silent dataset substitution; OOM dead end | pre-flight checklist; OOM prescription ladder |
| L3 | drift from original goal; using test set during selection; no baseline | phase-advance gate; locked test set; mandatory baseline |

A tool that only does L1 (autoresearch) cannot prevent L3 drift. A framework that only does L3 (rad-research) cannot run L1 overnight. ml-researcher encodes all three and the rules for crossing between them.

## Project-centric, not user-centric

A research project is a single directory. **All configuration lives in the project**; there is no user-level (`~/.mlr/`) configuration. Rationale:

- A research project is a sealed scientific record. Reproducibility from the directory alone is a hard requirement.
- No global state means no cross-contamination between projects (different metrics, different test-set rules, different paper databases).
- Cloning the project is the same as cloning its agent configuration.

This is enforced at compile time (see [`02_architecture.md`](02_architecture.md)) — the `nouserconfig` build tag removes user-level config code paths from the binary.

## What ml-researcher is not

- Not a training framework. We don't ship trainers, schedulers, or dataloaders.
- Not a model registry. We don't store weights centrally.
- Not a SaaS dashboard. Monitoring runs in the terminal or via the project's own tools.
- Not an autoresearch clone. autoresearch is one of three loops; we add structure above it.
- Not a HF-locked tool. ml-intern is HF-locked by design; ml-researcher is provider-neutral. HF Jobs is one of several supported execution targets.
- Not a chat companion. The system prompt enforces concise, action-oriented output.
