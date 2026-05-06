#!/usr/bin/env bash
# Phase advancement safety net. Mechanical rules live in hooks/checks.sh;
# the deeper structural checks (per-stage required sections, ledger rows)
# are run by the phase-advance skill, which calls this same script.
set -uo pipefail
cat > /dev/null

HOOKS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! bash "$HOOKS_DIR/checks.sh" progress-present; then
  echo "Cannot advance a phase that isn't recorded." >&2
  exit 2
fi

exit 0
