---
name: trial-log
description: Append a structured entry to research/trial_trace.md with motivation, change diff, parameters, results, decision, and next step. Used after every meaningful experiment. Entry format and example in references/.
allowed-tools: Read Edit
---

# When to use

After every meaningful experiment — registered + run + decided. Crashes-only without a decision can be skipped.

# Steps

1. **Read `research/trial_trace.md`.** If absent, create with the header:

   ```markdown
   # Trial Trace

   Append-only audit log of every meaningful experiment. New entries at the top.
   Source of truth for "why was X done?".
   ```

2. **Build the entry** from required inputs:
   - `exp_id`, `name`, `date`
   - `motivation` (one sentence)
   - `change_summary` (≤ 2 sentences) and `parent_exp` (or "none" for baseline)
   - `data_version` — git hash of `data/` or manifest file path
   - `key_parameters` — at minimum: model name, lr, batch size, optimizer, random seed
   - `results` — primary metric (with CI if computed), secondary metrics
   - `decision` — `accept` / `reject` / `needs-more-runs`
   - `reason` (one sentence) and `next_step` (one sentence)

   Full entry format: `references/entry_format.md`. Worked example: `references/example.md`.

3. **Append to the top of the file** (after the header). New entries first, oldest last.

4. **Verify** by reading the first 50 lines back.

# Discipline

- **Be honest about negative results.** "Tried wavelet features; AUC dropped 0.05; stop this direction" is more valuable than silence.
- **Cite the experiment ID** in any other document that references this entry — the trial trace is the audit source.
- **Append, never edit history.** If a prior entry was wrong, add a new entry that corrects it; never delete or rewrite.

# Related

Pairs with [[ledger-append]] (machine-readable history; trial-log is the human-readable companion). The experimenter agent calls trial-log after each kept / discarded / crashed trial.
