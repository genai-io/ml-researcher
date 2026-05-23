# Small-sample medical reporting requirements

For a defensible small-N medical paper, the analysis report must include:

## Mandatory metrics

- **AUC** with **bootstrap 95% CI** (not just point estimate) — use [[bootstrap-ci]]
- **Sensitivity / Specificity** at a clinically motivated threshold (NOT the threshold that maximizes accuracy on test)
- **Calibration** — Brier score + reliability diagram (via [[calibration-check]])
- **DeLong's test** for AUC comparisons between models (via [[delong-test]])
- **Confidence interval overlap** for accuracy / F1 comparisons

## Mandatory sections

- **Data summary** — sample units, splits, label distribution, QC findings
- **Goal achievement** — for each promised metric, did we hit the criterion? No spin.
- **Model comparison** — all serious candidates × splits × metrics, with CI columns
- **Statistical tests** — paired tests where applicable
- **Limits** — small N, single-center, retrospective, label quality, calibration drift — **always include**
- **Conclusion** — one paragraph: what's supported, what isn't, what's next

## Common failures to avoid

- **Slice-level splits leaking patients across train/test** — most common small-sample bug (see `splits.md`)
- **Selecting threshold on test set** then reporting Sens/Spec at it
- **Training on test labels through tabular features** (e.g., MRI volume measurements that were used as labels)
- **Reporting train AUC alongside test AUC without CI** — looks impressive, says nothing
- **Switching to deep nets when boosted trees / TabPFN already work** — expensive, not better, harder to interpret

## Reference implementations

- nnU-Net: https://github.com/MIC-DKFZ/nnUNet
- MONAI: https://monai.io
- RadDINO: https://huggingface.co/microsoft/rad-dino
- TabPFNv2: https://github.com/PriorLabs/TabPFN
- DeLong test: `scripts/delong_test.py` in this project
