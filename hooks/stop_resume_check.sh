#!/usr/bin/env bash
# At session stop, remind the user (via stderr) if research/progress.md
# hasn't been updated recently.
#
# Stop hooks have a narrow JSON contract: `decision: "block"` + `reason`
# would force the agent to keep going. We don't want that — we want a
# soft, user-facing nudge. So we print to stderr (visible in the terminal,
# not injected into LLM context) and exit 0 to allow the stop.
set -uo pipefail

cat > /dev/null  # consume hook stdin

if [ ! -f research/progress.md ]; then
  exit 0
fi

# Was progress.md modified in the last hour?
NOW=$(date +%s)
if stat -f %m research/progress.md >/dev/null 2>&1; then
  MTIME=$(stat -f %m research/progress.md)  # macOS / BSD
else
  MTIME=$(stat -c %Y research/progress.md)  # GNU
fi
DIFF=$((NOW - MTIME))

if [ "$DIFF" -gt 3600 ]; then
  {
    echo ""
    echo "ℹ research/progress.md has not been updated in this session."
    echo "  Consider updating it with: current phase, what was done,"
    echo "  what's next, and any blockers. This preserves resume context."
  } >&2
fi

exit 0
