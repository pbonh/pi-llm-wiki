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
5. Update `wiki/index.md` and append to `wiki/log.md`.
6. Flag contradictions with existing pages.

Never modify files in `raw/`. Prefer updating existing pages over duplicating.

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
