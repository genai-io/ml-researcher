---
description: Manage sandbox mode — a sandboxed dev mode where mock metrics / subset data / fake predictions are allowed but cannot be promoted to results/. Subcommands: on, off, status.
---

Manage sandbox mode.

Argument parsing: `$ARGUMENTS` is `on`, `off`, or `status` (default).

# Subcommand: on

1. Touch `.mlr-sandbox-mode` at project root.
2. Print:

```
✓ Sandbox mode ENABLED.

You may now: subset data, mock metrics, fake predictions, skip real training.
You MUST: prefix ledger rows with [SANDBOX], add .sandbox marker to experiments/<id>/,
          set "sandbox_mode": true in metrics.json.
You CANNOT: promote artifacts to results/, run /research report final, cite sandbox rows in
            research/analysis_report.md.

Disable when ready: /sandbox off
```

3. Read the `sandbox-mode` skill for the full rules and recommend the user do the same.

# Subcommand: off

1. Verify no sandbox-mode rows are stranded in places they shouldn't be:
   - Search `research/analysis_report.md` for `[SANDBOX]` references → if any, warn the user to clean up before disabling.
2. Remove `.mlr-sandbox-mode`.
3. Print:

```
✓ Sandbox mode DISABLED.

Reminder: any [SANDBOX] rows in experiments/ledger.tsv remain and will be
flagged by /audit. Re-register real experiments via /exp new for any
direction you want to take seriously.
```

# Subcommand: status (default)

1. Check whether `.mlr-sandbox-mode` exists.
2. Count `[SANDBOX]` rows in `experiments/ledger.tsv` if it exists.
3. Print:

```
Sandbox mode: ON | OFF
[SANDBOX] rows in ledger: <n>
```

If mode is ON, also remind: see `skills/sandbox-mode/SKILL.md` for full rules.

$ARGUMENTS
