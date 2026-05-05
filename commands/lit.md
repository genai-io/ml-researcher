---
description: Literature triage. Subcommands: search <query>, list, read <paper-id>.
---

Parse `$ARGUMENTS` as `<subcommand> [args...]`. If no subcommand, print usage.

# Usage

```
/lit search <query> [--year-min <yyyy>] [--limit <n>]
/lit list
/lit read <paper-id>
```

---

# Subcommand: search

Delegate to the `literature` subagent.

1. Read `research/research_goal.md` for the project's data regime, task, and constraints. Pass as context to the subagent.
2. Spawn `literature` subagent with:
   - query = $ARGUMENTS rest
   - constraints from research_goal
   - output destination = `papers/shortlist.md` (append) and `papers/notes/<id>.md` (one per paper)
   - limit = `--limit` (default 5)
3. When the subagent returns, surface the top 3 candidates with one-line relevance plus the recommendation.

---

# Subcommand: list

Show the current literature shortlist.

1. Read `papers/shortlist.md`.
2. Print active entries grouped by section (Active / Rejected).
3. For each entry, show: paper ID, title, one-line relevance.

---

# Subcommand: read

Fetch and notebook a single paper.

1. Take paper ID (arxiv ID, HuggingFace papers ID, or DOI) from $ARGUMENTS.
2. Use the `paper-read` skill (or WebFetch on ar5iv) to fetch the methodology / experiments / results sections.
3. Write structured notes to `papers/notes/<paper-id>.md`.
4. Surface the key methodology (model, dataset, metric, headline claim) to the user.

$ARGUMENTS
