---
name: citation-graph
description: Traverse the citation graph from a seed arxiv id — outgoing (papers this one cites) or incoming (papers citing this one). Wraps scripts/citation_graph.py (Semantic Scholar API). Use for "what did X build on" / "who used X downstream" / "find recent work applying X to setting Y".
allowed-tools: Bash Read WebFetch
---

# When to use

- After `paper-read` on a landmark paper, to find recent downstream applications (`direction=in`).
- To check whether a method has been validated by independent groups (`direction=in` with `limit=20`).
- To trace a method back to its original formulation (`direction=out`).
- When you suspect a paper is part of a chain: e.g., DINO → DINOv2 → DINOv3 → RadDINO.

Do NOT use as a substitute for `paper-search` — citation-graph requires a known seed paper.

# Steps

1. **Identify the seed**. Must be an arxiv id (e.g., `2304.07193` for DINOv2) or a Semantic Scholar paper id.

2. **Pick direction**:
   - `out` — papers that the seed cites (look backward into prior art)
   - `in` — papers that cite the seed (look forward into downstream work)

3. **Pick depth + limit**. Default `depth=1, limit=20`. Going deeper (`depth=2`) grows results combinatorially — only do it for narrow surveys.

4. **Invoke**:

   ```bash
   python scripts/citation_graph.py \
     --seed 2304.07193 \
     --direction in \
     --depth 1 \
     --limit 20 \
     --since 2024-06-01
   ```

5. **Parse output** — one JSON object per neighbor:

   ```json
   {"arxiv_id": "2410.12345", "title": "...", "year": 2024, "venue": "NeurIPS", "citations": 8, "edge": "cites_seed", "snippet": "We adapt DINOv2 to medical imaging by ..."}
   ```

6. **Filter and rank**:
   - Drop results > 5 years old in fast-moving subfields unless they are the seed's *parents* (direction=out).
   - Prefer venue-published over preprint when both are available.
   - Up-weight results whose `snippet` mentions the user's regime (modality, sample size).

7. **Return top N** (default 8) to the calling agent. For each, one-line relevance to the seed.

# Hard rules

- Cap `depth` at 2. Depth-3 returns hundreds of papers and breaks the agent's context.
- Cap `limit` at 50 per call.
- Cite the exact edge type (`cites_seed` vs `cited_by_seed`) so the user can verify.
- If the seed is unknown to Semantic Scholar, the script exits 4. Tell the user the seed needs an arxiv id (not a private URL).

# Script contract

`scripts/citation_graph.py` accepts:

| Flag | Meaning | Default |
|---|---|---|
| `--seed <id>` | arxiv id or S2 paper id | required |
| `--direction <in\|out>` | citation direction | `in` |
| `--depth <n>` | hops from seed | 1 |
| `--limit <n>` | max results | 20 |
| `--since <YYYY-MM-DD>` | minimum publication date | none |
| `--api-key <key>` | optional S2 API key (rate-limit relief) | env `S2_API_KEY` |

Output: JSONL on stdout, one neighbor per line. Stderr for rate-limit warnings.

Exit codes: `0` success, `4` seed not found, `5` rate-limited.

# Fallback

If the script is unavailable or rate-limited, `WebFetch` Semantic Scholar's public paper page (`https://www.semanticscholar.org/paper/<paper-id>`) and extract the "Cited by" / "References" tabs by hand. Quality is lower; mark results `"verified": false`.

# Related skills

See [[paper-search]] for entering the literature without a seed. See [[paper-read]] for going deep on any neighbor that survives ranking.
