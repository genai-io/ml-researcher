# ML Researcher Specification

> v0.1 spec. ml-researcher is a [San](https://github.com/genai-io/san) persona (system prompt + skills + config), installed by `install.sh` and toggled with `/persona ml-researcher`. The contents below describe the design; the persona content (`system/`, `agents/`, `skills/`, etc.) lives at the repo root.

## Reading Order

Spec documents are numbered to suggest a reading order for newcomers:

| File | Topic |
|---|---|
| [`01_overview.md`](01_overview.md) | Why ml-researcher exists; the three-layer loop model |
| [`02_architecture.md`](02_architecture.md) | San persona architecture; the four-part prompt; installer responsibilities; `.san/` layout |
| [`03_project_structure.md`](03_project_structure.md) | Research project directory layout |
| [`04_methodology.md`](04_methodology.md) | Research phases, records, guardrails |
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

- **[rad-research](https://github.com/yanmxa/rad-research)** — research methodology framework: lifecycle stages, `respec/` templates, trial trace, methodology guardrails.
- **[huggingface/ml-intern](https://github.com/huggingface/ml-intern)** — ML-domain tooling: paper search, citation graph, dataset inspection, pre-flight checklists, OOM recovery.
- **[karpathy/autoresearch](https://github.com/karpathy/autoresearch)** — overnight automation loop: edit → run → measure → keep-or-reset, with git as the ledger.

See [`01_overview.md`](01_overview.md) for how these are combined.

## Decisions locked (v0.1)

| Question | Decision |
|---|---|
| Delivery vehicle | `install.sh` curl-bash, San persona; **no plugin install, no binary, no package manager** |
| Config dir | `.san/` (project scope) or `~/.san` (`--user` scope); persona at `.san/personas/ml-researcher/` |
| Runtime | [San](https://github.com/genai-io/san) only; legacy `claude`/`gen`/`codex` `init.sh` path removed |
| Train Loop metric scope | Single primary metric; optional secondary metrics declared per project |
| `respec/` flavor | Domain-neutral default; project-level overrides via `playbook.md` |
| Standalone binary | Deferred indefinitely; tracked in [`TODO.md`](TODO.md) |
