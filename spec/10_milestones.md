# 10 — Milestones

The v0.1 roadmap. Each milestone is a complete, demonstrable slice; do not start the next until the current one is verifiably working.

## M0 — Spec freeze

**Goal**: this directory is reviewed and locked for v0.1.

Deliverables:
- All ten spec files reviewed by the project owner.
- Open questions in [`README.md`](README.md) resolved or explicitly deferred.
- Decision recorded on the five v0.1 questions:
  1. Binary name (default `mlr`)
  2. Project config directory (default `.mlr/`)
  3. L1 metric scope (default single primary + secondary)
  4. gen-code build tag — implement upstream now or later?
  5. `respec/` flavor — domain-neutral default

Exit criteria: spec README's "Open Questions" section either resolved or moved to "Deferred to v0.2".

## M1 — gen-code build tag

**Goal**: gen-code compiles cleanly with `-tags nouserconfig`, with user-level loading stubbed.

Tasks (against gen-code repo):
- [ ] Add paired files for `internal/setting/`
- [ ] Add paired files for `internal/skill/`
- [ ] Add paired files for `internal/plugin/`
- [ ] Add paired files for `internal/hook/`
- [ ] Add paired files for `internal/mcp/`
- [ ] CI matrix: build and test under both tagged and untagged
- [ ] Document the tag in gen-code's `CLAUDE.md`

Exit criteria:
```
cd gen-code
go test -tags nouserconfig ./...   # passes
go build -tags nouserconfig ./...  # passes; binary ignores ~/.gen/
```

## M2 — Skeleton binary

**Goal**: `mlr` builds, launches a TUI, and proves it ignores user-level config.

Tasks:
- [ ] Add gen-code as submodule, pinned to a tagged release
- [ ] `cmd/mlr/main.go` assembling a `core.Agent` with default tools
- [ ] `Makefile` per [`09_build.md`](09_build.md)
- [ ] `cmd/mlr-hook/main.go` skeleton
- [ ] `mlr --version` reports gen-code commit

Exit criteria: `make build && ./bin/mlr` opens a TUI; running `gen` and `mlr` against the same project loads `.gen/` for `gen` but not for `mlr`; `mlr` reads only `.mlr/`.

## M3 — Project init + templates

**Goal**: `/init research --topic <topic>` produces a working project skeleton.

Tasks:
- [ ] `internal/template/` with `respec/`, `.mlr/settings.json`, root `README.md`, stub `progress.md`
- [ ] `init` command implementation
- [ ] Methodology templates (domain-neutral version of rad-research's `respec/`)

Exit criteria:
```
mkdir test-project && cd test-project
mlr /init research --topic "test"
ls   # respec/, research/, data/, experiments/, results/, papers/, .mlr/, README.md
```

## M4 — L1 experiment loop

**Goal**: an end-to-end autoresearch-style loop on a simple optimization task.

Tasks:
- [ ] `experimenter` agent definition
- [ ] Tools: `experiment_register`, `experiment_run`, `metric_grep`, `git_keep_or_reset`, `ledger_append`
- [ ] Hook: protect `data/raw/`, post-tool-use trace append
- [ ] Slash commands: `/exp new`, `/exp run`, `/exp loop`
- [ ] `experiments/ledger.tsv` format finalized
- [ ] Demo: a tiny `train.py` that the loop can optimize over (e.g. dummy `val_bpb` based on a random hyperparameter)

Exit criteria: `/exp loop --metric val_bpb --budget 30s --max-iter 20` runs to completion, advances/resets git correctly, and the TSV reflects all attempts.

## M5 — L2 literature tools

**Goal**: paper search and citation graph work end-to-end.

Tasks:
- [ ] `paper_search` against arxiv + HF Papers + Semantic Scholar
- [ ] `paper_read` with ar5iv parsing
- [ ] `citation_graph` (Semantic Scholar API)
- [ ] `dataset_inspect` for HF Hub + local files
- [ ] `literature` agent definition
- [ ] Slash commands: `/lit search`, `/lit shortlist`, `/lit read`

Exit criteria: `/lit search "small-sample radiomics"` produces a populated `papers/shortlist.md` with at least 5 entries each annotated with relevance.

## M-K — Knowledge integration

**Goal**: ml-researcher acts with senior-engineer depth, not generic-LLM guessing. See [`12_knowledge_integration.md`](12_knowledge_integration.md) for the full design.

Tasks:
- [ ] `internal/prompts/ml_researcher_v1.yaml` — system prompt structured after ml-intern v3 (persona, three-phase workflow, anti-patterns, hardware sizing, OOM ladder, dataset format rules, pre-flight checklist)
- [ ] `internal/data/model_registry.yaml` — initial 60-100 entries spanning the 6 domains in `12_knowledge_integration.md` §2; each entry has `last_verified` date
- [ ] `model_recommend` tool wired to read the registry
- [ ] `skills/ml/` initial set — at least `medical-small-sample-transfer.md`, `tabular-tabpfn-vs-xgboost.md`, `vision-classification-fine-tune.md`, `oom-recovery-checklist.md`
- [ ] HF MCP server pre-configured in default `.mlr/mcp.json` template
- [ ] arxiv-mcp-server documented as opt-in for `paper_search`

Exit criteria: a fresh project asks `mlr` "what model for tumor purity prediction with 270 cases of MRI + clinical?" and the response cites specific candidates from the registry (e.g. RadDINO, BiomedCLIP, MedGemma, or a tabular fusion route via TabPFNv2), with `last_verified` dates and pros/cons — not a generic "you could try a CNN" answer.

## M6 — L3 methodology enforcement

**Goal**: the lifecycle gates and `critic` actually block bad behavior.

Tasks:
- [ ] `phase_advance` tool with phase-gate hook
- [ ] `critic` agent definition
- [ ] Hook: test set lock during selection/tuning
- [ ] Hook: pre-flight on `experiment_run`
- [ ] `analyst` agent definition
- [ ] Tools: `bootstrap_ci`, `delong_test`, `figure_render`
- [ ] Slash commands: `/phase`, `/phase advance`, `/checklist`, `/critic`, `/report draft`, `/report finalize`
- [ ] `mlr-hook` subcommands implemented

Exit criteria:
- `/phase advance` blocks when requirements unmet, with a clear missing-list.
- A test that writes to `data/splits/test/` during `Model Selection` is hard-blocked.
- `/critic` flags a test-set leak in a planted bad project.

## M7 — End-to-end example

**Goal**: replicate (in skeleton) the rad-research GBM project as ml-researcher demo.

Tasks:
- [ ] `examples/gbm-tumor-purity/` with anonymized synthetic data
- [ ] Walkthrough README that takes a fresh user from `mlr init` to `analysis_report.md`
- [ ] Domain-specific `.mlr/playbook.md` showing radiomics-flavored guidance

Exit criteria: a new user can `git clone examples/gbm-tumor-purity && cd ... && mlr` and produce a defensible `results/reports/final.md` in under an hour.

## M8 — Release v0.1.0

**Goal**: tagged release with binary distribution.

Tasks:
- [ ] CI for cross-platform release builds
- [ ] Homebrew formula or equivalent install path
- [ ] CHANGELOG covering M1–M7
- [ ] `mlr --version` shows correct version + gen-code pin
- [ ] README badges live

Exit criteria: `brew install genai-io/tap/mlr` (or equivalent) installs a working binary that passes the M3 init smoke test on a clean machine.

## Deferred to v0.2 (not in scope for v0.1)

- HF Jobs / cloud GPU submission (ml-intern parity)
- Trackio-style monitoring dashboard integration
- Multi-project orchestration (run multiple `mlr` projects in parallel)
- Plugin marketplace tailored for ML
- `migrate` command to convert a project from `.gen/` to `.mlr/`
- Auto-published gen-code module versioning (move from `replace` to pinned `require`)
- Domain-specific playbooks shipped as installable add-ons

## Risk & sequencing notes

- **M1 is the only milestone that touches gen-code.** Per the v0.1 decision, M1 starts as a **fork** of gen-code (validate the build-tag approach), then upstreams the tag once proven. All other milestones are additive in ml-researcher.
- **M2 unblocks the rest.** Until the binary builds, nothing else can be tested integrated.
- **M-K is the highest-leverage differentiator.** The model registry + skills + ml playbook prompt is what separates ml-researcher from "yet another agent over gen-code." Run M-K in parallel with M5 once M2 is done.
- **M4 is the highest-value demo.** A working L1 loop is the most surprising outcome a reviewer will see; prioritize over M5.
- **M6 is the highest-risk milestone.** Phase gates and critic agent involve subtle prompt engineering and may need iteration.
- **M7 doubles as documentation.** It produces the canonical "show me how it works" demo.

## v0.1 sequencing

```
M0 (spec freeze)
   │
   ▼
M1 (fork gen-code, add nouserconfig tag) ── M2 (skeleton binary)
                                              │
                                              ├── M3 (init + templates)
                                              │
                                              ├── M4 (L1 loop) ─────────────┐
                                              │                             │
                                              ├── M5 (literature tools) ───┤
                                              │                             │
                                              ├── M-K (knowledge) ─────────┤
                                              │                             │
                                              └── M6 (L3 enforcement) ─────┤
                                                                            │
                                                                            ▼
                                                                       M7 (example) → M8 (release)
```

M4, M5, M-K can proceed in parallel once M3 lands. M6 needs M-K's playbook prompt to inform the critic agent's checks.
