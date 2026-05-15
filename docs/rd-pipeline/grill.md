# `/wiki-grill`

Surface and resolve open design questions **before** specs are written. Modeled on [Matt Pocock's `grill-me` skill](https://github.com/mattpocock/skills/blob/main/skills/productivity/grill-me/SKILL.md): build a decision tree, interrogate depth-first, ask **one question at a time** with concrete options. Park what you cannot answer; record what you decide. The output is the wiki's record of why later ADRs and specs ended up where they did.

Grill sits between [`/wiki-strategy`](./strategy.md) (which names *what* the R&D effort is) and [`/wiki-architecture`](./architecture.md) (which draws *how* the system fits together). It is the answer to "we have a vision, but what are the actual decisions we have not yet made?"

## Usage

```
/wiki-grill <topic>
```

`<topic>` is the same topic slug used by `/wiki-strategy`. Re-running `/wiki-grill <same-topic>` **resumes** rather than duplicating: it picks up at the next unanswered subtree.

## Where it sits in the pipeline

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> ...
```

The pipeline manifest (`wiki/.pipeline.yaml`) wires this in. `/wiki-grill` calls [`scripts/check-prereqs.sh`](./pipeline-manifest.md) with artifact name `grill`; the helper walks `requires: [strategy]` and refuses to proceed when the vision page is missing.

In v1, `grill` is marked `optional_in_v1: true` — downstream phases will warn rather than hard-fail when no grill page exists. Tighten to required in v2.

## What it reads

- `wiki/vision/<topic-slug>.md` — the strategy output. Hard prereq.
- Every `wiki/contexts/<context>.md` referenced from the vision page.
- Every `wiki/concepts/<concept>.md` reachable via `[[wikilinks]]` from those pages.
- The existing `wiki/grills/<topic-slug>.md` if any — used for resume, not overwritten.

## What it writes

`wiki/grills/<topic-slug>.md`. One page per topic slug; same slug on re-run updates in place.

### Frontmatter

```yaml
---
title: "Grill: <topic>"
type: grill
tags: [grill, design]
sources: [<related strategy / context / concept slugs>]
last_updated: <ISO 8601 date>
---
```

### Required sections

| Section | Purpose | Idempotency |
|---|---|---|
| `## Decision Tree` | Numbered 3–7 top-level decisions, with indented sub-questions surfaced during interrogation. | Sub-question lines append; top-level entries keyed by short title rewrite in place. |
| `## Q&A Log` | Numbered `Q<n>` / `A<n>` pairs, exact wording preserved, oldest-first. | **Append-only**, global numbering. Resume picks up at `Q<next>`. |
| `## Decisions Made` | One bullet per resolved decision: `**<title>** — <picked option>. <rationale>`. | Keyed by `<title>` — same title rewrites the same bullet; new titles append. |
| `## Open Questions` | Parked items, verbatim. | Append-only across runs; never re-ask. |
| `## Cross-Links` | Backlinks to strategy / contexts / concepts; forward placeholders to architecture / ADR / spec. | Rewritten on each run. |
| `## Status` | `in progress` mid-grill, `done` on clean exit (or omitted). | Rewritten on each run. |

Plus a `## Grill Notes` section appended (or updated in place) on `wiki/vision/<topic-slug>.md` pointing forward to the grill page.

## Workflow

1. **Preflight.** Run `scripts/check-prereqs.sh grill --slug <topic-slug>`. Exit 1 → print `missing: <name> — <hint>` and abort. Exit 0 → proceed. Manifest absent → exit 0 (back-compat).
2. **Context load.** Read the vision page in full, then every `wiki/contexts/*.md` it cites, then every `wiki/concepts/*.md` reachable from there via `[[wikilinks]]`.
3. **Resume check.** If the grill page exists, treat its `## Decision Tree`, `## Q&A Log`, `## Decisions Made`, and `## Open Questions` as authoritative. Resume at the next unanswered question.
4. **Decision-tree elicitation (first run only).** Identify 3–7 top-level decisions, print them numbered under a candidate `## Decision Tree`, and ask which to grill first. **Do not proceed until the user picks.**
5. **Depth-first interrogation.** For the chosen subtree, ask **exactly one question per turn**. Each question has 2–4 concrete options numbered, plus an `other → free text` escape. Branch into follow-ups until the subtree is exhausted; then return to the next top-level decision the user selects.
6. **Park open questions.** "I don't know yet", "park this", "skip" → copy the question verbatim into `## Open Questions` and move on. Never blocks; never re-asked in the same run.
7. **Output write.** Emit / update `wiki/grills/<topic-slug>.md` with the required sections above. Re-runs append to `## Q&A Log` and update `## Decisions Made` bullets keyed by title.
8. **Cross-link back.** Append a `## Grill Notes` section to the vision page linking the grill.
9. **Abandonment handling.** On mid-session exit, set `## Status: in progress (resume with /wiki-grill <topic>)`. On clean exit, set `## Status: done` or omit.
10. **Zero-dangling-links acceptance gate.** Stub or remove. Forward-placeholder links to not-yet-written architecture / ADR / spec pages get stub pages with `confidence: low`.
11. **Index + log.** Add a row under `## Grills` in `wiki/index.md` (create the table if absent); append a dated entry to `wiki/log.md`.

## One question per turn — why

Batching questions ("here are five things I need to know") trains both human and agent to give shallow answers. Depth-first single-question interrogation forces the choice to settle before its consequences are explored, which is the part that makes the rationale recoverable months later. The `grill-me` skill calls this out explicitly; we copy the discipline.

The trade-off is wall-clock time. A grill session is slow on purpose. If you want fast and you do not need the rationale captured, write the spec directly and skip the grill — `optional_in_v1: true` allows that.

## Refusal modes

- **No strategy page.** Preflight returns `missing: strategy — run /wiki-strategy first`. The grill aborts without writing.
- **Thin vision page.** If the vision page is present but does not give enough material to derive 3 top-level decisions, the agent says so and suggests `/wiki-strategy <topic>` to enrich it. **It does not invent decisions** the wiki cannot support.
- **More than one question per turn.** The prompt forbids this; if the agent slips, the user should redirect and the agent should re-ask one question at a time.

## Idempotency

- `## Q&A Log` is append-only, globally numbered. Resume continues at `Q<next>`.
- `## Decisions Made` bullets are keyed by short title. Same title → same bullet rewritten. New title → appended.
- `## Open Questions` is append-only across runs.
- `## Decision Tree` top-level entries are keyed by short title; sub-questions append under their parent.
- A clean re-run on a finished grill is a no-op (nothing to ask, no diff).

## Downstream consumers

- `/wiki-architecture` reads the grill to understand which questions the diagrams should be answering. Its preflight reports `missing: grill` when no grill page exists (downgraded to a warning when `grill.optional_in_v1: true`).
- `/wiki-adr` typically cites a specific `## Decisions Made` bullet as the rationale for the decision being pinned.
- `/wiki-spec` may cite the grill in `## Sources` when a scenario depends on a decision made there.
- `/wiki-refine` opens a fresh grill (or appends to the existing one) when a kanban run invalidates the rationale a decision rested on.

## Failure modes to watch for

- **Decision Tree drift.** If the grill page's `## Decision Tree` says one thing and `## Decisions Made` says another, trust the latter — the tree is a planning artifact; the decisions log is the record. `/wiki-lint` (Phase 7) will flag the mismatch.
- **Stale Open Questions.** Items in `## Open Questions` are intentionally append-only; they accumulate. Use `/wiki-triage` (Phase 5b) to promote a parked question into a real spec when it is time to answer it.
- **Empty rationale.** A `## Decisions Made` bullet without a one-line rationale is decoration; the rationale is what survives personnel turnover. The agent will ask for it before recording the bullet.
