#!/usr/bin/env bash
# Run the pre-flight checklist before exp-run.
# Currently a soft check: emits warnings for missing items but does not block.
# A future stricter version would exit 2 on hard violations.
#
# All mechanical rules live in hooks/checks.sh — this script is just a
# sequencer that decides which checks apply for a pre-experiment context.
set -uo pipefail

cat > /dev/null

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS="$HOOKS_DIR/checks.sh"

WARN=0
warn_if_fail() {
  # Run a check; if it fails, print its stderr as "WARN: ..." and bump counter.
  local name="$1" reason
  reason=$(bash "$CHECKS" "$name" 2>&1 >/dev/null) || {
    echo "WARN: $reason" >&2
    WARN=$((WARN+1))
  }
}

# Only require a baseline when we're on a non-baseline experiment branch
# (a baseline experiment is itself the thing being registered).
BRANCH=$(git branch --show-current 2>/dev/null || echo "")
if [[ "$BRANCH" =~ ^mlr/exp/EXP[0-9]+_ ]] && [[ ! "$BRANCH" =~ baseline ]]; then
  warn_if_fail baseline-kept
fi

warn_if_fail progress-present
warn_if_fail no-test-refs-in-current-exp

if [ "$WARN" -gt 0 ]; then
  echo "" >&2
  echo "Pre-flight checklist: $WARN warning(s). Review before continuing." >&2
fi

exit 0
