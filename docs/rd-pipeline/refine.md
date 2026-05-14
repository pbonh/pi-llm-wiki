# `/wiki-refine`

Close the structural half of the refinement loop. When a run outcome or a free-form "breakthrough" note invalidates a prior model — an architectural commitment is wrong, a new false cognate surfaced, a bounded-context boundary moved, a new concept emerged — Refine updates the upstream model, opens a superseding ADR, and re-emits affected kanban tasks under a fresh idempotency key.

This is the named realization of [evolving order](https://martinfowler.com/bliki/EvolvingOrder.html) and breakthrough inside the multi-agent substrate.

## Usage

```
/wiki-refine <run-id-or-breakthrough-note>
```

`<run-id>` is a Hermes run id whose completion surfaced new structural information.
`<breakthrough note>` is a free-form description of something that invalidates prior decisions (use this when the trigger is not a single run — e.g. accumulated evidence across several runs).

## Workflow

### 1. Classify the trigger

Read the run's structured handoff (or the user's note). Decide:

- **Documentary only** — what was learned is a concept-page-level fact; no architectural commitment is invalidated, no boundary moved, no new false cognate. **Hand off to `/wiki-kanban-ingest` and stop.** Refine is not the right tool here.
- **Structural** — at least one of:
  - An architectural commitment was invalidated (the cited ADR is wrong).
  - A new false cognate surfaced (same word, different meaning in two contexts — or the same meaning split across two words).
  - A bounded-context boundary moved (something that used to live in context A now lives in context B).
  - A new concept emerged that deserves its own page.

  Continue with steps 2–6.

The split is deliberate. Most run outcomes are documentary; using Refine on them would create churn. Reserve it for the cases that actually require supersession.

### 2. Update the upstream model

Depending on what changed:

- **Concept-page-level fact** → open or update `wiki/concepts/<term>.md`. New concept → create a new page (full schema, `confidence` graded honestly).
- **Bounded-context boundary moved** → update `wiki/contexts/<context>.md` `## Boundary` and add a `## Revisions`-style dated note.
- **New false cognate surfaced** → update `wiki/context-maps/<topic>.md` `## False Cognates` list and `## Translations` table.

### 3. Open a superseding ADR (if a decision was invalidated)

Hand off to `/wiki-adr` to open a new ADR that supersedes the prior one. **Do not edit the accepted predecessor.** The new ADR's `## Context` must cite the originating run id (or breakthrough note) — this is the audit trail.

The predecessor's `## Status` is flipped to `superseded by NNNN` with a link to the successor. The predecessor body stays intact.

If no decision was invalidated, skip this step — supersede only what was wrong.

### 4. Re-emit affected kanban tasks

For every active kanban task whose spec page cites the now-superseded ADR, hand off to `/wiki-kanban-emit` with the originating spec slug. The fresh `<spec-slug>:<new-adr-id>:<sha256>` triple — with the *new* ADR id — produces a **new task row** rather than updating the old one.

The old row is closed with a `kanban_comment` pointing forward to the successor task. Workers stop on the old row and continue (or restart) on the new one.

### 5. Zero-dangling-links acceptance gate

Same as Ingest, applied to every page touched. Stub or remove until zero remain.

### 6. Update `wiki/index.md` and `wiki/log.md`

The log entry records:

- The trigger (run id or breakthrough note).
- The model changes (which concept / context / context-map pages were updated).
- The new ADR id.
- The superseded ADR id.
- The re-emitted task ids.

## What Refine refuses to do

- **Edit an accepted ADR.** Always supersede. The discipline is the whole point.
- **Silently re-emit.** Re-emission goes through `/wiki-kanban-emit` so the orchestrator pattern and idempotency rules stay enforced.
- **Discard the old task row.** The old row is *closed*, not deleted, with a forward pointer. The board is the execution history; deletion loses it.
- **Cascade into unrelated specs.** Only tasks whose spec page cites the superseded ADR are re-emitted. The agent will surface tasks that may *also* need re-emitting and ask before continuing.

## When to use Refine vs. just opening a new ADR by hand

You can always open a new ADR with `/wiki-adr` directly. Use Refine when:

- The trigger is a *kanban run outcome* — the structured handoff is the audit trail you want cited in the new ADR's `## Context`.
- There are active kanban tasks affected by the supersession — Refine re-emits them in one pass.
- The model change spans multiple artifact types (concept + context + context-map + decision) — Refine touches them all and runs the acceptance gates once.

Use `/wiki-adr` directly when:

- The trigger is upstream of any kanban work (e.g. a research finding before any spec exists).
- There are no active tasks to re-emit.
- You only need to update one decision, not the broader model.

## Discipline rules

- **Refine sparingly.** Most outcomes are documentary. Promoting documentary changes to structural ones creates churn and ADR log-bloat.
- **Refine without hesitation when an ADR is invalidated.** An unrecorded supersession is worse than an explicit one — the decision log loses its anchor.
- **Always cite the trigger.** The new ADR's `## Context` must cite the run id or breakthrough note. Without that, the supersession looks arbitrary in six months.
- **Never edit the predecessor's body.** Flip its status, link the successor, move on.

## Failure modes to watch for

- **Refine triggered on a documentary outcome.** The classifier should short-circuit to `/wiki-kanban-ingest`. If it does not, the new ADR will not have a real ASR and you have just added decoration to the decision log.
- **Re-emission without closing the old row.** The board accumulates ghost tasks that the dispatcher may try to gate on. Always close the predecessor with a `kanban_comment` forward pointer.
- **Multiple specs cite the same superseded ADR but only one was re-emitted.** Refine reports the affected specs explicitly. If you skipped some, run `/wiki-kanban-emit` against each remaining spec manually — the new ADR id will produce new task rows under the standard idempotency triple.
- **The breakthrough note is too vague to cite.** If you cannot phrase the trigger as a specific architectural change, the change is probably documentary. Do not promote it.
