# ML Researcher Specification

> v0.1 spec — pre-implementation. The contents below describe the intended design; nothing is built yet.

## Reading Order

Spec documents are numbered to suggest a reading order for newcomers:

| File | Topic |
|---|---|
| [`01_overview.md`](01_overview.md) | Why ml-researcher exists; the three-layer loop model |
| [`02_architecture.md`](02_architecture.md) | Relationship to `gen-code`; submodule + build tag strategy |
| [`03_project_structure.md`](03_project_structure.md) | Research project directory layout |
| [`04_methodology.md`](04_methodology.md) | Lifecycle stages, records, guardrails |
| [`05_agents.md`](05_agents.md) | Built-in agents and their tool subsets |
| [`06_tools.md`](06_tools.md) | ML-specific tools |
| [`07_commands.md`](07_commands.md) | Slash commands |
| [`08_hooks.md`](08_hooks.md) | Methodology enforcement via hooks |
| [`09_build.md`](09_build.md) | Build tag strategy, submodule pinning, sync workflow |
| [`10_milestones.md`](10_milestones.md) | v0.1 implementation roadmap |
| [`11_related_projects.md`](11_related_projects.md) | Landscape survey: AIDE, AI-Scientist, MLE-bench, RD-Agent, MLR-Bench, gaps ml-researcher fills |
| [`12_knowledge_integration.md`](12_knowledge_integration.md) | Embedding ML domain expertise: techniques, model taxonomy, registry design |

## Influences

This spec synthesizes three sources:

- **[rad-research](https://github.com/yanmxa/rad-research)** — research methodology framework: lifecycle stages, `respec/` templates, iteration trace, methodology guardrails.
- **[huggingface/ml-intern](https://github.com/huggingface/ml-intern)** — ML-domain tooling: paper search, citation graph, dataset inspection, pre-flight checklists, OOM recovery.
- **[karpathy/autoresearch](https://github.com/karpathy/autoresearch)** — overnight automation loop: edit → run → measure → keep-or-reset, with git as the ledger.

See [`01_overview.md`](01_overview.md) for how these are combined.

## Open Questions (v0.1)

The following decisions are tentative and may change before M1:

1. **Binary name**: `mlr` (current default). Alternatives considered: `mlrun`, `lab`, `fwd`.
2. **Project config dir**: `.mlr/` (current default). Inheriting `.gen/` is also possible.
3. **L1 metric scope**: single primary metric with optional secondaries (current default), or multi-metric Pareto.
4. **`gen-code` build tag**: requires upstream change. Alternative: maintain a fork until the tag is upstreamed.
5. **`respec/` flavor**: ship a domain-neutral version; project-level overrides for domain specialization (e.g. radiomics, NLP, RL).

These are tracked in [`10_milestones.md`](10_milestones.md).
