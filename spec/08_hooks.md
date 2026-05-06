# 08 — Hooks

Hooks are gen-code's event-driven extensibility mechanism. ml-researcher ships a default hook set that enforces methodology guardrails. Projects may add or override hooks via `.mlr/settings.json`.

## Hook events used

| Event | Purpose |
|---|---|
| `SessionStart` | Read `progress.md`; warn if stale (> 7 days untouched) |
| `UserPromptSubmit` | Surface the expect-mode banner when `.mlr-expect-mode` exists (otherwise no-op — phase/best/next-step live in `progress.md` and are read on demand) |
| `PreToolUse` | Methodology guardrails: protect raw data, locked test set, baseline requirement |
| `PostToolUse` | Audit trail: append to `iteration_trace.md` after experiments |
| `Stop` | Stop-and-resume rule: ensure `progress.md` is updated; prompt if not |

## Default hook set

Embedded into the binary as `internal/hooks/defaults.json` and merged into the project's `.mlr/settings.json` at load time (project-defined hooks take precedence).

### 1. Protect raw data

```json
{
  "PreToolUse": [{
    "matcher": "Write|Edit",
    "if": "Write(data/raw/**) || Edit(data/raw/**)",
    "hooks": [{
      "type": "command",
      "command": "echo '{\"continue\": false, \"stopReason\": \"data/raw/ is immutable. Write to data/derived/ instead.\"}' && exit 2"
    }]
  }]
}
```

### 2. Lock the test set during selection and tuning

```json
{
  "PreToolUse": [{
    "matcher": "Read|Bash",
    "if": "any(data/splits/test/**)",
    "hooks": [{
      "type": "command",
      "command": "mlr-hook test-set-guard"
    }]
  }]
}
```

`mlr-hook test-set-guard` reads `research/progress.md` to determine the active phase. If the phase is `Model Selection` or `Fine Tuning`, the hook returns `{"continue": false, "stopReason": "Test set is locked during this phase. Use validation split for model selection."}`.

### 3. Pre-flight before experiment_run

```json
{
  "PreToolUse": [{
    "matcher": "experiment_run",
    "hooks": [{
      "type": "command",
      "command": "mlr-hook preflight",
      "statusMessage": "Running pre-flight checklist..."
    }]
  }]
}
```

`mlr-hook preflight` runs `checklist_verify --kind pre_experiment` and blocks if any check fails.

### 4. Auto-append iteration_trace after experiment_run

```json
{
  "PostToolUse": [{
    "matcher": "experiment_run",
    "hooks": [{
      "type": "command",
      "command": "mlr-hook trace-append",
      "async": true
    }]
  }]
}
```

`mlr-hook trace-append` reads the just-completed experiment's metrics, appends a structured entry to `research/iteration_trace.md`, and is non-blocking.

### 5. Phase advance gate

```json
{
  "PreToolUse": [{
    "matcher": "phase_advance",
    "hooks": [{
      "type": "command",
      "command": "mlr-hook phase-gate"
    }]
  }]
}
```

`mlr-hook phase-gate` runs the per-stage requirements check (see [`04_methodology.md`](04_methodology.md)). Returns the missing-requirements list as the block reason.

### 6. Expect-mode banner

```json
{
  "UserPromptSubmit": [{
    "hooks": [{
      "type": "command",
      "command": "bash <CFG>/hooks/expect_mode_banner.sh",
      "async": false
    }]
  }]
}
```

When `.mlr-expect-mode` exists at project root, the hook injects:

```xml
<expect-mode rows="3">ACTIVE — mock/subset/fake results allowed; promotion to results/ blocked. See skills/methodology/expect-mode.md.</expect-mode>
```

`rows` counts `[EXPECT]` entries already in `experiments/ledger.tsv`. When the marker is absent, the hook exits silently — nothing is injected.

**Why narrow scope.** An earlier version of this hook also injected `<phase>`, `<current-best>`, and `<next-step>` extracted from `research/progress.md`. That was redundant: those facts live in `progress.md`, and the agent can read it whenever it actually needs them. Maintaining a parallel injected copy violates the single-source-of-truth principle and risks drift if the parsing regexes don't match the file format. The expect-mode flag is different — it's a hidden marker file that the agent would not otherwise notice, and it flips every methodology rule (mocks allowed, promotion blocked), so a banner on every prompt is justified.

### 7. Stop-and-resume reminder

```json
{
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "mlr-hook stop-resume-check"
    }]
  }]
}
```

`mlr-hook stop-resume-check` verifies that `research/progress.md` was modified during this session. If not, it injects a reminder asking the agent to update `progress.md` before stopping. (Does not block hard; this is a nudge.)

### 8. Critic review before phase_advance

```json
{
  "PreToolUse": [{
    "matcher": "phase_advance",
    "hooks": [{
      "type": "agent",
      "agent": "critic",
      "input": "Audit current phase artifacts for methodology compliance before advancing to the next phase."
    }]
  }]
}
```

Spawns the `critic` agent. If critic returns BLOCK, the phase_advance is rejected.

## Hook helper binary

`mlr-hook` is a sidecar CLI shipped with `mlr` that implements the hook scripts above. Subcommands:

```
mlr-hook test-set-guard
mlr-hook preflight
mlr-hook trace-append
mlr-hook phase-gate
mlr-hook inject-state
mlr-hook stop-resume-check
```

Source: `cmd/mlr-hook/main.go`.

## Disabling defaults

A project can disable a default hook by name in `.mlr/settings.json`:

```json
{
  "mlr": {
    "disabledHooks": ["test-set-guard"]
  }
}
```

This is intentionally noisy in the UI — disabled hooks are listed at session start so the user doesn't silently drop a guardrail.

## Adding custom hooks

Project-specific hooks go in `.mlr/settings.json` under the standard `hooks` key (gen-code semantics). Example: enforce that any change to `data/derived/` carries a corresponding entry in `research/data_understanding.md`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "if": "Write(data/derived/**) || Edit(data/derived/**)",
      "hooks": [{
        "type": "command",
        "command": "scripts/check_data_documentation.sh"
      }]
    }]
  }
}
```
