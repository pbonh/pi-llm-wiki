---
description: Generate a Marp slide deck from wiki content on a topic
argument-hint: "<topic-or-question>"
---
Read `AGENTS.md` and follow the **Presentation** workflow for the topic: $@

Steps (from AGENTS.md):
1. Read `wiki/index.md` and find the pages relevant to the topic (same retrieval as the Query workflow).
2. Read those pages in full.
3. Build the deck slide-by-slide, with each slide separated by `---` on its own line:
   - Title slide: `# <Topic>` plus a one-line subtitle summarizing the deck.
   - Outline slide: `## Outline` with a bulleted list of section titles.
   - Content slides: one section per concept/entity, key claims pulled from source pages. Keep each slide short — 3–6 bullets or a single example.
   - References slide: `## References` followed by a `[[wiki/...]]` link for every cited page.
4. Write `wiki/presentations/<topic-slug>.md` with Marp frontmatter (`marp: true`, `theme: default`, `paginate: true`) merged with the standard wiki frontmatter (`title`, `type: presentation`, `tags`, `created`, `updated`, `sources` listing every cited page).
5. Update `wiki/index.md` — add an entry under the Presentations table.
6. Append a dated entry to `wiki/log.md` recording the topic, deck path, and pages cited.

Rules:
- `marp: true` in frontmatter is mandatory; without it the file will not render as a deck.
- Every page cited in the body MUST appear on the References slide as a `[[wiki/...]]` link.
- Do not invent claims. If the wiki lacks enough material for a coherent deck, say so and suggest which sources would fill the gap.
- Do not create a synthesis page — the Presentation workflow only produces the deck.
- Use ISO 8601 dates (YYYY-MM-DD).
