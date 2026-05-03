#!/usr/bin/env bash
# Block any Write/Edit on data/raw/**.
# Input: hook receives JSON on stdin with the tool call details.
# Output: exit 0 → allow; exit 2 → block with stopReason.
set -euo pipefail

cat > /dev/null  # consume stdin

cat <<'EOF' >&2
{"continue": false, "stopReason": "data/raw/ is immutable. Raw data must not be modified after init. Write to data/derived/ for cleaned/processed datasets, and document the transformation in research/data_understanding.md."}
EOF
exit 2
