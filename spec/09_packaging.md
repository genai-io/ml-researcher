# 09 — Packaging and Install

ml-researcher is a San persona, delivered by an installer script — the same model as [genai-io/social-creator](https://github.com/genai-io/social-creator). There is no package manager, no plugin manifest, no module registry. This document describes the install model end-to-end so anyone — human or agent — can reproduce it.

## The delivery mechanism

**macOS / Linux:**

```bash
# Persona only (enable it in an existing project)
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh | bash

# Persona + scaffold a research project for a topic
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh \
  | bash -s -- "<topic>"

# User scope (persona everywhere; no project scaffold)
curl -fsSL .../install.sh | bash -s -- --user
```

**Windows (PowerShell 5.1+):**

```powershell
irm https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.ps1 | iex
& ([scriptblock]::Create((irm .../install.ps1))) -Topic "<topic>"
```

The script source ([`install.sh`](../install.sh)) reads top-to-bottom as the spec — there is no hidden behavior. Equivalent without the curl pipe:

```bash
git clone --depth 1 https://github.com/genai-io/ml-researcher.git /tmp/mlr
/tmp/mlr/install.sh "<topic>"
rm -rf /tmp/mlr   # optional
```

## Scope

| Flag | Config dir | Use |
|---|---|---|
| (default) | `<cwd>/.san` | project scope — persona active in this project |
| `--dir <path>` | `<path>/.san` | project scope at an explicit path (and scaffold there) |
| `--user` | `~/.san` | user scope — persona available in every project; no scaffold |

Project scope overrides user scope, matching San's persona precedence.

## What ends up on disk

After `install.sh "GBM tumor purity"` (project scope):

```
gbm-tumor-purity/             ← project root (run install from here)
├── .san/
│   ├── personas/ml-researcher/
│   │   ├── system/{identity,behavior,rules}.md
│   │   ├── skills/<name>/SKILL.md
│   │   └── settings.json        ← the persona overlay
│   ├── agents/<name>.md         ← 6 subagents
│   ├── commands/<name>.md       ← 6 slash commands
│   ├── hooks/<name>.sh          ← methodology hook scripts
│   └── settings.json            ← "persona": "ml-researcher" + merged hooks block
├── research/   progress.md (phase=Data Understanding) + per-phase stubs
├── experiments/ ledger.tsv (header only)
├── data/       raw/ derived/ splits/ + model_registry.yaml
├── results/ papers/ respec/ scripts/
└── .git/       initialized with first commit
```

The scaffolded project is self-contained: move it to another machine, `git clone`, install San, and `/persona ml-researcher` — it works. Run `install.sh` with no topic (or `--no-scaffold`) and only the `.san/` persona is written — nothing else in the directory is touched.

## Enabling and switching

The installer sets `"persona": "ml-researcher"` in the target `settings.json` (other keys preserved). After that, `san` in the directory loads the persona. Switch by hand:

```
/persona ml-researcher    # activate
/persona default          # back to built-in San
```

## Versioning

`install.sh` honors `ML_RESEARCHER_REF` (default `main`); the clone is `--depth 1 --branch <ref>`:

```bash
ML_RESEARCHER_REF=v0.1.0 curl -fsSL .../install.sh | bash -s -- "<topic>"
```

The chosen ref is recorded in the scaffolded project's first commit.

## Updates after install

Scaffolded projects do not auto-update. A research project is a sealed scientific record; methodology drift after creation is a reproducibility hazard. To pull newer ml-researcher behavior into an existing project, re-run `install.sh --no-scaffold` (refreshes the `.san/` persona without touching your `research/` work). Selective porting of methodology templates is tracked in [`TODO.md`](TODO.md).

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/uninstall.sh | bash
# Windows: irm .../uninstall.ps1 | iex
```

Removes the persona directory and the agents/commands/hooks files this persona owns (by exact name, so other personas are untouched), and drops the `"persona"` selection only if it points at ml-researcher. It does **not** delete a scaffolded `research/ experiments/ data/` — that is the user's work.

## Distribution

ml-researcher is a public GitHub repo. No PyPI / npm / Homebrew, no plugin marketplace listing (possible later; see TODO), no Docker image — the installer needs only `git`, `bash`, `sed`, `find`, and optionally `python3`.

## Legacy `init.sh` (removed)

The previous bootstrapper (`init.sh "<topic>" --runtime claude|gen|codex`) has been **removed**. `install.sh` fully replaces it: a `<topic>` argument scaffolds the project (the old `--in-place` is the default behavior), `--ref` is replaced by the `ML_RESEARCHER_REF` env var, and the `--runtime` flag is gone (San is the runtime).

## Verification

To verify a fresh install on a clean machine:

```bash
docker run -it --rm -v "$(pwd):/work" alpine sh -c '
  apk add --no-cache git bash curl coreutils findutils sed python3
  cd /work
  curl -fsSL https://raw.githubusercontent.com/genai-io/ml-researcher/main/install.sh \
    | bash -s -- "smoke test"
  ls -la .san/personas/ml-researcher && cat .san/settings.json
'
```

The result should match the layout above, with `"persona": "ml-researcher"` and a `hooks` block in `.san/settings.json`.

## What's deferred

- Plugin marketplace listing for San.
- Auto-update / selective-port tooling for existing projects.
- Docker image (only useful if the installer grows complex; resist).

Tracked in [`TODO.md`](TODO.md).
