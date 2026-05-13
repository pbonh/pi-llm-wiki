---
name: wiki-maintainer
description: Maintain an llm-wiki knowledge base — ingest sources, answer queries, lint pages, generate flashcards and Marp presentations, or bootstrap a new wiki. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
---

# wiki-maintainer

Operate an [llm-wiki](https://github.com/pbonh/llm-wiki) knowledge base.

The wiki schema — page format, frontmatter, tagging, linking, confidence levels, and the Ingest/Query/Lint workflows — lives in `AGENTS.md` at the repo root. Always read `AGENTS.md` first; this skill is a thin dispatcher into the workflows defined there.

## Subcommands

### `ingest <path>`

Run the Ingest workflow on `<path>` (a file in `raw/`).

1. Read the source completely.
2. Create `wiki/summaries/<source-slug>.md`.
3. Create/update every concept, entity, and strategy page mentioned.
4. Add bidirectional `[[wiki/...]]` cross-links.
5. **Verify zero dangling links — acceptance gate.** Scan every page you created or updated for `[[...]]` references and confirm each target file exists on disk. For each dangling link, either create the missing page (full schema, stub content OK if the source mentions the concept only in passing — set `confidence: low`) or remove the link. Re-scan until zero dangling links remain. A summary that cites pages which don't exist is a workflow failure.
6. Update `wiki/index.md` and append to `wiki/log.md`.
7. Flag contradictions with existing pages.

Never modify files in `raw/`. Prefer updating existing pages over duplicating. Every `[[wiki-link]]` must resolve to a real file by the end of the run.

### `query <question>`

Run the Query workflow:

1. Read `wiki/index.md` and the relevant pages.
2. Answer with `[[wiki-link]]` citations.
3. If the answer reveals novel cross-cutting insight, create a synthesis page in `wiki/syntheses/` and update `wiki/index.md` + `wiki/log.md`.

If the wiki can't support a confident answer, say so and suggest sources that would fill the gap. Do not invent claims.

### `lint`

Run the Lint workflow:

1. Read every page under `wiki/`.
2. Detect orphans, contradictions, missing cross-links, incomplete sections, and weak low-confidence pages.
3. Fix what is fixable from existing sources; report the rest for human judgment.
4. Suggest sources or topics worth investigating.
5. Append a `lint` entry to `wiki/log.md`.

Lint does **not** flag pages missing flashcards or presentations — those workflows are explicit.

### `flashcards <page>`

Run the Flashcards workflow on a wiki page (e.g. `concepts/braising`, `entities/cast-iron-skillet`):

1. Read the source page.
2. Derive cards from its content — definitions, parameters, key points — and choose the right syntax for each: basic (`Q\n?\nA`), reversed (`Q\n??\nA`) for symmetric pairs, cloze (`==hidden==`) for fill-in-the-blank.
3. Write `wiki/flashcards/<page-slug>.md` with `type: flashcards` and `tags:` that includes `flashcards` (required by the obsidian-spaced-repetition plugin).
4. Link source page ↔ cards file bidirectionally.
5. Update `wiki/index.md` and append to `wiki/log.md`.

### `present <topic>`

Run the Presentation workflow to produce a Marp slide deck on a topic:

1. Find relevant pages via `wiki/index.md` (same retrieval as `query`) and read them.
2. Stitch their key claims into slides: title → outline → one section per concept/entity → references.
3. Write `wiki/presentations/<topic-slug>.md` with Marp frontmatter (`marp: true`, `theme: default`, `paginate: true`) plus the standard wiki frontmatter; slides separated by `---`.
4. Every cited page appears as a wiki link on the References slide.
5. Update `wiki/index.md` and append to `wiki/log.md`. No paired synthesis page.

If the wiki can't support a coherent deck on the topic, say so and suggest sources — do not invent claims.

### `pdfbook <path>`

Run the PDF → mdBook workflow on a PDF (typically under `raw/`, but any path is fine). Produces a runnable mdBook under `wiki/books/<slug>/`.

**Scope: this is conversion only.** Do NOT create `wiki/summaries/<slug>.md`, concept pages, entity pages, or `Relevant Concepts` cross-links. If the user wants the book's content ingested into the wiki graph, they will invoke `ingest` separately. Treat conversion and ingestion as independent workflows.

1. Verify required tooling is on PATH: `pdfinfo`, `pdftotext`, `pdftoppm`, `pdfimages`, `ocrmypdf`, `tesseract`, `mdbook`, and `python3` with `pypdf`. Fail fast with an install hint (`brew install poppler ocrmypdf tesseract mdbook`) if anything is missing.
2. Sample text from the first few pages; if sparse, run `ocrmypdf --skip-text --output-type pdf --rotate-pages --deskew` automatically (no confirmation, even on long books).
3. Extract *reference* text with `pdftotext -layout` and `pdftotext` (flow), and raster images with `pdfimages -all`. The text files are advisory only — chapter content is reconstructed from page images in step 5.
4. Recover structure — critical step #1:
   - Try the embedded PDF outline via `pypdf`. Reject it if empty or if entries look like filenames (`00.pdf`, `chapter01.pdf`).
   - Otherwise render representative pages with `pdftoppm -png` and use vision capabilities to read the ToC and chapter openings, producing a grounded `{depth, title, start_page, end_page}` list. Cross-check each `start_page` against the recovered title before committing.
5. Reconstruct chapter content via vision-per-page — critical step #2. Render every page in each chapter (`pdftoppm -png -r 150`; 200 DPI for math/figure-heavy pages, 100 DPI for plain prose on very long books) and read them in 3–5-page batches. Produce markdown matching the printed page in reading order: honour columns, drop running headers/footers/page numbers and in-figure labels, preserve math as `$...$`/`$$...$$`, code as fenced blocks, tables as GFM, figures referenced from `src/images/` with captions quoted from the page. Stitch sentences across page breaks; cross-check long identifiers and URLs against the reference text from step 3. For vector figures, **crop just the figure region** using `pdftoppm -x -y -W -H` (pixel coords at the rendering DPI); never embed full-page renders. Verify each crop visually and tighten or widen the bounding box if body text bleeds in or the caption is clipped.
6. Write `book.toml` (mathjax enabled), `src/SUMMARY.md` in strict mdBook syntax, and one `# Chapter` markdown file per chapter under `src/`.
7. Run `mdbook build wiki/books/<slug>/`. A non-zero exit is a hard stop — fix and rebuild.
8. Update `wiki/index.md` `## Books` table with a row whose `Page` cell links directly to the rendered book (`[[books/<slug>/src/SUMMARY|<Title>]]`) — do not link to a summary page; this workflow does not create one. Append a dated `wiki/log.md` entry.

Never invent chapters or content. Re-runs overwrite chapter files in place rather than duplicating. Prefer `marker` or `docling` if installed for higher-fidelity extraction, but never add them as deps.

### `new <domain>`

Bootstrap an llm-wiki in the current directory for `<domain>`. Works in either an empty directory (drops the bundled template first) or an existing llm-wiki clone (customizes in place).

1. Check whether `AGENTS.md` exists in the cwd.
   - If NOT: run `pi-llm-wiki-init` to drop the bundled `template/` (AGENTS.md, CLAUDE.md stub, raw/, wiki/ skeleton, .gitignore). The `pi-llm-wiki-init` binary ships with this package; no clone or network is needed.
   - If YES: proceed directly to step 2.
2. Read `AGENTS.md` end-to-end.
3. Enumerate every `<!-- ... -->` customization block (`grep -n '<!--' AGENTS.md`). Each block's comments describe what's expected; the placeholder text immediately after (e.g. `[YOUR TOPIC]`, `Category-A: tag-1, tag-2, tag-3`) is what gets replaced. Treat the markers — not specific section names — as the authoritative list.
4. For each block:
   - **Mechanical fills** (e.g. Purpose paragraph from `<domain>`): generate the replacement, swap it in, and delete the `<!-- ... -->` comments.
   - **Judgment calls** (e.g. taxonomy category names and tags): propose your choices to the user and incorporate feedback before committing, then delete the comments.
5. Re-run `grep -n '<!--' AGENTS.md` — must return zero results.
6. Update title and domain-flavored copy in `wiki/index.md` and `wiki/log.md`.
7. If the directory is a git repo, commit: `Customize llm-wiki for <domain>`.

Leave `raw/` empty — the user adds sources after bootstrap.

## Rules (from AGENTS.md, repeated for safety)

- Never modify files in `raw/`.
- Always update `wiki/index.md` and `wiki/log.md` after any wiki change.
- All dates in ISO 8601 format (YYYY-MM-DD).
- Use plain English; define jargon on first use in each page.
- One concept per page — split if a page grows too long.
