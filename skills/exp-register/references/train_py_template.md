# train.py — minimal stub

When no parent experiment exists, seed `experiments/EXP<id>_<name>/train.py` with this stub. It follows the metric-printing convention (one `<key>: <value>` per line) that `metric-grep` depends on.

```python
#!/usr/bin/env python3
"""EXP<id>: <one-line motivation>"""
import argparse, json
# TODO: import your model, dataset, metrics


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--epochs", type=int, default=10)
    args = parser.parse_args()

    # TODO: train and eval
    metrics = {
        "val_auc": 0.0,
        "peak_vram_mb": 0,
        "duration_seconds": 0,
    }

    # Print metrics in the ml-researcher convention: one key per line
    for k, v in metrics.items():
        print(f"{k}: {v}")

    with open("metrics.json", "w") as f:
        json.dump(metrics, f, indent=2)


if __name__ == "__main__":
    main()
```

## Why this exact shape

- **`<key>: <value>` per line** — the `metric-grep` skill greps `^<key>:` (anchored, first match). Other formats silently break the Train Loop.
- **`metrics.json` written at end** — analyst reads this for the model-comparison table. Always write it, even on partial runs.
- **`--seed` flag with default 42** — `repro-seal` records the seeds, but they must be present in the script to be recorded.
- **No package imports in the stub** — keeps registration fast; the user fills imports when editing.
