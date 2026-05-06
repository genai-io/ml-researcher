---
description: Produce the analysis report. Subcommands: draft (create from current state), final (promote to results/).
---

Produce the analysis report.

Argument parsing: `$ARGUMENTS` is `draft` (default) or `final`.

# Subcommand: draft

1. Verify the current phase is `Analysis Report`. If not, ask the user to `/phase advance` first (or confirm they want to draft early).

2. Spawn the `analyst` subagent with:
   - Inputs: `research/research_goal.md`, `research/progress.md`, `experiments/ledger.tsv`, all `experiments/EXPxxx_*/metrics.json`
   - Template: `respec/05_analysis_report.md`
   - Output: `research/analysis_report.md`
   - Required sections: Data summary, Goal achievement, Model comparison, Statistical tests, Limits, Conclusion
   - Reporting language discipline: per `CLAUDE.md` / `GEN.md`

3. After the analyst returns, automatically spawn `critic` with `scope=report` for an audit. Surface findings.

4. If critic is PASS or WARN, the draft stands; if BLOCK, the analyst should iterate.

# Subcommand: final

1. Verify `research/analysis_report.md` exists and was last critic'd as PASS.

2. Promote selected artifacts:
   - Copy figures from cited experiments into `results/figures/`.
   - Copy tables into `results/tables/`.
   - Write `results/reports/final.md` (a short reader-facing version of analysis_report).

3. Update `results/README.md` with the finalized summary (best model, headline metric, link to `research/analysis_report.md`). Do **not** edit root `README.md` — it is project description, not a state mirror; current-best numbers live only in `research/progress.md` and `experiments/ledger.tsv`.

4. Spawn `critic` with `scope=current-best` for a final consistency check.

5. If PASS, mark `research/progress.md` with status `Finalized` and note the final analysis_report path.

$ARGUMENTS
