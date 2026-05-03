# Template: Data Understanding

Define what your data can answer, what it cannot, and the data boundaries that all subsequent modeling must respect.

## Dataset Inventory

| Dataset | Source | Version/Date | Unit | Modalities/Files | N | Owner/Notes |
|---|---|---|---|---|---:|---|
| `<dataset_name>` | `<path_or_source>` | `<version>` | `<unit>` | `<columns/files>` | `<n>` | `<notes>` |

## Data Dictionary

| Field | Dataset | Type | Meaning | Missing Rule | Encoding Rule | Use |
|---|---|---|---|---|---|---|
| `<field>` | `<dataset>` | `<continuous/categorical/text/image/etc>` | `<meaning>` | `<rule>` | `<rule>` | `<input/label/qc/exclude>` |

## Sample Unit and Linkage

- Sample unit:
- Primary ID:
- Cross-dataset linkage key:
- Duplicate handling:
- Repeated measurement handling:
- Multi-center or batch variables:

## Label Definition

| Label | Source | Definition | Positive Class | Negative Class | Conflict Rule |
|---|---|---|---|---|---|
| `<label>` | `<source>` | `<definition>` | `<positive>` | `<negative>` | `<rule>` |

Required checks:

- Label distribution:
- Missing labels:
- Label conflicts:
- Label leakage risk:
- Whether label was defined before model inspection:

## Cohort and Split

| Split | Purpose | N | Positive | Negative | Rule |
|---|---|---:|---:|---:|---|
| Train | Model fitting and internal CV | `<n>` | `<n>` | `<n>` | `<rule>` |
| Validation | Model selection if available | `<n>` | `<n>` | `<n>` | `<rule>` |
| Test | Final locked evaluation | `<n>` | `<n>` | `<n>` | `<rule>` |
| External | Generalization if available | `<n>` | `<n>` | `<n>` | `<rule>` |

Split principles:

- Stratification variable:
- Random seed:
- Grouping rule to avoid leakage:
- Time-based or site-based split if applicable:
- Whether test set is locked:

## Quality Control

| QC Item | Rule | Output | Status |
|---|---|---|---|
| Missingness | `<rule>` | `<file>` | `<done/todo>` |
| Outliers | `<rule>` | `<file>` | `<done/todo>` |
| Duplicates | `<rule>` | `<file>` | `<done/todo>` |
| File integrity | `<rule>` | `<file>` | `<done/todo>` |
| Label consistency | `<rule>` | `<file>` | `<done/todo>` |

## Derived Data Policy

- Raw data modification allowed: **No** (enforced by hook).
- Derived data output location: `data/derived/`
- Cleaning script:
- Data version file:
- Audit log:

## Data Understanding Conclusion

- Data supports:
- Data does not support:
- Main risks:
- Required actions before modeling:
