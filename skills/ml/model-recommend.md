---
name: model-recommend
description: Recommend ML models from data/model_registry.yaml given a task, n_samples, modality, and constraints. Returns 5-10 candidates with pros/cons, hyperparameters, and last-verified date. Use whenever the user asks "what model should I use" or you need to propose an architecture.
allowed-tools: Read, Grep
---

# Steps

1. **Read the registry**: `Read data/model_registry.yaml` (project root). If absent, fall back to ml-researcher's source registry — look in `<config-dir>/skills/ml/../../../data/model_registry.yaml` or note that the project lacks the registry.

2. **Identify constraints from the user's question**:
   - `task` — image_classification, object_detection, segmentation, vlm, medical_imaging, tabular, time_series, embedding, generation, asr, ...
   - `n_samples` — extract from the question (e.g., "270 cases" → 270)
   - `modality` — vision, text, audio, multimodal, tabular
   - `constraints` — license requirements, max params, edge deployment, etc.

3. **Filter the registry** by:
   - `task` matches (exact or related — e.g., user says "tumor classification" → task=medical_imaging OR image_classification)
   - `min_data.fine_tune <= n_samples` if the user is fine-tuning
   - `min_data.linear_probe <= n_samples` if linear probe is acceptable
   - any explicit constraint

4. **Rank by relevance** to the user's specific situation (sample regime, domain match, license fit).

5. **Format output** — for each of the top 5-10 candidates:

   ```
   - **{id}** — {pros[0]}; needs {min_data.fine_tune}+ samples; license: {license}
     Verified {last_verified}. {sota_tracker URL if known}.
     Pros: {pros joined by "; "}
     Cons: {cons joined by "; "}
     Reference: {reference_impl}
   ```

6. **Freshness flag**: if `last_verified` is more than 90 days ago (compare to today's date), prefix with `[STALE]`. Tell the user the entry hasn't been re-verified recently and suggest cross-checking with `paper-search` or HF Hub.

7. **End with one explicit recommendation**: based on the constraints, which candidate would you actually use? One sentence.

# Example

User: "I have 270 MRI cases for tumor purity prediction"

You:
1. Read registry.
2. Constraints: task=medical_imaging, modality=vision, n_samples=270, fine-tune mode.
3. Filter to medical-imaging entries with `min_data.fine_tune <= 270`.
4. Rank by fit: RadDINO > MedSigLIP > BiomedCLIP > MedGemma-4B > nnU-Net (if segmentation).
5. Format and present.
6. Recommend: "RadDINO is the strongest pretraining for radiology with limited data; combine with a tabular model (TabPFNv2) for clinical features and use late fusion. Verify dataset format with `dataset-inspect` before training."

# Notes

- Never recommend a model that's not in the registry as if it's vetted. If the registry lacks an entry, say so and offer to look it up via `paper-search`.
- Always include `last_verified`. The user should know freshness.
- Prefer permissive licenses unless the user asks for something else.
