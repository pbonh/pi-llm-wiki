---
description: Generate obsidian-spaced-repetition flashcards from a wiki page
argument-hint: "<wiki-page-path>"
---
Read `AGENTS.md` and follow the **Flashcards** workflow for the page at `$1`.

Steps (from AGENTS.md):
1. Read the source page at `$1` completely.
2. Derive cards from the page's content:
   - Concept pages: `## Definition`, `## How It Works`, `## Key Parameters`, `## When To Use`, `## Risks & Pitfalls`.
   - Entity pages: `## Overview`, `## Characteristics`.
   - Summary pages: `## Key Points`.
3. Choose a format for each card:
   - Basic (`Q\n?\nA`) for one-way recall — the default.
   - Reversed (`Q\n??\nA`) for symmetric term ↔ definition pairs that should drill both ways.
   - Cloze (`==hidden==`) for fill-in-the-blank inside a natural-language sentence.
4. Write `wiki/flashcards/<page-slug>.md` with the required frontmatter (`type: flashcards`, and the `tags:` list MUST include `flashcards`), a `## Source` section with a single `[[wiki/...]]` link to the source page, and a `## Cards` section with the cards separated by blank lines.
5. Add a `## Flashcards` link on the source page pointing back to the new cards file so the two stay discoverable from each other.
6. Update `wiki/index.md` — add an entry under the Flashcards table.
7. Append a dated entry to `wiki/log.md` recording the source page and cards file.

Rules:
- Never modify files in `raw/`.
- The frontmatter `tags:` list MUST contain `flashcards` — without it the obsidian-spaced-repetition plugin will not find the cards.
- Prefer rewriting an existing `wiki/flashcards/<page-slug>.md` over creating a new one if the source page is re-ingested.
- Use ISO 8601 dates (YYYY-MM-DD).
- Do not invent facts the source page does not contain.
