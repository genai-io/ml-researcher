---
name: hypothesis-ledger
description: First-class hypothesis ledger separate from trial_trace.md. Each hypothesis gets an ID, a pre-registered prediction, and a list of trials/experiments that test it. Inspired by RD-Agent's hypothesis-first pattern. Use when a research direction needs to outlive any single experiment. Entry format in references/.
allowed-tools: Read Edit
---

# When to use

- Before starting a multi-trial direction in Fine Tuning ("LR warmup matters for this regime") — the hypothesis is the unit you're testing, not any one trial.
- When the same hypothesis is being re-tested across experiments and you want a single artifact to anchor the verdict.
- When [[ablation-planner]] produces a matrix — each row is a hypothesis; the ledger is where their verdicts live.

Do NOT use as a replacement for [[trial-log]]. Trial-log records per-trial outcomes; hypothesis-ledger records the longer-lived claims trials are evidence for or against.

# The unit

A hypothesis is a falsifiable statement: "If we change X to Y, metric M will move by Δ in direction D, because Z."

Examples of well-formed hypotheses:
- "Switching from random to patient-stratified splits will close the train-val gap from 0.15 to ≤ 0.05, because the original gap is driven by patient memorization."
- "Adding gradient checkpointing will preserve metric while reducing peak VRAM by ≥ 30%, because activations dominate memory in this model size."

Examples of poorly-formed hypotheses (do NOT log these):
- "LoRA might help" — no direction, no magnitude, no mechanism.
- "EXP005 was better" — that's an observation, not a hypothesis.

# Where it lives

`research/hypothesis_ledger.md`. One ID per hypothesis, append-only, never edited (corrections are new entries that supersede prior ones).

# Steps

1. **Read `research/hypothesis_ledger.md`**. If absent, create with header:

   ```markdown
   # Hypothesis Ledger

   Append-only. Each hypothesis is a pre-registered, falsifiable claim with a verdict
   accumulated across trials.
   ```

2. **Assign an ID**: list existing entries, find the highest `HYP<NNN>` and increment.

3. **Write the entry** using the format in `references/entry_format.md`. Required fields: statement, mechanism, prediction (direction + magnitude), evidence-trials list, verdict (`open` / `supported` / `refuted` / `mixed`).

4. **Mark `verdict: open`** at registration. As trials run, append evidence rows; flip verdict only when the evidence justifies it.

5. **Cross-reference from trial-log**. Every trial whose purpose is to test a hypothesis should cite the HYP id in its trial-log entry's `motivation`. This is what lets the ledger accumulate evidence.

# Hard rules

- **Pre-register the prediction.** Direction + magnitude written BEFORE any trial runs. No post-hoc edits to the prediction.
- **Mechanism is mandatory.** "Because Z" forces you to articulate the model — that's what makes the hypothesis testable.
- **Verdicts have evidence.** `supported` / `refuted` requires a list of trial IDs. `mixed` is the right verdict when trials disagree — don't force it to one side.
- **Open hypotheses do not block trials.** The ledger is documentation; the actual trial pacing is the experimenter's call.
- **A refuted hypothesis is valuable.** Mark and keep — preserves the search history so future-you doesn't re-attempt the same wrong path.

# Difference from trial-log

| | trial-log | hypothesis-ledger |
|---|---|---|
| Unit | One trial (edit + run + decide) | One claim (lives across N trials) |
| Lifetime | Append per trial | Append per claim; updated per evidence |
| Mandatory? | Yes, per meaningful experiment | Optional; use when claim spans multiple trials |
| Audit role | "What did we try?" | "What do we believe and why?" |

# Related

- [[trial-log]] — per-trial record; cite HYP ids in motivations to link.
- [[ablation-planner]] — produces a matrix of hypotheses to register here.
- [[critic]] — reads the ledger during pre-finalize to verify the report's claims are supported by accumulated evidence.
