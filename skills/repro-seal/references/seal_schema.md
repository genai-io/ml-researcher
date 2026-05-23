# Repro-seal JSON schema

The seal is a single JSON object written to `experiments/<exp_id>/repro_seal.json`.

## Full example

```json
{
  "exp_id": "EXP003_combined-linear-svm",
  "sealed_at": "2026-05-23T15:14:33+08:00",
  "code": {
    "git_sha": "39ac9ee",
    "branch": "mlr/exp/EXP003_combined-linear-svm",
    "dirty": false,
    "untracked_count": 0
  },
  "python": {
    "version": "3.11.7",
    "executable": "/Users/.../venv/bin/python",
    "packages_hash": "sha256:c1d3...",
    "packages_file": "experiments/EXP003_combined-linear-svm/repro/requirements.txt"
  },
  "cuda": {
    "available": true,
    "version": "12.2",
    "device_count": 1,
    "device_names": ["NVIDIA A10G"]
  },
  "data": {
    "splits": {
      "train": "sha256:9a4f...",
      "val": "sha256:1b22...",
      "test": "sha256:7e31..."
    },
    "splits_locked": true,
    "manifest": "data/splits/MANIFEST.json"
  },
  "seeds": {
    "python": 42,
    "numpy": 42,
    "torch": 42,
    "torch_cudnn_deterministic": true
  }
}
```

## Field meanings

| Field | Type | Meaning |
|---|---|---|
| `exp_id` | string | Experiment directory name |
| `sealed_at` | ISO 8601 string | When the seal was generated |
| `code.git_sha` | string | Short sha of HEAD at sealing time |
| `code.dirty` | bool | True if working tree has uncommitted changes |
| `code.untracked_count` | int | Untracked files (not gitignored) |
| `python.packages_hash` | string | sha256 of frozen requirements file |
| `python.packages_file` | string | Path to the frozen requirements |
| `cuda.available` | bool | False if no GPU detected |
| `data.splits.*` | string | sha256 of each split directory (or manifest stored hash) |
| `data.splits_locked` | bool | True iff `MANIFEST.json` exists and matches |
| `seeds.torch_cudnn_deterministic` | bool | True iff `torch.backends.cudnn.deterministic = True` was set |

## Companion file

`repro/requirements.txt` sits next to the seal. It's a frozen package list (output of `pip freeze` or `uv export`). The seal's `packages_hash` is the sha256 of this file. Do not edit the requirements file by hand — re-seal instead.

## Drift detection

`--verify` compares the current environment against a stored seal and exits `6` with a diff if any field changed. The diff is human-readable:

```
DRIFT
- python.version: 3.11.7 → 3.11.10
- packages.torch: 2.3.1 → 2.4.0
- data.splits.val: sha256:1b22... → sha256:8f44...
```

The data-split drift is the most serious — it means the val set's contents changed since the seal, which invalidates any metric computed against that seal.
