# `/wiki-strategy`

Run the [domain-driven design](https://martinfowler.com/bliki/BoundedContext.html) strategic-design phase against the wiki's existing knowledge: distill the core domain, name the bounded contexts that will participate in the R&D effort, draw the initial context map. Downstream specs and ADRs anchor in this model.

## Usage

```
/wiki-strategy <topic>
```

`<topic>` is the topic of the R&D effort — a domain, a feature area, a product theme. The topic slug is the stable identifier across re-runs.

## What it reads

- `wiki/index.md` to find pages relevant to the topic.
- Every concept / entity / summary page the topic touches, in full.
- If they exist: `wiki/concepts/distillation.md`, `wiki/concepts/strategic-design.md`, `wiki/concepts/bounded-context.md` (auto-stubbed by the dangling-links gate if absent).

## What it writes

Three artifact types, all under `wiki/`:

### `wiki/vision/<topic-slug>.md` — one page per R&D effort

Frontmatter: `type: vision`. Required sections:

- `## Value Proposition` — one paragraph naming what this R&D effort delivers that is differentiating. Plain English, no jargon.
- `## In Scope` — bulleted list of capabilities, audiences, or domains covered.
- `## Out of Scope` — bulleted list of what is explicitly excluded, especially things a reader might assume are in.
- `## Differentiation` — how this effort differs from adjacent or competing approaches. Cite specific alternatives.
- `## Revisions` — append-only dated log of scope changes. Each entry: `YYYY-MM-DD — what changed and why`.

### `wiki/contexts/<context-slug>.md` — one page per bounded context

Frontmatter: `type: context`. Required sections:

- `## Model` — the model that lives inside this bounded context: its core entities, key invariants, the language it uses.
- `## Boundary` — where this context starts and stops. Name the adjacent contexts and the artifacts that cross the boundary (events, payloads, translated terms).
- `## Ubiquitous Language` — inline glossary (`Term — definition`) for every term that has a specific meaning inside this context. **Inline definitions, do not just link out.** This per-context dictionary is what prevents drift and what `/wiki-kanban-emit` later inlines into task bodies.
- `## Relationships` — links into the relevant `wiki/context-maps/` page(s).

### `wiki/context-maps/<topic-slug>.md` — one page per R&D effort

Frontmatter: `type: context-map`. Required sections:

- `## Contexts` — bulleted list of links to every participating `wiki/contexts/<slug>.md`.
- `## Translations` — markdown table `Term in A | Context A | Term in B | Context B | Notes`. One row per cross-boundary term that needs explicit translation.
- `## False Cognates` — bulleted list of terms that *look* identical across contexts but mean different things. Each entry calls out both meanings and why conflating them would be a bug.
- `## Integration Patterns` — which integration pattern governs each pair of contexts: `shared-kernel`, `customer-supplier`, `conformist`, `anticorruption-layer`, `published-language`, `open-host-service`, `separate-ways`.

## Workflow

1. Read `wiki/index.md`; identify relevant concept/entity/summary pages; read them in full.
2. **Distillation pass.** Identify core (load-bearing) vs. supporting concepts. Pull from `[[concepts/distillation]]` and `[[concepts/strategic-design]]` if they exist.
3. Write `wiki/vision/<topic-slug>.md`.
4. Identify each bounded context that will participate. Write `wiki/contexts/<context-slug>.md` for each.
5. Write `wiki/context-maps/<topic-slug>.md`.
6. Cross-link: every context page references the context map under `## Relationships`; the context map references every context page under `## Contexts`; the vision page references both.
7. **Zero-dangling-links acceptance gate.** Create stubs (`confidence: low`) or remove links until zero remain.
8. Update `wiki/index.md` (Vision / Contexts / Context Maps tables, Statistics counts) and append a dated entry to `wiki/log.md`.

## Re-runs are idempotent

Running `/wiki-strategy <same-topic>` again *updates* the existing pages by slug rather than duplicating them — the same way `/wiki-ingest` updates concept pages. Use this when the wiki has accumulated more material and you want the strategy to reflect it.

## Refusal modes

- **Not enough domain knowledge.** If the wiki does not have enough material to identify distinct bounded contexts (e.g. only two or three concept pages on the topic), the agent says so and suggests sources / further `/wiki-ingest` runs that would fill the gap. **It will not invent contexts.**
- A single bounded context is a valid outcome — in that case the context map is a one-row map of the context against the outside world.

## Downstream consumers

- `/wiki-spec` reads the relevant `wiki/contexts/<slug>.md` glossaries to ground ubiquitous-language terms in scenarios.
- `/wiki-adr` typically cites the bounded-context page(s) the ADR governs.
- `/wiki-kanban-emit` reads the inline `## Ubiquitous Language` from each cited context and **inlines** the glossary excerpt into every task body — this is the false-cognate guard at the worker-fleet scale.
- `/wiki-lint` checks that every `wiki/contexts/` page is referenced by at least one `wiki/context-maps/` page (orphan contexts cannot drift safely).

## Failure modes to watch for

- **Empty Ubiquitous Language sections.** If a context page has no inline glossary, downstream kanban tasks will have nothing to inline and false-cognate drift becomes a runtime risk. The dangling-links gate catches link drift but not empty sections — re-run `/wiki-strategy` or edit the context page directly if you spot this.
- **Vision drift over time.** The `## Revisions` log on the vision page is your audit trail for scope changes. If it falls out of sync with reality, the next `/wiki-strategy <same-topic>` run will surface the gap.
- **Untranslated cross-boundary terms.** Anything that crosses a context boundary must be in the `## Translations` table; anything that looks identical but means different things must be in `## False Cognates`. Missing rows here are the precursor to integration bugs.
