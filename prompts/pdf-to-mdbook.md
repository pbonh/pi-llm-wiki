---
description: Convert a PDF (scanned, structured, textbook, or paper) into a runnable mdBook under wiki/books/
argument-hint: "<path-to-pdf>"
---
Read `AGENTS.md` and follow the **PDF → mdBook** workflow for the PDF at `$1`.

Steps (from AGENTS.md):
1. Resolve the slug from the PDF filename and pick `wiki/books/<slug>/` as the output dir.
2. Verify required tooling is on PATH (`pdfinfo`, `pdftotext`, `pdftoppm`, `pdfimages`, `ocrmypdf`, `tesseract`, `mdbook`, `python3` with `pypdf`). If anything is missing, stop and print the install hint.
3. Classify the PDF by sampling text from the first ~5 pages; if sparse, run `ocrmypdf --skip-text --output-type pdf --rotate-pages --deskew` automatically (no confirmation).
4. Extract *reference* text with `pdftotext -layout` and `pdftotext` (flow), and extract raster images with `pdfimages -all`. The text files are advisory only — chapter content is reconstructed from page images in step 6.
5. Recover structure — critical step #1:
   - Try the embedded PDF outline first via `pypdf`. Reject the outline when it is empty or when the entries look like filenames (e.g. `01.pdf`).
   - Otherwise render representative pages with `pdftoppm -png` and use vision capabilities to read the ToC and chapter-opening pages, producing a grounded `{depth, title, start_page, end_page}` chapter list. Cross-check each `start_page` against the recovered title before committing.
6. Reconstruct chapter content — critical step #2. **Choose strategy by page count:**
   - **≤ ~25 pages (Strategy A — pure vision):** Render every page at 150 DPI (200 DPI for math/figure-heavy pages) and read them in batches of 3–5 pages. Produce markdown matching the printed page exactly: honour columns, drop headers/footers/page numbers and in-figure labels, preserve math as `$...$`/`$$...$$`, code as fenced blocks, tables as GFM, reference figures from `src/images/` with captions quoted from the page. Stitch sentences across page boundaries; cross-check long identifiers/URLs/citations against the reference text from step 4.
   - **> ~25 pages (Strategy B — hybrid):** Most vision APIs cap at ~30 images per conversation, so pure vision-per-page is impossible for long books. Use vision strategically and `pdftotext` for bulk prose:
     1. **Vision sample set** (keep under 25 images total): render every TOC page, the first page of every chapter, and any page where `pdftotext` output is garbled or where figures/tables/equations appear. Read these to confirm titles, detect headers/footers, and note figure-heavy pages.
     2. **Bulk prose:** run `pdftotext -layout` (or flow mode for two-column papers) on the source PDF. Strip headers/footers using patterns observed in the vision samples, then slice by chapter range.
     3. **Stitching:** start each chapter with the vision-reconstructed opening page, append the bulk `pdftotext` prose, and swap in vision-reconstructed markdown for any figure/table/math-heavy pages identified in the sample. Insert cropped figure images with captions quoted from vision.
     4. Cross-check math, code, tables, and long identifiers from the vision sample against the bulk text; correct OCR artefacts (e.g. `Ð` for em-dash, `ł` for left-quote) using patterns observed on the vision samples.
   - **Vector figures** (which `pdfimages` does not extract): **crop just the figure region** with `pdftoppm -x <X> -y <Y> -W <W> -H <H>`; never embed whole-page renders. Pixel coordinates are at the target DPI; verify each crop visually and tighten/widen the bounding box if body text bleeds in or the caption is clipped.
7. Write `book.toml` (with `[output.html] mathjax-support = true`), `src/SUMMARY.md` in strict mdBook syntax, and one `# Chapter` markdown file per chapter.
8. Run `mdbook build wiki/books/<slug>/` and fix any failures until it exits 0.
9. Write `wiki/summaries/<slug>.md` (standard summary frontmatter + `## Key Points`, `## Relevant Concepts`, `## Source Metadata`, `## Book`) linking to the rendered book.
10. Update `wiki/index.md` — add an entry under the `## Books` table (create the table if missing).
11. Append a dated entry to `wiki/log.md` recording PDF path, slug, chapter count, page count, OCR status, structure-recovery method (`outline` / `vision` / `mixed`), and `mdbook build` result.

Rules:
- Never modify files in `raw/` (or wherever the source PDF lives — the workflow only reads it).
- Never invent chapters, sections, or paragraphs the PDF does not contain. The vision pass must ground every entry in actual rendered pages.
- A failed `mdbook build` is a hard stop — fix `SUMMARY.md` and chapter files until it succeeds.
- Math stays as TeX; do not convert to ASCII. Enable mathjax in `book.toml`.
- Use ISO 8601 dates (YYYY-MM-DD).
- Re-runs overwrite chapter files in place rather than duplicating; bump `updated:` in the paired summary page.
- Optional: prefer `marker` or `docling` if installed for higher-fidelity extraction on textbooks and papers, but never add them as hard deps.
