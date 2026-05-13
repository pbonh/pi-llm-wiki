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
5. **Verify zero dangling links — acceptance gate.** Before declaring done, list every `[[...]]` link you wrote across every page you created or updated. For each link, confirm the target file exists on disk (`ls wiki/<path>.md`). For each dangling link, either (a) create the missing page now with full frontmatter and the required sections for its type (even a stub is fine if the source only mentions the concept in passing — set `confidence: low`), or (b) remove the link from the citing page when the source genuinely does not support a page. Re-run the scan until it returns zero dangling links. Do not skip this step — a summary that cites pages which don't exist is a workflow failure.
6. Update `wiki/index.md` — new entries for created pages, refreshed entries for updated pages.
7. Append a dated entry to `wiki/log.md` recording the source, pages created, and pages updated.
8. Flag any contradictions with existing wiki content in the log entry.

Rules:
- Never modify files in `raw/`.
- Prefer updating existing pages over creating duplicates.
- When uncertain about a claim, set `confidence: low` and note the uncertainty.
- Use ISO 8601 dates (YYYY-MM-DD).
- Every `[[wiki-link]]` you write must resolve to an existing file by the end of the run. No exceptions.
