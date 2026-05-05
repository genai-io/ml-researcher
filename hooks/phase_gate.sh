#!/usr/bin/env bash
# Phase advancement safety net. Full check is in skills/methodology/phase-advance.md.
set -euo pipefail
cat > /dev/null

if [ ! -f research/progress.md ]; then
  echo "research/progress.md is missing. Cannot advance a phase that isn't recorded." >&2
  exit 2
fi

exit 0
