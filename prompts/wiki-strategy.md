---
description: Derive vision, bounded contexts, and a context map from the wiki
argument-hint: "<topic>"
---
Read `AGENTS.md` and follow the **Strategy** workflow to produce strategic-design artifacts for: $@

Steps (from AGENTS.md):
1. Read `wiki/index.md` to find concept/entity/summary pages relevant to the topic; read them in full.
2. Distillation pass — identify which concepts are core (load-bearing) vs. supporting.
3. Write `wiki/vision/<topic-slug>.md` with `type: vision` and the required sections (`## Value Proposition`, `## In Scope`, `## Out of Scope`, `## Differentiation`, `## Revisions`).
4. Identify each model that will participate. For each, write `wiki/contexts/<context-slug>.md` with `type: context` and the required sections (`## Model`, `## Boundary`, `## Ubiquitous Language` inline glossary, `## Relationships`).
5. Write `wiki/context-maps/<topic-slug>.md` with `type: context-map` and the required sections (`## Contexts`, `## Translations` table, `## False Cognates`, `## Integration Patterns`).
6. Cross-link vision ↔ contexts ↔ context map bidirectionally.
7. **Verify zero dangling links — acceptance gate.** Create stubs (`confidence: low`) or remove links until zero remain.
8. Update `wiki/index.md` (Vision / Contexts / Context Maps tables, Statistics counts) and append a dated entry to `wiki/log.md`.

Re-runs *update* existing pages by slug rather than duplicating. If the wiki lacks enough material to identify distinct bounded contexts, say so and suggest sources — do not invent contexts.

After a clean run, hint: *"Strategy written. Next: run `/wiki-grill <topic>` to surface the open design questions before specs are drafted."*
