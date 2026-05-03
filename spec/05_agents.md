# 05 — Built-in Agents

ml-researcher ships five built-in agents. Each is defined in `internal/agents/<name>.md` (markdown with YAML frontmatter) and embedded into the binary at compile time. Projects may override or supplement them via `.mlr/agents/`.

## Roster

| Agent | Role | Active loop | Spawned by |
|---|---|---|---|
| `navigator` | Top-level dispatcher; identifies the active loop layer | L3 entry | default |
| `literature` | Paper search, citation graph, dataset discovery | L2 sub-step | navigator, `/lit *` |
| `experimenter` | Runs the L1 edit-run-measure-keep loop | L1 | navigator, `/exp loop` |
| `analyst` | Produces analysis reports, statistical comparisons, figures | L3 stage 5 | navigator, `/report` |
| `critic` | Enforces methodology guardrails | cross-layer | hooks; on demand |

## navigator

**Role**: Default conversation agent. Reads `research/progress.md` to determine the active phase and dispatches to specialists. Owns L3-level decisions like phase transitions.

**Tools**: full set inherited from gen-code, plus `phase_advance`, `iteration_log`.

**System prompt fragment** (illustrative; see `internal/prompts/`):

> You are the entry agent for an ml-researcher session. Read `research/progress.md` first to know the current phase. Your job is to advance the project at the L3 timescale: data → goal → selection → tuning → report → revision. Delegate L2 work (literature) and L1 work (experiments) to specialist agents via the `Agent` tool. Do not run experiments yourself; spawn `experimenter`.

## literature

**Role**: All paper / dataset / external-knowledge research. Spawned as a subagent so its read-heavy work doesn't pollute the main context.

**Tools**:
- `paper_search`, `paper_read`, `citation_graph` — see [`06_tools.md`](06_tools.md)
- `dataset_inspect`
- `WebSearch`, `WebFetch`
- `Read`, `Write` (writes to `papers/notes/` and `papers/shortlist.md` only)

**System prompt fragment**:

> You are a literature subagent. Your output is a shortlist of papers and datasets relevant to the user's research question, with extracted methodology snippets. Read methodology sections, not abstracts. When recommending a paper, include: arxiv ID, year, what it claims, what method it uses, what dataset it uses, and your one-line take on relevance. Append to `papers/shortlist.md`; never overwrite existing entries.

## experimenter

**Role**: Runs the L1 loop. Edits `train.py` (or equivalent), runs it, grep the metric, decides keep-or-reset.

**Tools**:
- `Edit`, `Bash` (sandboxed to current `experiments/EXPxxx/`)
- `experiment_register`, `experiment_run`
- `metric_grep`, `git_keep_or_reset`, `ledger_append`

**System prompt fragment** (drawn directly from autoresearch's `program.md`):

> You are running an L1 iteration loop for a registered experiment. The loop is:
> 1. Inspect git state.
> 2. Edit `train.py` with one experimental change.
> 3. `git commit` with a one-line summary.
> 4. Run `experiment_run` with a fixed time budget. Redirect output to `run.log`; do NOT tee or print.
> 5. `metric_grep` the primary metric.
> 6. If improved: `git_keep_or_reset keep` and `ledger_append status=keep`.
> 7. If worse, equal, or crashed: `git_keep_or_reset reset` and `ledger_append status=discard`.
> 8. Repeat until budget exhausted or human interrupt.
> Do not stop to ask if you should continue. Do not pause for confirmation. Run until interrupted.

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
  ├── Agent literature  ── for any /lit task or paper/dataset question
  ├── Agent experimenter ── for /exp loop, /exp run, multi-iteration optimization
  ├── Agent analyst      ── for /report or finalization
  └── (hook-triggered) Agent critic ── before phase_advance, before commit on protected paths
```

A subagent's session is forked from navigator's project context (same `.mlr/`, same project files). It does not inherit conversation history unless explicitly forked.

## Agent overrides at project level

A project can override any built-in agent by placing a same-named file in `.mlr/agents/`. The project file fully replaces the built-in. Example: a clinical research project might override `analyst` to require DeLong tests for AUC comparisons by default.

For minor additions, a project can add new agents (e.g., `radiomics-feature-engineer`) in `.mlr/agents/` without touching the built-ins.
