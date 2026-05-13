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

`AGENTS.md` (the one inside the user's wiki, copied from `template/AGENTS.md`) is the source of truth for page format and all five workflows. The slash commands and skill in this package delegate to it rather than restating the rules.

## Repo layout

```
prompts/          pi slash commands: /wiki-new, /wiki-ingest, /wiki-query, /wiki-lint, /wiki-flashcards, /wiki-present, /pdf-to-mdbook
skills/           pi skill bundle: wiki-maintainer (same workflows, skill UX)
template/         snapshot of the llm-wiki template — what pi-llm-wiki-init copies
bin/init.js       the pi-llm-wiki-init CLI (copies template/ into cwd)
scripts/          maintainer helpers (e.g. sync-from-llm-wiki.sh)
package.json      pi-package keyword, bin entry, files list
README.md         end-user docs
```
