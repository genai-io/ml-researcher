# 07 — Slash Commands

Six built-in slash commands cover the entire lifecycle. Each is a markdown file under `commands/`, copied into a project's `<config-dir>/commands/` by `init.sh`. Subcommands are dispatched via `$ARGUMENTS` parsing inside the command body.

## The six commands

| Command | Subcommands | Phase | Notes |
|---|---|---|---|
| `/research phase` | (default = show), `advance` | Research navigation | Show requirements, attempt transition |
| `/exp` | `new <name>`, `loop`, `list`, `compare` | Experiment / Train | Subcommand dispatch |
| `/exp paper` | `search <query>`, `list`, `read <id>` | Experiment: literature | Spawns literature subagent |
| `/research report` | `draft`, `final` | Research: Analysis Report | Spawns analyst + critic |
| `/preflight` | (no subcommand) | cross-layer | Pre-flight checklist |
| `/audit` | (default = current-best), scope arg | cross-layer | Spawns critic for methodology audit |

## Naming rationale

- **Verb-first or namespace-noun-first** — never both. `phase`, `report`, `check`, `audit` are verbs/nouns; `exp` and `train` are namespaces with subcommand verbs.
- **Subcommand pattern** — like `git commit` / `kubectl get` / `docker run`. `/exp` without args prints usage; `/exp new <name>` does the action.
- **No hyphenated multi-word commands** — `/exp new` is replaced by `/exp new`. Cleaner shell-style discoverability and easier to remember.
- **Subagent → command alignment is intentional** — `audit` (the verb) invokes `critic` (the agent name). The agent does the work; the command names the action.

## Per-command spec

### `/research phase`

Show the current research phase and what's needed to advance.

**Default form**: print the requirements checklist.

```
Current phase: Model Selection
Updated:       2026-04-30

Required to advance to Fine Tuning:
  ✓ research/research_goal.md filled
  ✓ research/model_selection.md has shortlist
  ✗ experiments/EXP001-baseline registered  ← BLOCKS

Blockers from progress.md: None
```

**`/research phase advance`**: spawn `critic` for a final audit, then update `research/progress.md` to the next phase if PASS.

### `/exp <subcommand>`

#### `/exp new <name> [motivation]`

Register a new experiment via `experiment-register` skill. Branch `mlr/exp/EXPxxx_<name>`, `experiments/EXPxxx_<name>/{README.md, train.py, config.yaml}`. Append `registered` row to ledger and entry to trial trace.

#### `/train run [--metric <m>] [--budget <d>] [--max-iter <n>]`

Spawn `experimenter` subagent for the Train Loop (autoresearch-style). Pre-flight runs first via `checklist-verify`. The loop edits → runs → measures → keeps-or-resets until budget is exhausted or interrupted.

#### `/exp list [--filter <status>]`

Print the ledger as a table. Mark current best.

#### `/exp compare <id1> <id2> [...]`

Bootstrap CI per experiment + DeLong (for AUC, exactly two experiments) + comparison bar chart. Reporting language follows the system prompt's discipline.

### `/exp paper <subcommand>`

#### `/exp paper search <query> [--year-min <yyyy>] [--limit <n>]`

Spawn `literature` subagent. Output → `papers/shortlist.md` (append) and `papers/notes/<id>.md`.

#### `/exp paper list`

Print `papers/shortlist.md` grouped Active / Rejected.

#### `/exp paper read <paper-id>`

Fetch a single paper, write structured notes to `papers/notes/<id>.md`.

### `/research report <subcommand>`

#### `/research report draft`

Spawn `analyst` subagent to write `research/analysis_report.md` from `experiments/ledger.tsv` + per-experiment `metrics.json`. Auto-spawns `critic` afterwards.

#### `/research report final`

Promote selected artifacts to `results/figures/`, `results/tables/`, `results/reports/final.md`. Update `results/README.md` with the finalized summary (root `README.md` is project description, not a state mirror — leave it alone). Auto-spawns `critic` for consistency check.

### `/preflight`

Run the appropriate pre-flight checklist (`pre-experiment` / `pre-phase-advance` / `pre-finalize`). Auto-detects kind from current state. Returns PASS or a structured remediation list.

### `/audit [scope]`

Spawn the `critic` subagent for an on-demand methodology audit.

Scopes:
- `current-best` (default) — current best EXPxxx + recent ledger + progress.md
- `recent` — git log of the last 24h
- `report` — analysis_report.md + referenced experiments
- `<path>` — a specific file or directory

Returns PASS / WARN / BLOCK with file:line citations. BLOCK halts the calling action.

## Custom commands

Projects can add commands in `<config-dir>/commands/<name>.md` (e.g. `.claude/commands/`). Same format as built-in: optional YAML frontmatter + markdown body. The `$ARGUMENTS` variable holds the user's input after the command name.

Example:

```markdown
---
description: Extract radiomics features from raw MRI for the GBM cohort
---

Run the radiomics feature extraction pipeline:

```bash
python scripts/rad_pipeline.py extract --image-types Original --image-set $1
```

Verify output exists in `data/derived/features/`.
```

## What we deliberately did NOT add

- `/init` slash command — bootstrapping a project is `init.sh`'s job (bash, outside the agent). Inside the agent, init is already done.
- `/state`, `/resume` — folded into `/research phase` (which reads progress.md). One command per concept.
- Bare `/critic` and `/checklist` — replaced by `/audit` and `/preflight` for consistency with the verb-first / noun-first rule.
