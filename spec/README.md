# ML Researcher Specification

> v0.1 spec — pre-implementation. The contents below describe the intended design; the actual content (`init.sh`, `agents/`, `skills/`, etc.) is being written in parallel.

## Reading Order

Spec documents are numbered to suggest a reading order for newcomers:

| File | Topic |
|---|---|
| [`01_overview.md`](01_overview.md) | Why ml-researcher exists; the three-layer loop model |
| [`02_architecture.md`](02_architecture.md) | Zero-install model; `init.sh` is the only delivery; multi-runtime support |
| [`03_project_structure.md`](03_project_structure.md) | Research project directory layout |
| [`04_methodology.md`](04_methodology.md) | Lifecycle stages, records, guardrails |
| [`05_agents.md`](05_agents.md) | Built-in subagents and their roles |
| [`06_tools.md`](06_tools.md) | Skills and Python scripts (no custom tools) |
| [`07_commands.md`](07_commands.md) | Slash commands |
| [`08_hooks.md`](08_hooks.md) | Methodology enforcement via hooks |
| [`09_packaging.md`](09_packaging.md) | Install model, versioning, distribution |
| [`10_milestones.md`](10_milestones.md) | v0.1 implementation roadmap |
| [`11_related_projects.md`](11_related_projects.md) | Landscape survey: AIDE, AI-Scientist, MLE-bench, RD-Agent, MLR-Bench, gaps ml-researcher fills |
| [`12_knowledge_integration.md`](12_knowledge_integration.md) | Embedding ML domain expertise: techniques, model taxonomy, registry design |
| [`TODO.md`](TODO.md) | Backlog: things explicitly out of scope for v0.1 |

## Influences

This spec synthesizes three sources:

- **[rad-research](https://github.com/yanmxa/rad-research)** — research methodology framework: lifecycle stages, `respec/` templates, iteration trace, methodology guardrails.
- **[huggingface/ml-intern](https://github.com/huggingface/ml-intern)** — ML-domain tooling: paper search, citation graph, dataset inspection, pre-flight checklists, OOM recovery.
- **[karpathy/autoresearch](https://github.com/karpathy/autoresearch)** — overnight automation loop: edit → run → measure → keep-or-reset, with git as the ledger.

See [`01_overview.md`](01_overview.md) for how these are combined.

## Decisions locked (v0.1)

| Question | Decision |
|---|---|
| Delivery vehicle | `init.sh` curl-bash; **no plugin install, no binary, no package manager** |
| Project config dir | `.claude/` (Claude Code default); `.gen/` for gen-code; `.codex/` for Codex |
| Multi-runtime support | First-class: Claude Code + gen-code; best-effort: Codex |
| L1 metric scope | Single primary metric; optional secondary metrics declared per project |
| `respec/` flavor | Domain-neutral default; project-level overrides via `playbook.md` |
| Standalone binary | Deferred indefinitely; tracked in [`TODO.md`](TODO.md) |
