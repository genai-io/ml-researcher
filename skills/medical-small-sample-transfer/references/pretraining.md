# Pretraining choice for medical imaging

## Radiology (chest X-ray, CT, MRI)

In order of preference:

1. **RadDINO** (`microsoft/rad-dino`) — DINOv2-style pretraining on chest X-ray and similar; strongest small-sample feature extractor for radiology. License: research-only (verify for clinical use).
2. **MedSigLIP** (`google/medsiglip-...`) — multimodal medical CLIP-style. Good for image-text retrieval and classification.
3. **BiomedCLIP** (`microsoft/BiomedCLIP-PubMedBERT_256-vit_base_patch16_224`) — CLIP-style on PubMed images. Older but well-tested.
4. **MedGemma-4B / 27B** (`google/medgemma-...`, July 2025) — multimodal medical foundation models. Good for QA-style tasks.
5. **DINOv2 / DINOv3** (`facebook/dinov2-large` etc.) — generic foundation; often beats medical-specific on linear probe at very small N.
6. **nnU-Net v2** — for segmentation tasks specifically (not classification).

## Other medical modalities (substitute the domain foundation)

| Modality | Foundation candidates |
|---|---|
| Pathology | PathDINO, UNI, Phikon, Virchow |
| Dermatology | DERM-VFM, MoCo-derm |
| Ophthalmology (fundus / OCT) | RetinaFM, RETFound |
| Endoscopy | Endo-FM, EndoVFM |

Verify each via `paper-search` for `last_verified` freshness before recommending.

## Selection heuristic

| Sample regime | Strategy |
|---|---|
| n ≤ 100 | Linear probe on frozen foundation features only |
| 100 < n ≤ 500 | Linear probe + LoRA fine-tune top 2-4 blocks |
| n > 500 | Full fine-tune with LR schedule + augmentation |

Always cite the checkpoint with revision pin: `microsoft/rad-dino@<sha>`, not the bare name.
