---
description: Drive the Research Loop. Subcommands: phase [advance], report draft|final.
---

Parse `$ARGUMENTS` as `<subcommand> [args...]`. If no subcommand, print usage.

# Usage

```
/research phase                        show current phase + advance requirements
/research phase advance                attempt the transition to the next phase
/research report draft                 create the analysis report from current state
/research report final                 promote artifacts to results/
```

---

# Subcommand: phase

## Show (default — `/research phase`)

1. Read `research/progress.md` to find the active phase.
2. Look up gate requirements (see `respec/respec.md` § Stage transitions).
3. For each requirement, verify whether it's met (file exists & non-empty, required sections present, experiment registered, etc.).
4. Report:

```
Current phase: <phase>
Updated:       <date from progress.md>

Required to advance to <next>:
  ✓ <requirement>
  ✗ <requirement>  ← BLOCKS

Progress notes:
  <next-step from progress.md>

Blockers:
  <blockers from progress.md, or "None">
```

If no blockers, tell the user: `/research phase advance`.

## advance (`/research phase advance`)

After running the show steps, attempt the transition:

1. Spawn the `critic` subagent for an audit.
2. If critic returns PASS or WARN: update `research/progress.md` to set phase to `<next>` and append a phase-transition entry.
3. If critic returns BLOCK: surface the issues; do NOT advance.

---

# Subcommand: report

Produce the analysis report.

## draft (`/research report draft`)

1. Verify the current phase is `Analysis Report`. If not, ask the user to `/research phase advance` first (or confirm they want to draft early).

2. Spawn the `analyst` subagent with:
   - Inputs: `research/research_goal.md`, `research/progress.md`, `experiments/ledger.tsv`, all `experiments/EXPxxx_*/metrics.json`
   - Template: `respec/05_analysis_report.md`
   - Output: `research/analysis_report.md`
   - Required sections: Data summary, Goal achievement, Model comparison, Statistical tests, Limits, Conclusion
   - Reporting language discipline: per `CLAUDE.md` / `GEN.md`

3. After the analyst returns, automatically spawn `critic` with `scope=report` for an audit. Surface findings.

4. If critic is PASS or WARN, the draft stands; if BLOCK, the analyst should iterate.

## final (`/research report final`)

1. Verify `research/analysis_report.md` exists and was last critic'd as PASS.

2. Promote selected artifacts:
   - Copy figures from cited experiments into `results/figures/`.
   - Copy tables into `results/tables/`.
   - Write `results/reports/final.md` (a short reader-facing version of analysis_report).

3. Update `results/README.md` with the finalized summary (best model, headline metric, link to `research/analysis_report.md`). Do **not** edit root `README.md` — it is project description, not a state mirror; current-best numbers live only in `research/progress.md` and `experiments/ledger.tsv`.

4. Spawn `critic` with `scope=current-best` for a final consistency check.

5. If PASS, mark `research/progress.md` with status `Finalized` and note the final analysis_report path.

$ARGUMENTS
