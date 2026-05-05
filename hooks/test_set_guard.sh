#!/usr/bin/env bash
# Block reads of data/splits/test/** during phases ∈ {Model Selection, Fine Tuning}.
# In Analysis Report phase, allow.
set -euo pipefail
cat > /dev/null

PHASE=""
if [ -f research/progress.md ]; then
  PHASE=$(grep -i '^[*-]\s*\(current\s*\)\?phase\s*:' research/progress.md \
    | head -n1 | sed -E 's|.*phase\s*:\s*||I' | tr -d '`*' | xargs || true)
fi

case "$PHASE" in
  "Model Selection"|"Fine Tuning")
    {
      echo "Test set is locked during \"$PHASE\" phase."
      echo "Reading data/splits/test/** is blocked to prevent leakage."
      echo "Use data/splits/val/ for selection and tuning."
      echo "The test set unlocks in the Analysis Report phase."
    } >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
