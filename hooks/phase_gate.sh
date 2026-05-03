#!/usr/bin/env bash
# Phase advancement gate. Runs lightweight checks; relies on the
# phase-advance skill for the full verification logic.
set -euo pipefail

cat > /dev/null

if [ ! -f research/progress.md ]; then
  cat <<EOF >&2
{"continue": false, "stopReason": "research/progress.md is missing. Cannot advance a phase that isn't recorded."}
EOF
  exit 2
fi

# This hook is a safety net. The phase-advance skill is responsible for the
# full requirements check; this hook just guards against the most obvious
# misuse (advancing without a progress.md).
exit 0
