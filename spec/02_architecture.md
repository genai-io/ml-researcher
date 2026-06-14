# 02 — Architecture

## ml-researcher is a San persona

ml-researcher is a [San](https://github.com/genai-io/san) **persona**: a switchable on-disk bundle of system prompt + skills + config that San loads to become an ML research engineer. The repository **is** the persona — its files sit at the root, exactly like the reference persona [genai-io/social-creator](https://github.com/genai-io/social-creator). An installer copies those files into a San config directory and enables them; San does the rest via its persona / slot model (see san's [`docs/concepts/persona.md`](https://github.com/genai-io/san/blob/main/docs/concepts/persona.md)).

A research project produced by the installer is still **self-contained** — it carries its own scaffolding (`research/`, `experiments/`, `data/`, `scripts/`, model registry) and is reproducible from `git clone` alone. The persona (the brain) is installed into `.san/`; the project (the record) is scaffolded into the project root.

## The persona, four parts

San's system prompt answers four questions through replaceable parts; ml-researcher supplies three of them (the fourth, `environment`, San computes at runtime):

| Question | Part | ml-researcher file |
|---|---|---|
| Who am I? | `identity` | `system/identity.md` — ML research engineer + epistemic stance |
| How do I act? | `behavior` | `system/behavior.md` — three-loop model, Train-Loop discipline, dispatch, operational know-how |
| What rules do I follow? | `rules` | `system/rules.md` — the non-negotiable methodology gates (research hygiene) |
| Where/when am I? | `environment` | computed by San; not shipped |

The persona also carries a `settings.json` **overlay** (description / active skills / agent allow-list / permissions) and a persona-scoped `skills/` directory.

## Repo layout

```
ml-researcher/
├── README.md
├── system/
│   ├── identity.md              # persona: who
│   ├── behavior.md              # persona: how
│   └── rules.md                 # persona: rules
├── settings.json                # persona overlay (description, skills, agents, permissions)
├── install.sh  install.ps1      # tooling — persona install + scaffold (NOT copied into the persona)
├── uninstall.sh uninstall.ps1
├── skills/                      # 28 skills (skills/<name>/SKILL.md) — persona-scoped
├── agents/                      # 6 subagents      -> installed to <confdir>/agents/
├── commands/                    # 6 slash commands -> installed to <confdir>/commands/
├── hooks/                       # hook scripts + settings.json hooks template
├── scripts/                     # python helpers (bootstrap_ci, delong_test, figure_render)
├── data/
│   └── model_registry.yaml      # 18-entry curated ML knowledge base
├── template/                    # project skeleton, copied 1:1 when scaffolding
│   ├── README.md                # uses {{TOPIC}}, {{DATE}}, {{SLUG}} placeholders
│   ├── respec/ research/ data/ experiments/ results/ papers/
└── spec/                        # design docs (this directory)
```

`install.sh` is the only "active" piece. Everything else is data.

## What ends up on disk

San reads personas from two scopes (project overrides user):

```
~/.san/                          # user scope   (install.sh --user)
<project>/.san/                  # project scope (default)
├── personas/ml-researcher/
│   ├── system/{identity,behavior,rules}.md
│   ├── skills/<name>/SKILL.md
│   └── settings.json            # the persona overlay
├── agents/<name>.md             # the 6 subagents (San's subagent registry)
├── commands/<name>.md           # the 6 slash commands
├── hooks/<name>.sh              # methodology hook scripts
└── settings.json                # "persona": "ml-researcher" + merged hooks block
```

When a topic is given (project scope), the installer also scaffolds the project root:

```
<project>/
├── research/   progress.md + per-phase stubs
├── experiments/ ledger.tsv (header only) + EXPxxx/ dirs
├── data/       raw/ derived/ splits/  + model_registry.yaml
├── results/ papers/ respec/ scripts/
└── .git/       initialized with first commit
```

## Installer responsibilities

`install.sh ["<topic>"] [--user] [--dir <path>] [--no-scaffold]`:

1. **Persona** — copy `system/ skills/ settings.json` → `<confdir>/personas/ml-researcher/`.
2. **Agents** — copy `agents/*.md` → `<confdir>/agents/` (San loads subagents from here).
3. **Commands** — copy `commands/*.md` → `<confdir>/commands/`.
4. **Hooks** — copy `hooks/*.sh` → `<confdir>/hooks/`; merge the `hooks` block from `hooks/settings.json` (with `__CFG__` → `.san`) into `<confdir>/settings.json`.
5. **Enable** — set `"persona": "ml-researcher"` in `<confdir>/settings.json`, preserving other keys.
6. **Scaffold** (topic given, project/`--dir` scope only) — copy `template/` + `data/` + `scripts/` into the project root, substitute `{{TOPIC}}/{{DATE}}/{{SLUG}}`, `git init` + first commit.

`install.ps1` is the Windows port (native PowerShell JSON merge — no python needed). `uninstall.sh` / `uninstall.ps1` remove the persona dir and the agents/commands/hooks files this persona owns (by exact name), and drop the `"persona"` selection only if it still points at ml-researcher.

## Hooks live in settings, not in the persona overlay

The documented persona overlay schema is description / skills / agents / disabledTools / permissions — it has no `hooks` key. ml-researcher's methodology hooks (raw-data lock, test-set guard, pre-flight, phase gate, …) are therefore merged into the **config-dir `settings.json`** (which San's settings natively support: permissions, hooks, env, identity), not into the persona's own `settings.json`. The persona stays portable and switchable; the load-bearing filesystem guards ride in the project/user settings the installer writes.

## Multi-runtime support (legacy)

ml-researcher previously shipped via `init.sh --runtime claude|gen|codex`, delivering the prompt as `CLAUDE.md` / `.gen/identities/` / `AGENTS.md`. That path is **deprecated**: San is now the runtime. `init.sh` is retained only as a thin shim that forwards to `install.sh`, so existing curl one-liners keep working.

## What `install.sh` does NOT do

- Does not install San itself.
- Does not modify anything outside `<confdir>` and (when scaffolding) the project root.
- Does not require a package manager (`git`, `bash`, `sed`, `find`, optional `python3`).
- Does not check for updates after install — a scaffolded project is frozen at the ml-researcher ref it was created from. Reproducibility first.

## What `spec/` is

`spec/` (this directory) is **design documentation for ml-researcher itself** — read by contributors, by agents loading the design intent, and by researchers evaluating the methodology. It is **not** copied into a research project. The user-facing methodology lives in `template/respec/` — short, actionable templates the user fills in.
