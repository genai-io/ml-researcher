---
name: repro-seal
description: Generate a reproducibility seal — a JSON snapshot of the run's environment (python, packages, CUDA), code state (git sha, branch, dirty flag), data state (split hashes), and seeds. Wraps scripts/repro_seal.py. Mandatory for any kept experiment that will be cited in research/analysis_report.md. Schema in references/seal_schema.md, critic rules in references/critic_enforcement.md.
allowed-tools: Bash Read Write
---

# When to use

- Inside `exp-register` (added to the registration commit) — establishes the seal at experiment birth.
- Before `git-keep-or-reset keep` on a trial intended to be cited — re-seal if env/data changed during the trial.
- Pre-finalize, by analyst, to verify every cited experiment has a seal and hashes haven't drifted.

Do NOT call on every trial in a tight Train Loop — the seal cost (pip freeze, CUDA query, file hashes) adds 1–3 s per call. Re-seal only on `keep` boundaries.

# What the seal contains (one-line)

`exp_id`, `sealed_at`, `code` (git sha + branch + dirty flag), `python` (version + packages hash), `cuda` (version + devices), `data` (split hashes + locked flag), `seeds` (python / numpy / torch + cudnn determinism).

Full JSON schema: `references/seal_schema.md`.

# Steps

1. **Identify the experiment** — current dir (`experiments/EXPxxx_*/`) or `--exp-id`.

2. **Invoke**:

   ```bash
   python scripts/repro_seal.py \
     --exp-id EXP003_combined-linear-svm \
     --out experiments/EXP003_combined-linear-svm/repro_seal.json
   ```

3. Two files are written: `repro_seal.json` and `repro/requirements.txt` (frozen package list).

4. **Verify the seal**:
   - `dirty: true` → tell the user there are uncommitted changes; this seal is advisory. Re-seal after committing.
   - `splits_locked: false` → BLOCK. Splits not locked; not reproducible at the data layer.
   - `cuda.available: false` while experiment used GPU code → flag for review.

5. **Append the seal sha** to the trial's ledger row via `ledger-append`'s `secondary_metrics_json` field as `"repro_seal_sha": "..."`.

# Verification mode

Analyst runs pre-finalize:

```bash
python scripts/repro_seal.py \
  --exp-id EXP003_combined-linear-svm \
  --verify experiments/EXP003_combined-linear-svm/repro_seal.json
```

Exits `0` on match, `6` on mismatch (diff on stdout: which fields drifted).

# Hard rules

- The seal records what's true *at sealing time*. It is NOT a re-run guarantee — it's a guarantee that the user can know exactly what changed.
- `dirty: true` seals must NOT be cited in `analysis_report.md` as authoritative. Critic checks this.
- Never delete a seal file. Rotate by appending new seals.
- `data.splits` hashes are read from `data/splits/MANIFEST.json`. If the manifest is missing, the seal records `splits_locked: false`.
- Default `--quick` mode uses manifest-stored hashes. Only pass `--deep` when verifying a final result.

# Script contract

`scripts/repro_seal.py`:

| Flag | Meaning | Default |
|---|---|---|
| `--exp-id <id>` | experiment ID (or infer from CWD) | inferred |
| `--out <path>` | output seal path | `<exp_dir>/repro_seal.json` |
| `--verify <path>` | compare current env against this seal | none |
| `--quick` / `--deep` | skip / force per-file hashing | `--quick` |
| `--packages-tool <pip\|uv>` | how to freeze packages | auto-detect |

Exit codes: `0` success or verify-match, `6` verify-mismatch, `7` no manifest / data not locked.

# Critic enforcement

Critic's pre-finalize audit enforces seal presence and validity on every cited experiment. Full rule list: `references/critic_enforcement.md`.

# Related

Pairs with [[ledger-append]] (seal sha lands in the ledger row), [[exp-register]] (initial seal at exp birth). Critic uses `--verify` during pre-finalize audit.
