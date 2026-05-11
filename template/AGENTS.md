# [Your Domain] Knowledge Base — Schema

## Purpose

<!-- CUSTOMIZE: Replace this with a one-paragraph description of your knowledge domain. -->
<!-- Examples: "machine learning research", "19th-century literature", "competitive landscape for SaaS tools" -->
This is an LLM-maintained knowledge base on [YOUR TOPIC]. The LLM writes and maintains all files under `wiki/`. The human curates raw sources and directs queries. The human never edits wiki files directly.

## Directory Layout

- `raw/` — Immutable source documents (transcripts, articles, notes). Never modify these.
- `wiki/index.md` — Master catalog. Every wiki page must appear here.
- `wiki/log.md` — Append-only activity log.
- `wiki/summaries/` — One summary page per raw source document.
- `wiki/concepts/` — Concept, strategy, and framework pages.
- `wiki/entities/` — Entity pages (people, tools, organizations, products — whatever "things" exist in your domain).
- `wiki/syntheses/` — Comparison tables, decision frameworks, cross-cutting analyses.
- `wiki/journal/` — Research or session journal entries.
- `wiki/flashcards/` — One flashcard file per source wiki page, formatted for the [obsidian-spaced-repetition](https://github.com/st3v3nmw/obsidian-spaced-repetition) plugin. Populated by the Flashcards workflow.
- `wiki/presentations/` — Marp slide decks synthesized from wiki content. Populated by the Presentation workflow.

## File Naming

- All lowercase, hyphens for word separation: `concept-name.md`
- No spaces, no special characters, no uppercase
- Name should match the page title slug

## Page Format

Every wiki page uses this frontmatter and structure:

```yaml
---
title: "Page Title"
type: concept | entity | summary | synthesis | flashcards | presentation
tags: [tag1, tag2, tag3]
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources: ["raw/filename.txt"]
confidence: high | medium | low
---
```

### Required Sections by Page Type

**Summary pages** (`wiki/summaries/`):
- `## Key Points` — Bulleted list of main claims/ideas
- `## Relevant Concepts` — Links to concept pages this source touches
- `## Source Metadata` — Type of source, author/speaker, date, URL or identifier

**Concept pages** (`wiki/concepts/`):
- `## Definition` — One-paragraph plain-English definition
- `## How It Works` — Mechanics, process, or structure of the concept
- `## Key Parameters` — Important variables, dimensions, or factors
- `## When To Use` — Situations and contexts where this concept applies
- `## Risks & Pitfalls` — Known failure modes, common mistakes, limitations
- `## Related Concepts` — Wiki links to related pages
- `## Sources` — Which raw sources inform this page

**Entity pages** (`wiki/entities/`):
- `## Overview` — What this entity is
- `## Characteristics` — Key properties, attributes, structure
- `## Common Strategies` — Links to concept pages for strategies or methods associated with this entity
- `## Related Entities` — Links to related entity pages

**Synthesis pages** (`wiki/syntheses/`):
- `## Comparison` — Table or structured comparison
- `## Analysis` — Cross-cutting insights
- `## Recommendations` — When to prefer which approach
- `## Pages Compared` — Links to all pages involved

**Flashcard pages** (`wiki/flashcards/`):
- `tags:` frontmatter must include `flashcards` — the obsidian-spaced-repetition plugin uses this tag to discover cards
- `## Source` — Single wiki link back to the page these cards were derived from
- `## Cards` — The cards themselves, separated by blank lines, using the multi-line formats:
  - Basic: `Question` on one line, `?` on its own line, `Answer` on the next line
  - Reversed (term ↔ definition pairs that should drill both ways): `Question` / `??` / `Answer`
  - Cloze (fill-in-the-blank inside a sentence): wrap the hidden span in `==double-equals==`

**Presentation pages** (`wiki/presentations/`):
- Frontmatter must include `marp: true` plus `theme: default` and `paginate: true` (Marp configuration), in addition to the standard wiki frontmatter
- Slides are separated by `---` on its own line (standard Marp convention)
- `## Outline` slide near the top listing the sections of the deck
- `## References` slide at the end listing every cited wiki page as a wiki link

## Linking Conventions

- Use Obsidian-style wiki links: `[[concepts/concept-name]]`
- Always use relative paths from wiki root
- Every page must link to at least one other page (no orphans)
- When mentioning a concept that has a page, always link it

## Tagging Taxonomy

<!-- CUSTOMIZE: Replace these placeholder categories with tags relevant to your domain. -->
<!-- Each category should have 3-8 specific tags. -->
<!-- Example for a cooking KB: -->
<!--   Cuisine: italian, japanese, french, mexican -->
<!--   Technique: braising, fermenting, sous-vide, grilling -->
<!--   Ingredient: protein, vegetable, grain, dairy -->

- **Category-A**: `tag-1`, `tag-2`, `tag-3`
- **Category-B**: `tag-4`, `tag-5`, `tag-6`
- **Category-C**: `tag-7`, `tag-8`, `tag-9`
- **Scope**: `foundational`, `advanced`, `experimental`
- **Status**: `well-established`, `emerging`, `speculative`

## Confidence Levels

- **high** — Well-established idea, multiple corroborating sources, demonstrated with concrete examples
- **medium** — Supported by sources but limited examples or single-source
- **low** — Single mention, anecdotal, or speculative

## Workflows

### Ingest

When the user says "ingest [source]" or adds a file to `raw/`:

1. Read the raw source completely
2. Create `wiki/summaries/<source-slug>.md` with full summary
3. Identify all concepts, entities, and strategies mentioned
4. For each concept/entity: create the page if it doesn't exist, or update it with new information if it does
5. Add cross-links in both directions between all touched pages
6. Update `wiki/index.md` — add new entries, update summaries of changed pages
7. Append to `wiki/log.md` with timestamp, source name, pages created/updated
8. Flag any contradictions with existing wiki content

### Query

When the user asks a question:

1. Read `wiki/index.md` to find relevant pages
2. Read those pages
3. Synthesize an answer citing specific pages with wiki links
4. If the answer reveals new insight worth preserving:
   - Create a synthesis page in `wiki/syntheses/`
   - Update index and log

### Lint

When the user says "lint" or "health check":

1. Read all wiki pages
2. Check for: orphan pages (no inbound links), stale claims, contradictions between pages, missing cross-links, incomplete sections, low-confidence pages that could be strengthened
3. Fix what can be fixed automatically
4. Report issues that need human judgment
5. Suggest new sources or topics to investigate
6. Update log

Lint does **not** flag pages that lack a corresponding flashcard or presentation file — those workflows are explicit and on-demand.

### Flashcards

When the user says "flashcards [page]" — argument is a wiki page path such as `concepts/braising` or `entities/cast-iron-skillet`:

1. Read the source page in full
2. Derive cards from the page's content. For **concept pages**: pull from `## Definition`, `## How It Works`, `## Key Parameters`, `## When To Use`, and `## Risks & Pitfalls`. For **entity pages**: pull from `## Overview` and `## Characteristics`. For **summary pages**: pull from `## Key Points`.
3. Choose the right format for each card:
   - **Basic** (`Q` / `?` / `A`) — one-way recall (the default; use this for most cards)
   - **Reversed** (`Q` / `??` / `A`) — symmetric term ↔ definition pairs where the user should drill both directions
   - **Cloze** (`==hidden==`) — fill-in-the-blank inside a sentence; good for highlighting key terms in their natural context
4. Write `wiki/flashcards/<page-slug>.md` with frontmatter (`title`, `type: flashcards`, `tags: [flashcards, ...source-page-tags]`, `created`, `updated`, `sources: ["wiki/<path>"]`), a `## Source` section with a single wiki link to the source page, and a `## Cards` section containing the cards separated by blank lines
5. Add a cross-link back from the source page (a `## Flashcards` link line) so the source and cards stay discoverable from each other
6. Update `wiki/index.md` — add an entry under the Flashcards table
7. Append a dated entry to `wiki/log.md` recording the source page and cards file

The `flashcards` tag on the frontmatter is **required** — without it the obsidian-spaced-repetition plugin will not find the cards. Prefer rewriting an existing flashcards file over creating a new one if the source page is re-ingested.

### Presentation

When the user says "present [topic]" or "presentation [topic]" — argument is a topic or question, not a page path:

1. Read `wiki/index.md` to identify pages relevant to the topic (same retrieval as Query)
2. Read those pages in full
3. Generate a Marp slide deck with these slides, separated by `---` on its own line:
   - **Title slide** — `# <Topic>`, with a subtitle line summarizing the deck
   - **Outline slide** — `## Outline` followed by a bulleted list of sections
   - **Content slides** — one section per concept or entity, with the key claims pulled from the source pages. Keep each slide short (3–6 bullets or a single diagram/example)
   - **References slide** — `## References` followed by a wiki-link line for every page cited
4. Write `wiki/presentations/<topic-slug>.md` with Marp frontmatter (`marp: true`, `theme: default`, `paginate: true`) merged with the standard wiki frontmatter (`title`, `type: presentation`, `tags`, `created`, `updated`, `sources` listing every cited wiki page)
5. Update `wiki/index.md` — add an entry under the Presentations table
6. Append a dated entry to `wiki/log.md` recording the topic, deck path, and pages cited

If the wiki lacks enough material to build a coherent deck on the requested topic, say so and suggest sources that would fill the gap — do not invent claims. The Presentation workflow does **not** create a synthesis page; it only produces the deck.

## Rules

- Never modify files in `raw/`
- Always update `index.md` and `log.md` after any wiki change
- Prefer updating existing pages over creating duplicates
- When in doubt about a claim, set confidence to "low" and note the uncertainty
- Keep pages focused — one concept per page, split if a page gets too long
- Use plain English — define jargon on first use in each page
- All dates in ISO 8601 format: YYYY-MM-DD
- When a source provides specific examples, include them with concrete details
