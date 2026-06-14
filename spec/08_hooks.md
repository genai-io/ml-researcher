# 08 — Hooks

Hooks are San's event-driven extensibility mechanism (shell / LLM / agent / HTTP lifecycle hooks). ml-researcher ships a default hook set — bash scripts under `.san/hooks/` — that enforces methodology guardrails. Projects may add or override hooks by editing `.san/settings.json` directly.

`install.sh` copies the hook scripts to `.san/hooks/` and merges the `hooks` block from the repo's `hooks/settings.json` (substituting the `__CFG__` placeholder → `.san`) into `.san/settings.json` at install time. The `hooks` block lives in the config-dir `settings.json`, not in the persona overlay — San's settings natively support hooks; the persona overlay schema does not.

## Hook events used

| Event | Purpose |
|---|---|
| `UserPromptSubmit` | Surface the sandbox-mode banner when `.mlr-sandbox-mode` exists (otherwise no-op — phase/best/next-step live in `progress.md` and are read on demand) |
| `PreToolUse` | Methodology guardrails: protect raw data, locked test set, baseline requirement, phase-advance gate |
| `PostToolUse` | Audit trail: append trial_trace stub after experiments |
| `Stop` | Stop-and-resume nudge: stderr reminder if `progress.md` is stale |

## Default hook set

Defined in `hooks/settings.json` (this repo) and merged into `.san/settings.json` by `install.sh`. The bash scripts ship to `.san/hooks/` alongside.

### A note on `if`-based matchers

The `if` field (`"if": "Write(data/raw/**)"`) is a fast-path filter only. Each guard script self-checks the relevant path by parsing the hook stdin JSON, so correctness never depends on the matcher firing — the `if` is an optimization, not a correctness barrier.

### 1. Protect raw data

```json
{
  "PreToolUse": [{
    "matcher": "Write|Edit",
    "if": "Write(data/raw/**) || Edit(data/raw/**)",
    "hooks": [{
      "type": "command",
      "command": "bash .san/hooks/raw_data_guard.sh",
      "statusMessage": "Checking raw data immutability"
    }]
  }]
}
```

`raw_data_guard.sh` reads `tool_input.file_path` from hook stdin; if it falls under `data/raw/**`, prints a remediation message to stderr and exits 2 (block).

### 2. Lock the test set during selection and tuning

```json
{
  "PreToolUse": [{
    "matcher": "Read|Bash",
    "if": "Read(data/splits/test/**) || Bash(*data/splits/test*)",
    "hooks": [{
      "type": "command",
      "command": "bash .san/hooks/test_set_guard.sh",
      "statusMessage": "Checking test-set lock"
    }]
  }]
}
```

`test_set_guard.sh` parses the path from hook stdin (`tool_input.file_path` for `Read`, `tool_input.command` for `Bash`); if it touches `data/splits/test/**`, it reads the active phase from `research/progress.md`. During `Model Selection` or `Fine Tuning`, blocks with exit 2. During `Analysis Report` (or anywhere else), allows.

### 3. Pre-flight before exp-run

```json
{
  "PreToolUse": [{
    "matcher": "exp-run",
    "hooks": [{
      "type": "command",
      "command": "bash .san/hooks/preflight.sh",
      "statusMessage": "Running pre-flight checklist"
    }]
  }]
}
```

`preflight.sh` is currently **soft**: it emits stderr warnings for missing items but exits 0 (does not block). Mechanical rules — baseline registered, `progress.md` present, no test-split refs in the active experiment dir — are delegated to `.san/hooks/checks.sh` so the same rules drive `phase_gate.sh` and the `checklist-verify` skill. A future stricter version would exit 2 on hard violations.

### 4. Auto-append trial_trace stub after exp-run

```json
{
  "PostToolUse": [{
    "matcher": "exp-run",
    "hooks": [{
      "type": "command",
      "command": "bash .san/hooks/trace_append.sh",
      "async": true
    }]
  }]
}
```

`trace_append.sh` derives the experiment ID from the current branch (`mlr/exp/EXPxxx_*`) and appends a `[STUB — fill in]` block to `research/trial_trace.md` with empty fields (Motivation, Change from parent, Results, Decision, …). The agent fills the stub from its own knowledge of what just ran — this script doesn't try to parse metrics out of tool output. Async, best-effort, never blocks.

### 5. Phase-advance gate

```json
{
  "PreToolUse": [{
    "matcher": "phase-advance",
    "hooks": [{
      "type": "command",
      "command": "bash .san/hooks/phase_gate.sh",
      "statusMessage": "Verifying phase advancement requirements"
    }]
  }]
}
```

`phase_gate.sh` is a thin safety net: it delegates to `checks.sh progress-present` and exits 2 if `research/progress.md` is missing. The deeper per-stage requirements (required sections, ledger rows per shortlist) are checked inside the `phase-advance` skill, which also spawns the `critic` subagent for a final semantic audit (`scope=current-best`) before flipping the phase. The critic invocation is **not** a separate hook — it lives in the skill so it runs only on actual phase advance attempts, not on every `PreToolUse`.

### 6. Sandbox-mode banner

```json
{
  "UserPromptSubmit": [{
    "hooks": [{
      "type": "command",
      "command": "bash .san/hooks/sandbox_mode_banner.sh"
    }]
  }]
}
```

When `.mlr-sandbox-mode` exists at project root, `sandbox_mode_banner.sh` injects:

```xml
<sandbox-mode rows="3">ACTIVE — mock/subset/fake results allowed; promotion to results/ blocked. See skills/sandbox-mode/SKILL.md.</sandbox-mode>
```

`rows` counts `[SANDBOX]` entries already in `experiments/ledger.tsv`. When the marker is absent, the hook exits silently — nothing is injected.

**Why narrow scope.** An earlier version of this hook also injected `<phase>`, `<current-best>`, and `<next-step>` extracted from `research/progress.md`. That was redundant: those facts live in `progress.md`, and the agent can read it whenever it actually needs them. Maintaining a parallel injected copy violates the single-source-of-truth principle and risks drift if the parsing regexes don't match the file format. The sandbox-mode flag is different — it's a hidden marker file the agent would not otherwise notice, and it flips every methodology rule (mocks allowed, promotion blocked), so a banner on every prompt is justified.

### 7. Stop-and-resume reminder

```json
{
  "Stop": [{
    "hooks": [{
      "type": "command",
      "command": "bash .san/hooks/stop_resume_check.sh"
    }]
  }]
}
```

`stop_resume_check.sh` checks the mtime of `research/progress.md`; if it hasn't been touched in the last hour, prints a soft reminder (current phase, what was done, what's next, blockers) to **stderr** and exits 0. Stop hooks are terminal-visible nudges, not LLM-context messages.

## Hook scripts

The actual implementation lives in `.san/hooks/` as plain bash:

```
.san/hooks/
├── raw_data_guard.sh
├── test_set_guard.sh
├── preflight.sh
├── trace_append.sh
├── phase_gate.sh
├── sandbox_mode_banner.sh
├── stop_resume_check.sh
└── checks.sh                # shared mechanical-checks library; sourced by preflight + phase_gate, also callable from /preflight
```

(The repo ships these scripts plus `hooks/settings.json`, whose `hooks` block `install.sh` merges into `.san/settings.json`.)

`checks.sh` is invoked as `bash .san/hooks/checks.sh <check-name>` and returns 0/1/2. Supported names: `progress-present`, `baseline-kept`, `no-test-refs-in-current-exp`. Adding a new mechanical rule means adding one function + one dispatcher case there; the skill and hook callers don't need to change.

There is no Go sidecar binary. Earlier drafts of this spec described an `mlr-hook` CLI; that was never implemented and would be redundant with bash + the shared `checks.sh` library.

## Disabling or overriding defaults

To disable a default hook, remove (or comment out) its entry in `.san/settings.json` after install. To override behavior, edit the corresponding script in `.san/hooks/` directly — the project owns its `.san/` config, and `install.sh --no-scaffold` refreshes the persona without clobbering a project's research records.

(Earlier drafts of this spec described an `mlr.disabledHooks` allow-list as a declarative opt-out mechanism. It was never wired up and has been removed from the shipped `settings.json` to avoid encoding a phantom contract.)

## Adding custom hooks

Project-specific hooks go in `.san/settings.json` under the standard `hooks` key. Example: enforce that any change to `data/derived/` carries a corresponding entry in `research/data_understanding.md`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "if": "Write(data/derived/**) || Edit(data/derived/**)",
      "hooks": [{
        "type": "command",
        "command": "bash scripts/check_data_documentation.sh"
      }]
    }]
  }
}
```

Custom hooks should follow the same pattern as the defaults: self-check the relevant path from stdin (don't trust `if`), print remediation to stderr, exit 0/2 for allow/block.
