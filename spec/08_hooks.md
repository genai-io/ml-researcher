# 08 — Hooks

Hooks are gen-code's event-driven extensibility mechanism. ml-researcher ships a default hook set that enforces methodology guardrails. Projects may add or override hooks via `.mlr/settings.json`.

## Hook events used

| Event | Purpose |
|---|---|
| `SessionStart` | Read `progress.md`; warn if stale (> 7 days untouched) |
| `UserPromptSubmit` | Inject current phase + current best into context (small XML block) |
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

### 6. Inject phase context into prompts

```json
{
  "UserPromptSubmit": [{
    "hooks": [{
      "type": "command",
      "command": "mlr-hook inject-state",
      "async": false
    }]
  }]
}
```

`mlr-hook inject-state` produces a small XML block:

```xml
<mlr-state>
  <phase>Model Selection</phase>
  <current-best exp-id="EXP004" metric="val_auc" value="0.715"/>
  <next-step>Run radiomics feature extraction with bin width 25</next-step>
  <blockers>None</blockers>
</mlr-state>
```

Injected as `additionalContext` so the agent always has fresh state.

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
