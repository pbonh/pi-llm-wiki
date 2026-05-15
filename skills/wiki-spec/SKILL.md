---
name: wiki-spec
description: Run the Spec workflow against an llm-wiki — synthesize Gherkin scenarios + ubiquitous-language glossary from a user goal. Output is a single wiki/specs/<slug>.md page with adr_ids[] + context frontmatter that feed the kanban round-trip. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
---

# wiki-spec

Synthesize Gherkin specs from a user goal. Output: `wiki/specs/<slug>.md` with `## Goal`, optional `## Scope` impact map, `## User Stories`, `## Scenarios` (fenced ` ```gherkin `), `## Glossary`, `## Sources`.

The wiki schema and workflow details live in `AGENTS.md`. Read `### Spec` and follow the steps there. The [pipeline manifest](../../docs/rd-pipeline/pipeline-manifest.md) is the source of truth for ordering.

## Where this fits

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> ...
```

`scripts/check-prereqs.sh spec --slug <slug>` walks `spec → adr → architecture (optional) → grill (optional) → strategy`. A missing ADR is the most common failure here.

## Usage

```
/skill:wiki-spec <goal or feature request>
```

## Hard rules

- **Accepted-ADR gate (Phase 3).** At least one ADR cited by this spec must be `## Status: accepted` (drafts and superseded don't count). Under `enforcement: warn` this downgrades to a warning; the choice is recorded in `## Sources`.
- **`adr_ids` is load-bearing** — `/wiki-kanban-emit` reads this list to populate per-task `@wiki-adr` tags and compute the per-spec idempotency key.
- **`context` is load-bearing** — `/wiki-kanban-emit` uses it as the `--tenant` value on every emitted task.
- **Quality rules for Gherkin:** business-readable (no UI buttons / DB tables / CSS selectors), single `When` per scenario, realistic data (named personas + concrete numbers), `Scenario Outline` + `Examples` for parameterized cases.
- **Zero-dangling-links acceptance gate** — every `[[...]]` resolves or is stubbed (`confidence: low`).

After a clean run, hint: *"Commit and push so the spec lands on `origin/<trunk>` — `/wiki-kanban-emit` refuses while it's on a feature branch."*
