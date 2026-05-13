# Papers — {{TOPIC}}

Literature shortlist and per-paper reading notes.

## Layout

| File | Purpose |
|---|---|
| `shortlist.md` | One-line summaries of papers under active consideration |
| `notes/<id>.md` | Per-paper reading notes (one file per arxiv ID) |

The `literature` subagent populates these via `/exp paper search` and related commands.

## Conventions

- Append, never overwrite `shortlist.md`. Move rejected papers to a "Rejected" section instead of deleting.
- Per-paper notes hold methodology details (equations, setup, hyperparameters, ablations) — copy verbatim from the paper, do not paraphrase.
- Cite arxiv IDs (e.g., `2502.13138`) consistently.
