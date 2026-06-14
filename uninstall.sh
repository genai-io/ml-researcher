#!/usr/bin/env bash
# ml-researcher — remove the San persona and the files it installed.
#
# Local:   ./uninstall.sh [--user] [--dir <path>]
# Remote:  curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/uninstall.sh | bash
#          curl -fsSL .../uninstall.sh | bash -s -- --user
#
# Removes the persona directory and the agents/commands/hooks files this persona
# owns (by exact name, so other personas are untouched), and drops the persona
# selection only if it currently points at ml-researcher. It does NOT delete a
# scaffolded research project (research/ experiments/ data/) — that is your work.
set -euo pipefail

PERSONA="ml-researcher"
AGENTS="analyst critic experimenter literature modeler navigator"
COMMANDS="audit exp preflight research sandbox train"
HOOKS="checks phase_gate preflight raw_data_guard sandbox_mode_banner stop_resume_check test_set_guard trace_append"

usage() {
  cat <<EOF
Usage: uninstall.sh [--user] [--dir <path>]
  --user        uninstall from ~/.san (user scope)
  --dir <path>  uninstall from <path>/.san
  (default: current project, ./.san)
EOF
}

SCOPE="project"
BASE="$PWD"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)    SCOPE="user"; shift ;;
    --dir)     BASE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)         echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ "$SCOPE" = "user" ]; then
  CONFDIR="$HOME/.san"
else
  CONFDIR="$BASE/.san"
fi

DEST="$CONFDIR/personas/$PERSONA"
if [ -d "$DEST" ]; then
  rm -rf "$DEST"
  echo "→ removed $DEST"
else
  echo "→ no persona dir at $DEST (already gone)"
fi

for a in $AGENTS;   do rm -f "$CONFDIR/agents/$a.md"; done
for c in $COMMANDS; do rm -f "$CONFDIR/commands/$c.md"; done
for h in $HOOKS;    do rm -f "$CONFDIR/hooks/$h.sh"; done
echo "→ removed ml-researcher agents / commands / hook scripts"

# Drop the selection only if it still points at this persona.
SETTINGS="$CONFDIR/settings.json"
if [ -f "$SETTINGS" ] && command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" "$PERSONA" <<'PY'
import json, sys
path, persona = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(0)
if data.get("persona") == persona:
    data.pop("persona", None)
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("→ dropped \"persona\" selection from " + path)
else:
    print("→ left \"persona\" selection unchanged (not pointing at " + persona + ")")
PY
fi

echo "note: the merged \"hooks\" block in $SETTINGS (if present) was left in place;"
echo "      remove it by hand if no other persona relies on those hook scripts."
cat <<EOF

✓ ml-researcher uninstalled ($SCOPE scope)
EOF
