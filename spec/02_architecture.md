# 02 — Architecture

## Relationship to gen-code

`mlr` is a derivative of [`gen-code`](https://github.com/genai-io/gen-code). The relationship is **submodule + build tag + extension layer**, not fork.

```
                ┌─────────────────────────────────────┐
                │         ml-researcher (mlr)         │
                │  ┌────────────────────────────────┐ │
                │  │ ML domain layer                │ │
                │  │  • ML-specific tools           │ │
                │  │  • Built-in agents             │ │
                │  │  • System prompts              │ │
                │  │  • Project templates           │ │
                │  │  • Methodology hooks           │ │
                │  └────────────────────────────────┘ │
                │                  │                  │
                │                  ▼                  │
                │  ┌────────────────────────────────┐ │
                │  │ gen-code (submodule)           │ │
                │  │  built with -tags nouserconfig │ │
                │  └────────────────────────────────┘ │
                └─────────────────────────────────────┘
```

ml-researcher does **not** patch gen-code source. It depends on gen-code as a Go module, registers extra tools and agents at startup, and ships its own `cmd/mlr` entry point.

## Directory layout (ml-researcher repo)

```
ml-researcher/
├── README.md
├── LICENSE
├── Makefile
├── go.mod
├── go.sum
├── gen-code/                 # git submodule, pinned commit
├── cmd/
│   └── mlr/
│       └── main.go           # mlr entry point; registers tools/agents/commands
├── internal/
│   ├── ml/                   # ML domain code
│   │   ├── paper/            # paper_search, citation_graph
│   │   ├── dataset/          # dataset_inspect
│   │   ├── experiment/       # register, run, ledger
│   │   ├── metric/           # bootstrap_ci, delong, etc.
│   │   └── monitor/          # train_monitor, oom_recover
│   ├── agents/               # 5 builtin agents (markdown, embedded)
│   ├── commands/             # builtin slash commands
│   ├── prompts/              # ML system prompts
│   └── template/             # project init template (respec/, .mlr/, etc.)
├── spec/                     # this directory
├── examples/
│   └── starter/              # output of `mlr init research`
└── scripts/
```

## Build & sync strategy

### gen-code build tags

ml-researcher requires gen-code to support a `nouserconfig` build tag that, when set, excludes user-level (`~/.gen/`) loading from the binary. Affected packages in gen-code:

- `internal/setting/` — user settings loader
- `internal/skill/` — user-level skill discovery
- `internal/plugin/` — user-level plugin loading
- `internal/hook/` — user-level hook registration
- `internal/mcp/` — user-level MCP servers

For each, gen-code adds a paired file:

```go
// foo.go
//go:build !nouserconfig
package x
func loadUser(home string) (X, error) { /* real impl */ }

// foo_nouserconfig.go
//go:build nouserconfig
package x
func loadUser(_ string) (X, error) { return X{}, nil }
```

This is one-time work in gen-code. See [`09_build.md`](09_build.md) for the implementation plan.

### Pinning gen-code

The `gen-code/` submodule is pinned to a specific commit. Upgrades are explicit:

```bash
cd gen-code
git fetch origin
git checkout v1.16.0
cd ..
git add gen-code
go mod tidy
make test
make build
git commit -m "bump gen-code to v1.16.0"
```

ml-researcher never auto-tracks `main` of gen-code.

### What conflicts when upgrading gen-code

| gen-code change | ml-researcher impact |
|---|---|
| New tool added | None (we keep our tool registration; opt in to new ones explicitly) |
| Existing tool signature change | Requires touch in our domain layer if we wrap it |
| `core.Agent` interface change | Requires touch in `cmd/mlr/main.go` agent assembly |
| New build-tag-relevant code path added | Requires updating gen-code's `nouserconfig` files |
| Settings schema change | Requires update in `internal/template/` if we ship a default `.mlr/settings.json` referencing it |

Routine upgrades (bug fixes, new providers, new models) require zero patches. The submodule + tag approach amortizes upstream maintenance.

## Why not fork gen-code

A hard fork would mean:
- Every gen-code commit must be merged or rebased into ml-researcher's branch.
- Conflict resolution every release cycle, even for unrelated areas (provider list, TUI tweaks, hook system).
- Two diverging codebases that drift apart over time.

Submodule + build tag means:
- gen-code stays clean and reusable for other downstream projects.
- ml-researcher absorbs upstream improvements just by bumping a commit.
- Specialization (ML tools, prompts, methodology) lives entirely in ml-researcher's source, never touching gen-code.

## Why not a plugin

gen-code's plugin system supports adding skills, commands, agents, MCP servers, and hooks. A plugin-based approach would not require any change to gen-code.

It was rejected because:

- A plugin cannot remove user-level config code from the binary; user config still loads at runtime.
- A plugin cannot rebrand the binary (`mlr` vs `gen`).
- A plugin cannot embed a custom system prompt as the default; it must register prompts that the user may or may not select.
- A plugin lives next to many others. ml-researcher wants the entire binary to be opinionated about ML research.

A plugin is appropriate for an *additive* extension of gen-code. ml-researcher is a *specialized distribution* of gen-code, which calls for a separate binary.

## Versioning

- ml-researcher follows independent SemVer.
- Each ml-researcher release records the gen-code commit it was built against in the binary (`mlr --version`).
- gen-code build tag (`nouserconfig`) is part of the contract; gen-code minor version bumps must preserve tag semantics.
