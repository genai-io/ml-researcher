# Paper-search — picking the source

| Source | Strengths | When to use | When NOT to use |
|---|---|---|---|
| `arxiv` | Broadest preprint coverage; daily updates; methodology disclosed | Default first choice; recent ML work | Closed-access journal-only papers |
| `hf_papers` | Curated multimodal / open-weights focus; HF community votes | Recent multimodal / open-source LLM / VLM work | Older papers or non-trending niches |
| `semantic_scholar` | Citation graph; venue metadata; older paper recall | Building citation context; finding the original formulation of a method | Bleeding-edge work (S2 indexing lags 1-2 weeks) |
| `paperswithcode` | SOTA tables; benchmark-keyed | "What's SOTA on dataset X" / "best result on benchmark Y" | Methodology-heavy queries (PWC is benchmark-first) |

## Chaining

Common patterns:

1. **Find landmark → forward citations**: `arxiv` to find the landmark, then [[citation-graph]] with `direction=in` for downstream work.
2. **Find SOTA → read methodology**: `paperswithcode` to find the top result, then [[paper-read]] on the paper.
3. **Build technique survey**: `arxiv` with broad query, then narrow with `--venue NeurIPS` or `--since YYYY-MM-DD`.

## Query-building tips

- **Specific over general**: "RadDINO chest X-ray fine-tune" beats "medical foundation model".
- **Include the constraint**: "small sample" / "few-shot" / "low resource" sharply narrows results.
- **One method + one task**: don't combine multiple method families in one query — search them separately and de-duplicate.
- **Date filtering**: in fast-moving subfields (LLM agents, multimodal), `--since` is usually more valuable than a tighter query.

## Anti-patterns

- Using paper-search as a question-answering tool ("what is contrastive learning") — use a textbook or a survey paper read end-to-end instead.
- Searching one source and stopping. If you got <3 relevant results from `arxiv`, try `semantic_scholar` next.
- Using `--limit 50+` "to be thorough". The top-10 from a good query beat the top-50 from a vague one.
