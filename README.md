# pi-llm-wiki

[pi coding agent](https://pi.dev/docs/latest) integration for the [llm-wiki](https://github.com/pbonh/llm-wiki) template.

Adds thirteen slash commands and one skill to pi, plus a standalone init binary. **The template is bundled** — you do not need to clone `llm-wiki` separately. `npm install -g pi-llm-wiki`, run `pi` in any directory (empty or existing), and `/wiki-new` will scaffold and customize a wiki for you.

Beyond the basics (ingest / query / lint / flashcards / presentations / Gherkin specs / PDF→mdBook), pi-llm-wiki ships a full **research-and-development pipeline**: strategic design (vision + bounded contexts + context map), Architectural Decision Records, and round-trip task emission onto a [Hermes Kanban](https://github.com/NousResearch/hermes) board with structured-handoff ingest and ADR-driven refinement loops.

## Documentation

- **[docs/](./docs/)** — long-form documentation hub.
- **[docs/tutorial-knowledge-graph.md](./docs/tutorial-knowledge-graph.md)** — basic tutorial: bootstrap a wiki and run the ingest / query / lint loop. The "research / knowledge graph only" path. No Hermes, no ADRs.
- **[docs/tutorial-rd-pipeline.md](./docs/tutorial-rd-pipeline.md)** — full pipeline walkthrough: strategy → ADR → spec → kanban emit → ingest → refine, end-to-end against a worked example.
- **[docs/rd-pipeline/](./docs/rd-pipeline/)** — per-feature reference pages for each R&D slash command (inputs, outputs, gates, idempotency rules, failure modes).

## Install

```bash
npm install -g pi-llm-wiki
```

This gives you three things:

1. pi auto-discovers the package (via the `pi-package` keyword) and installs `prompts/` and `skills/` into your pi config.
2. The `pi-llm-wiki-init` binary lands on your `PATH`.
3. A snapshot of the `llm-wiki` template ships inside the package at `template/` and is read by `pi-llm-wiki-init`.

## Usage

### Start a new wiki in an empty directory

```bash
mkdir my-coffee-kb && cd my-coffee-kb
pi
```

In pi:

```
/wiki-new a knowledge base about espresso extraction
```

pi will detect the directory is empty, run `pi-llm-wiki-init` to drop the bundled template into place, then walk through the `<!--` customization markers in `AGENTS.md` — the Purpose paragraph, the Tagging Taxonomy, and any future customization blocks — confirming taxonomy choices with you before committing.

### Operate an existing wiki

Run `pi` inside any directory that already has an `AGENTS.md` matching the llm-wiki schema. The same commands work — `/wiki-new` will skip re-initialization and go straight to customizing whatever markers remain.

### Slash commands

| Command | What it does |
|---|---|
| `/wiki-new <domain>` | Bootstrap a wiki in the cwd. Drops the bundled template if `AGENTS.md` is missing, then customizes every `<!-- ... -->` block. |
| `/wiki-ingest <path>` | Run the Ingest workflow on a file in `raw/` — generates a summary page, creates/updates concept and entity pages, adds cross-links, updates `wiki/index.md` and `wiki/log.md`. |
| `/wiki-query <question>` | Search the wiki and synthesize an answer with `[[wiki-link]]` citations. Creates a synthesis page in `wiki/syntheses/` if the answer reveals novel insight. |
| `/wiki-spec <goal>` | Synthesize Gherkin specs from a user goal into `wiki/specs/<slug>.md`. Runs an automated specification-by-example workshop: derives user stories + acceptance criteria, emits Gherkin scenarios in fenced blocks, and records a ubiquitous-language glossary. Same zero-dangling-links acceptance gate as `/wiki-ingest`. |
| `/wiki-lint` | Audit the wiki for orphans, contradictions, missing links, and incomplete sections. Fixes what it can and reports the rest. |
| `/wiki-flashcards <page>` | Generate obsidian-spaced-repetition cards from a wiki page into `wiki/flashcards/<slug>.md`. Uses basic, reversed, and cloze formats. |
| `/wiki-present <topic>` | Generate a Marp slide deck on a topic from relevant wiki content into `wiki/presentations/<slug>.md`. References every cited page. |
| `/pdf-to-mdbook <path>` | Convert any PDF (scanned, structured, textbook, or research paper) into a runnable [mdBook](https://rust-lang.github.io/mdBook/) under `wiki/books/<slug>/`. Auto-OCRs scanned PDFs, uses the embedded outline when present and vision-based structure recovery otherwise, builds with `mdbook build`, and records the book in `wiki/index.md` + `wiki/log.md`. **Conversion only** — does not write a summary page, concept pages, or any `Relevant Concepts` cross-links. Run `/wiki-ingest` afterwards if you want the book's content ingested into the wiki graph. Requires `poppler`, `ocrmypdf`, `tesseract`, `mdbook`, and `python3` with `pypdf` on PATH. |
| `/wiki-strategy <topic>` | Derive strategic-design artifacts from the wiki: a vision statement (`wiki/vision/<topic>.md`), one or more bounded-context pages (`wiki/contexts/`), and a context map (`wiki/context-maps/<topic>.md`) with translations table and false-cognate list. Re-runnable; later runs update existing pages by slug. |
| `/wiki-adr <title>` | Open a new Architectural Decision Record at `wiki/decisions/NNNN-<kebab-title>.md`. Refuses to proceed without a triggering ASR (architecturally-significant requirement). Defaults to the Nygard template; promotes to MADR when alternatives need preserved analysis; offers Y-Statement for one-liners. Refuses to edit `accepted` ADRs — opens a superseding one instead. |
| `/wiki-kanban-emit <spec-slug>` | Decompose a `wiki/specs/<slug>.md` spec onto a [Hermes Kanban](https://github.com/NousResearch/hermes) board. Each task body carries the goal, acceptance criteria verbatim, the Gherkin block, an inlined ubiquitous-language glossary, the ADR id(s), and a `@wiki-spec` traceability tag. Idempotency key is `<spec-slug>:<adr-id>:<sha256(spec-body)>`. Collaboration pattern (P1 fan-out / P2 pipeline / P3 quorum / P5 human-in-the-loop) is picked from ADR status. **Requires `hermes` on PATH.** |
| `/wiki-kanban-ingest <task-id\|run-id>` | Round-trip a completed Hermes run back onto the originating wiki page as an `## Implementation Evidence` section (verification commands, changed files, residual risk, run id). Sanitizes the structured handoff — refuses to copy tokens, OAuth material, or raw logs. **Requires `hermes` on PATH.** |
| `/wiki-refine <run-id\|note>` | Close the refinement loop when a run outcome or breakthrough invalidates a prior model — update concept/context pages, open a superseding ADR via `/wiki-adr`, re-emit affected kanban tasks via `/wiki-kanban-emit` with a fresh idempotency key. |

### Optional runtime dependency

`hermes` (https://github.com/NousResearch/hermes) is required only for `/wiki-kanban-emit`, `/wiki-kanban-ingest`, and the kanban-aware lint checks. Everything else — ingest, query, spec, ADR, strategy, refinement-as-documentary, flashcards, presentations, PDF→mdBook — works without it. The kanban prompts preflight `hermes kanban assignees` and abort with an install hint if it is missing; they never silently degrade.

### Skill (alternative entry point)

```
/skill:wiki-maintainer new <domain>
/skill:wiki-maintainer ingest <path>
/skill:wiki-maintainer query <question>
/skill:wiki-maintainer spec <goal>
/skill:wiki-maintainer lint
/skill:wiki-maintainer flashcards <page>
/skill:wiki-maintainer present <topic>
/skill:wiki-maintainer pdfbook <path>
/skill:wiki-maintainer strategy <topic>
/skill:wiki-maintainer adr <decision title>
/skill:wiki-maintainer kanban-emit <spec-slug>
/skill:wiki-maintainer kanban-ingest <task-id|run-id>
/skill:wiki-maintainer refine <run-id|note>
```

### Binary (no pi required)

If you just want the template files without running pi, the init binary works standalone:

```bash
mkdir my-wiki && cd my-wiki
pi-llm-wiki-init
# AGENTS.md, CLAUDE.md, raw/, wiki/, .gitignore now exist; customize manually or via pi later
```

`pi-llm-wiki-init` refuses to run if `AGENTS.md` already exists, and it skips any individual file that would collide.

## How it works

`pi-llm-wiki` does not duplicate the wiki schema in its prompts or skill. The slash commands and skill point pi at `AGENTS.md` and tell it to follow the workflows defined there — Ingest, Query, Lint. The schema in `AGENTS.md` (which is what ships in `template/AGENTS.md`) is the source of truth.

The `<!--` HTML comments in `AGENTS.md` mark the customization points. `/wiki-new` enumerates them with `grep`, treats the comment text as the spec for what to fill in, and verifies completion by re-running `grep` and requiring zero matches. New customization blocks added to `AGENTS.md` upstream are automatically handled — no `pi-llm-wiki` change needed.

## Keeping the bundled template in sync with upstream

The `template/` directory is a snapshot of the [llm-wiki](https://github.com/pbonh/llm-wiki) repo (minus `LICENSE` and `README.md`). To resync after an upstream schema change:

```bash
scripts/sync-from-llm-wiki.sh ../llm-wiki   # or wherever your clone lives
git diff template/
# bump version in package.json and publish
```

## License

MIT
