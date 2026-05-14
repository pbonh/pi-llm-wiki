---
name: wiki-maintainer
description: Maintain an llm-wiki knowledge base — ingest sources, answer queries, lint pages, generate flashcards, Marp presentations, and Gherkin specs, derive vision/contexts/context-maps via strategic design, manage ADRs, emit & round-trip Hermes Kanban tasks, run the refinement loop, or bootstrap a new wiki. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
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

### `spec <goal>`

Run the Spec workflow to synthesize Gherkin scenarios from a user goal or feature request. Output is a single `wiki/specs/<slug>.md` page with Gherkin in ` ```gherkin ` fenced blocks (copy-paste into a target repo's test suite as needed). Spec is to Query what Presentation is to Synthesis — same retrieval, different artifact.

1. Read `wiki/index.md` and the concept/entity pages relevant to the goal's domain.
2. **Vagueness check.** If the goal lacks a clear actor + outcome, emit only the `## Scope` impact map (`Actor | Impact | Deliverable`) and ask the user to confirm scope before producing scenarios. Otherwise skip the impact map.
3. Derive user stories with binary pass/fail acceptance criteria, then translate each criterion into Gherkin scenarios under the quality rules: business-readable (no UI buttons, DB tables, or CSS selectors), single `When` per scenario, realistic data (named personas + concrete numbers), `Scenario Outline` + `Examples` for parameterized cases.
4. Write `wiki/specs/<slug>.md` with `type: spec` frontmatter and sections `## Goal`, optional `## Scope`, `## User Stories`, `## Scenarios`, `## Glossary`, `## Sources`.
5. **Verify zero dangling links — acceptance gate.** Same rule as `ingest`: every `[[...]]` reference must resolve. Create stub concept pages (`confidence: low`) for dangling glossary terms or remove the link.
6. Update `wiki/index.md` `## Specs` table + Statistics, and append a dated `wiki/log.md` entry.

No paired synthesis page is produced. If the wiki lacks enough material to ground the scenarios in real domain concepts, say so and suggest sources — do not invent business rules.

### `pdfbook <path>`

Run the PDF → mdBook workflow on a PDF (typically under `raw/`, but any path is fine). Produces a runnable mdBook under `wiki/books/<slug>/`.

**Scope: this is conversion only.** Do NOT create `wiki/summaries/<slug>.md`, concept pages, entity pages, or `Relevant Concepts` cross-links. If the user wants the book's content ingested into the wiki graph, they will invoke `ingest` separately. Treat conversion and ingestion as independent workflows.

1. Verify required tooling is on PATH: `pdfinfo`, `pdftotext`, `pdftoppm`, `pdfimages`, `ocrmypdf`, `tesseract`, `mdbook`, and `python3` with `pypdf`. Fail fast with an install hint (`brew install poppler ocrmypdf tesseract mdbook`) if anything is missing.
2. Sample text from the first few pages; if sparse, run `ocrmypdf --skip-text --output-type pdf --rotate-pages --deskew` automatically (no confirmation, even on long books).
3. Extract *reference* text with `pdftotext -layout` and `pdftotext` (flow), and raster images with `pdfimages -all`. The text files are advisory only — chapter content is reconstructed from page images in step 5.
4. Recover structure — critical step #1:
   - Try the embedded PDF outline via `pypdf`. Reject it if empty or if entries look like filenames (`00.pdf`, `chapter01.pdf`).
   - Otherwise render representative pages with `pdftoppm -png` and use vision capabilities to read the ToC and chapter openings, producing a grounded `{depth, title, start_page, end_page}` list. Cross-check each `start_page` against the recovered title before committing.
5. Reconstruct chapter content — critical step #2. **Choose strategy by page count:**
   - **≤ ~25 pages (Strategy A — pure vision):** Render every page in each chapter (`pdftoppm -png -r 150`; 200 DPI for math/figure-heavy pages) and read them in 3–5-page batches. Produce markdown matching the printed page exactly: honour columns, drop headers/footers/page numbers and in-figure labels, preserve math as `$...$`/`$$...$$`, code as fenced blocks, tables as GFM, figures referenced from `src/images/` with captions quoted from the page. Stitch sentences across page breaks; cross-check long identifiers and URLs against the reference text from step 3.
   - **> ~25 pages (Strategy B — hybrid):** Most vision APIs cap at ~30 images per conversation, so pure vision-per-page is impossible for long books. Use vision strategically and `pdftotext` for bulk prose:
     1. **Vision sample set** (keep under 25 images total): render every TOC page, the first page of every chapter, and any page where `pdftotext` output is garbled or where figures/tables/equations appear. Read these to confirm titles, detect headers/footers, and note figure-heavy pages.
     2. **Bulk prose:** run `pdftotext -layout` (or flow mode for two-column papers) on the source PDF. Strip headers/footers using patterns observed in the vision samples, then slice by chapter range.
     3. **Stitching:** start each chapter with the vision-reconstructed opening page, append the bulk `pdftotext` prose, and swap in vision-reconstructed markdown for any figure/table/math-heavy pages identified in the sample. Insert cropped figure images with captions quoted from vision.
     4. Cross-check math, code, tables, and long identifiers from the vision sample against the bulk text; correct OCR artefacts (e.g. `Ð` for em-dash, `ł` for left-quote) using patterns observed on the vision samples.
   - **Vector figures:** for vector figures (which `pdfimages` does not extract), **crop just the figure region** using `pdftoppm -x -y -W -H` (pixel coords at the rendering DPI); never embed full-page renders. Verify each crop visually and tighten or widen the bounding box if body text bleeds in or the caption is clipped.
6. Write `book.toml` (mathjax enabled), `src/SUMMARY.md` in strict mdBook syntax, and one `# Chapter` markdown file per chapter under `src/`.
7. Run `mdbook build wiki/books/<slug>/`. A non-zero exit is a hard stop — fix and rebuild.
8. Update `wiki/index.md` `## Books` table with a row whose `Page` cell links directly to the rendered book (`[[books/<slug>/src/SUMMARY|<Title>]]`) — do not link to a summary page; this workflow does not create one. Append a dated `wiki/log.md` entry.

Never invent chapters or content. Re-runs overwrite chapter files in place rather than duplicating. Prefer `marker` or `docling` if installed for higher-fidelity extraction, but never add them as deps.

### `strategy <topic>`

Run the Strategy workflow to derive [[concepts/domain-driven-design]] strategic-design artifacts from the wiki. Output: one page in `wiki/vision/`, one or more pages in `wiki/contexts/`, one page in `wiki/context-maps/`. Strategy is re-runnable; later runs update existing pages by slug rather than duplicating.

1. Read `wiki/index.md` and relevant concept/entity/summary pages.
2. Distillation — identify core vs. supporting concepts.
3. Write `wiki/vision/<topic-slug>.md` (`type: vision`) with `## Value Proposition`, `## In Scope`, `## Out of Scope`, `## Differentiation`, `## Revisions`.
4. For each bounded context, write `wiki/contexts/<context-slug>.md` (`type: context`) with `## Model`, `## Boundary`, `## Ubiquitous Language` inline glossary, `## Relationships`.
5. Write `wiki/context-maps/<topic-slug>.md` (`type: context-map`) with `## Contexts`, `## Translations` table, `## False Cognates`, `## Integration Patterns`.
6. Cross-link vision ↔ contexts ↔ context map.
7. Zero-dangling-links acceptance gate.
8. Update `wiki/index.md` (Vision / Contexts / Context Maps tables + Statistics) and append to `wiki/log.md`.

A single bounded context is fine and common; the context map then describes the boundary against the outside world. If the wiki lacks enough material to identify distinct contexts, say so — do not invent.

### `adr <decision title>`

Run the ADR workflow to open a new [[concepts/architectural-decision-record]] in `wiki/decisions/`.

1. Pick the next four-digit number by scanning `wiki/decisions/NNNN-*.md`.
2. Ask the user for the triggering [[concepts/architecturally-significant-requirement]] — **refuse to proceed without one** (an ADR without an ASR is the AKM log-bloat failure mode). The ASR goes in `## Context`.
3. Choose a template: **Nygard** (default, 5 sections), **MADR** (when multiple alternatives deserve preserved analysis), **Y-Statement** (one-liner).
4. Write `wiki/decisions/NNNN-<kebab-title>.md` with `type: decision`, `## Status: proposed`, ASR citation, and the required sections for the chosen template.
5. Cross-link to every wiki page the decision governs.
6. **Refuse to edit an `accepted` ADR.** Open a new ADR that supersedes it; with the user's permission, flip the predecessor's `## Status` to `superseded by NNNN` and link the successor.
7. Zero-dangling-links acceptance gate.
8. Update `wiki/index.md` Decisions table + Statistics, append to `wiki/log.md`.

Status is load-bearing for downstream workflows — `/wiki-spec` warns when no `accepted` ADR governs the domain, and `/wiki-kanban-emit` picks the collaboration pattern from status.

### `kanban-emit <spec-slug>`

Run the Kanban Emit workflow to decompose a spec page onto a [[concepts/durable-task-board]] hosted by [[entities/hermes-agent]].

**Preflight (hard).** `hermes kanban assignees` must succeed. If `hermes` is not on `PATH`, abort with the install hint pointing at https://github.com/NousResearch/hermes. Kanban emission requires Hermes; the rest of this wiki works without it.

**ADR gate (soft).** If the spec cites no `accepted` ADR, warn the user and offer to hand off to `/wiki-adr` first. Proceed on confirmation; record the choice in the spec's `## Sources`.

1. Read `wiki/specs/<spec-slug>.md` in full.
2. Read every cited ADR (confirm `## Status: accepted`) and the relevant `wiki/contexts/<context>.md` `## Ubiquitous Language` for inlining.
3. Compute idempotency key: `<spec-slug>:<adr-id>:<sha256(spec-body)>` per [[concepts/idempotency-key]].
4. Enumerate Hermes profiles via the preflight output; map logical roles (`implementer`/`reviewer`/`integrator`) to real profile names. Fail loudly on missing mappings.
5. Pick the [[concepts/collaboration-pattern]] from ADR status: `accepted` → P2 pipeline; `proposed` → P5 human-in-the-loop; multiple feature files → P1 fan-out parent; `deprecated`/`superseded` without successor → refuse to emit.
6. Decompose into one `kanban_create` per user story. Each task body MUST include goal, approach, acceptance criteria verbatim, Gherkin block fenced, inlined glossary excerpt, wiki backlink, ADR id(s), and a `@wiki-spec` tag.
7. Express ordering with `parents=[...]`. Reject relative `workspace=dir:` paths.
8. Append a `## Kanban Tasks` section to the spec page recording the key, ADR ids, pattern, profile mapping, and task ids.
9. Zero-dangling-links acceptance gate on the updated spec page.
10. Append to `wiki/log.md`. **Fire and forget — do not poll** (per [[concepts/orchestrator-pattern]]).

**Discipline:** the extension creates rows and steps back. It does not claim, run, or shell out to do worker tasks.

### `kanban-ingest <task-id | run-id>`

Run the Kanban Ingest workflow to round-trip a completed Hermes run back into the wiki as a [[concepts/living-documentation]] receipt.

**Preflight (hard).** Same `hermes kanban assignees` check as `kanban-emit`. Abort with the same install-hint message if Hermes is unavailable.

1. Fetch the run via `hermes kanban show <id>` (or db-layer equivalent). Capture `summary`, `verification`, `changed_files`, `residual_risk`, and the [[concepts/structured-handoff]] payload.
2. **Sanitize.** Refuse to copy tokens, OAuth material, raw logs, or unrelated transcripts. If metadata is dirty, surface to the user and stop — do not silently scrub.
3. Locate the originating wiki page via the `@wiki-spec` tag or wiki backlink.
4. Append a `## Implementation Evidence` section: run id, timestamp, assignee, `verification` + result, `changed_files`, `residual_risk`, one-paragraph summary. On re-ingest, add a new dated subheading.
5. Update the target's frontmatter `updated` field.
6. Zero-dangling-links acceptance gate.
7. Append to `wiki/log.md`.

If the run failed, still ingest — mark `Result: failed` and quote the failure reason. Documenting failures honestly is the point of living documentation.

### `refine <run-id | breakthrough note>`

Run the Refine workflow — the *structural* counterpart to `kanban-ingest`. Use when a run outcome or [[concepts/breakthrough]] invalidates a prior model (moved context boundary, new [[concepts/false-cognate]], invalidated decision).

1. Classify the trigger: **documentary only** → hand off to `kanban-ingest` and stop; **structural** → continue.
2. Update upstream model — `wiki/concepts/`, `wiki/contexts/`, or `wiki/context-maps/` as appropriate.
3. If a decision was invalidated: hand off to `adr` to open a superseding ADR (write-once, never edit the accepted predecessor). The new ADR cites the originating run id; flip the predecessor's status to `superseded by NNNN`.
4. Re-emit affected kanban tasks via `kanban-emit` — the fresh `<spec-slug>:<new-adr-id>:<sha256>` triple produces a new task row. Close old rows with a `kanban_comment` pointing forward.
5. Zero-dangling-links acceptance gate on every page touched.
6. Update `wiki/index.md` and append to `wiki/log.md`.

Use Refine sparingly — most outcomes are documentary — but use it without hesitation when an ADR is invalidated. An unrecorded supersession is worse than an explicit one.

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
