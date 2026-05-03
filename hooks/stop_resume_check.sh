#!/usr/bin/env bash
# At session stop, remind the agent to update progress.md if it hasn't been
# touched in this session. Soft nudge, not a block.
set -uo pipefail

cat > /dev/null

if [ ! -f research/progress.md ]; then
  exit 0
fi

# Was progress.md modified in the last hour?
NOW=$(date +%s)
if stat -f %m research/progress.md >/dev/null 2>&1; then
  MTIME=$(stat -f %m research/progress.md)  # macOS
else
  MTIME=$(stat -c %Y research/progress.md)  # GNU
fi
DIFF=$((NOW - MTIME))

if [ "$DIFF" -gt 3600 ]; then
  cat <<'EOF'
{"hookSpecificOutput": {"additionalContext": "<mlr-stop-reminder>research/progress.md has not been updated in this session. Before stopping, please update it with: current phase, what was done, what's next, and any blockers. This preserves the resume context for the next session.</mlr-stop-reminder>"}}
EOF
fi

exit 0
