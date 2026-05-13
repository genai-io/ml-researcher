# 02 — Architecture

## Zero-install, self-contained projects

ml-researcher does not install anything. The repository is a content store. A single bash script (`init.sh`) clones the content, copies it into a new (or existing) research project directory, and exits. The resulting project is **self-contained** — it carries its own `agents/`, `skills/`, `commands/`, `hooks/`, prompts, model registry, and Python helpers in-tree.

A research project cloned to a fresh machine works without ml-researcher being present anywhere on disk. That property is the architectural goal.

## End-to-end flow

```bash
# Bootstrap a new project (one command)
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "GBM tumor purity"

# What this produces:
gbm-tumor-purity/
├── README.md                 # filled with topic, date, current phase
├── CLAUDE.md                 # the ml-researcher system prompt
├── .claude/                  # runtime config — agents/skills/commands/hooks
│   ├── agents/   (5 files)
│   ├── skills/   (~14 files)
│   ├── commands/ (~7 files)
│   └── hooks/
├── respec/                   # methodology templates
├── research/
│   ├── progress.md           # filled with phase=Data Understanding
│   ├── data_understanding.md (stub)
│   └── ...
├── data/
│   ├── model_registry.yaml
│   ├── raw/, derived/, splits/
├── experiments/
│   ├── README.md
│   └── ledger.tsv (header only)
├── results/, papers/
├── scripts/                  # Python helpers
└── .git/                     # initialized with first commit

# Start the agent
cd gbm-tumor-purity && claude
> /research phase                      # see what's needed to advance
> /exp new baseline-logistic
> /exp paper search "small-sample radiomics"
```

No global plugin install. No `~/.claude/plugins/` dependency. The project's `.claude/` directory is the entire runtime config.

## Repo layout

```
ml-researcher/
├── README.md
├── init.sh                       # the only delivery mechanism
├── spec/                         # design docs (this directory) — for contributors and AI reading the design
├── prompts/
│   └── ml_researcher.md          # written to <project>/CLAUDE.md by init.sh
├── agents/                       # 6 subagents
├── skills/                       # ~17 skills
├── commands/                     # slash commands (NOT including init — that's bash)
├── hooks/                        # hook config + helper scripts
├── scripts/                      # Python helpers (bootstrap_ci, delong_test, ...)
├── data/
│   └── model_registry.yaml
└── template/                     # project skeleton, copied 1:1 by init.sh
    ├── README.md                 # uses {{TOPIC}}, {{DATE}}, {{SLUG}} placeholders
    ├── respec/                   # methodology templates (rad-research-derived)
    ├── research/                 # progress.md, *.md stubs
    ├── data/, experiments/, results/, papers/
```

`init.sh` is the only "active" piece. Everything else is data.

## Multi-runtime support

`init.sh` accepts `--runtime claude|gen|codex`. The runtime determines the project-level config directory and **how the persona is delivered**.

| Runtime | Config dir | Persona delivery | Status |
|---|---|---|---|
| Claude Code | `.claude/` | `CLAUDE.md` (project memory; system-reminder) | First-class |
| Gen Code | `.gen/` | `.gen/identities/ml-researcher.md` (system prompt slot 0) + `.gen/settings.json` activates it | First-class |
| Codex | `.codex/` | `AGENTS.md` (project memory) | Best-effort |

Gen Code has a [first-class identity slot](https://github.com/genai-io/gen-code/blob/main/docs/system-prompt.md) in its system prompt — separate from project memory. ml-researcher's prompt is persona-shaped (epistemic stance + methodology), so it slots in cleanly at slot 0 (`identity`) without polluting project memory (`GEN.md`).

Claude Code and Codex don't yet expose an identity slot, so the persona rides in project memory (`CLAUDE.md` / `AGENTS.md`), which the runtime injects on every turn via the system-reminder channel.

Same agents, same skills, same commands across all three runtimes. Only the persona placement differs. Default runtime is `claude`.

## init.sh (the only delivery mechanism)

```bash
#!/usr/bin/env bash
# Bootstrap an ml-researcher project.
# Usage: init.sh "<topic>" [--runtime claude|gen|codex] [--in-place]
set -euo pipefail

TOPIC="" RUNTIME="claude" IN_PLACE=0
REF="${ML_RESEARCHER_REF:-main}"
REPO="${ML_RESEARCHER_REPO:-https://github.com/genai-io/ml-researcher.git}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --runtime) RUNTIME="$2"; shift 2 ;;
    --in-place) IN_PLACE=1; shift ;;
    --ref) REF="$2"; shift 2 ;;
    -*) echo "unknown flag: $1"; exit 1 ;;
    *) TOPIC="$1"; shift ;;
  esac
done
[ -z "$TOPIC" ] && { echo 'usage: init.sh "<topic>" [--runtime claude|gen|codex] [--in-place]'; exit 1; }

case "$RUNTIME" in
  claude) CFG=".claude"; PROMPT="CLAUDE.md" ;;
  gen)    CFG=".gen";    PROMPT="GEN.md"    ;;   # for gen, persona goes to .gen/identities/, not GEN.md
  codex)  CFG=".codex";  PROMPT="AGENTS.md" ;;
  *) echo "unknown runtime: $RUNTIME"; exit 1 ;;
esac

SLUG=$(echo "$TOPIC" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-\|-$//g')
[ -z "$SLUG" ] && SLUG="research"

if [ "$IN_PLACE" = 1 ]; then DEST="."; else
  DEST="$SLUG"; [ -e "$DEST" ] && { echo "error: $DEST exists"; exit 1; }
  mkdir -p "$DEST"
fi

TMP=$(mktemp -d); trap "rm -rf $TMP" EXIT
echo "→ fetching ml-researcher@$REF"
git clone --depth 1 --branch "$REF" "$REPO" "$TMP/src" >/dev/null 2>&1

SRC="$TMP/src"
echo "→ initializing $DEST"

cp -R "$SRC/template/." "$DEST/"
mkdir -p "$DEST/$CFG"
cp -R "$SRC/agents" "$SRC/skills" "$SRC/commands" "$SRC/hooks" "$DEST/$CFG/"
cp    "$SRC/prompts/ml_researcher.md" "$DEST/$PROMPT"
cp -R "$SRC/data" "$SRC/scripts" "$DEST/"

DATE=$(date +%Y-%m-%d)
find "$DEST" -type f \( -name '*.md' -o -name '*.yaml' \) -print0 \
  | xargs -0 sed -i.bak "s|{{TOPIC}}|$TOPIC|g;s|{{DATE}}|$DATE|g;s|{{SLUG}}|$SLUG|g"
find "$DEST" -name '*.bak' -delete

[ ! -d "$DEST/.git" ] && (
  cd "$DEST" && git init -q && git add . \
    && git commit -qm "initial: ml-researcher project for $TOPIC"
)

cat <<EOF

✓ Project initialized
  Path:    $(cd "$DEST" && pwd)
  Topic:   $TOPIC
  Runtime: $RUNTIME
  Phase:   Data Understanding

Next:
  cd $DEST
  $RUNTIME
  > /research phase
  > /exp paper search "<query>"
  > /exp new <name>
EOF
```

Reading this script top-to-bottom is sufficient to understand ml-researcher's entire delivery model. There is nothing hidden.

## What `init.sh` does NOT do

- Does not install ml-researcher globally.
- Does not modify `~/.claude/`, `~/.gen/`, or `~/.codex/`.
- Does not require a package manager.
- Does not install Python dependencies (the user installs whatever their `scripts/` need).
- Does not check for runtime updates after init — the project is frozen at the ml-researcher commit it was init'd from.

The last property is intentional: a research project's methodology version should not silently drift after creation. Reproducibility comes first.

## What `spec/` is

`spec/` (this directory) is **design documentation for ml-researcher itself**. It describes why the methodology has the shape it does, what the research project flow looks like, and how the runtime files are organized. It is read by:

- contributors to ml-researcher
- AI agents loading the design intent
- ML researchers evaluating whether to adopt this methodology

`spec/` is **not** copied into a research project by `init.sh`. The user-facing methodology lives in `template/respec/` — short, actionable templates the user fills in.

## What's deferred

- **Standalone `mlr` binary** — earlier drafts proposed gen-code derivatives with build tags. Indefinitely deferred: the runtime exists; we don't need to ship one.
- **Plugin manifest** (`.claude-plugin/plugin.json`) — possible later if marketplace listing matters.
- **MCP server packaging** — possible later if a runtime can't load skills.
- **Cross-tool spec-kit compatibility** — possible later if Cursor/Copilot demand emerges.

These live in [`TODO.md`](TODO.md).
