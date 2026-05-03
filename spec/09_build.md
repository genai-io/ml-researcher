# 09 — Build & Sync

## Build matrix

| Build target | Command | Output |
|---|---|---|
| Local development | `make build` | `bin/mlr` (host platform) |
| Cross-platform release | `make release` | `bin/mlr-{linux,darwin,windows}-{amd64,arm64}` |
| Local install | `make install` | `~/.local/bin/mlr` |
| Hook helper | `make build-hook` | `bin/mlr-hook` |

## Makefile sketch

```makefile
GENCODE_DIR := gen-code
GENCODE_TAGS := nouserconfig
LDFLAGS := -X main.version=$(shell git describe --tags --always --dirty) \
           -X main.gencodeCommit=$(shell git -C $(GENCODE_DIR) rev-parse HEAD)

.PHONY: build
build:
	go build -tags '$(GENCODE_TAGS)' -ldflags '$(LDFLAGS)' -o bin/mlr ./cmd/mlr
	go build -ldflags '$(LDFLAGS)' -o bin/mlr-hook ./cmd/mlr-hook

.PHONY: install
install: build
	install bin/mlr ~/.local/bin/mlr
	install bin/mlr-hook ~/.local/bin/mlr-hook

.PHONY: test
test:
	go test -tags '$(GENCODE_TAGS)' ./...

.PHONY: gencode-update
gencode-update:
	@if [ -z "$(VERSION)" ]; then echo "Usage: make gencode-update VERSION=v1.16.0"; exit 1; fi
	cd $(GENCODE_DIR) && git fetch origin && git checkout $(VERSION)
	go mod tidy
	$(MAKE) test
	@echo "gen-code updated to $(VERSION). Commit the submodule pointer when ready."
```

## go.mod strategy

Two options:

### Option A — replace directive (recommended for v0.1)

```go
module github.com/genai-io/ml-researcher

go 1.23

require (
    github.com/genai-io/gen-code v0.0.0
)

replace github.com/genai-io/gen-code => ./gen-code
```

Pros: simple, works with the submodule directly, no need for gen-code to publish module versions.
Cons: gen-code must compile cleanly as a Go module from its repo root.

### Option B — published module versions

Once gen-code publishes proper SemVer tags (`v1.x.y`), drop the `replace` and pin via `require`:

```go
require github.com/genai-io/gen-code v1.16.0
```

The submodule then becomes optional (for source browsing only). Migration to B happens after gen-code stabilizes its public API.

## Build tag implementation in gen-code

This is the upstream change ml-researcher requires. Each affected package gets a paired file.

### internal/setting

```go
// internal/setting/loader.go
//go:build !nouserconfig

package setting

func loadUser(home string) (Settings, error) {
    path := filepath.Join(home, ".gen", "settings.json")
    return loadFile(path)
}
```

```go
// internal/setting/loader_nouserconfig.go
//go:build nouserconfig

package setting

func loadUser(_ string) (Settings, error) {
    return Settings{}, nil
}
```

### Other packages following the same pattern

| Package | Function paired |
|---|---|
| `internal/skill` | `loadUserSkills` |
| `internal/plugin` | `loadUserPlugins` |
| `internal/hook` | `loadUserHooks` |
| `internal/mcp` | `loadUserMCPServers` |
| `internal/llm` | `loadUserProviderConnections` (if user-level provider config exists) |

### Test coverage

gen-code's CI should run both tagged and untagged builds:

```yaml
- run: go test ./...
- run: go test -tags nouserconfig ./...
```

The tagged build verifies that the binary still functions with user-level loading stubbed out.

## Submodule workflow

### Initial setup

```bash
git clone --recurse-submodules https://github.com/genai-io/ml-researcher.git
```

If cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### Pinning to a new gen-code version

```bash
make gencode-update VERSION=v1.16.0
git diff   # should show submodule pointer change
git add gen-code go.mod go.sum
git commit -m "bump gen-code to v1.16.0"
```

### Tracking which gen-code version is in a binary

```bash
mlr --version
# mlr v0.1.0 (gen-code abc1234, built nouserconfig)
```

## Rebuilding after upstream changes

The decision tree when gen-code releases a new version:

```
new gen-code version
   │
   ├── only tools/providers/UI changes ─────────── safe bump, no patch needed
   │
   ├── core.Agent or tool.Set interface changes ── update cmd/mlr/main.go assembly
   │
   ├── new code path that loads from ~/.gen/ ────── add corresponding nouserconfig stub
   │
   └── settings schema change ─────────────────── update internal/template/settings.json
```

The cost of a normal upstream bump is `make gencode-update VERSION=...` plus running tests.

## Release process

```bash
# in ml-researcher
git tag v0.1.0 -m "first release"
git push origin v0.1.0
# CI builds release binaries via make release
```

Release notes must record:
- ml-researcher version
- gen-code commit pinned
- Built tags (`nouserconfig` always)
- Methodology version (from `respec/respec.md` heading)

## Open question — do we vendor gen-code?

Vendoring gen-code's source into ml-researcher's tree (in addition to or instead of the submodule) would:
- Pros: single-clone build; visible at grep time; immune to submodule misconfiguration.
- Cons: doubles repo size; obscures upstream ↔ fork distinction; tempting to "just patch it locally."

**v0.1 decision**: submodule, no vendoring. Reconsider if submodule UX causes friction.
