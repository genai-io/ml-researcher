# 10 — Milestones

The v0.1 roadmap reflects the zero-install architecture. Each milestone is a complete, demonstrable slice; do not start the next until the current one is verifiably working.

## M0 — Spec freeze

Lock the design described in `spec/`. Resolve open questions (binary name, runtime priorities, model registry coverage). Exit when this directory is reviewed and stable.

## M1 — `init.sh` and template skeleton

The minimum viable bootstrap: `curl | bash` produces a working project directory.

Tasks:
- [ ] `init.sh` per the spec in [`02_architecture.md`](02_architecture.md), with `--runtime`, `--in-place`, `--ref` flags
- [ ] `template/` skeleton: `README.md`, `respec/` (methodology templates from rad-research, domain-neutral), `research/progress.md` stub, `data/`, `experiments/ledger.tsv` (header), `results/`, `papers/`
- [ ] Placeholder substitution: `{{TOPIC}}`, `{{DATE}}`, `{{SLUG}}`
- [ ] Smoke test in a clean Alpine docker container

Exit: `init.sh "test"` produces a project that has correct directory structure and filled metadata.

## M2 — System prompt

Ship the ml playbook prompt that future projects load as `CLAUDE.md` / `GEN.md` / `AGENTS.md`.

Tasks:
- [ ] `prompts/ml_researcher.md` modeled after ml-intern v3 (persona, three-phase workflow, anti-patterns, hardware sizing, OOM ladder, dataset format rules per training method, mandatory monitoring discipline, framing line about LLM knowledge being outdated)
- [ ] Cite influences (rad-research methodology, ml-intern, autoresearch)
- [ ] First version domain-neutral; project-level overrides happen in `template/respec/init.md`'s playbook section

Exit: a project initialized with this prompt produces sensible, methodology-aware first-turn behavior.

## M3 — Subagents

Five subagents, each as a markdown file in `agents/`.

Tasks:
- [ ] `agents/navigator.md` — top-level dispatcher, reads progress.md, advances L3
- [ ] `agents/literature.md` — paper / dataset search subagent
- [ ] `agents/experimenter.md` — L1 autoresearch-style loop runner
- [ ] `agents/analyst.md` — produces analysis_report, statistical comparisons
- [ ] `agents/critic.md` — methodology audit (no leakage, baseline present, locked test set)

Exit: each subagent has a clear role description, tool subset, and example invocations.

## M4 — Commands

Slash commands the user invokes inside the agent.

Tasks:
- [ ] `commands/phase.md` — show current phase + advance requirements
- [ ] `commands/exp-new.md` — register experiment
- [ ] `commands/exp-loop.md` — kick off L1 autoresearch loop
- [ ] `commands/exp-list.md` — show ledger
- [ ] `commands/exp-compare.md` — multi-experiment comparison with bootstrap CI
- [ ] `commands/lit-search.md` — invoke literature subagent
- [ ] `commands/checklist.md` — pre-flight check
- [ ] `commands/critic.md` — invoke critic subagent
- [ ] `commands/report.md` — draft analysis report

Note: there is no `init-mlresearch` slash command. Bootstrapping a project is `init.sh`'s job.

Exit: each command runs and produces useful output in a real project.

## M5 — Skills

Skills organized into `skills/ml/`, `skills/experiment/`, `skills/methodology/`.

Tasks:
- [ ] `skills/ml/` — at least: `model-recommend.md`, `medical-small-sample-transfer.md`, `tabular-tabpfn-vs-xgboost.md`, `oom-recovery-checklist.md`, plus a few more covering vision/multimodal/NLP
- [ ] `skills/experiment/` — `exp-register.md`, `exp-run.md`, `metric-grep.md`, `git-keep-or-reset.md`, `ledger-append.md`
- [ ] `skills/methodology/` — `phase-advance.md`, `checklist-verify.md`, `iteration-log.md`, `bootstrap-ci.md`, `delong-test.md`, `train-monitor.md`, `figure-render.md`

Exit: each skill loads when its description triggers and successfully completes its recipe.

## M6 — Model registry

Structured ML knowledge as embedded YAML.

Tasks:
- [ ] `data/model_registry.yaml` schema finalized (id, task, modality, params, license, min_data, recommended_hparams, pros, cons, failure_modes, sota_tracker, reference_impl, last_verified)
- [ ] Seed entries: 60-100 spanning vision, multimodal, medical imaging, tabular, NLP, generative
- [ ] `skills/ml/model-recommend.md` reads it correctly

Exit: `model-recommend` returns sensible answers for "tumor purity from MRI with 270 cases" (medical small-sample) and "fine-tune SigLIP2 for retrieval with 5K pairs" (multimodal).

## M7 — Hooks

Methodology guardrails enforced by hooks. See [`08_hooks.md`](08_hooks.md).

Tasks:
- [ ] `hooks/settings.json` — protect `data/raw/`, lock test set during selection/tuning, pre-flight on `experiment_run` skill, audit append on completion
- [ ] `hooks/check_data_immutable.sh`, `hooks/test_set_guard.sh`, `hooks/preflight.sh`, `hooks/trace_append.sh`
- [ ] `init.sh` copies these into `<project>/.claude/hooks/` and installs the JSON config

Exit: writing to `data/raw/` is hard-blocked; reading test labels during Selection phase is hard-blocked; `experiment_run` triggers pre-flight automatically.

## M8 — Scripts

Python helpers invoked by skills.

Tasks:
- [ ] `scripts/bootstrap_ci.py` — bootstrap CI for AUC / accuracy / F1
- [ ] `scripts/delong_test.py` — DeLong paired AUC test
- [ ] `scripts/figure_render.py` — ROC, calibration, confusion, learning curve, comparison bar
- [ ] `scripts/README.md` — usage and dependency notes

Exit: each skill+script pair works end-to-end. The user installs Python deps once (numpy, scipy, scikit-learn, matplotlib).

## M9 — End-to-end demo

Replicate a small slice of rad-research's GBM project as a self-contained demo.

Tasks:
- [ ] `examples/gbm-tumor-purity/` produced by `init.sh "GBM tumor purity demo"` and pre-filled with synthetic data
- [ ] Walkthrough README showing `data_understanding → research_goal → /exp-loop → /report` end to end
- [ ] Domain-specific `playbook.md` showing radiomics-flavored guidance

Exit: a new user can clone `examples/gbm-tumor-purity` and produce a defensible `results/reports/final.md` in under an hour.

## M10 — Release v0.1.0

Tasks:
- [ ] Tag `v0.1.0`
- [ ] CHANGELOG covering M1–M9
- [ ] Smoke-test docker run in CI for every PR to main
- [ ] Public README badges live

Exit: `curl -fsSL .../init.sh | bash -s -- "smoke"` works on macOS, Linux, and Alpine for a third-party tester.

## v0.1 sequencing

```
M0 (spec freeze)
   │
   ▼
M1 (init.sh + template)
   │
   ├─► M2 (system prompt)         ──┐
   ├─► M3 (subagents)             ──┤
   ├─► M4 (commands)              ──┤  parallelizable
   ├─► M5 (skills)                ──┤
   ├─► M6 (model registry)        ──┤
   ├─► M7 (hooks)                 ──┤
   └─► M8 (scripts)               ──┘
                                    │
                                    ▼
                                M9 (demo)
                                    │
                                    ▼
                               M10 (release)
```

M2-M8 are largely independent once M1 is done. M3 (agents) and M5 (skills) coordinate on tool subsets, but the file format is fixed.

## Risk and sequencing notes

- **M1 unblocks everything else.** Until `init.sh` exists, none of the other content can be tested in a real project.
- **M5 is the highest-leverage differentiator.** Skills + scripts + registry is what separates ml-researcher from "yet another agent prompt."
- **M9 doubles as documentation.** It produces the canonical "show me how it works" demo, which becomes the README's hero example.
- **Risk concentrations**: M2 (prompt engineering subtle), M5 (skill boundary cases), M9 (pulling rad-research's domain-specific bits into a domain-neutral demo without losing fidelity).

## Out-of-scope for v0.1 (deferred)

These are real product directions, just not v0.1. Tracked in [`TODO.md`](TODO.md):

- Standalone `mlr` binary (gen-code derivative)
- MCP server packaging for tools
- Claude Code plugin marketplace listing
- Cross-tool spec-kit compatibility (Cursor / Copilot / Gemini portability)
- Auto-update tooling for existing projects
- Sysbox-style sandbox isolation for `experiment_run`
- BFTS over experiment directions (AI-Scientist v2 style)
- Automated paper drafting (deliberately not v0.1 — fabrication risk)
