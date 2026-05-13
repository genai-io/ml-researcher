# 05 — Built-in Agents

ml-researcher ships six built-in agents. Each is defined in `agents/<name>.md` (markdown with YAML frontmatter) and copied into a project's `<config-dir>/agents/` by `init.sh`. Projects may override or supplement them via `<config-dir>/agents/`.

## Roster

| Agent | Role | Active loop | Spawned by |
|---|---|---|---|
| `navigator` | Top-level dispatcher; identifies the active loop layer | Research entry | default |
| `literature` | Paper search, citation graph, dataset discovery — *what exists* | Experiment sub-step | navigator, `/exp paper *` |
| `modeler` | Builds the candidate model matrix + rejection log — *what to actually try* | Research: Model Selection | navigator |
| `experimenter` | Runs the Train Loop: hypothesize → localize → edit → run → measure → keep/reset | Train | navigator, `/train run` |
| `analyst` | Produces analysis reports, statistical comparisons, figures | Research: Analysis Report | navigator, `/research report` |
| `critic` | Enforces methodology guardrails | cross-layer | hooks; on demand |

`literature` and `modeler` split the Model Selection workload: `literature` stays read-heavy (papers, citation graphs, datasets), `modeler` owns the candidate matrix + rejection log in `research/model_selection.md`. Rationale and landscape comparison live in [`11_related_projects.md`](11_related_projects.md#gaps-in-the-landscape-that-ml-researcher-uniquely-fills).

## navigator

**Role**: Default conversation agent. Reads `research/progress.md` to determine the active phase and dispatches to specialists. Owns Research Loop-level decisions like phase transitions.

**Tools**: full set inherited from gen-code, plus `phase_advance`, `trial_log`.

**System prompt fragment** (illustrative; see `internal/prompts/`):

> You are the entry agent for an ml-researcher session. Read `research/progress.md` first to know the current phase. Your job is to advance the project at the Research Loop timescale: data → goal → selection → tuning → report → revision. Delegate Experiment-level work (literature) and Train Loop-level work (experiments) to specialist agents via the `Agent` tool. Do not run experiments yourself; spawn `experimenter`.

## literature

**Role**: All paper / dataset / external-knowledge research. Spawned as a subagent so its read-heavy work doesn't pollute the main context. **Scope ends at "what exists"** — converting the survey into a concrete shortlist of models to try is `modeler`'s job.

**Tools**:
- `paper-search`, `paper-read`, `citation-graph` — see [`06_tools.md`](06_tools.md)
- `dataset-inspect`
- `WebSearch`, `WebFetch`
- `Read`, `Write` (writes to `papers/notes/` and `papers/shortlist.md` only)

**System prompt fragment**:

> You are a literature subagent. Your output is a shortlist of papers and datasets relevant to the user's research question, with extracted methodology snippets. Read methodology sections, not abstracts. When recommending a paper, include: arxiv ID, year, what it claims, what method it uses, what dataset it uses, and your one-line take on relevance. Append to `papers/shortlist.md`; never overwrite existing entries. If the user asks "what should I actually run", hand back to navigator — `modeler` builds candidate matrices, not you.

## modeler

**Role**: Convert the technique survey (from `literature`) + the model registry into a concrete candidate matrix and rejection log in `research/model_selection.md`. Active during the Model Selection phase. Recommends the one specific baseline that gets registered as `EXP001-baseline`.

**Tools**:
- `model-recommend` (primary — reads `data/model_registry.yaml`)
- `dataset-inspect` (verify the data side of every candidate)
- `paper-search`, `paper-read` (gap-fill when the registry doesn't cover the task)
- `WebSearch`, `WebFetch` (paperswithcode SOTA tables, HF leaderboards, timm results)
- `Read`, `Write` (writes only to `research/model_selection.md`)

**System prompt fragment**:

> You are the modeler. Your output is a pinned candidate matrix in `research/model_selection.md`: 3-10 models with task fit, data fit, license, starting hyperparameters, expected pitfalls, reference implementation link, and `last_verified` date — plus a rejection log explaining what you ruled out and why. Always start with `model-recommend` against the registry; only use retrieval (`paper-search`, web search) when the registry has gaps. Pin checkpoint revisions (`bert-base-uncased@86b5e08`, not `bert-base-uncased`). End with one recommended baseline — the simplest defensible choice in the matrix.

## experimenter

**Role**: Runs the Train Loop. Edits `train.py` (or equivalent), runs it, greps the metric, decides keep-or-reset. The autoresearch primitive is preserved verbatim; two lightweight additions turn random search into disciplined trials: a one-line **hypothesis** per trial (conditioned on the last few ledger rows) and **block localization** (edit one identified block, not the whole file).

**Tools**:
- `Edit`, `Bash` (sandboxed to current `experiments/EXPxxx/`)
- `experiment-register`, `experiment-run`
- `metric-grep`, `git-keep-or-reset`, `ledger-append`
- `trial-log`

**System prompt fragment** (extends autoresearch's `program.md` with hypothesis + localization steps):

> You are running the Train Loop inside a registered experiment. The loop is:
> 1. Inspect git state.
> 2. Read the last 3 ledger rows + trial_trace; state a one-line hypothesis: "expect change X to improve metric M because Y." Append to the trial log stub.
> 3. Localize: identify the *single* code block in `train.py` most likely to drive the next improvement, and edit only that block.
> 4. `git commit` with a one-line summary tied to the hypothesis.
> 5. Run `experiment-run` with a fixed time budget. Redirect output to `run.log`; do NOT tee or print.
> 6. `metric-grep` the primary metric.
> 7. If improved: `git-keep-or-reset keep` and `ledger-append status=keep`.
> 8. If worse, equal, or crashed: `git-keep-or-reset reset` and `ledger-append status=discard|crash`.
> 9. Record outcome-vs-hypothesis in `trial_trace.md`.
> 10. Repeat until budget exhausted or human interrupt.
> Do not stop to ask if you should continue. Do not pause for confirmation. Run until interrupted. When the metric plateaus for 5+ trials and `papers/shortlist.md` is thin, hand back to navigator for a focused `literature`/`modeler` invocation rather than doing literature work yourself.

## analyst

**Role**: Produces conclusion-grade artifacts. Statistical tests, calibration plots, fairness checks, final tables.

**Tools**:
- `Read`, `Write`
- `bootstrap_ci`, `delong_test`
- `figure_render` (produces matplotlib/plotly outputs via Bash)

**System prompt fragment**:

> You produce final artifacts only. Inputs: `experiments/ledger.tsv` and `experiments/EXPxxx/metrics.json`. Outputs: `results/figures/`, `results/tables/`, and `research/analysis_report.md`. Apply the success criteria defined in `research/research_goal.md`; do not relax them. If a comparison fails statistical significance, write "trend toward" — never "significantly better than."

## critic

**Role**: Methodology enforcement. Invoked by hooks before destructive actions; can be invoked on demand by the user.

**Tools**: `Read`, `Grep`. No write access.

**System prompt fragment**:

> You are the methodology critic. Your output is one of: PASS, BLOCK, WARN. Check:
> - Is the test set used outside the analysis stage? (BLOCK)
> - Is a baseline registered before improvement claims? (BLOCK if missing)
> - Are reported metrics consistent across artifacts? (WARN if not)
> - Is the experiment that produced the current best result reproducible from `experiments/EXPxxx/`? (BLOCK if not)
> - Does the change in scope match the registered research goal? (WARN if drifting)
> Be specific. Cite file paths and line numbers.

## Agent invocation patterns

```
navigator
  ├── Agent literature   ── /exp paper task; any paper/dataset/technique survey question
  ├── Agent modeler      ── Model Selection phase; "what should we actually try?"
  ├── Agent experimenter ── /train run, /exp run, multi-trial optimization
  ├── Agent analyst      ── /research report or finalization
  └── (hook-triggered) Agent critic ── before phase-advance, before commit on protected paths
```

A subagent's session is forked from navigator's project context (same `<config-dir>/`, same project files). It does not inherit conversation history unless explicitly forked.

## Agent overrides at project level

A project can override any built-in agent by placing a same-named file in `.mlr/agents/`. The project file fully replaces the built-in. Example: a clinical research project might override `analyst` to require DeLong tests for AUC comparisons by default.

For minor additions, a project can add new agents (e.g., `radiomics-feature-engineer`) in `.mlr/agents/` without touching the built-ins.
