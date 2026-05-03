#!/usr/bin/env bash
# Run the pre-flight checklist before exp-run.
# Currently a soft check: emits warnings for missing items but does not block.
# A future stricter version would exit 2 on hard violations.
set -euo pipefail

cat > /dev/null

WARN=0

# 1. Baseline exists if the current branch isn't itself a baseline
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [[ "$BRANCH" =~ ^mlr/exp/EXP[0-9]+_ ]] && [[ ! "$BRANCH" =~ baseline ]]; then
  if [ -f experiments/ledger.tsv ]; then
    if ! grep -i baseline experiments/ledger.tsv | grep -q $'\tkeep\t' 2>/dev/null; then
      echo "WARN: No baseline experiment with status=keep found in experiments/ledger.tsv. Improvement claims need a baseline." >&2
      WARN=$((WARN+1))
    fi
  fi
fi

# 2. progress.md exists
if [ ! -f research/progress.md ]; then
  echo "WARN: research/progress.md is missing. The agent should know the current phase before running experiments." >&2
  WARN=$((WARN+1))
fi

# 3. test set protection — heuristic check that no test references appear in the experiment's planned files
EXP_DIR=$(echo "$BRANCH" | sed 's|^mlr/exp/||')
if [ -n "$EXP_DIR" ] && [ -d "experiments/$EXP_DIR" ]; then
  if grep -rn "data/splits/test" "experiments/$EXP_DIR" 2>/dev/null; then
    echo "WARN: experiments/$EXP_DIR references data/splits/test/. Selection/Tuning phases must not read test data." >&2
    WARN=$((WARN+1))
  fi
fi

if [ "$WARN" -gt 0 ]; then
  echo "" >&2
  echo "Pre-flight checklist: $WARN warning(s). Review before continuing." >&2
fi

exit 0
