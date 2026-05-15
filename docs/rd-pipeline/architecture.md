# `/wiki-architecture`

Draw C4 architecture diagrams in Mermaid for a topic, only after the grill has surfaced the questions they need to answer, and only with a stated `## Purpose`. The page's `## Decisions Surfaced` list is what `/wiki-adr` consumes next.

Architecture sits between [`/wiki-grill`](./grill.md) (which surfaces the *questions*) and [`/wiki-adr`](./adr.md) (which pins the *commitments*). It is the answer to "we know what we're deciding; how does the system actually fit together?"

## Usage

```
/wiki-architecture <topic>
```

`<topic>` is the same topic slug used by `/wiki-strategy` and `/wiki-grill`. Re-running `/wiki-architecture <same-topic>` updates the existing page in place — Mermaid blocks are keyed by their parent heading.

## Where it sits in the pipeline

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> ...
```

The pipeline manifest wires this in. `/wiki-architecture` calls [`scripts/check-prereqs.sh architecture --slug <topic>`](./pipeline-manifest.md); the helper walks `requires: [grill]`, and `grill.requires: [strategy]` transitively, so a missing vision page surfaces as `missing: strategy` even when the immediate cause is the missing grill.

`architecture.optional_in_v1: true` in the default manifest — downstream `/wiki-adr` will warn rather than hard-fail when no architecture page exists. Tighten to required in v2.

## What it reads

- `wiki/vision/<topic-slug>.md` — the strategy output (transitively required).
- `wiki/grills/<topic-slug>.md` if present — its `## Decisions Made` and `## Open Questions` shape which questions the diagrams must answer.
- `wiki/contexts/<context>.md` referenced from the vision or grill — for ubiquitous-language terms inside the diagrams.
- `wiki/concepts/<concept>.md` reachable via `[[wikilinks]]`.

## What it writes

`wiki/architecture/<topic-slug>.md`. One page per topic slug; same slug on re-run updates in place.

### Frontmatter

```yaml
---
title: "Architecture: <topic>"
type: architecture
tags: [architecture, c4]
sources: [<related vision / grill / context / concept slugs>]
last_updated: <ISO 8601>
---
```

### Required sections

| Section | Purpose | Idempotency |
|---|---|---|
| `## Purpose` | One-sentence question this diagram set answers. **Hard gate**: page is not written until this is filled. | Rewritten on each run. |
| `## System Context` | Mermaid `C4Context` block (when chosen). | Keyed by heading; rewritten in place. |
| `## Container Diagram` | Mermaid `C4Container` block (when chosen). | Keyed by heading; rewritten in place. |
| `## Component Diagram` | Mermaid `C4Component` block (when chosen). | Keyed by heading; rewritten in place. |
| `## Dynamic Diagram` | Mermaid `sequenceDiagram` / `flowchart` (when chosen). | Keyed by heading; rewritten in place. |
| `## Deployment Diagram` | Mermaid `C4Deployment` block (when chosen). | Keyed by heading; rewritten in place. |
| `## Assumptions` | Bulleted list of assumptions the diagrams bake in. | Append-only across runs. |
| `## Open Questions` | Anything still uncertain; carries forward to `/wiki-adr` or `/wiki-refine`. | Append-only across runs. |
| `## Decisions Surfaced` | Bulleted list — one bullet per architectural decision the diagrams surface. **Load-bearing for `/wiki-adr`.** | Keyed by short title; same title rewrites, new titles append. After `/wiki-adr` runs, each bullet is upserted with `→ ADR-NNNN`. |
| `## Cross-Links` | Backlinks to vision / grill / contexts; forward placeholders to ADRs / spec. | Rewritten on each run. |

Plus a `## Architecture` section appended (or updated in place) on each referenced `wiki/contexts/<context>.md` linking forward to the architecture page.

## Workflow

1. **Preflight.** Run `scripts/check-prereqs.sh architecture --slug <topic-slug>`. Exit 1 → print `missing` + `hint` and abort. Exit 0 → proceed. Manifest absent → exit 0 (back-compat).
2. **Context load.** Read vision + grill (if present) + cited contexts + reachable concepts.
3. **Purpose gate.** Ask the user *"What question does this diagram set answer?"*. Refuse to draw anything until they give a non-empty sentence.
4. **Level selection.** Ask which C4 levels are needed. Default to Context + Container. Refuse all five without explicit per-level justification.
5. **Format.** All diagrams as fenced Mermaid (` ```mermaid `). Use `C4Context` / `C4Container` / `C4Component` / `C4Deployment` syntax; use `sequenceDiagram` or `flowchart` for the Dynamic level. ASCII fallback only on opt-out.
6. **Output write.** Emit the page with the sections above.
7. **Approval gate.** Print *"Architecture pending approval. Run `/wiki-adr <decision title>` for each surfaced decision."* Do **not** invoke `/wiki-adr` automatically — the user picks which surfaced decisions warrant a written record.
8. **Cross-link back.** Append a `## Architecture` link on every referenced `wiki/contexts/<context>.md`.
9. **Zero-dangling-links acceptance gate.** Forward placeholders to ADR / spec pages that don't exist yet get stubbed (`confidence: low`) or removed.
10. **Index + log.** Update `wiki/index.md` `## Architecture` table (create if absent) and append to `wiki/log.md`.

## Refusal modes

- **Empty `## Purpose`.** No diagram is written. The page is not emitted at all.
- **All five levels without justification.** The prompt re-asks for the question each level answers.
- **Missing vision page.** Preflight returns `missing: strategy — run /wiki-strategy first` (transitively, even though the immediate prereq is `grill` which is optional in v1).
- **Empty grill `## Decisions Made`.** Warn but proceed; flag that `## Decisions Surfaced` will be the first record of any decision identified during diagramming.

## Idempotency

- Mermaid blocks are keyed by parent heading (`## Container Diagram` etc.); a re-run rewrites the block under the existing heading rather than appending.
- `## Decisions Surfaced` bullets are keyed by short title — same title rewrites, new titles append.
- `## Assumptions` and `## Open Questions` are append-only across runs.
- After `/wiki-adr` is run for a surfaced decision, the matching bullet is upserted with `→ ADR-NNNN` (this is `/wiki-adr`'s job, not architecture's).

## Downstream consumers

- `/wiki-adr` requires a `## Decisions Surfaced` entry on the architecture page that matches the ADR's short title. ADRs whose ASR can't be traced to a surfaced decision are exactly the AKM log-bloat failure mode this whole pipeline guards against.
- `/wiki-spec` reads the diagrams to ground actor / boundary / cross-system terminology in scenarios.
- `/wiki-refine` may amend the diagrams (and append to `## Open Questions`) when a run outcome invalidates an architectural assumption.
- `/wiki-lint` (Phase 7) parses every Mermaid block and validates it (via `mmdc --parseOnly` when `mmdc` is on PATH).

## Failure modes to watch for

- **Drawing without a question.** A page with diagrams but a thin `## Purpose` decays into wallpaper. If `## Purpose` reads like *"general system architecture"*, the gate should have rejected it; if it slipped through, `/wiki-lint` will flag it.
- **Decisions that never get ADRs.** A bullet in `## Decisions Surfaced` that never gets a `→ ADR-NNNN` annotation is a deferred commitment. `/wiki-lint` reports these so the user can either open an ADR or remove the bullet.
- **Diagrams that drift from contexts.** The diagrams use ubiquitous-language terms from `wiki/contexts/<context>.md`; if a context's `## Ubiquitous Language` changes, re-run `/wiki-architecture` so the diagrams stay anchored.
