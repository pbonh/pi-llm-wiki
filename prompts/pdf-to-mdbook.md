---
description: Convert a PDF (scanned, structured, textbook, or paper) into a runnable mdBook under wiki/books/. Conversion only — does NOT ingest content into the wiki graph.
argument-hint: "<path-to-pdf>"
---
Read `AGENTS.md` and follow the **PDF → mdBook** workflow for the PDF at `$1`.

**Scope: this command only converts the PDF into a runnable mdBook.** It does NOT create a summary page, concept pages, entity pages, or any `[[wiki-link]]` ingestion of the book's content. If the user wants the book ingested into the wiki graph, they will run `/wiki-ingest` separately afterwards (against the source PDF or the rendered book). Do not infer ingestion from the conversion request.

Steps (from AGENTS.md):
1. Resolve the slug from the PDF filename and pick `wiki/books/<slug>/` as the output dir.
2. Verify required tooling is on PATH (`pdfinfo`, `pdftotext`, `pdftoppm`, `pdfimages`, `ocrmypdf`, `tesseract`, `mdbook`, `python3` with `pypdf`). If anything is missing, stop and print the install hint.
3. Classify the PDF by sampling text from the first ~5 pages; if sparse, run `ocrmypdf --skip-text --output-type pdf --rotate-pages --deskew` automatically (no confirmation).
4. Extract *reference* text with `pdftotext -layout` and `pdftotext` (flow), and extract raster images with `pdfimages -all`. The text files are advisory only — chapter content is reconstructed from page images in step 6.
5. Recover structure — critical step #1:
   - Try the embedded PDF outline first via `pypdf`. Reject the outline when it is empty or when the entries look like filenames (e.g. `01.pdf`).
   - Otherwise render representative pages with `pdftoppm -png` and use vision capabilities to read the ToC and chapter-opening pages, producing a grounded `{depth, title, start_page, end_page}` chapter list. Cross-check each `start_page` against the recovered title before committing.
6. Reconstruct chapter content via vision-per-page — critical step #2. Render every page in each chapter with `pdftoppm -png -r 150` (use 200 DPI on math/figure-heavy textbook pages, 100 DPI on plain prose for long books to save tokens) and read them in order, in batches of 3–5 pages. Produce markdown that matches the printed page in reading order: honour columns, drop running headers/footers/page numbers, drop in-figure labels, preserve math as `$...$`/`$$...$$`, code as fenced blocks (with language hints), tables as GFM, and reference figures from `src/images/` with captions quoted from the page. Stitch sentences across page boundaries and undo end-of-line hyphenation. Cross-check long identifiers/URLs/citations against the reference text from step 4. For vector figures (which `pdfimages` does not extract), **crop just the figure region** with `pdftoppm -x <X> -y <Y> -W <W> -H <H>`; never embed whole-page renders as figures. Pixel coordinates are at the target DPI; verify each crop visually and tighten/widen the box if body text bleeds in or the caption is clipped.
7. Write `book.toml` (with `[output.html] mathjax-support = true`), `src/SUMMARY.md` in strict mdBook syntax, and one `# Chapter` markdown file per chapter.
8. Run `mdbook build wiki/books/<slug>/` and fix any failures until it exits 0.
9. Update `wiki/index.md` — add an entry under the `## Books` table (create the table if missing). The `Page` cell links directly to the rendered book: `[[books/<slug>/src/SUMMARY|<Title>]]`. Do NOT link to a summary page; this workflow does not create one.
10. Append a dated entry to `wiki/log.md` recording PDF path, slug, chapter count, page count, OCR status, structure-recovery method (`outline` / `vision` / `mixed`), and `mdbook build` result.

Rules:
- Never modify files in `raw/` (or wherever the source PDF lives — the workflow only reads it).
- Never invent chapters, sections, or paragraphs the PDF does not contain. The vision pass must ground every entry in actual rendered pages.
- A failed `mdbook build` is a hard stop — fix `SUMMARY.md` and chapter files until it succeeds.
- Math stays as TeX; do not convert to ASCII. Enable mathjax in `book.toml`.
- Use ISO 8601 dates (YYYY-MM-DD).
- Do NOT create `wiki/summaries/<slug>.md`, concept pages, entity pages, or any `Relevant Concepts` cross-links. That is the Ingest workflow's job, invoked separately by the user.
- Re-runs overwrite chapter files in place rather than duplicating.
- Optional: prefer `marker` or `docling` if installed for higher-fidelity extraction on textbooks and papers, but never add them as hard deps.
