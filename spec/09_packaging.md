# 09 — Packaging and Install

ml-researcher delivers content via one bash script. There is no package manager, no plugin manifest, no module registry. This document describes the install model end-to-end so anyone — human or agent — can reproduce it.

## The only delivery mechanism

```bash
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
  | bash -s -- "<topic>" [--runtime claude|gen|codex] [--in-place]
```

The script source is in [`02_architecture.md`](02_architecture.md). Reading it top-to-bottom is the spec — there is no hidden behavior.

Equivalent without the curl pipe:

```bash
git clone --depth 1 https://github.com/genai-io/ml-researcher.git /tmp/mlr
/tmp/mlr/init.sh "<topic>"
rm -rf /tmp/mlr   # optional
```

## What ends up on disk

After `init.sh "GBM tumor purity"` (default runtime = claude):

```
gbm-tumor-purity/             ← project root, fully self-contained
├── .git/                     ← initialized with first commit
├── README.md                 ← topic, date, current phase, navigation
├── CLAUDE.md                 ← ml_researcher.md system prompt
├── .claude/
│   ├── agents/               ← copied from ml-researcher/agents/
│   ├── skills/               ← copied from ml-researcher/skills/
│   ├── commands/             ← copied from ml-researcher/commands/
│   └── hooks/                ← copied from ml-researcher/hooks/
├── respec/                   ← methodology templates, copied from template/respec/
├── research/
│   ├── progress.md           ← phase=Data Understanding, date filled
│   ├── data_understanding.md ← stub
│   └── ...                   ← stubs for remaining stages
├── data/
│   ├── README.md
│   ├── model_registry.yaml   ← copied from ml-researcher/data/
│   ├── raw/, derived/, splits/  (empty dirs)
├── experiments/
│   ├── README.md
│   └── ledger.tsv            ← header-only TSV
├── results/
├── papers/
└── scripts/                  ← copied from ml-researcher/scripts/
    ├── bootstrap_ci.py
    ├── delong_test.py
    └── figure_render.py
```

Nothing references `~/.claude/`, `~/.gen/`, or anything outside this directory. Move the project to another machine, run `git clone` then `claude` — it works.

## Runtime selection

| Flag | Project config dir | System prompt file |
|---|---|---|
| (default) `--runtime claude` | `.claude/` | `CLAUDE.md` |
| `--runtime gen` | `.gen/` | `GEN.md` |
| `--runtime codex` | `.codex/` | `AGENTS.md` |

The agents/skills/commands/hooks content is identical across runtimes. Only file paths differ. See [`02_architecture.md`](02_architecture.md) for the runtime support matrix.

## Versioning

`init.sh` accepts `--ref <commit-or-tag-or-branch>` (default `main`). The clone is `--depth 1 --branch <ref>`, so:

```bash
init.sh "topic" --ref v0.1.0       # frozen at tagged release
init.sh "topic" --ref abc1234      # specific commit
init.sh "topic"                     # latest main
```

The chosen ref is recorded in the project's git history (the initial commit's message could include the ml-researcher commit if useful — TODO).

## Updates after init

Projects do not auto-update. This is intentional:

- A research project is a sealed scientific record. Methodology drift after creation is a reproducibility hazard.
- If a user wants newer ml-researcher behavior in an existing project, they re-run `init.sh --in-place "<topic>"` in the project directory — but this overwrites methodology files. They must reconcile manually.
- For most projects, freeze-at-init is the right default.

A future tool could selectively port new agents/skills into an existing project without touching the methodology templates. Tracked in [`TODO.md`](TODO.md).

## Distribution

ml-researcher is a public GitHub repo. There is no other distribution channel:

- No PyPI / npm / Homebrew / brew tap.
- No Claude Code plugin marketplace listing (possible later; see TODO).
- No Docker image (init.sh only needs `git`, `bash`, `sed`, `find` — already on every developer machine).

## Verification

To verify a fresh install works on a clean machine:

```bash
docker run -it --rm -v $(pwd):/work alpine sh -c '
  apk add --no-cache git bash curl coreutils findutils sed
  cd /work
  curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/init.sh \
    | bash -s -- "smoke test" --in-place
  ls -la
'
```

The result should match the layout above.

## What's deferred

- Optional `mlr` CLI wrapper (just runs `init.sh` with sane defaults). Marginal value vs the curl-bash one-liner.
- Plugin marketplace listing for Claude Code or gen-code.
- Auto-update tooling for existing projects.
- Docker image (only useful if init.sh grows complex; resist).

These are tracked in [`TODO.md`](TODO.md).
