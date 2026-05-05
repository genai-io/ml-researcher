---
description: Manage expect mode — a sandboxed dev mode where mock metrics / subset data / fake predictions are allowed but cannot be promoted to results/. Subcommands: on, off, status.
---

Manage expect mode.

Argument parsing: `$ARGUMENTS` is `on`, `off`, or `status` (default).

# Subcommand: on

1. Touch `.mlr-expect-mode` at project root.
2. Print:

```
✓ Expect mode ENABLED.

You may now: subset data, mock metrics, fake predictions, skip real training.
You MUST: prefix ledger rows with [EXPECT], add .expect marker to experiments/<id>/,
          set "expect_mode": true in metrics.json.
You CANNOT: promote artifacts to results/, run /report final, cite expect rows in
            research/analysis_report.md.

Disable when ready: /expect off
```

3. Read the `expect-mode` skill for the full rules and recommend the user do the same.

# Subcommand: off

1. Verify no expect-mode rows are stranded in places they shouldn't be:
   - Search `research/analysis_report.md` for `[EXPECT]` references → if any, warn the user to clean up before disabling.
2. Remove `.mlr-expect-mode`.
3. Print:

```
✓ Expect mode DISABLED.

Reminder: any [EXPECT] rows in experiments/ledger.tsv remain and will be
flagged by /audit. Re-register real experiments via /exp new for any
direction you want to take seriously.
```

# Subcommand: status (default)

1. Check whether `.mlr-expect-mode` exists.
2. Count `[EXPECT]` rows in `experiments/ledger.tsv` if it exists.
3. Print:

```
Expect mode: ON | OFF
[EXPECT] rows in ledger: <n>
```

If mode is ON, also remind: see `skills/methodology/expect-mode.md` for full rules.

$ARGUMENTS
