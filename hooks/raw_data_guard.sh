#!/usr/bin/env bash
# Block Write/Edit on data/raw/** only.
#
# We can't rely on settings.json's `if` field — Claude Code does not
# honor it (only gen-code does). So the script self-checks the file path
# from the hook stdin JSON.
#
# Hook input format: {"tool_name": "Write", "tool_input": {"file_path": "...", ...}}
set -uo pipefail

INPUT=$(cat)

FILE_PATH=$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", ""))
except Exception:
    pass
' 2>/dev/null)

# Allow if the target isn't under data/raw/
case "$FILE_PATH" in
  *data/raw/*|data/raw/*|*/data/raw/*)
    {
      echo "data/raw/ is immutable. Raw data must not be modified after init."
      echo "Write to data/derived/ for cleaned/processed datasets, and"
      echo "document the transformation in research/data_understanding.md."
    } >&2
    exit 2
    ;;
  *)
    exit 0
    ;;
esac
