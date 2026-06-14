#!/usr/bin/env bash
# ml-researcher — install the San persona (and optionally scaffold a project).
#
# Local:   ./install.sh ["<topic>"] [--user] [--dir <path>] [--no-scaffold]
# Remote:  curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh | bash
#          curl -fsSL .../install.sh | bash -s -- "GBM tumor purity"
#          curl -fsSL .../install.sh | bash -s -- --user
#
# What it does:
#   1. Install the persona  -> <confdir>/personas/ml-researcher/ (system/ skills/ settings.json)
#   2. Install the 6 agents -> <confdir>/agents/
#   3. Install slash commands -> <confdir>/commands/   (best-effort)
#   4. Install methodology hooks -> <confdir>/hooks/ + merge the hooks block into <confdir>/settings.json
#   5. Enable the persona   -> "persona": "ml-researcher" in <confdir>/settings.json
#   6. If a <topic> is given (project/--dir scope): scaffold the research project
#      skeleton (template/ + data/ + scripts/) into the project root and git-init it.
#
# Default scope is the current project (<cwd>/.san). --user installs to ~/.san;
# --dir <path> targets <path>/.san.
set -euo pipefail

PERSONA="ml-researcher"
REPO_URL="${ML_RESEARCHER_REPO:-https://github.com/genai-io/ml-researcher.git}"
REF="${ML_RESEARCHER_REF:-main}"

usage() {
  cat <<EOF
Usage: install.sh ["<topic>"] [--user] [--dir <path>] [--no-scaffold]
  <topic>         scaffold a research project for this topic (project/--dir scope only)
  --user          install into ~/.san (user scope; no project scaffold)
  --dir <path>    install into <path>/.san and scaffold there
  --no-scaffold   install the persona only, never scaffold (even with a topic)
  -h, --help      show this help
  (default: current project, ./.san)
EOF
}

SCOPE="project"
BASE="$PWD"
TOPIC=""
NO_SCAFFOLD=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)        SCOPE="user"; shift ;;
    --dir)         SCOPE="dir"; BASE="$2"; shift 2 ;;
    --no-scaffold) NO_SCAFFOLD=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    -*)            echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
    *)             TOPIC="$1"; shift ;;
  esac
done

if [ "$SCOPE" = "user" ]; then
  CONFDIR="$HOME/.san"
  PROJECT_ROOT=""    # no project scaffold at user scope
else
  CONFDIR="$BASE/.san"
  PROJECT_ROOT="$BASE"
fi

# Resolve the source root holding the persona files (system/, skills/,
# settings.json) and the project assets (agents/, commands/, hooks/, template/,
# data/, scripts/). They sit at the repo root, so use the checkout when run from
# one, otherwise clone the repo (the `curl | bash` path).
SRC_ROOT=""
if [ -n "${BASH_SOURCE:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  { [ -d "$here/system" ] || [ -f "$here/settings.json" ]; } && SRC_ROOT="$here"
fi
if [ -z "$SRC_ROOT" ]; then
  command -v git >/dev/null 2>&1 || { echo "error: git is required for remote install" >&2; exit 3; }
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  echo "→ fetching $PERSONA@$REF"
  git clone --depth 1 --branch "$REF" --quiet "$REPO_URL" "$TMP/src"
  SRC_ROOT="$TMP/src"
fi

# 1. Persona ---------------------------------------------------------------
DEST="$CONFDIR/personas/$PERSONA"
rm -rf "$DEST"
mkdir -p "$DEST"
copied=0
for item in system skills settings.json; do
  if [ -e "$SRC_ROOT/$item" ]; then
    cp -R "$SRC_ROOT/$item" "$DEST/"
    copied=1
  fi
done
[ "$copied" = 1 ] || { echo "error: no persona content found in $SRC_ROOT" >&2; exit 3; }
echo "→ installed persona to $DEST"

# 2. Agents ----------------------------------------------------------------
if [ -d "$SRC_ROOT/agents" ]; then
  mkdir -p "$CONFDIR/agents"
  cp "$SRC_ROOT"/agents/*.md "$CONFDIR/agents/" 2>/dev/null || true
  echo "→ installed agents to $CONFDIR/agents"
fi

# 3. Commands (best-effort) ------------------------------------------------
if [ -d "$SRC_ROOT/commands" ]; then
  mkdir -p "$CONFDIR/commands"
  cp "$SRC_ROOT"/commands/*.md "$CONFDIR/commands/" 2>/dev/null || true
  echo "→ installed commands to $CONFDIR/commands"
fi

# 4. Hooks: scripts + merge the hooks block into <confdir>/settings.json ----
if [ -d "$SRC_ROOT/hooks" ]; then
  mkdir -p "$CONFDIR/hooks"
  for hf in "$SRC_ROOT"/hooks/*.sh; do
    [ -f "$hf" ] && cp "$hf" "$CONFDIR/hooks/"
  done
  chmod +x "$CONFDIR/hooks"/*.sh 2>/dev/null || true
  echo "→ installed hooks to $CONFDIR/hooks"
fi

# 5. Settings: merge hooks block (if any) + enable the persona --------------
SETTINGS="$CONFDIR/settings.json"
HOOK_SRC="$SRC_ROOT/hooks/settings.json"
if command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS" "$PERSONA" "$HOOK_SRC" ".san" <<'PY'
import json, sys, os
settings_path, persona, hook_src, cfg = sys.argv[1:5]

try:
    with open(settings_path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

# Merge the hooks block from the repo's hooks/settings.json, substituting the
# __CFG__ placeholder (config dir) with the San config dir name.
if os.path.exists(hook_src):
    with open(hook_src) as f:
        hook_settings = json.load(f)

    def sub(obj):
        if isinstance(obj, dict):
            return {k: sub(v) for k, v in obj.items()}
        if isinstance(obj, list):
            return [sub(x) for x in obj]
        if isinstance(obj, str):
            return obj.replace("__CFG__", cfg)
        return obj

    hook_settings = sub(hook_settings)
    for key in ("hooks", "mlr"):
        if key in hook_settings:
            data[key] = hook_settings[key]

data["persona"] = persona

with open(settings_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
elif [ ! -s "$SETTINGS" ]; then
  printf '{\n  "persona": "%s"\n}\n' "$PERSONA" > "$SETTINGS"
  echo "warning: python3 not found; wrote persona only (hooks not merged)." >&2
else
  echo "warning: python3 not found and $SETTINGS already exists." >&2
  echo "         add  \"persona\": \"$PERSONA\"  to it manually to enable." >&2
fi
echo "→ enabled '$PERSONA' in $SETTINGS ($SCOPE scope)"

# 6. Scaffold the research project (only with a topic, project/--dir scope) --
SCAFFOLDED=0
if [ -n "$TOPIC" ] && [ "$NO_SCAFFOLD" = 0 ]; then
  if [ "$SCOPE" = "user" ]; then
    echo "note: --user scope does not scaffold a project; persona installed only." >&2
  else
    SLUG=$(printf '%s' "$TOPIC" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
    [ -z "$SLUG" ] && SLUG="research"
    [ -d "$SRC_ROOT/template" ] && cp -R "$SRC_ROOT/template/." "$PROJECT_ROOT/"
    [ -d "$SRC_ROOT/data" ]     && cp -R "$SRC_ROOT/data"     "$PROJECT_ROOT/"
    [ -d "$SRC_ROOT/scripts" ]  && cp -R "$SRC_ROOT/scripts"  "$PROJECT_ROOT/"

    DATE=$(date +%Y-%m-%d)
    ML_VERSION=$(git -C "$SRC_ROOT" rev-parse --short HEAD 2>/dev/null || echo "$REF")
    while IFS= read -r -d '' f; do
      sed \
        -e "s|{{TOPIC}}|$TOPIC|g" \
        -e "s|{{DATE}}|$DATE|g" \
        -e "s|{{SLUG}}|$SLUG|g" \
        -e "s|{{RUNTIME}}|san|g" \
        -e "s|{{ML_VERSION}}|$ML_VERSION|g" \
        "$f" > "$f.tmp" && mv "$f.tmp" "$f"
    done < <(find "$PROJECT_ROOT" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) -not -path '*/.san/*' -print0)

    if [ ! -d "$PROJECT_ROOT/.git" ]; then
      ( cd "$PROJECT_ROOT" && git init -q && git add . \
        && git commit -qm "initial: ml-researcher project for $TOPIC

Persona: ml-researcher (San)
ml-researcher: $REF ($ML_VERSION)
Topic: $TOPIC
Created: $DATE" )
    fi
    SCAFFOLDED=1
    echo "→ scaffolded research project at $PROJECT_ROOT (phase: Data Understanding)"
  fi
fi

cat <<EOF

✓ ml-researcher installed & enabled ($SCOPE scope)
  Persona:  $DEST
  Enabled:  $SETTINGS  →  "persona": "$PERSONA"
EOF
[ "$SCAFFOLDED" = 1 ] && echo "  Project:  $PROJECT_ROOT  (research/ experiments/ data/ scaffolded)"
cat <<EOF

Start san in this directory and the persona is active. Switch anytime with:
  /persona $PERSONA      (activate)   ·   /persona default   (back to built-in San)
EOF
