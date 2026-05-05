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

# Expect-mode flag (project root). Presence = mode active.
EXPECT_MODE="off"
EXPECT_COUNT="0"
if [ -f .mlr-expect-mode ]; then
  EXPECT_MODE="on"
  if [ -f experiments/ledger.tsv ]; then
    EXPECT_COUNT=$(grep -c '\[EXPECT\]' experiments/ledger.tsv 2>/dev/null || echo 0)
  fi
fi

# JSON output for the runtime to merge as additionalContext.
python3 - <<PY
import json
phase = """${PHASE}"""
best = """${BEST}"""
nxt = """${NEXT}"""
expect_mode = """${EXPECT_MODE}"""
expect_count = """${EXPECT_COUNT}"""

lines = ["<mlr-state>"]
lines.append(f"  <phase>{phase}</phase>")
lines.append(f"  <current-best>{best}</current-best>")
lines.append(f"  <next-step>{nxt}</next-step>")
if expect_mode == "on":
    lines.append(f'  <expect-mode rows="{expect_count}">ACTIVE — mock/subset/fake results allowed; promotion to results/ blocked. See skills/methodology/expect-mode.md.</expect-mode>')
lines.append("</mlr-state>")
ctx = "\n".join(lines)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": ctx,
    }
}))
PY
