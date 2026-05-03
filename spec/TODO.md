# Backlog

Things explicitly out of scope for v0.1, with a brief reason and the trigger that would put them back on the table.

## Standalone `mlr` binary

Earlier drafts proposed building a binary derived from gen-code with a `nouserconfig` build tag. Dropped because: a binary duplicates work the runtime already does. The methodology is the product; the runtime is gen-code or Claude Code.

**Trigger to revisit**: a runtime-level capability (e.g., custom permission policy, custom UI) becomes load-bearing for ml-researcher AND can't be expressed as a hook or skill.

## Plugin marketplace listing

Listing on Claude Code or gen-code's plugin marketplace would lower install friction for casual users (one click vs `curl | bash`).

**Trigger to revisit**: ml-researcher has a stable user base of ≥20 active projects and a marketplace listing would clearly help discovery.

## MCP server packaging

Wrapping ml-researcher's skills + scripts as MCP servers would let runtimes that don't load skills (Cursor, OpenHands) still get the tools.

**Trigger to revisit**: a non-skill runtime acquires a meaningful share of users requesting ml-researcher.

## Cross-tool spec-kit compatibility

Adopting GitHub's [spec-kit](https://github.com/github/spec-kit) layout for the methodology templates would make ml-researcher's per-experiment lifecycle work in 30+ AI tools (Cursor, Copilot, Gemini, etc.) for free.

**Trigger to revisit**: a user request from someone on Cursor/Copilot, or a clean way to layer spec-kit's `.specify/` next to `.claude/` without doubling the conceptual surface.

## Auto-update tooling for existing projects

Currently, `init.sh --in-place` overwrites methodology files; it does not selectively port new agents/skills into a project that's already done research. A tool that diffs `.claude/` against a target ml-researcher version and previews changes would be useful.

**Trigger to revisit**: a researcher with a long-lived project asks how to take advantage of new ml-researcher features without re-init-ing.

## Sysbox-style sandbox isolation

Per [`11_related_projects.md`](11_related_projects.md), MLE-bench's "dummy verifier proves it cannot read holdout labels" pattern is the strongest anti-fabrication guarantee in the landscape. Adding a sysbox (or rootless container) wrapper around `experiment_run` would harden the test-set firewall.

**Trigger to revisit**: a documented case where a hook-based test-set lock was bypassed.

## BFTS / experiment-tree visualization

AI-Scientist v2 uses best-first tree search over experimental directions, with a separate experiment-manager agent that prunes branches. AIDE produces an HTML tree visualization of every solution attempt. ml-researcher's flat ledger.tsv could grow into a tree, with HTML rendering.

**Trigger to revisit**: users report that linear `iteration_trace.md` doesn't reflect the branching structure of their actual research.

## Automated paper drafting

AI-Scientist (Sakana) writes full LaTeX papers from a topic. Deliberately not in v0.1 because of MLR-Bench's 80% fabrication finding. The risk-reward is unfavorable until anti-fabrication guarantees are stronger.

**Trigger to revisit**: stronger anti-fabrication primitives are in place AND a user case for "paper draft" produces value beyond `analysis_report.md`.

## Domain playbook library

Today, `playbook.md` is per-project. A central library of domain playbooks (radiomics, NLP fine-tuning, RL, time-series, computer vision) shipped as opt-in installs would speed project setup.

**Trigger to revisit**: at least three domains have stable, distinct playbook patterns that justify packaging.

## Live model registry refresh

Currently `data/model_registry.yaml` is a static snapshot at `init` time. A scheduled job (cron / GitHub Action) that re-verifies entries against HF Hub and PapersWithCode and updates `last_verified` would address staleness.

**Trigger to revisit**: a project notices a stale entry causing a wrong recommendation, OR `last_verified` median age exceeds 6 months.
