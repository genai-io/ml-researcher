# Template: Iteration Trace

Append-only audit log of every meaningful experiment in the project.

Each entry is added by the `iteration-log` skill (or manually) after an experiment is run and a decision is made.

## Format

```markdown
## EXP<id>_<name> — <date>

- **Motivation**: <why this experiment was run, in one sentence>
- **Change from parent (`<parent_exp>`)**: <one or two sentences describing the diff>
- **Data version**: <hash or path of the dataset version used>
- **Key parameters**: <model, lr, batch, optimizer, seed, ...>
- **Results**:
  - <split>_<metric>: <value> (CI: <low>, <high>)
  - secondary: <key-value pairs>
- **Decision**: <accept | reject | needs-more-runs>
- **Reason**: <one sentence>
- **Next step**: <what's the next experiment OR "stop this direction">
```

## Conventions

- Newest entry at top, oldest at bottom.
- "Meaningful" experiment = registered + run + decided. Crashes-only without a decision are skipped.
- Be honest about negative results. "Tried X; AUC dropped 0.05; stop this direction" is more valuable than silence.
- Cite the experiment ID anywhere this entry is referenced — this file is the audit source.
