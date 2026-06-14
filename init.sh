#!/usr/bin/env bash
# ml-researcher — DEPRECATED bootstrapper.
#
# ml-researcher is now a San persona. `init.sh` is a thin shim kept so existing
# one-liners keep working; it forwards to `install.sh`, which installs the
# persona AND scaffolds the project.
#
#   OLD:  init.sh "<topic>" [--runtime claude|gen|codex] [--in-place] [--ref <ref>]
#   NEW:  install.sh "<topic>" [--user] [--dir <path>] [--no-scaffold]
#
# Migration notes:
#   --runtime claude|gen|codex   no longer applies — San is the runtime. (warned, ignored)
#   --in-place                   now the default (install.sh scaffolds in the current dir).
#   --ref <ref>                  forwarded via ML_RESEARCHER_REF.
set -euo pipefail

echo "⚠ init.sh is deprecated — ml-researcher is now a San persona. Forwarding to install.sh." >&2

TOPIC=""
PASS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime)  echo "  note: --runtime '$2' ignored (San is the runtime now)." >&2; shift 2 ;;
    --in-place) shift ;;                       # default behavior now
    --ref)      export ML_RESEARCHER_REF="$2"; shift 2 ;;
    --local)    PASS+=(--dir "."); shift 2 ;;  # best-effort map
    -h|--help)  echo 'usage: init.sh "<topic>"   (deprecated; use install.sh)'; exit 0 ;;
    -*)         echo "  note: flag '$1' ignored by the shim." >&2; shift ;;
    *)          TOPIC="$1"; shift ;;
  esac
done

HERE=""
if [ -n "${BASH_SOURCE:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$HERE" ] && [ -f "$HERE/install.sh" ]; then
  exec bash "$HERE/install.sh" ${TOPIC:+"$TOPIC"} "${PASS[@]}"
else
  # curl | bash path: fetch install.sh from the same repo/ref.
  REPO_RAW="${ML_RESEARCHER_RAW:-https://raw.githubusercontent.com/genai-io/ml-researcher/${ML_RESEARCHER_REF:-main}}"
  curl -fsSL "$REPO_RAW/install.sh" | bash -s -- ${TOPIC:+"$TOPIC"} "${PASS[@]}"
fi
