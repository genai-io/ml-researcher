#!/usr/bin/env bash
# Block any Write/Edit on data/raw/**.
# Block convention: stderr message + exit 2.
set -euo pipefail
cat > /dev/null  # consume hook stdin
echo "data/raw/ is immutable. Raw data must not be modified after init." >&2
echo "Write to data/derived/ for cleaned/processed datasets, and document" >&2
echo "the transformation in research/data_understanding.md." >&2
exit 2
