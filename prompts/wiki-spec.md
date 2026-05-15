---
description: Synthesize Gherkin specs from a user goal
argument-hint: "<goal or feature request>"
---
Read `AGENTS.md` and follow the **Spec** workflow to produce specs for: $@

Derive the spec slug from `$@` (kebab-case).

**Preflight (hard).** Run `scripts/check-prereqs.sh spec --slug <spec-slug>` from the wiki root. On exit 1, print the helper's `missing` + `hint` verbatim and abort without writing anything. The manifest walks `spec → adr → architecture (optional) → grill (optional) → strategy (required)`. A missing ADR is the most common failure here — the helper prints `missing: adr — run /wiki-adr first`. Exit 0 → proceed. Manifest absent → back-compat.

**Accepted-ADR gate (hard).** Beyond the file-existence the helper checks, at least one ADR cited by this spec must have `## Status: accepted` (drafts and superseded ADRs don't count). If the spec references no accepted ADR, abort with: *"missing: accepted-adr — at least one ADR cited by this spec must be `## Status: accepted` before tasks can be emitted from it. Flip an existing ADR to accepted, or open a new one via `/wiki-adr`."* Under `enforcement: warn` this downgrades to a warning the user can override; record any proceed-without-accepted-ADR choice in the spec's `## Sources` section.

Steps (from AGENTS.md):
1. Read `wiki/index.md` to find concept/entity pages relevant to the goal, then read those pages in full.
2. **ADR selection.** The hard preflight above is binary; this step picks *which* accepted ADRs the spec actually depends on. Read each candidate ADR's `## Context` and `## Decision`; cite every ADR whose decision constrains the scenarios.
3. If the goal lacks a clear actor + outcome, emit only the `## Scope` impact map (actors, impacts, deliverables) and ask the user to confirm scope before producing scenarios. Otherwise skip the impact map.
4. Derive user stories with binary pass/fail acceptance criteria.
5. Translate acceptance criteria into Gherkin scenarios inside ` ```gherkin ` fenced blocks. Quality rules: business-readable (no UI buttons, DB tables, or CSS selectors); single `When` per scenario; realistic data (named personas, concrete numbers); `Scenario Outline` + `Examples` for parameterized cases.
6. Emit a `## Glossary` of ubiquitous-language terms used; link any term that already exists as `concepts/<term>`.
7. **Write `wiki/specs/<slug>.md`** with frontmatter:

   ```yaml
   ---
   title: "Spec: <goal slug>"
   type: spec
   tags: [spec, gherkin, <domain tags>]
   created: <today>
   updated: <today>
   sources: [<related concept/entity slugs>]
   adr_ids: ["NNNN", "MMMM"]      # every ADR id this spec depends on
   context: <bounded-context-slug>  # used by /wiki-kanban-emit as the tenant
   ---
   ```

   Required sections: `## Goal`, optional `## Scope`, `## User Stories`, `## Scenarios`, `## Glossary`, `## Sources`. **`adr_ids` is load-bearing for `/wiki-kanban-emit`** — it reads this list to populate per-task `@wiki-adr` tags and to compute the per-spec idempotency key. **`context` is load-bearing for `/wiki-kanban-emit`** — it becomes the `--tenant` value on every emitted task.

8. **Verify zero dangling links — acceptance gate.** Scan every `[[...]]` reference and confirm the target file exists. For each dangling link, either create a stub concept page (full schema, `confidence: low`) or remove the link. Re-scan until zero remain.
9. Update `wiki/index.md` (add a row under `## Specs`, bump Statistics) and append a dated entry to `wiki/log.md`.

If the wiki lacks enough domain knowledge to ground the scenarios in real concepts, say so and suggest sources that would fill the gap — do not invent claims.

After a clean run, hint: *"Spec written. Commit and push so it lands on `origin/<trunk>` — `/wiki-kanban-emit <slug>` will refuse to emit kanban tasks while the spec is on a feature branch (idempotency keys would hash a moving target)."*
