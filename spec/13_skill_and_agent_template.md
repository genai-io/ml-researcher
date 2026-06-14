# 13 — Skill and Agent Templates

Canonical frontmatter + body skeletons for new skills and sub-agents in ml-researcher. Follows the official Agent Skills spec (https://agentskills.io/specification) and the Claude Code sub-agent spec (https://code.claude.com/docs/en/sub-agents) — San consumes the same markdown-with-frontmatter format for both. The two file types share `name` + `description` but differ on tool-listing syntax — see the warning box below.

## Field-name warning

| File type | Tool-list field | Separator | Example |
|---|---|---|---|
| `skills/<slug>/SKILL.md` | `allowed-tools` (hyphenated) | **space** | `allowed-tools: Bash Read` |
| `agents/<name>.md` | `tools` (no hyphen) | **comma** | `tools: Read, Glob, Grep` |

Getting these mixed up is the single most common authoring mistake. The skill `allowed-tools` field is also flagged **experimental** by the spec — treat it as advisory, not a security boundary. Real isolation is enforced at the runtime layer (hooks, permission settings).

## Progressive disclosure (default pattern)

Most skills follow this layout. Keep SKILL.md slim; push depth into sibling files the agent loads only on demand.

```
skills/<slug>/
├── SKILL.md                  # 40-80 lines: trigger + steps + hard rules + brief contract
├── references/               # loaded on demand
│   ├── <topic>.md            # long template / lookup table / interpretation guide
│   └── <schema>.md           # JSON schema, gate requirements, etc.
└── (optional) scripts/       # only if the script isn't shared at scripts/ root
```

When to push content into `references/`:

| Content | Push? |
|---|---|
| Decision tree, hard rules, brief script call | Keep in SKILL.md |
| Per-kind input/output tables (>10 rows) | references/ |
| Long markdown templates (>20 lines) | references/ |
| JSON schema examples (>15 lines) | references/ |
| Interpretation guides ("how to read the metric") | references/ |
| Copy-pasteable code snippets per regime | references/ |

The agent's SKILL.md should link references inline:

```markdown
3. Read the three outputs for patterns. Output template: `references/output_template.md`.
```

When the agent's workflow needs the deep content, it reads the referenced file. Otherwise the deeper material stays out of context — the win of progressive disclosure.

## Skill archetypes

Skills fall into two shapes. Use the right archetype's skeleton.

### Archetype A — knowledge-only skill

A recipe / playbook / decision tree the LLM consults. No script wrapping, no extra tool grants. Omit `allowed-tools` entirely.

Examples in this repo: `medical-small-sample-transfer`, `oom-recovery-checklist`, `sandbox-mode`, `tabular-tabpfn-vs-xgboost`, `ablation-planner`, `hypothesis-ledger`.

```markdown
---
name: <kebab-case-slug>
description: <when to use this skill — one sentence; mention the trigger phrase>
---

# When to use

<one paragraph: the situation that makes this skill the right reach>

# Decision tree | The ladder | The recipe

<the actual content — checklist, decision tree, ordered ladder, or recipe>

# Hard rules

- <rule 1 — what NOT to do and why>
- <rule 2>

# Common failures to avoid

- <pattern 1>

# Reference implementations

- <links to canonical code or papers, with `last_verified` dates if relevant>
```

### Archetype B — tool-wrapping skill

A skill that invokes a script in `scripts/` via Bash, or chains primitive tools into a deterministic workflow. Declare `allowed-tools`.

Examples in this repo: `bootstrap-ci`, `delong-test`, `exp-register`, `metric-grep`, `figure-render`, `phase-advance`, `data-leak-scan`, `seed-sensitivity`.

```markdown
---
name: <kebab-case-slug>
description: <action verb + what it does + what it wraps; one sentence>
allowed-tools: Bash Read  # space-separated, hyphenated field name
---

# Steps

1. <input gathering — file paths, args>
2. <verification — preconditions that must hold>
3. <invocation — exact command line>

   ```bash
   python scripts/<name>.py --flag value ...
   ```

4. <output parsing — what the script returns, JSON shape>
5. <reporting — how to surface to the calling agent>

# Hard rules

- <invariant — e.g., seed required, no test-set path in selection phase>
- <determinism — reproducibility expectations>

# Script contract

`scripts/<name>.py` accepts:

| Flag | Meaning | Default |
|---|---|---|
| `--foo <path>` | … | required |

Output: <stdout shape, exit codes>.
```

## Sub-agent template

```markdown
---
name: <agent-name>                  # lowercase, no spaces
description: <when to use this agent vs others; one or two sentences>
tools: Read, Glob, Grep             # comma-separated; OMIT to inherit all tools
model: inherit                      # inherit | sonnet | opus | haiku | <full-id>
color: blue                         # optional UX hint (blue|cyan|purple|green|yellow|red)
---

# <Agent name>

<one-paragraph role statement: what this agent owns and what it does not>

## Allowed tools

<repeat the `tools:` list here in prose, plus any Skills the agent should reach for>

## When to use vs other agents

| Question | Right agent |
|---|---|
| <case 1> | <this agent> |
| <case 2> | <other agent> |

## Workflow

1. <step>
2. <step>

## Hard rules

- <invariant — e.g., one change per trial, no test-set reads, read-only>

## When you're done

<what the agent returns to its parent — concise summary contract>
```

## Choosing `model:` for a sub-agent

| Agent profile | Recommended model |
|---|---|
| Read-only verifier / linter (e.g., `critic`) | `haiku` |
| Routing / dispatch (e.g., `navigator`) | `inherit` |
| Long iterative work in tight loops (e.g., `experimenter`) | `inherit` (let the user's session choice apply) |
| Methodology-heavy synthesis (e.g., `analyst`, `modeler`) | `inherit` |

Don't pin `opus` on a sub-agent unless the role genuinely requires the strongest model — it forces cost on every spawn.

## Choosing `color:` for a sub-agent

Purely UX in clients that show agent badges (e.g., San, Claude Code). Current assignments:

| Agent | Color | Mnemonic |
|---|---|---|
| navigator | blue | top-level dispatcher |
| literature | cyan | retrieval / "cool" reading work |
| modeler | purple | model decisions |
| experimenter | green | active running |
| analyst | yellow | report drafting |
| critic | red | audit / blocking |

## What goes in `description`

The `description` field is what the runtime uses to *decide whether to load this skill/agent*. Be specific.

- ✗ `description: Helps with experiments.`
- ✓ `description: Run the Train Loop edit→run→measure→keep-or-reset on a single train.py; spawn for /train run or hyperparameter search. Do NOT use for one-off runs.`

Two signals to include:
1. **Trigger** — what user phrasing or situation should invoke this?
2. **Anti-trigger** — what looks similar but is the WRONG case?

## Slug rules

- Lowercase ASCII letters, digits, hyphens.
- No leading/trailing/consecutive hyphens.
- 1–64 characters.
- Directory name (for skills) MUST match the `name:` field exactly.

## When to add a new skill vs extend an existing one

Add new when:
- The trigger phrasing is meaningfully different.
- The hard rules differ (e.g., test-set lock vs no such constraint).
- The output contract differs.

Extend existing when:
- It's a new optional flag or `kind=` variant of the same workflow (see `figure-render`'s `kind` table).
- It's a new entry in a decision table inside a knowledge skill.

## When to add a new sub-agent

Default to NO. Sub-agents are expensive (context spin-up, dispatch decisions for the navigator). Add a new agent only when:
1. The role is **read-mode-different** from existing agents (e.g., critic is read-only; a new "reproducer" might need its own write scope on `experiments/replicas/`).
2. The role spans **more than one phase** and would otherwise have to be duplicated as skills inside multiple existing agents.
3. The role has a distinct **lifecycle contract** that the navigator must reason about (e.g., long-running vs single-turn).

Otherwise, encode the capability as a skill and let an existing agent invoke it.
