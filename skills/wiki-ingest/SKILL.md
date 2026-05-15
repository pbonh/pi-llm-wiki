---
name: wiki-ingest
description: Run the Ingest workflow against an llm-wiki — read a raw source, produce a summary page plus concept and entity pages, add cross-links, run the zero-dangling-links acceptance gate. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
---

# wiki-ingest

Read a file from `raw/` and produce the wiki pages it implies — a summary, concept pages, entity pages, all cross-linked. The zero-dangling-links acceptance gate keeps the graph honest: every `[[...]]` must resolve.

The wiki schema and workflow details live in `AGENTS.md` at the repo root. Read `### Ingest` and follow the steps there.

## Usage

```
/skill:wiki-ingest <path>
```

`<path>` is a file in `raw/`.

## Hard rules

- Never modify files in `raw/`.
- **Zero-dangling-links acceptance gate.** Every `[[...]]` reference must resolve to a real file. Create stub concept pages (`confidence: low`) for terms that only surface in passing, or remove the link. A summary that cites pages which don't exist is a workflow failure, not a partial success.
- Prefer updating existing pages over duplicating.
- Flag contradictions with existing wiki content — do not silently overwrite.

## Where this fits

Ingest is the entry point of the *knowledge-graph* loop. Re-run it whenever a new source lands. The downstream R&D pipeline (`/wiki-strategy`, `/wiki-grill`, …) reads the concept graph this skill builds.
