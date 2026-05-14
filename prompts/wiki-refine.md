---
description: Close the refinement loop — supersede ADRs, re-emit tasks, update concept pages
argument-hint: "<run-id | breakthrough note>"
---
Read `AGENTS.md` and follow the **Refine** workflow on: $@

Refine is the *structural* counterpart to `/wiki-kanban-ingest`. Use it when a run outcome or [[concepts/breakthrough]] invalidates a prior model — a moved context boundary, a new [[concepts/false-cognate]], an invalidated decision. The named realization of [[concepts/evolving-order]] inside the multi-agent substrate.

Steps (from AGENTS.md):
1. **Classify the trigger.** Read the structured handoff (or breakthrough note). Decide:
   - **Documentary only** → hand off to `/wiki-kanban-ingest` and stop.
   - **Structural** → at least one of: an architectural commitment was invalidated; a new false cognate surfaced; a bounded-context boundary moved; a new concept emerged. Continue.
2. Update upstream model — concept page (`wiki/concepts/`), bounded-context page (`wiki/contexts/`), or context map (`wiki/context-maps/`) as appropriate.
3. **If a decision was invalidated:** hand off to `/wiki-adr` to open a new ADR that supersedes the prior one. Do not edit the accepted predecessor. The new ADR's `## Context` must cite the originating run id or breakthrough note. Flip the predecessor's `## Status` to `superseded by NNNN` with a link.
4. **Re-emit affected kanban tasks.** For every active task whose spec page cites the now-superseded ADR, hand off to `/wiki-kanban-emit` with the spec slug. The fresh `<spec-slug>:<new-adr-id>:<sha256>` triple produces a new task row; close the old row with a `kanban_comment` pointing forward.
5. **Verify zero dangling links — acceptance gate** on every page touched.
6. Update `wiki/index.md` and append a dated entry to `wiki/log.md` recording the trigger, model changes, new ADR id, superseded ADR id, and re-emitted task ids.

Use Refine sparingly — most outcomes are documentary, not structural. But use it without hesitation when an ADR is invalidated; an unrecorded supersession is worse than an explicit one.
