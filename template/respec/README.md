# Research Spec Templates

`respec/` holds the methodology constitution and templates.

| File | Role |
|---|---|
| [`respec.md`](respec.md) | Methodology + lifecycle + 10 core principles |
| [`init.md`](init.md) | Project initialization protocol + update rules |
| [`01_data_understanding.md`](01_data_understanding.md) | Data inventory, splits, QC template |
| [`02_research_goal.md`](02_research_goal.md) | Question, metric, baseline, success template |
| [`03_model_selection.md`](03_model_selection.md) | Lateral candidate comparison template |
| [`04_fine_tuning.md`](04_fine_tuning.md) | Bounded tuning template |
| [`05_analysis_report.md`](05_analysis_report.md) | Final report template |
| [`iteration_trace.md`](iteration_trace.md) | Per-experiment audit log template |
| [`progress.md`](progress.md) | Project state record template |

## Read order

1. `respec.md`
2. `init.md`
3. `01_data_understanding.md` → `05_analysis_report.md`
4. `iteration_trace.md` and `progress.md`

## Usage

These are templates. **Do not fill them in here.** Copy each into `research/<same_name>.md` and fill the project's actual content there. The agent's `phase-advance` skill checks for the filled `research/*.md` files, not for these templates.

The `init.sh` script already created stub `research/*.md` files based on these templates.
