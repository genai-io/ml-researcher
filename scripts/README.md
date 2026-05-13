# scripts/

Python helpers invoked by skills via Bash. Each script:

- has a single responsibility
- is self-contained (no shared library)
- prints structured output (JSON line) for parsable results, free-form for figures
- depends on the standard scientific Python stack (numpy, pandas, scipy, scikit-learn, matplotlib)

These dependencies are not installed by `init.sh`. The user installs them once per machine (e.g., `pip install numpy pandas scipy scikit-learn matplotlib` or via `uv add`).

## Inventory

| Script | Purpose | Output |
|---|---|---|
| `bootstrap_ci.py` | Bootstrap 95% CI for AUC / accuracy / F1 / Brier | one JSON line on stdout |
| `delong_test.py` | DeLong paired AUC test for two models on the same dataset | one JSON line on stdout |
| `figure_render.py` | Render ROC / calibration / confusion / learning curve / comparison bar to PNG | PNG file, no stdout |

Run any script with `--help` for full options.

## Conventions

- `--seed 42` default for reproducibility.
- CSV inputs: one column with the relevant array, OR a column named `pred` / `label`.
- JSON output: numerics rounded to 3-4 decimals to keep the line short.
- Figures: PNG at 200dpi, sans-serif, color-blind friendly.

## Adding a new script

1. Single responsibility. If a script grows past ~150 lines, split it.
2. Pure CLI — no environment variables, no config files. All config via flags.
3. Output JSON on stdout if the result is structured. Free-form text only for `--help` and figures.
4. Document in this README.
5. Wire in via a corresponding skill at `skills/<slug>/SKILL.md`.
