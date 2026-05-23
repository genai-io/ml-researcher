---
name: paper-search
description: Search arxiv / HuggingFace Papers / Semantic Scholar / paperswithcode for papers matching a query. Wraps scripts/paper_search.py; falls back to WebSearch + WebFetch when the script is unavailable. Returns a ranked list of candidates. Source-picking guidance in references/sources.md.
allowed-tools: Bash Read WebSearch WebFetch
---

# When to use

- Literature agent's first move after restating the user's problem.
- Modeler agent when the registry returns no candidates for the user's regime.
- Anytime an agent says "what does the recent literature say about X" — never invent answers from memory.

Do NOT use as a substitute for reading the methodology section. paper-search returns *what exists*; the agent still needs `paper-read` for any candidate it shortlists.

# Steps

1. **Build the query.** 2-4 terms: task + modality + method family + constraint. Avoid stop-words; avoid >5 terms (recall drops).

2. **Pick the source** (default `arxiv`). Per-source guidance: `references/sources.md`.

3. **Invoke**:

   ```bash
   python scripts/paper_search.py \
     --query "MRI tumor classification small sample transfer learning" \
     --source arxiv \
     --since 2024-01-01 \
     --limit 15
   ```

4. **Parse output** — one JSON object per result on stdout:

   ```json
   {"arxiv_id": "2410.12345", "title": "...", "authors": ["..."], "abstract": "...", "url": "https://arxiv.org/abs/2410.12345", "venue": "NeurIPS 2024", "citations": 18}
   ```

5. **Rank by relevance** to the user's regime. Down-weight: surveys (unless requested), older papers in fast-moving subfields, papers with no methodology disclosed.

6. **Return top N (default 5)** with one-sentence relevance per item. Do NOT dump abstracts — the agent's next step is `paper-read` on the top 1-3.

# Fallback when the script is unavailable

If `scripts/paper_search.py` doesn't exist, fall back to WebSearch with site-restricted queries:

```
site:arxiv.org "MRI tumor classification" "small sample" 2024..2026
```

Then `WebFetch` arxiv abstract pages for the top results. Report in the same JSON-like shape so callers don't branch on backend.

# Hard rules

- Cite the exact arxiv id and URL. Never paraphrase a title or invent an id.
- Prefer papers ≤ 18 months old for fast-moving subfields; ≤ 5 years for stable subfields.
- If a result has no abstract or no methodology section, mark it `"abstract_only": true` and de-prioritize.
- Do not exceed `--limit 25`. Larger result sets dilute relevance and bloat agent context.

# Script contract

`scripts/paper_search.py`:

| Flag | Meaning | Default |
|---|---|---|
| `--query <str>` | search query | required |
| `--source <name>` | `arxiv`, `hf_papers`, `semantic_scholar`, `paperswithcode` | `arxiv` |
| `--since <YYYY-MM-DD>` | minimum publication date | none |
| `--venue <str>` | venue filter (e.g., "NeurIPS") | none |
| `--limit <n>` | max results | 10 |

Output: JSONL on stdout, one result per line. Errors on stderr.

# Related

Chain into [[paper-read]] for the shortlist. Use [[citation-graph]] when you have a landmark paper and want to traverse downstream work.
