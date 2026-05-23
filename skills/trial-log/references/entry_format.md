# Trial-log entry format

Each entry is a section in `research/trial_trace.md`:

```markdown
## EXP<id>_<name> — <date>

- **Motivation**: <why this experiment was run, in one sentence>
- **Change from parent (`<parent_exp>`)**: <one or two sentences describing the diff>
- **Data version**: <hash or path of the dataset version used>
- **Key parameters**: <model, lr, batch, optimizer, seed, ...>
- **Results**:
  - val_<metric>: <value> (CI: <low>, <high>)
  - test_<metric>: <value> (only if Analysis phase)
  - secondary: <key-value pairs>
- **Decision**: <accept | reject | needs-more-runs>
- **Reason**: <one sentence>
- **Next step**: <what's the next experiment OR "stop this direction">
```

## Field meanings

| Field | Required | Notes |
|---|---|---|
| Motivation | yes | One sentence. Why this experiment vs no experiment. |
| Change from parent | yes | What's different vs the parent EXP id. "none" for baseline. |
| Data version | yes | Reproducibility anchor. Git hash or manifest path. |
| Key parameters | yes | Minimum: model, lr, batch, optimizer, seed. Add others as relevant. |
| Results | yes | Primary metric with CI if computed. Test metric only in Analysis phase. |
| Decision | yes | `accept` keeps the experiment in the candidate set; `reject` removes it; `needs-more-runs` defers. |
| Reason | yes | Why the decision. Negative results are valuable — say *why* a thing didn't work. |
| Next step | yes | Concrete suggestion or "stop this direction". The experimenter agent reads this to pick its next trial. |
