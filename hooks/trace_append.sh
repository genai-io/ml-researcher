#!/usr/bin/env bash
# Auto-append a stub trial_trace entry after exp-run completes.
# Async hook — best-effort; fail silently rather than block.
set -uo pipefail

# Read hook JSON; if the tool call failed, skip.
HOOK_JSON=$(cat || echo "{}")
TOOL_RESULT=$(echo "$HOOK_JSON" | jq -r '.toolResult // empty' 2>/dev/null || echo "")
[ -z "$TOOL_RESULT" ] && exit 0

BRANCH=$(git branch --show-current 2>/dev/null || echo "")
case "$BRANCH" in
  mlr/exp/EXP*_*) EXP_ID="${BRANCH#mlr/exp/}" ;;
  *) exit 0 ;;
esac

DATE=$(date +%Y-%m-%d)
TRACE="research/trial_trace.md"
[ -f "$TRACE" ] || echo "# Iteration Trace" > "$TRACE"

# Append a stub for the agent to fill in. We don't try to parse the metric
# from the tool result — that's the agent's job.
cat >> "$TRACE" <<EOF

## $EXP_ID — $DATE [STUB — fill in]

- **Motivation**:
- **Change from parent**:
- **Data version**:
- **Key parameters**:
- **Results**:
- **Decision**:
- **Reason**:
- **Next step**:
EOF

exit 0
