---
name: wiki-strategy
description: Run the Strategy workflow against an llm-wiki — distill the core domain, name bounded contexts, draw a context map. Use in any directory containing an AGENTS.md that follows the llm-wiki schema. Composes with wiki-grill, wiki-architecture, wiki-adr, wiki-spec for the full R&D pipeline.
---

# wiki-strategy

Run the [domain-driven design](https://martinfowler.com/bliki/BoundedContext.html) strategic-design phase against an llm-wiki knowledge base. Output: one page in `wiki/vision/`, one or more pages in `wiki/contexts/`, one page in `wiki/context-maps/`.

The wiki schema and workflow details live in `AGENTS.md` at the repo root. This skill is a thin dispatcher — read AGENTS.md `### Strategy` and follow the steps there. The [pipeline manifest](../../docs/rd-pipeline/pipeline-manifest.md) (`wiki/.pipeline.yaml`) is the source of truth for which artifacts come before and after.

## Where this fits

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> ...
```

`/wiki-strategy <topic>` is the entry point of the R&D pipeline. No prereqs (other than enough ingested domain material to identify bounded contexts).

## Usage

```
/skill:wiki-strategy <topic>
```

Re-runnable — later runs update existing pages by slug rather than duplicating.

## Refusal modes

- Wiki has too few concept/entity pages to identify distinct bounded contexts → say so, suggest `/wiki-ingest` first. Do not invent contexts.
- A single bounded context is a valid outcome — the context map then describes the boundary against the outside world.

After a clean run, hint: *"Next: `/wiki-grill <topic>` to surface the open design questions."*
