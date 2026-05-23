---
name: paper-read
description: Read a paper's methodology section (and ablations, if present), extract recipe and key numbers faithfully, and write a structured notes file to papers/notes/<arxiv_id>.md. Wraps scripts/paper_read.py (PDF parsing); falls back to WebFetch + manual extraction. Never paraphrase equations or invent table rows. Notes template in references/notes_template.md.
allowed-tools: Bash Read Write WebFetch
---

# When to use

- After `paper-search` returns a shortlist; literature picks the top 1-3 and runs paper-read on each.
- When the user says "what does paper X say about Y" — read the paper, don't guess.
- Before adding a method to `papers/shortlist.md` Active section: notes must exist.

Do NOT use to skim abstracts (paper-search already returns abstracts). paper-read is for methodology depth.

# Steps

1. **Identify the paper** — arxiv id, URL, or HF Papers id.

2. **Invoke**:

   ```bash
   python scripts/paper_read.py \
     --arxiv-id 2410.12345 \
     --sections methodology,experiments,ablations \
     --out papers/notes/2410.12345.md
   ```

3. **Fill the notes template** with the required fields: method, training setup, pretraining data + scale, downstream eval, key numbers, ablations, caveats. Template: `references/notes_template.md`.

4. **Cite faithfully.** Equations / hyperparameters appear as in the paper — no rephrasing, no rounded numbers. Use `(Eq. 3)` / `(Table 2, row 4)` for traceability. Rules: `references/extraction_rules.md`.

5. **Update `papers/shortlist.md`** — append (don't overwrite) the paper's entry to the Active section using the format in [[literature]]'s spec.

# Fallback when the script is unavailable

If `scripts/paper_read.py` doesn't exist, fall back to `WebFetch` on the arxiv abstract page + linked PDF. Mark sections you couldn't read as `[unreadable]` rather than guessing.

# Hard rules

- **Never invent equation numbers, table rows, or hyperparameters.** If you can't find a value, write `[not reported]`, never an estimate.
- **Verbatim quoting for claims**: a "3.2 AUC improvement" claim requires that exact number and metric in the paper, with table cited.
- **One paper, one notes file.** Don't merge.
- **No abstract-only conclusions.** Mark `[needs verification]` and do not promote to shortlist Active.
- The notes file is append-mostly — re-reads should extend, not rewrite history.

# Script contract

`scripts/paper_read.py`:

| Flag | Meaning | Default |
|---|---|---|
| `--arxiv-id <id>` | arxiv id (e.g., `2410.12345`) | one of `--arxiv-id` / `--url` required |
| `--url <url>` | direct PDF / abstract URL | — |
| `--sections <list>` | comma-separated section names | `methodology,experiments` |
| `--out <path>` | output notes file | `papers/notes/<arxiv_id>.md` |
| `--max-pages <n>` | cap pages parsed (cost guard) | 40 |

Output: writes the notes file. Prints `WROTE <path>` on stdout. Errors on stderr.

# Related

See [[paper-search]] for finding candidates. See [[citation-graph]] for tracing forward citations after a landmark read.
