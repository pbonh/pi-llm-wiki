---
description: Draw C4 architecture diagrams in Mermaid — purpose-gated, level-selected, decisions-surfaced
argument-hint: "<topic>"
---
Read `AGENTS.md` and follow the **Architecture** workflow to produce C4 diagrams for: $@

Derive the topic slug from `$@` (kebab-case, the same slug used by `/wiki-strategy` and `/wiki-grill`).

Steps (from AGENTS.md):

1. **Preflight.** Run `scripts/check-prereqs.sh architecture --slug <topic-slug>` from the wiki root. On exit 1, print the helper's `missing` + `hint` verbatim (e.g. `missing: grill — run /wiki-grill first`) and **abort without writing anything**. On exit 0, continue. If `wiki/.pipeline.yaml` is absent, the helper exits 0 and architecture proceeds (back-compat). `grill` is marked `optional_in_v1: true`, so a missing grill page degrades to a warning when enforcement is `strict`-with-optional; it does not block. The vision page upstream of grill IS required.

2. **Context load.** Read `wiki/vision/<topic-slug>.md` in full; read every `wiki/contexts/*.md` it cites; read `wiki/grills/<topic-slug>.md` if it exists (the grill's `## Decisions Made` and `## Open Questions` shape which questions these diagrams must answer). Read related `wiki/concepts/*.md` via `[[wikilinks]]`.

3. **Purpose gate (hard).** Ask the user: *"What question does this diagram set answer?"* — refuse to draw anything until the answer is a single, non-empty sentence. Bad: *"general system architecture"*. Good: *"How does a rate request flow through the cache, carrier adapters, and aggregator when one carrier times out?"*. The one-sentence answer becomes the page's `## Purpose` section verbatim. This is the article's purpose/format/rigor gate; diagrams without a stated question are decoration.

4. **Level selection.** Ask which C4 levels are needed: **Context**, **Container**, **Component**, **Dynamic**, **Deployment**. If the user says *"minimum"* or *"default"*, draw Context + Container only. **Refuse to draw all five without explicit justification** — each level should answer a real question the user can name. If the user insists on all five, ask them to state the question each level answers; record those questions next to each diagram block.

5. **Format — Mermaid C4.** Every diagram is a fenced ` ```mermaid ` block using Mermaid's C4 syntax (`C4Context`, `C4Container`, `C4Component`, `C4Deployment`) or a `sequenceDiagram` / `flowchart` for the Dynamic level. ASCII fallback only if the user explicitly opts out of Mermaid. Do not mix diagrams styles within one level.

6. **Output write.** Emit `wiki/architecture/<topic-slug>.md` with frontmatter:

   ```yaml
   ---
   title: "Architecture: <topic>"
   type: architecture
   tags: [architecture, c4]
   sources: [<related vision / grill / context / concept slugs>]
   last_updated: <today, ISO 8601>
   ---
   ```

   Required sections in this order:

   - `## Purpose` — the one-sentence question this diagram set answers (from step 3).
   - `## System Context` (if chosen) — ` ```mermaid C4Context ` block.
   - `## Container Diagram` (if chosen) — ` ```mermaid C4Container ` block.
   - `## Component Diagram` (if chosen) — ` ```mermaid C4Component ` block.
   - `## Dynamic Diagram` (if chosen) — ` ```mermaid sequenceDiagram ` or `flowchart`.
   - `## Deployment Diagram` (if chosen) — ` ```mermaid C4Deployment ` block.
   - `## Assumptions` — bulleted list of assumptions the diagrams bake in (e.g. *"carrier APIs return within 2s under nominal load"*).
   - `## Open Questions` — anything still uncertain that the diagrams could not resolve; these carry forward to `/wiki-adr` or `/wiki-refine`. Pull verbatim from the grill's `## Open Questions` when relevant.
   - `## Decisions Surfaced` — **bulleted list**, one bullet per architectural decision that the diagrams surface. Each bullet: `**<short decision title>** — <one-line summary>`. This list is what `/wiki-adr` consumes — every accepted ADR must cite a bullet here as its triggering ASR context.
   - `## Cross-Links` — backlinks to `[[wiki/vision/<topic-slug>]]`, `[[wiki/grills/<topic-slug>]]` (if present), cited contexts/concepts; forward placeholders to `[[wiki/decisions/...]]` and `[[wiki/specs/<topic-slug>]]` (resolve via the dangling-links gate by stubbing or removing).

7. **Approval gate (no auto-invoke).** After writing the page, print: *"Architecture pending approval. Run `/wiki-adr <decision title>` for each entry in `## Decisions Surfaced` to pin its rationale and unblock `/wiki-spec`."* **Do not invoke `/wiki-adr` automatically** — the user picks which surfaced decisions warrant a written record.

8. **Cross-link back.** For each `wiki/contexts/<context>.md` page the diagrams reference, append (or update in place) a `## Architecture` section linking `[[wiki/architecture/<topic-slug>]]`. Do not rewrite the rest of the context page.

9. **Idempotency.** Mermaid blocks are keyed by their parent heading (`## Container Diagram` etc.). A re-run rewrites the block under the existing heading rather than appending. `## Decisions Surfaced` bullets are keyed by short title — same title rewrites the same bullet, new titles append. `## Assumptions` and `## Open Questions` are append-only. After `/wiki-adr` is run for a surfaced decision, the bullet is upserted with `→ ADR-NNNN` at the end (this is `/wiki-adr`'s job, not architecture's).

10. **Zero-dangling-links acceptance gate.** Same rule as the rest of the wiki: every `[[...]]` reference must resolve. Stub (`confidence: low`) or remove. Forward placeholders to ADRs and specs that don't exist yet get the same treatment.

11. **Index + log.** Update `wiki/index.md` (add a row under a `## Architecture` table; create the table if absent; bump Statistics) and append a dated entry to `wiki/log.md`.

After a clean run, `scripts/check-prereqs.sh adr --slug <topic-slug>` is expected to succeed — `/wiki-adr <surfaced decision title>` is the next step in the pipeline.

**Refusal modes:**

- `## Purpose` empty → refuse to emit any diagram. The page is not written.
- User requests all five C4 levels without stating a question each answers → refuse and re-ask.
- Vision page missing → preflight catches it via the transitive walk.
- Grill present but empty `## Decisions Made` → warn but proceed; flag that `## Decisions Surfaced` will be the first record of any decision identified during diagramming.
