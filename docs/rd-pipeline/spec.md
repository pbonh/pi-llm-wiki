# `/wiki-spec`

Run an automated [specification-by-example](https://en.wikipedia.org/wiki/Specification_by_example) workshop against the wiki's existing knowledge. Consumes domain concepts the same way `/wiki-query` does, but emits formal Gherkin scenarios + binary-pass/fail acceptance criteria + a ubiquitous-language glossary instead of prose.

## Usage

```
/wiki-spec <goal>
```

`<goal>` is a user goal, feature request, or capability description in plain English.

## What it writes

`wiki/specs/<slug>.md` — one page per spec.

Frontmatter: `type: spec`, tags including `spec` and `gherkin` plus domain tags.

Required sections:

- `## Goal` — one-paragraph restatement of the user's intent.
- `## Scope` *(conditional)* — emitted only when the goal was vague enough to need impact-mapping. Table of `Actor | Impact | Deliverable`.
- `## User Stories` — one block per story:
  ```
  **Story:** As a <actor>, I want <capability>, so that <outcome>.
  **Acceptance criteria:**
  - binary pass/fail statement
  - binary pass/fail statement
  ```
- `## Scenarios` — Gherkin feature(s) inside ```` ```gherkin ```` fenced blocks. Quality rules below.
- `## Glossary` — `Term — definition` lines for the ubiquitous-language terms used. Existing terms link as `concepts/<term>`.
- `## Sources` — wiki links to every concept or entity page cited.

## Gherkin quality rules

- **Business-readable.** No UI buttons, no DB tables, no CSS selectors. Steps describe outcomes ("the invoice is marked paid"), not interactions ("she clicks the Pay button").
- **Single `When` per scenario.** Keep behaviors decoupled.
- **Realistic data.** Named personas, concrete numbers, not generic placeholders (`customer1`, `value1`).
- **`Scenario Outline` + `Examples`** for parameterized cases (the carrier-timeout case in the tutorial covers all three carriers in one outline).

## Workflow

1. Read `wiki/index.md`; find concept/entity pages relevant to the goal's domain; read them in full.
2. **ADR check (soft gate).** Scan `wiki/decisions/` for an `accepted` ADR governing this domain — heuristic: an ADR whose `## Context` cites the same context/concept pages the goal touches. If none, warn the user:
   > *"No accepted ADR found for this domain. Architectural commitments embedded inline in this spec will be hard to track across re-emissions. Consider drafting a [[concepts/y-statement]] ADR via `/wiki-adr` first."*
   Offer to hand control to `/wiki-adr`. On confirm-to-proceed-without-ADR, continue; record the choice in the spec's `## Sources`.
3. **Vagueness check.** If the goal lacks a clear actor + outcome, emit only the `## Scope` impact map and ask the user to confirm scope before producing scenarios. If actor + outcome are clear, skip the impact map.
4. Derive user stories with binary pass/fail acceptance criteria.
5. Translate each acceptance criterion into Gherkin under the quality rules above.
6. Extract a `## Glossary` of every ubiquitous-language term used. Link terms that already exist as `concepts/<term>`; flag any new term that warrants its own concept page.
7. Write `wiki/specs/<slug>.md` with full frontmatter and required sections.
8. **Zero-dangling-links acceptance gate.** Same as Ingest — every `[[...]]` resolves to a real file. Missing pages get stubbed (`confidence: low`, brief content grounded in how the spec uses the term) or the link is removed. Re-scan until zero.
9. Update `wiki/index.md` (add a row under `## Specs`, bump the Specs Statistics count); append to `wiki/log.md` (goal, slug, story count, scenario count, pages cited).

## Refusal modes

- **Not enough domain knowledge.** If the wiki lacks enough material to ground the scenarios in real concepts, the agent says so and suggests sources that would fill the gap. **It will not invent business rules.**
- **Vague goal with no scope confirmation.** If the vagueness check kicked in and the user does not confirm scope, the workflow stops at the impact map — no scenarios are written.

## Re-emission

Re-running `/wiki-spec` on the same goal will *update* the existing `wiki/specs/<slug>.md` if the slug matches. If the goal is materially different but you reuse the slug, you will overwrite the prior spec — pick a new goal phrasing or a new slug if that is a concern.

`/wiki-kanban-emit` computes its idempotency key over the spec body, so editing the spec page (re-running `/wiki-spec` or editing by hand) bumps the sha256 and triggers a task update on the next emit.

## What the spec *is* and *is not*

- **Is:** an executable specification. The Gherkin block is intended to be copy-pasted into a real test runner. The acceptance criteria and glossary feed kanban task bodies verbatim.
- **Is not:** a synthesis page. The Spec workflow does not write a `wiki/syntheses/` page — specs are the artifact, not a cross-cutting analysis.
- **Is not:** a design document. Architectural commitments belong in ADRs, not embedded in spec prose. The ADR gate is what enforces this — when you hit it and proceed without an ADR, you are accumulating an inline commitment that will be painful to track.

## Downstream consumers

- `/wiki-kanban-emit` reads the spec in full and decomposes it onto a kanban board, inlining glossary excerpts from the context page(s) into each task body.
- `/wiki-kanban-ingest` appends `## Implementation Evidence` to the spec page as runs complete.
- `/wiki-refine` re-emits affected tasks against the spec when an underlying ADR is invalidated.
- `/wiki-lint` warns on specs that cite no `accepted` ADR (same heuristic as the soft gate above).

## Failure modes to watch for

- **Glossary drift.** If the same term means different things across two specs, you have a false-cognate problem; the context-map page is where false cognates should be flagged. Re-run `/wiki-strategy` on the affected topic.
- **Acceptance criteria that are not binary.** "The system should be fast" is not a binary criterion; "the p99 latency is <50ms" is. The Gherkin scenarios should be testable, not aspirational.
- **Inline architectural commitments.** If you find yourself writing "and the cache must be keyed by X" inside a scenario, that is an ADR hiding in spec clothing. Open `/wiki-adr` for it.
