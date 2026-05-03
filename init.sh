#!/usr/bin/env bash
# ml-researcher — bootstrap an ML research project.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh | bash -s -- "<topic>"
#   curl -fsSL .../init.sh | bash -s -- "<topic>" --runtime gen
#   ./init.sh "<topic>" [--runtime claude|gen|codex] [--in-place] [--ref <commit-or-tag>]
#
# Effects:
#   1. Clone ml-researcher (shallow) to a temp dir (skipped if running locally).
#   2. Create <slug>/ (or use current dir with --in-place).
#   3. Copy template/* into the project.
#   4. Write agents/skills/commands/hooks into <project>/<config-dir>/.
#   5. Write prompts/ml_researcher.md as <project>/<prompt-file>.
#   6. Copy data/ and scripts/ to project root.
#   7. Substitute {{TOPIC}}, {{DATE}}, {{SLUG}}.
#   8. git init + first commit.
set -euo pipefail

TOPIC=""
RUNTIME="claude"
IN_PLACE=0
REF="${ML_RESEARCHER_REF:-main}"
REPO="${ML_RESEARCHER_REPO:-https://github.com/genai-io/ml-researcher.git}"
LOCAL_SRC=""

usage() {
  cat <<'EOF'
Usage: init.sh "<topic>" [options]

Options:
  --runtime <name>    claude (default) | gen | codex
  --in-place          initialize current directory instead of creating a new one
  --ref <ref>         git ref to clone (commit, tag, or branch). Default: main
  --local <path>      use a local ml-researcher checkout instead of cloning
  -h, --help          show this help

Examples:
  init.sh "GBM tumor purity"
  init.sh "Bird classification" --runtime gen
  init.sh "Sentiment analysis" --in-place
  init.sh "test" --ref v0.1.0
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime)  RUNTIME="$2"; shift 2 ;;
    --in-place) IN_PLACE=1; shift ;;
    --ref)      REF="$2"; shift 2 ;;
    --local)    LOCAL_SRC="$2"; shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    -*)         echo "unknown flag: $1" >&2; usage >&2; exit 2 ;;
    *)          TOPIC="$1"; shift ;;
  esac
done

if [ -z "$TOPIC" ]; then usage >&2; exit 2; fi

case "$RUNTIME" in
  claude) CFG=".claude"; PROMPT_FILE="CLAUDE.md" ;;
  gen)    CFG=".gen";    PROMPT_FILE="GEN.md"   ;;
  codex)  CFG=".codex";  PROMPT_FILE="AGENTS.md" ;;
  *) echo "unknown runtime: $RUNTIME (use claude|gen|codex)" >&2; exit 2 ;;
esac

# Slug from topic: lowercase, non-alphanumeric → hyphen, collapse, trim.
SLUG=$(printf '%s' "$TOPIC" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')
[ -z "$SLUG" ] && SLUG="research"

# Pick destination
if [ "$IN_PLACE" = 1 ]; then
  DEST="."
else
  DEST="$SLUG"
  if [ -e "$DEST" ]; then
    echo "error: $DEST already exists. Use --in-place or pick a different topic." >&2
    exit 3
  fi
  mkdir -p "$DEST"
fi

# Acquire source
if [ -n "$LOCAL_SRC" ]; then
  SRC="$LOCAL_SRC"
  if [ ! -d "$SRC" ]; then echo "error: --local path not found: $SRC" >&2; exit 3; fi
  echo "→ using local ml-researcher source at $SRC"
else
  TMP=$(mktemp -d)
  trap 'rm -rf "$TMP"' EXIT
  echo "→ fetching ml-researcher@$REF"
  git clone --depth 1 --branch "$REF" --quiet "$REPO" "$TMP/src"
  SRC="$TMP/src"
fi

DEST_ABS=$(cd "$DEST" && pwd)
echo "→ initializing project at $DEST_ABS"

# Copy project skeleton
cp -R "$SRC/template/." "$DEST/"

# Place runtime config
mkdir -p "$DEST/$CFG"
for d in agents skills commands hooks; do
  if [ -d "$SRC/$d" ]; then
    cp -R "$SRC/$d" "$DEST/$CFG/"
  fi
done

# System prompt → project prompt file
if [ -f "$SRC/prompts/ml_researcher.md" ]; then
  cp "$SRC/prompts/ml_researcher.md" "$DEST/$PROMPT_FILE"
fi

# Project-root assets
[ -d "$SRC/data" ]    && cp -R "$SRC/data"    "$DEST/"
[ -d "$SRC/scripts" ] && cp -R "$SRC/scripts" "$DEST/"

# Placeholder substitution
DATE=$(date +%Y-%m-%d)
ML_VERSION=$(git -C "$SRC" rev-parse --short HEAD 2>/dev/null || echo "$REF")

# Find files containing placeholders and substitute. Use a temp file for portability between BSD and GNU sed.
substitute() {
  local f="$1"
  sed \
    -e "s|{{TOPIC}}|$TOPIC|g" \
    -e "s|{{DATE}}|$DATE|g" \
    -e "s|{{SLUG}}|$SLUG|g" \
    -e "s|{{RUNTIME}}|$RUNTIME|g" \
    -e "s|{{ML_VERSION}}|$ML_VERSION|g" \
    "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

while IFS= read -r -d '' f; do substitute "$f"; done < <(
  find "$DEST" -type f \( -name '*.md' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) -print0
)

# Initialize git
if [ ! -d "$DEST/.git" ]; then
  (
    cd "$DEST"
    git init -q
    git add .
    git commit -qm "initial: ml-researcher project for $TOPIC

Runtime: $RUNTIME
ml-researcher: $REF ($ML_VERSION)
Topic: $TOPIC
Created: $DATE"
  )
fi

cat <<EOF

✓ ml-researcher project initialized
  Path:    $DEST_ABS
  Topic:   $TOPIC
  Runtime: $RUNTIME
  Phase:   Data Understanding
  Version: ml-researcher@$ML_VERSION

Next steps:
  cd $DEST_ABS
  $RUNTIME
  > /phase                 # see what's needed to advance the phase
  > /lit-search "<query>"  # delegate literature triage
  > /exp-new <name>        # register a baseline experiment
EOF
