# pi-llm-wiki

[pi coding agent](https://pi.dev/docs/latest) integration for the [llm-wiki](https://github.com/pbonh/llm-wiki) template.

Adds four slash commands and one skill to pi, plus a standalone init binary. **The template is bundled** — you do not need to clone `llm-wiki` separately. `npm install -g pi-llm-wiki`, run `pi` in any directory (empty or existing), and `/wiki:new` will scaffold and customize a wiki for you.

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
/wiki:new a knowledge base about espresso extraction
```

pi will detect the directory is empty, run `pi-llm-wiki-init` to drop the bundled template into place, then walk through the `<!--` customization markers in `AGENTS.md` — the Purpose paragraph, the Tagging Taxonomy, and any future customization blocks — confirming taxonomy choices with you before committing.

### Operate an existing wiki

Run `pi` inside any directory that already has an `AGENTS.md` matching the llm-wiki schema. The same commands work — `/wiki:new` will skip re-initialization and go straight to customizing whatever markers remain.

### Slash commands

| Command | What it does |
|---|---|
| `/wiki:new <domain>` | Bootstrap a wiki in the cwd. Drops the bundled template if `AGENTS.md` is missing, then customizes every `<!-- ... -->` block. |
| `/ingest <path>` | Run the Ingest workflow on a file in `raw/` — generates a summary page, creates/updates concept and entity pages, adds cross-links, updates `wiki/index.md` and `wiki/log.md`. |
| `/query <question>` | Search the wiki and synthesize an answer with `[[wiki-link]]` citations. Creates a synthesis page in `wiki/syntheses/` if the answer reveals novel insight. |
| `/lint` | Audit the wiki for orphans, contradictions, missing links, and incomplete sections. Fixes what it can and reports the rest. |

### Skill (alternative entry point)

```
/skill:wiki-maintainer new <domain>
/skill:wiki-maintainer ingest <path>
/skill:wiki-maintainer query <question>
/skill:wiki-maintainer lint
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

The `<!--` HTML comments in `AGENTS.md` mark the customization points. `/wiki:new` enumerates them with `grep`, treats the comment text as the spec for what to fill in, and verifies completion by re-running `grep` and requiring zero matches. New customization blocks added to `AGENTS.md` upstream are automatically handled — no `pi-llm-wiki` change needed.

## Keeping the bundled template in sync with upstream

The `template/` directory is a snapshot of the [llm-wiki](https://github.com/pbonh/llm-wiki) repo (minus `LICENSE` and `README.md`). To resync after an upstream schema change:

```bash
scripts/sync-from-llm-wiki.sh ../llm-wiki   # or wherever your clone lives
git diff template/
# bump version in package.json and publish
```

## License

MIT
