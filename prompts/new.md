---
description: Bootstrap a new llm-wiki (in an empty dir or an existing clone) and customize it
argument-hint: "<one-paragraph-domain-description>"
---
Bootstrap an llm-wiki in the current directory for the domain: "$@"

Step 1 — ensure the template exists.

- Check whether `AGENTS.md` exists in the current directory.
- If it does NOT exist, run `!pi-llm-wiki-init` to drop the bundled llm-wiki template (AGENTS.md, CLAUDE.md stub, raw/, wiki/ skeleton, .gitignore) into the current directory. This command ships with `pi-llm-wiki` and copies its bundled `template/` into the cwd; no network or clone required.
- If `AGENTS.md` does exist, proceed without running the init — the directory is already an llm-wiki, and we're customizing it in place.

Step 2 — customize via the `<!--` marker workflow.

The customization points in `AGENTS.md` are marked with `<!-- ... -->` HTML comments. Every such block tells you what the user is meant to fill in (Purpose paragraph, Tagging Taxonomy, etc.). Treat the markers — not any specific section names — as the authoritative list of things to customize. Future versions of the template may add more.

1. Read `AGENTS.md` end-to-end.
2. Run `grep -n '<!--' AGENTS.md` (or scan the file) to enumerate every customization block. For each block, the contiguous `<!-- ... -->` comments describe what's expected and the placeholder text immediately following them is what gets replaced (e.g. `[YOUR TOPIC]`, `Category-A: tag-1, tag-2, tag-3`).
3. For each block:
   - **Mechanical fills** (e.g. the Purpose paragraph derived directly from "$@"): generate the replacement, swap it in, and remove the `<!-- ... -->` comments. Show the user a summary at the end, not before each step.
   - **Judgment calls** (e.g. choosing taxonomy category names and specific tags): propose your choices to the user first and incorporate their feedback before committing the change. Then remove the `<!-- ... -->` comments.
4. After all blocks are processed, run `grep -n '<!--' AGENTS.md` again. It must return zero results — that's the completion signal. If any markers remain, you missed a block; finish it.
5. Update the title in `wiki/index.md` and any domain-flavored copy in `wiki/index.md` and `wiki/log.md`.

Step 3 — commit.

If the directory is a git repo (or you just created one via `git init`), stage and commit with the message: `Customize llm-wiki for <domain>`. If the user prefers not to initialize git, skip the commit.

Do not ingest any sources yet — leave `raw/` empty. The user will add sources and run `/ingest` next.
