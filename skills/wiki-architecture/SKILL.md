---
name: wiki-architecture
description: Run the Architecture workflow against an llm-wiki — draw C4 diagrams in Mermaid that answer a stated Purpose, surface architectural decisions for ADR ingestion. Use in any directory containing an AGENTS.md that follows the llm-wiki schema. Composes with wiki-grill (upstream) and wiki-adr (downstream).
---

# wiki-architecture

Draw [C4 diagrams](https://c4model.com/) in Mermaid for a topic, only after stating a one-sentence `## Purpose`, and only at the chosen levels. Output: `wiki/architecture/<topic>.md` with the diagrams plus a `## Decisions Surfaced` list that `/wiki-adr` consumes.

The wiki schema and workflow details live in `AGENTS.md`. Read `### Architecture` and follow the steps there. The [pipeline manifest](../../docs/rd-pipeline/pipeline-manifest.md) is the source of truth for ordering.

## Where this fits

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> ...
```

`scripts/check-prereqs.sh architecture --slug <topic>` walks `architecture → grill → strategy`. The vision page is required; `grill` is `optional_in_v1: true` (warns rather than blocks).

## Usage

```
/skill:wiki-architecture <topic>
```

## Hard rules

- **Refuse to draw without a stated `## Purpose`.** *"general system architecture"* fails the gate; *"How does a rate request flow through cache, carrier adapters, and aggregator when one carrier times out?"* passes.
- **Refuse all five C4 levels without per-level justification.** Each level should answer a real question the user can name.
- **`## Decisions Surfaced` is load-bearing** for `/wiki-adr` — every accepted ADR must cite a bullet here. After `/wiki-adr` runs, the matching bullet is upserted with `→ ADR-NNNN`.
- **Mermaid only** (`C4Context` / `C4Container` / `C4Component` / `C4Deployment`; `sequenceDiagram` / `flowchart` for Dynamic). ASCII fallback only on explicit opt-out.

Re-runs update Mermaid blocks in place (keyed by parent heading).

After a clean run, hint: *"Architecture pending approval. Run `/wiki-adr <decision title>` for each surfaced decision."*
