---
description: Ingest a raw source into the wiki
argument-hint: "<path-to-raw-file>"
---
Read `AGENTS.md` and follow the **Ingest** workflow for the source at `$1`.

Steps (from AGENTS.md):
1. Read the source at `$1` completely.
2. Create `wiki/summaries/<source-slug>.md` with the required frontmatter and `## Key Points`, `## Relevant Concepts`, `## Source Metadata` sections.
3. Identify every concept, entity, strategy, and framework mentioned. For each: create the page if it doesn't exist, or update it if it does.
4. Add bidirectional cross-links between all touched pages using `[[concepts/...]]`-style Obsidian links.
5. Update `wiki/index.md` — new entries for created pages, refreshed entries for updated pages.
6. Append a dated entry to `wiki/log.md` recording the source, pages created, and pages updated.
7. Flag any contradictions with existing wiki content in the log entry.

Rules:
- Never modify files in `raw/`.
- Prefer updating existing pages over creating duplicates.
- When uncertain about a claim, set `confidence: low` and note the uncertainty.
- Use ISO 8601 dates (YYYY-MM-DD).
