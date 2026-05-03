#!/usr/bin/env bash
# Inject the current project state into the agent's context as additionalContext.
# Read by Claude Code (and equivalents) on UserPromptSubmit.
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

# Output JSON for the runtime to merge as additionalContext.
cat <<EOF
{"hookSpecificOutput": {"additionalContext": "<mlr-state>\n  <phase>${PHASE}</phase>\n  <current-best>${BEST}</current-best>\n  <next-step>${NEXT}</next-step>\n</mlr-state>"}}
EOF
