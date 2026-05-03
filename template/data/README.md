# Data — {{TOPIC}}

## Layout

| Subdir | Purpose | Mutable? |
|---|---|---|
| `raw/` | Original, untouched data | **No** (hook-protected) |
| `derived/` | Cleaned, encoded, feature-extracted data | Yes |
| `splits/` | Train/val/test split manifests; test set is **locked** | Test split read-only during Selection/Tuning |

## Conventions

- All transformations from `raw/` to `derived/` must be reproducible from a script in `scripts/` or in a notebook with seed set.
- Data version is captured in `derived/<filename>.json` sidecar OR in the file's git hash.
- Splits are created once at project init or in a deliberate Data Understanding update; do NOT re-randomize after locking.

## Notes for {{TOPIC}}

(Fill in dataset-specific notes here — sources, citations, license, access controls.)

## Files

(populate as data lands)
