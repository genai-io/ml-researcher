# Experiments — {{TOPIC}}

Each experiment lives in `EXPxxx_<name>/` and contains everything needed to reproduce it.

## Layout

```
experiments/
├── README.md         (this file)
├── ledger.tsv        machine-readable log of every trial
└── EXPxxx_<name>/
    ├── README.md     motivation, parent, hypothesis
    ├── train.py      the training script (the editable file in the Train Loop)
    ├── config.yaml   hyperparameters and config
    ├── run.log       stdout+stderr (do not commit if huge)
    ├── metrics.json  parsed metrics
    ├── figures/      experiment-specific figures
    └── artifacts/    model files, predictions, intermediate outputs
```

## ledger.tsv

Tab-separated, append-only log of every trial. Schema:

```
exp_id    commit    primary_metric    metric_value    status    description    secondary_metrics_json
```

Status values: `registered` | `keep` | `discard` | `crash`.

The `experimenter` subagent appends rows; humans usually don't edit it directly. To inspect: `/exp list` or `cat ledger.tsv`.

## Conventions

- Each experiment has a git branch: `mlr/exp/EXPxxx_<name>`.
- The Train Loop advances or resets the branch on each trial.
- The branch tip after the loop = the best version of that experiment.
- The full attempt history (including discards) is in `ledger.tsv`.
