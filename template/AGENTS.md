<!-- CUSTOMIZE: Replace [Your Domain] with a short title for this knowledge base (e.g. "Machine Learning", "19th-Century Literature", "SaaS Competitive Landscape"). -->
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
- `wiki/books/` — Long-form mdBook renderings of source PDFs. Each book is its own directory (`wiki/books/<slug>/`) with `book.toml`, `src/SUMMARY.md`, chapter files, and `src/images/`. Populated by the PDF → mdBook workflow.

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

**Book directories** (`wiki/books/<slug>/`):
- A complete, runnable [mdBook](https://rust-lang.github.io/mdBook/) project, not a single markdown file.
- Required files: `book.toml` (mdBook config), `src/SUMMARY.md` (chapter list), one markdown file per chapter under `src/`, optional `src/images/` for figures.
- `src/SUMMARY.md` follows mdBook syntax strictly: chapters as `- [Title](path.md)`, two-space indent for sub-chapters, `# Part Title` for parts, `---` on its own line for separators. mdBook will refuse to build if this file is malformed.
- Each chapter file starts with a single `# Chapter Title` H1 matching its `SUMMARY.md` entry; sub-sections use `##`/`###`.
- Discoverability comes from the `## Books` row in `wiki/index.md`, which links directly to `[[books/<slug>/src/SUMMARY|<Title>]]`. The PDF → mdBook workflow does **not** produce a paired `wiki/summaries/<slug>.md`; if a summary or concept extraction is wanted, the user invokes the Ingest workflow separately on the source PDF or the rendered book.

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
6. **Verify zero dangling links — acceptance gate.** Before declaring the ingest complete, scan every page you created or updated and list every `[[...]]` reference. For each link, confirm the target file exists on disk. For each dangling link, either (a) create the missing page now with the full schema for its type (a stub with frontmatter + required sections is fine if the source only mentions the concept in passing — set `confidence: low` and note the source mention), or (b) remove the link from the citing page when the source genuinely does not support a standalone page. Re-run the scan until it returns zero dangling links. A summary that cites pages which do not exist is a workflow failure, not a partial success. Every `[[wiki-link]]` you write must resolve to a real file by the end of the run.
7. Update `wiki/index.md` — add new entries, update summaries of changed pages
8. Append to `wiki/log.md` with timestamp, source name, pages created/updated
9. Flag any contradictions with existing wiki content

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

### PDF → mdBook

When the user says "pdfbook [path]" or runs `/pdf-to-mdbook <path>` — argument is a path to a PDF, typically under `raw/` but any readable path is allowed.

The goal is to convert a single PDF (scanned, structured, textbook, or research paper) into a faithful, runnable mdBook under `wiki/books/<slug>/`. The chapter/section hierarchy must match the real source. **Do not invent chapters or content the PDF does not contain.**

**Scope: conversion only.** This workflow does NOT ingest the book's content into the wiki graph. It does not write `wiki/summaries/<slug>.md`, does not create concept or entity pages, and does not produce `Relevant Concepts` cross-links. Its only wiki-graph touchpoints are a row in the `## Books` table of `wiki/index.md` and a `wiki/log.md` entry — both of which merely record that the book exists. If the user wants the book ingested into the knowledge graph (concepts extracted, entities cross-linked, syntheses drawn), they will invoke the Ingest workflow separately afterwards on the source PDF or the rendered book. Treat conversion and ingestion as independent — running PDF → mdBook never implies running Ingest.

**Required tooling on PATH** (fail fast with `brew install poppler ocrmypdf tesseract mdbook` if any are missing):

- `pdfinfo`, `pdftotext`, `pdftoppm`, `pdfimages` (poppler)
- `ocrmypdf` and `tesseract`
- `mdbook`
- `python3` with `pypdf` (used only to read the embedded outline; fall back to vision if absent)

Optional, used if present: `marker` or `docling` for higher-fidelity extraction on textbooks and papers. Never add these as hard dependencies.

Steps:

1. **Resolve inputs.** Compute `slug` from the PDF filename (lowercase, hyphenated, no extension). Choose `wiki/books/<slug>/` as the output dir. If it already exists, treat this as a re-run and overwrite chapter files rather than duplicating.

2. **Classify the PDF.** Sample text from the first ~5 pages with `pdftotext -layout -f 1 -l 5 <pdf> -` and count alphabetic characters. If the sample is sparse (≲ 100 alpha chars per page on average), treat the PDF as scanned.

3. **OCR when needed (automatic, no confirmation).** For scanned PDFs, run `ocrmypdf --skip-text --output-type pdf --rotate-pages --deskew <input.pdf> <work>/ocr.pdf`. This is expected to be slow on 500+ page books — let it run. Use the OCRed PDF as the working source for all subsequent steps.

4. **Extract reference text.** Run `pdftotext -layout <work>/source.pdf <work>/text-layout.txt` and `pdftotext <work>/source.pdf <work>/text-flow.txt`. Keep both as *reference material* for the vision pass — they help disambiguate hard-to-read characters, technical identifiers, citations, and long URLs. They are **not** the primary source of chapter content. `pdftotext` consistently fails on two-column research papers (it interleaves columns), on scanned PDFs after OCR (artefact noise), on figure-heavy textbook pages (vector-figure labels bleed into prose), and on math-heavy content (operators and superscripts are lost). Treat the extracted text as advisory only.

5. **Extract images.** Run `pdfimages -all <work>/source.pdf <work>/img/fig` and copy the result into `wiki/books/<slug>/src/images/`. Keep a manifest mapping image file → originating page so figure references in chapters can point to the right file.

6. **Recover structure — this is the critical step.** Spend tokens generously here.
   1. Try the embedded outline first:
      ```bash
      python3 -c "import pypdf,sys,json; r=pypdf.PdfReader(sys.argv[1]); \
      def w(it,d=0,o=[]):
       for x in it:
        if isinstance(x,list): w(x,d+1,o)
        else: o.append({'depth':d,'title':getattr(x,'title','')})
       return o\nprint(json.dumps(w(r.outline)))" <pdf>
      ```
      (Run it as a heredoc or short script — the example is schematic.) Reject the outline if it is empty, if titles look like filenames (e.g. `00.pdf`, `chapter01.pdf`), or if the depth-1 entries clearly do not correspond to chapters.
   2. **Vision-based structure extraction** when the outline is missing or unreliable. Render representative pages with `pdftoppm -png -r 150 <work>/source.pdf <work>/pages/p` and read those PNGs as images. Cover at minimum: the table of contents pages (when present), the first page of every plausible chapter (detect by skimming page thumbnails at lower DPI like `-r 75` first to find chapter-opening pages), and any pages whose text extraction looks scrambled. The expectation is that the vision pass produces a structured list of `{depth, title, start_page, end_page}` entries grounded in what is actually on the page images — not invented.
   3. Cross-check: every chapter's `start_page` must contain text matching the proposed title; if it does not, re-examine the image and correct the entry before continuing.

7. **Assemble chapter files via vision-per-page reconstruction.** This is the second critical step — spend tokens generously. The pipeline is vision-first: render every page as an image and have the agent read each rendered page to produce the chapter's markdown. `pdftotext` output is consulted only as a cross-check for tricky identifiers, citations, and long URLs.

   For each chapter in the recovered structure:

   1. Render the chapter's page range at 150 DPI (200 DPI for math-heavy or figure-heavy textbook pages, 100 DPI for plain prose on very long books to save tokens):
      ```bash
      pdftoppm -png -r 150 -f <start> -l <end> <work>/source.pdf <work>/ch<NN>/p
      ```
   2. Read the rendered PNGs in order (in batches of 3–5 pages per read when the chapter is long). For each page, produce clean markdown that reflects what is actually on the page — nothing more, nothing less:
      - Honour the visual reading order (top-to-bottom within each column for two-column layouts; reconstruct the prose column-by-column, not interleaved).
      - Drop running headers, running footers, page numbers, and the copyright/permissions notices that journals stamp on the first page.
      - Drop in-figure labels and arrows; do not splice them into the surrounding prose.
      - Preserve math as inline TeX (`$...$`) or display TeX (`$$...$$`). Do not approximate equations as ASCII; if a symbol is genuinely unreadable, mark it `$\text{?}$` and note it in the log entry instead of guessing.
      - Preserve code listings as fenced blocks. Use a language hint when the language is clear (` ```python `, ` ```c `, ` ```verilog `); fall back to plain fences otherwise.
      - Preserve tables as GitHub-flavoured markdown when feasible; fall back to fenced plain-text for tables that do not survive the conversion.
      - Preserve citation markers in their original form (e.g. `[12]`, `(Smith, 2021)`).
      - Stitch sentences across page boundaries: undo end-of-line hyphenation, merge paragraphs that continue from one page to the next, and do not introduce a paragraph break where the source had none.
   3. Figures:
      - For raster figures already extracted to `wiki/books/<slug>/src/images/` (step 5), reference them at the position they appeared on the page: `![Figure N.M: <caption from the page>](images/<filename>)`.
      - For vector figures (which `pdfimages` does not extract — common in research papers and modern textbooks), **crop just the figure region**, not the whole page. Use `pdftoppm`'s built-in cropping: `pdftoppm -png -r 150 -f <page> -l <page> -x <X> -y <Y> -W <width> -H <height> <source.pdf> <out-prefix>`. Coordinates are in pixels at the rendering DPI; a US Letter page at 150 DPI is 1275×1650. Determine the bounding box for each figure by reading the rendered page image at 150 DPI and estimating the four bounds from what you see (figure plus caption, excluding running headers, body prose, and adjacent figures). Verify the crop visually by reading the resulting PNG; tighten the box if body text bleeds in, widen it if the caption or right edge is clipped. Rename the output to a stable filename (`pdftoppm` appends a page-number suffix like `-08.png`).
      - Whole-page renders are an inferior fallback. Use them only when the figure occupies the entire page or when cropping is genuinely impractical.
      - Never invent a figure caption — quote it from the page.
   4. Cross-check identifiers, long URLs, DOIs, ISBNs, and citation keys against the corresponding region in `text-layout.txt`/`text-flow.txt`; vision OCR can miss a digit or a hyphen in long alphanumeric strings.
   5. Start each chapter file with `# <Chapter Title>` matching `SUMMARY.md` exactly. Sub-sections become `##`/`###` honouring the recovered hierarchy and the printed numbering on the page.
   6. Write to `wiki/books/<slug>/src/<NN>-<chapter-slug>.md` where `NN` is a zero-padded order index.

   For very long chapters (e.g. a 50-page textbook chapter), process pages in fixed-size batches, append each batch to the chapter file as you go, and confirm continuity at each batch boundary by re-reading the last paragraph from the previous batch alongside the first page of the next batch.

8. **Write `book.toml`** at `wiki/books/<slug>/book.toml`:
   ```toml
   [book]
   title = "<PDF Title>"
   authors = ["<from PDF metadata when available>"]
   language = "en"
   src = "src"

   [output.html]
   mathjax-support = true
   ```

9. **Write `src/SUMMARY.md`** in strict mdBook syntax. Example:
   ```markdown
   # Summary

   [Introduction](00-introduction.md)

   # Part I — Fundamentals

   - [Chapter 1: Title](01-chapter-one.md)
     - [1.1 Subsection](01-chapter-one.md#section-anchor)
   - [Chapter 2: Title](02-chapter-two.md)
   ```
   Use two-space indents for sub-chapters. Use `[Title]()` (empty link) only for unwritten draft chapters; the workflow should not normally emit drafts.

10. **Validate the build.** Run `mdbook build wiki/books/<slug>/`. If it fails, fix `SUMMARY.md` or chapter files until it succeeds. A successful build is part of the acceptance bar.

11. **Update `wiki/index.md`.** Add an entry under the `## Books` table (create the table if missing). Columns: `Page | Title | Pages | OCR | Created`. The `Page` cell links directly to the rendered book — `[[books/<slug>/src/SUMMARY|<Title>]]`. Do **not** link to a `summaries/<slug>` page; this workflow does not create one.

12. **Append `wiki/log.md`** with a dated entry recording the PDF path, slug, total chapters, page count, OCR status, structure-recovery method, and `mdbook build` result.

Do **not** create `wiki/summaries/<slug>.md`. Do **not** create concept or entity pages. Do **not** produce `## Relevant Concepts` links from the book's content. Those are the Ingest workflow's responsibilities; the user invokes that separately if desired.

Quality bar (acceptance):
- `mdbook build wiki/books/<slug>/` exits 0.
- Chapter list in `SUMMARY.md` matches the actual structure of the PDF (verify by spot-checking 2–3 chapter openings against the source).
- No invented chapters, sections, paragraphs, or figure captions.
- Chapter prose matches the printed page in reading order; no column interleaving, no in-figure labels spliced into the prose, no copyright/permissions notices bleeding into chapter 1.
- Math preserved as TeX, code as fenced blocks with a language hint where possible, tables as GFM where feasible, figures present where they appear in the source with captions quoted from the page.
- Front matter (preface, TOC, copyright) is either included as `[Front Matter](00-front-matter.md)` style entries before the first numbered part, or omitted deliberately and noted in the log.
- No `wiki/summaries/<slug>.md` was written, no concept/entity pages were created, and the only `wiki/` touchpoints outside `wiki/books/<slug>/` are the `Books` table row in `index.md` and the dated `log.md` entry.

## Rules

- Never modify files in `raw/`
- Always update `index.md` and `log.md` after any wiki change
- Prefer updating existing pages over creating duplicates
- When in doubt about a claim, set confidence to "low" and note the uncertainty
- Keep pages focused — one concept per page, split if a page gets too long
- Use plain English — define jargon on first use in each page
- All dates in ISO 8601 format: YYYY-MM-DD
- When a source provides specific examples, include them with concrete details
