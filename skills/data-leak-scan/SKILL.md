---
name: data-leak-scan
description: Scan for the four main data-leakage patterns beyond what test_set_guard.sh catches — group leakage (patient-id, session-id), temporal leakage (future-in-train), proxy-label leakage (features derived from the label), and split-rederivation leakage (re-randomizing splits during the project). Wraps scripts/data_leak_scan.py. Use as a pre-flight check before any phase advance and before report finalize. Pattern detail in references/leak_patterns.md.
allowed-tools: Bash Read
---

# When to use

- Pre-flight, before any new `exp-run` in Model Selection / Fine Tuning — the `preflight` hook can be configured to call this.
- Pre-finalize, by analyst before promoting `analysis_report.md` to results.
- After any change to `data/derived/` or `data/splits/` — re-scan immediately.

Do NOT use as a substitute for `test_set_guard.sh` (which blocks raw test-set Reads at the hook layer). data-leak-scan catches the more subtle leak patterns that file-path checks miss.

# What it scans

Four pattern families (full detail: `references/leak_patterns.md`):

1. **Group leakage** — the same patient / session / device appears in both train and test
2. **Temporal leakage** — train timestamps include events from after the test set's earliest timestamp
3. **Proxy-label leakage** — a feature was computed using the label (e.g., MRI volume measurements where volume was used as the label)
4. **Split-rederivation** — splits files were modified after the initial init.sh lock

# Steps

1. **Identify the dataset target**. Typically `data/splits/MANIFEST.json` (which references the split CSVs and the derived features).

2. **Invoke**:

   ```bash
   python scripts/data_leak_scan.py \
     --manifest data/splits/MANIFEST.json \
     --features data/derived/clean.parquet \
     --groups patient_id \
     --timestamp acquisition_date \
     --label-derivation-rules data/derivation_rules.yaml
   ```

3. **Parse output** — one JSON object on stdout:

   ```json
   {
     "group_leakage": {"detected": false, "overlap_count": 0},
     "temporal_leakage": {"detected": false, "max_overlap_days": 0},
     "proxy_label_leakage": {"detected": true, "suspect_features": ["tumor_volume_ml"]},
     "split_rederivation": {"detected": false, "manifest_unchanged": true},
     "verdict": "BLOCK"
   }
   ```

4. **Surface verdict to caller**:
   - `PASS` — no leak detected; proceed.
   - `WARN` — soft signal (e.g., one timestamp slightly off); analyst review needed.
   - `BLOCK` — hard leak; experiment / report must not proceed until fixed.

5. **If BLOCK**, refuse to proceed with the calling operation. Print the leak details. The user must fix the underlying data issue, re-lock splits if needed, and re-run the scan.

# Hard rules

- `BLOCK` is not advisory — when called from a hook, exit 2 (blocking exit code) to stop the parent operation.
- Each detected leak must include a *concrete pointer* (sample id, feature name, file path) — agents can't act on "leakage somewhere".
- Proxy-label scan requires `--label-derivation-rules` (a YAML mapping feature names to their derivation sources). Without it, proxy-label scan is skipped and reported as `"skipped": "no rules file"`, NOT silently passed.
- Never modify the splits as a side effect. data-leak-scan is read-only.

# Script contract

`scripts/data_leak_scan.py`:

| Flag | Meaning | Default |
|---|---|---|
| `--manifest <path>` | splits manifest JSON | required |
| `--features <path>` | derived features parquet/CSV | required |
| `--groups <col>` | group key column for group-leakage scan | none (group scan skipped) |
| `--timestamp <col>` | timestamp column for temporal scan | none (temporal scan skipped) |
| `--label-derivation-rules <path>` | YAML of feature → derivation source | none (proxy-label scan skipped) |
| `--strict` | upgrade WARN to BLOCK | false |

Output: single JSON object. Exit codes: `0` PASS, `1` WARN (unless `--strict`), `2` BLOCK.

# Why this skill exists

`test_set_guard.sh` is a file-path firewall: it blocks Reads of `data/splits/test/**` during the wrong phases. But the four patterns above all leak *through* the features file or *through* the split definition itself — file-path checks don't catch them. This skill is the second layer.

# Related

- [[dataset-inspect]] runs at registration; data-leak-scan runs at pre-flight / pre-finalize.
- [[critic]] consults data-leak-scan output during `kind=pre-finalize` audit; a `BLOCK` verdict here causes critic to block report promotion.
