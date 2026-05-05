#!/usr/bin/env bash
# Block reads of data/splits/test/** during phases ∈ {Model Selection, Fine Tuning}.
# In Analysis Report phase, allow.
#
# Self-checks the file path from hook stdin (Claude Code does not honor
# the `if` field in settings.json).
set -uo pipefail

INPUT=$(cat)

FILE_PATH=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {})
    # Read tool uses file_path; Bash uses command (we substring-search command).
    print(ti.get("file_path", "") or ti.get("command", ""))
except Exception:
    pass
' 2>/dev/null)

# Only check paths under data/splits/test/ — anything else is irrelevant.
case "$FILE_PATH" in
  *data/splits/test/*|data/splits/test/*)
    : ;;  # falls through to phase check
  *)
    exit 0 ;;
esac

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
