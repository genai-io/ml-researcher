#!/usr/bin/env bash
# Block reads of data/splits/test/** during phases ∈ {Model Selection, Fine Tuning}.
# In Analysis Report phase, allow.
# Input: hook JSON on stdin (we don't need it for this check).
# Output: exit 0 → allow; exit 2 → block.
set -euo pipefail

cat > /dev/null

PHASE=""
if [ -f research/progress.md ]; then
  PHASE=$(grep -i '^[*-]\s*\(current\s*\)\?phase\s*:' research/progress.md \
    | head -n1 | sed -E 's|.*phase\s*:\s*||I' | tr -d '`*' | xargs || true)
fi

case "$PHASE" in
  "Model Selection"|"Fine Tuning")
    cat <<EOF >&2
{"continue": false, "stopReason": "Test set is locked during \"$PHASE\" phase. Reading data/splits/test/** is blocked to prevent leakage. Use data/splits/val/ for selection and tuning. The test set unlocks in the Analysis Report phase."}
EOF
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
