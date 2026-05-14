# pi-llm-wiki

This is the [pi coding agent](https://pi.dev/docs/latest) integration for the [llm-wiki](https://github.com/pbonh/llm-wiki) template. It ships pi slash commands, a skill, and the wiki template bundled inside the package — so a user can install pi-llm-wiki, run `pi` in an empty directory, and bootstrap a fully customized wiki without ever cloning `llm-wiki` separately.

Note: there are two `AGENTS.md` files in this repo. **This one** describes the `pi-llm-wiki` package itself. The one at `template/AGENTS.md` is the *wiki schema* that ships to end users and tells the LLM how to structure pages, link concepts, and run the Ingest/Query/Lint workflows.

## How the wiki works

End-user flow:

```bash
npm install -g pi-llm-wiki
mkdir my-kb && cd my-kb
pi
```

Then inside pi:

1. `/wiki-new a knowledge base on <domain>` — if the directory has no `AGENTS.md`, the slash command runs `pi-llm-wiki-init` to drop the bundled template (AGENTS.md, wiki/, raw/, .gitignore) into place. Then it customizes the `<!--` markers in `AGENTS.md`: fills in the Purpose paragraph from the domain description, proposes a tagging taxonomy and confirms it with the user, and strips the markers.

2. Drop source documents (articles, transcripts, notes) into `raw/`.

3. `/wiki-ingest raw/<file>` — the agent reads the source and produces a summary page, plus concept and entity pages, cross-linked, indexed, and logged.

4. `/wiki-query <question>` — the agent searches the wiki and answers with `[[wiki-link]]` citations. Novel insights become synthesis pages.

5. `/wiki-lint` — the agent audits for orphans, missing links, contradictions, and incomplete sections.

6. `/wiki-flashcards <page>` — the agent generates obsidian-spaced-repetition cards (basic, reversed, cloze) from any wiki page into `wiki/flashcards/<slug>.md`.

7. `/wiki-present <topic>` — the agent stitches relevant wiki pages into a Marp slide deck at `wiki/presentations/<slug>.md`.

8. `/pdf-to-mdbook <path>` — the agent converts a PDF (scanned, structured, textbook, or paper) into a runnable [mdBook](https://rust-lang.github.io/mdBook/) under `wiki/books/<slug>/`. Auto-OCRs scanned PDFs, prefers the embedded outline and falls back to vision-based structure recovery, validates with `mdbook build`, and records the book in `wiki/index.md` + `wiki/log.md`. **Conversion only** — does not create concept/entity/summary pages or ingest the book's content into the wiki graph; run `/wiki-ingest` separately if that's what you want. Requires `poppler`, `ocrmypdf`, `tesseract`, `mdbook`, and `python3`+`pypdf` on PATH.

9. `/wiki-strategy <topic>` — the agent runs the [[domain-driven-design]] strategic-design phase against the wiki: writes a vision statement (`wiki/vision/`), one or more bounded-context pages (`wiki/contexts/`), and a context map (`wiki/context-maps/`) with translations table and false-cognate list. Re-runnable; later runs update existing pages by slug.

10. `/wiki-adr <decision title>` — the agent opens a new Architectural Decision Record under `wiki/decisions/NNNN-<kebab-title>.md`. Refuses to proceed without a triggering ASR. Defaults to the Nygard template; promotes to MADR or Y-Statement when appropriate. Refuses to edit `accepted` ADRs — opens a superseding one instead, write-once / supersede-don't-edit.

11. `/wiki-kanban-emit <spec-slug>` — the agent decomposes a `wiki/specs/<slug>.md` page onto a [Hermes Kanban](https://github.com/NousResearch/hermes) board. Each task body carries goal + acceptance criteria + fenced Gherkin + inlined glossary + ADR id(s) + a `@wiki-spec` traceability tag. Idempotency key is the triple `<spec-slug>:<adr-id>:<sha256(spec-body)>`. Picks the collaboration pattern from ADR status. The extension is the orchestrator, never a worker. **Requires `hermes` on PATH; preflights `hermes kanban assignees` and aborts with an install hint if missing.**

12. `/wiki-kanban-ingest <task-id|run-id>` — the agent fetches a completed Hermes run and appends an `## Implementation Evidence` section to the originating wiki page (verification commands, changed files, residual risk, run id, one-paragraph summary). Sanitizes the structured handoff — refuses to copy tokens, OAuth material, or raw logs. **Requires `hermes` on PATH.**

13. `/wiki-refine <run-id | breakthrough note>` — the agent closes the R∞ refinement loop when a run outcome or breakthrough invalidates a prior model: updates concept/context pages, hands off to `/wiki-adr` to open a superseding ADR (never edits the accepted predecessor), and re-emits affected kanban tasks via `/wiki-kanban-emit` with a fresh idempotency key.

`AGENTS.md` (the one inside the user's wiki, copied from `template/AGENTS.md`) is the source of truth for page format and every workflow. The slash commands and skill in this package delegate to it rather than restating the rules.

## Repo layout

```
prompts/          pi slash commands: /wiki-new, /wiki-ingest, /wiki-query, /wiki-spec, /wiki-lint,
                  /wiki-flashcards, /wiki-present, /pdf-to-mdbook, /wiki-strategy, /wiki-adr,
                  /wiki-kanban-emit, /wiki-kanban-ingest, /wiki-refine
skills/           pi skill bundle: wiki-maintainer (same workflows, skill UX)
template/         snapshot of the llm-wiki template — what pi-llm-wiki-init copies
bin/init.js       the pi-llm-wiki-init CLI (copies template/ into cwd)
scripts/          maintainer helpers (e.g. sync-from-llm-wiki.sh)
package.json      pi-package keyword, bin entry, files list
README.md         end-user docs
```

## Optional runtime dependency

`hermes` (https://github.com/NousResearch/hermes) is required only for the kanban workflows (`/wiki-kanban-emit`, `/wiki-kanban-ingest`) and the kanban-aware checks inside `/wiki-lint`. The rest of the wiki — ingest, query, spec, ADR, strategy, refinement-as-documentary, flashcards, presentations, PDF→mdBook — works without it. The kanban prompts preflight `hermes kanban assignees` and abort loudly with an install hint when it is missing; they never silently degrade.
