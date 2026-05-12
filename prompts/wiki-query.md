---
description: Query the wiki and synthesize an answer
argument-hint: "<question>"
---
Read `AGENTS.md` and follow the **Query** workflow to answer: $@

Steps (from AGENTS.md):
1. Read `wiki/index.md` to find pages relevant to the question.
2. Read those pages in full.
3. Synthesize an answer that cites specific pages using `[[concepts/...]]`-style wiki links.
4. If the answer reveals a novel cross-cutting insight worth preserving:
   - Create a synthesis page in `wiki/syntheses/` with the required frontmatter and `## Comparison`, `## Analysis`, `## Recommendations`, `## Pages Compared` sections.
   - Update `wiki/index.md` with the new synthesis page.
   - Append an entry to `wiki/log.md`.

If the wiki lacks the information to answer well, say so explicitly and suggest which raw sources would fill the gap — do not invent claims.
