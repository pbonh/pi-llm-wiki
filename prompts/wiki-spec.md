---
description: Synthesize Gherkin specs from a user goal
argument-hint: "<goal or feature request>"
---
Read `AGENTS.md` and follow the **Spec** workflow to produce specs for: $@

Steps (from AGENTS.md):
1. Read `wiki/index.md` to find concept/entity pages relevant to the goal, then read those pages in full.
2. If the goal lacks a clear actor + outcome, emit only the `## Scope` impact map (actors, impacts, deliverables) and ask the user to confirm scope before producing scenarios. Otherwise skip the impact map.
3. Derive user stories with binary pass/fail acceptance criteria.
4. Translate acceptance criteria into Gherkin scenarios inside ` ```gherkin ` fenced blocks. Quality rules: business-readable (no UI buttons, DB tables, or CSS selectors); single `When` per scenario; realistic data (named personas, concrete numbers); `Scenario Outline` + `Examples` for parameterized cases.
5. Emit a `## Glossary` of ubiquitous-language terms used; link any term that already exists as `concepts/<term>`.
6. Write `wiki/specs/<slug>.md` with frontmatter (`type: spec`) and the required sections (`## Goal`, optional `## Scope`, `## User Stories`, `## Scenarios`, `## Glossary`, `## Sources`).
7. **Verify zero dangling links — acceptance gate.** Scan every `[[...]]` reference and confirm the target file exists. For each dangling link, either create a stub concept page (full schema, `confidence: low`) or remove the link. Re-scan until zero remain.
8. Update `wiki/index.md` (add a row under `## Specs`, bump Statistics) and append a dated entry to `wiki/log.md`.

If the wiki lacks enough domain knowledge to ground the scenarios in real concepts, say so and suggest sources that would fill the gap — do not invent claims.
