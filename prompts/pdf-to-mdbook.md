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
6. Reconstruct chapter content — critical step #2. **Choose strategy by page count:**
   - **≤ ~25 pages (Strategy A — pure vision in the parent):** Render every page at 150 DPI (200 DPI for math/figure-heavy pages) and read them in batches of 3–5 pages. Produce markdown matching the printed page exactly: honour columns, drop headers/footers/page numbers and in-figure labels, preserve math as `$...$`/`$$...$$`, code as fenced blocks, tables as GFM, reference figures from `src/images/` with captions quoted from the page. Stitch sentences across page boundaries; cross-check long identifiers/URLs/citations against the reference text from step 4.
   - **> ~25 pages (Strategy B — subagent-dispatched).** Vision APIs cap at ~30 images per conversation, so neither pure vision-per-page nor "sample every chapter opening" works in a single conversation for a long book. The parent does structure + assembly only; per-chapter prose is reconstructed by subagents that each get a fresh image budget. **Hard rule: the parent conversation must never render or read more than ~12 page images for the whole job.** If you approach that cap, stop and dispatch.

     1. **Structure pass in the parent (≤12 images, hard cap):**
        - Try the pypdf outline first (step 5).
        - If the outline is unusable, render only TOC pages plus 2–3 sample chapter-opening pages for cross-check. Read them, then stop rendering in the parent.
        - Commit the recovered structure to `work/chapters.json` as a list of `{index, title, start_page, end_page}`. The parent uses this for both `SUMMARY.md` and subagent dispatch.

     2. **Bulk prose with `pdftotext` (no vision):**
        - Run `pdftotext -layout <source> work/text/layout.txt` (or flow mode for two-column papers).
        - Note header/footer patterns from the structure pass and strip them from `layout.txt` (e.g. `grep -v` for repeated header lines, drop trailing page-number-only lines).
        - Slice the cleaned text by chapter range into `work/text/ch-<NN>.txt` using the page map.

     3. **Per-chapter `worker` dispatch via the `subagent` tool (`pi-subagents`).** This is the actual workaround for the image limit — each chapter is reconstructed by a fresh `worker` child whose conversation starts empty and gets its own ~30-image budget. For each chapter in `work/chapters.json`, call the `subagent` tool with the builtin `worker` agent. **You MUST pass `context: "fresh"` explicitly:** `worker` defaults to `context: "fork"` (forked from the parent session), which would inherit the parent's images and defeat the entire point. Dispatch independent chapters in a single `tasks: [...]` call so they run in parallel (pi-subagents default `concurrency: 4`, `maxTasks: 8` per call — for books with > 8 chapters, send multiple `subagent` calls of ≤8 tasks each, or raise `parallel.maxTasks` in `~/.pi/agent/extensions/subagent/config.json`).

        Call shape:
        ```ts
        subagent({
          tasks: [
            { agent: "worker", task: "<chapter 1 self-contained prompt>" },
            { agent: "worker", task: "<chapter 2 self-contained prompt>" },
            ...
          ],
          context: "fresh"
        })
        ```

        Each `task` string must be a self-contained prompt (the worker starts fresh and inherits `AGENTS.md`/`CLAUDE.md`, but has no other parent context). Include:
        - PDF path, slug, chapter index, title, `start_page`, `end_page`.
        - Path to the chapter's `pdftotext` slice (`work/text/ch-<NN>.txt`).
        - Path to the `pdfimages` output dir and the figure→page manifest.
        - The target chapter-file path (`wiki/books/<slug>/src/<NN>-<chapter-slug>.md`) and the exact required first line (`# <Chapter Title>` matching `SUMMARY.md`).
        - **Hard rule for the worker: render and read at most ~20 page images.** Spend that budget on (a) the chapter opening, (b) any page identified as figure/table/equation/math-heavy from the slice, and (c) any page where the slice is garbled. Do not render every page of the chapter.
        - Stitching: start with the vision-reconstructed opening page, append the bulk slice prose, swap in vision-reconstructed markdown for the figure/table/math-heavy pages, cross-check math/code/tables/long identifiers between vision and bulk text, correct OCR artefacts (`Ð`→em-dash, `ł`→left-quote, etc.) using patterns observed in the vision reads.
        - The worker writes the chapter file directly with `Write`/`Edit` and returns a short status message (pages rendered, figures inserted, any unresolved issues). It must not write `SUMMARY.md`, `book.toml`, or touch other chapters.

     4. **Re-dispatch on worker failure.** If a worker reports it hit its own image cap or could not complete the chapter, re-dispatch that one chapter with a narrower page range (split the chapter in half into two tasks) rather than retrying in the parent.

   - **Vector figures** (which `pdfimages` does not extract): **crop just the figure region** with `pdftoppm -x <X> -y <Y> -W <W> -H <H>`; never embed whole-page renders. Pixel coordinates are at the target DPI; verify each crop visually and tighten/widen the bounding box if body text bleeds in or the caption is clipped. Under Strategy B, cropping happens inside the subagent that owns that chapter.
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
- **Image cap (parent conversation):** never render or read more than ~12 page images in this conversation. Long books are reconstructed by per-chapter subagents (Strategy B), not by reading more pages here. If you have already rendered 12 images and the book is not yet done, stop and dispatch — do not push the cap higher.
- Optional: prefer `marker` or `docling` if installed for higher-fidelity extraction on textbooks and papers, but never add them as hard deps.
