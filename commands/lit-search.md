---
description: Spawn the literature subagent to search papers, traverse citation graphs, inspect candidate datasets, and append to papers/shortlist.md.
---

Delegate literature triage to the `literature` subagent.

Argument parsing:
- `$ARGUMENTS` should be a search query in natural language.
- Optional `--year-min <yyyy>` — limit to recent work.
- Optional `--limit <n>` — max papers to shortlist (default 5).

Steps:

1. Read `research/research_goal.md` to remind the subagent of the project's data regime, task, and constraints. Provide this context in the spawn prompt.

2. Spawn the `literature` subagent with:
   - Query: $ARGUMENTS
   - Constraints: from research_goal
   - Output destination: `papers/shortlist.md` (append) and `papers/notes/<id>.md` (one per paper)
   - Limit: `--limit` or 5

3. When the subagent returns, read its summary and the new entries in `papers/shortlist.md`.

4. Surface the top 3 candidates to the user with one-line relevance for each, plus the subagent's overall recommendation.

$ARGUMENTS
