#!/usr/bin/env bash
# Inject the current project state into the agent's context as additionalContext.
# Read by the runtime on UserPromptSubmit.
set -uo pipefail

cat > /dev/null

if [ ! -f research/progress.md ]; then
  exit 0
fi

PHASE=$(grep -i '^[*-]\s*\(current\s*\)\?phase\s*:' research/progress.md \
  | head -n1 | sed -E 's|.*phase\s*:\s*||I' | tr -d '`*' | xargs || echo "Unknown")

BEST=$(grep -i '^[*-]\s*\(current\s*\)\?best\s*:' research/progress.md \
  | head -n1 | sed -E 's|.*best\s*:\s*||I' | tr -d '`*' | xargs || echo "—")

NEXT=$(grep -A1 -i '^##\s*Next' research/progress.md \
  | tail -n1 | sed 's|^[*-]\s*||' | xargs || echo "—")

# JSON output for the runtime to merge as additionalContext.
# Fields: hookEventName (required by Claude Code) + additionalContext.
# Use python for safe JSON encoding (handles quotes / newlines in values).
python3 - <<PY
import json
phase = """${PHASE}"""
best = """${BEST}"""
nxt = """${NEXT}"""
ctx = (
    f"<mlr-state>\n"
    f"  <phase>{phase}</phase>\n"
    f"  <current-best>{best}</current-best>\n"
    f"  <next-step>{nxt}</next-step>\n"
    f"</mlr-state>"
)
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": ctx,
    }
}))
PY
