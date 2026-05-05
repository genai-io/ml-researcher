---
description: Spawn the critic subagent for an on-demand methodology audit. Returns PASS, WARN, or BLOCK with file:line citations.
---

Spawn the `critic` subagent.

Argument parsing: `$ARGUMENTS` may be `current-best`, `recent`, `report`, or a specific file path. Default is `current-best`.

Steps:

1. Resolve scope:
   - `current-best` → current best EXPxxx + last 5 ledger rows + research/progress.md
   - `recent` → changes in the last 24h via git log
   - `report` → research/analysis_report.md + all referenced experiments
   - `<path>` → just the named file or directory

2. Spawn the `critic` subagent with the scope and the list of files to read.

3. Surface the critic's verdict (PASS/WARN/BLOCK) verbatim.

4. If BLOCK, do NOT proceed with whatever the user was about to do. State plainly: "Critic blocked: <issue>. Fix and rerun /audit before proceeding."

5. If WARN, note the warnings but allow the user to proceed if they choose.

$ARGUMENTS
