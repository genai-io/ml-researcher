# Template: Progress

Project state. Updated whenever something material changes.

## Format

```markdown
- Current phase: <Data Understanding | Research Goal | Model Selection | Fine Tuning | Analysis Report>
- Current best: <exp_id> — <metric=value>
- Last action: <what just happened>
- Last updated: <date>

## Next

<one paragraph: what's the next concrete step>

## Blockers

<list of open blockers, or "None">

## Recent decisions

- <decision>
- <decision>

## Resume notes

(if the session ended without full progress.md update)
- Last action:
- Files changed:
- Results generated:
- Not yet reviewed:
- Next command:
```

## Update triggers

Update this file when:

- A phase completes or transitions
- The current best experiment changes
- A new blocker appears or is resolved
- The main conclusion changes
- A goal revision happens
- The session ends (write Resume notes if you can't fully update)

This file is the single source of truth for project state — the agent reads it on demand whenever phase, current best, or next step is needed. Keep it accurate.
