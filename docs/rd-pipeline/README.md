# R&D pipeline reference

Per-feature reference pages for the slash commands that turn the wiki into a research-and-development pipeline. The tutorials cover *what to run when*; these pages cover *exactly what each command does, accepts, rejects, and produces*.

If you have not read [`docs/tutorial-rd-pipeline.md`](../tutorial-rd-pipeline.md) yet, start there. The reference pages assume you know roughly where each command sits in the loop.

## The pipeline at a glance

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> (workers) ──> kanban-ingest ──> refine ──> back to adr / spec
                                                            ▲                                ▲
                                                            │                                │
                                                  triage / triage-promote feed parked questions in
```

| Stage | Command | Output | Hermes required |
|---|---|---|---|
| Strategic design | [`/wiki-strategy`](./strategy.md) | `wiki/vision/`, `wiki/contexts/`, `wiki/context-maps/` | No |
| Question surfacing | [`/wiki-grill`](./grill.md) | `wiki/grills/<topic>.md` — decision tree, depth-first Q&A log, decisions made, open questions | No |
| Diagrams | [`/wiki-architecture`](./architecture.md) | `wiki/architecture/<topic>.md` — Mermaid C4 blocks + `## Decisions Surfaced` | No |
| Architectural commitment | [`/wiki-adr`](./adr.md) | `wiki/decisions/NNNN-<title>.md`; upserts `→ ADR-NNNN` on matching surfaced-decision bullet | No |
| Executable specification | [`/wiki-spec`](./spec.md) | `wiki/specs/<slug>.md` with Gherkin + glossary + `adr_ids` frontmatter | No |
| Task emission | [`/wiki-kanban-emit`](./kanban-emit.md) | Parent + per-scenario children + aggregator kanban tasks; `## Kanban Tasks` section on spec | **Yes** |
| Run round-trip | [`/wiki-kanban-ingest`](./kanban-ingest.md) | `## Implementation Evidence` with per-attempt subsections on the originating wiki page | **Yes** |
| Parking inbox | `/wiki-triage`, `/wiki-triage-promote` | Triage-column tasks with `@wiki-source` traceability; promotion expands a one-liner into a real spec | **Yes** |
| Structural feedback | [`/wiki-refine`](./refine.md) | Updated concept/context pages + superseding ADR + re-emitted tasks | Only if it ends up re-emitting |

The [pipeline manifest](./pipeline-manifest.md) wires these into a dependency graph. Every slash command runs `scripts/check-prereqs.sh <artifact>` before doing any work; missing prereqs abort with a named error. The kanban surface also adds two `git_check`s (`spec-on-trunk`, `worker-branch-merged`) that refuse to emit or ingest while idempotency keys would hash moving values or evidence would point at unmerged code.

## Load-bearing properties

A few invariants run across the whole pipeline. They are repeated on each reference page but worth understanding once up front.

### Zero dangling links — acceptance gate

Every workflow that writes wiki pages ends with a zero-dangling-links scan: every `[[...]]` reference must resolve to a real file on disk. The agent either (a) creates the missing page with full schema for its type (a stub with `confidence: low` is fine if the source only mentions the concept in passing), or (b) removes the link. The scan re-runs until it returns zero. This is what keeps the graph honest — a wiki page that cites pages which do not exist is a workflow failure, not a partial success.

### Write-once ADRs

Once `## Status: accepted`, an ADR's body is **never edited**. To change an accepted decision, you open a new ADR that supersedes it. The predecessor's status is flipped to `superseded by NNNN` with a link forward; its body stays intact. `/wiki-refine` is the workflow that orchestrates supersession when a run outcome invalidates a prior decision.

### Idempotency triple

Kanban task identity is the triple `<spec-slug>:<adr-id>:<sha256(spec-body)>`. Same triple → updates the existing task. Spec edited → new sha256 → updates. ADR superseded → new ADR id → **new task row**. Spec split → multiple new task rows. This is what makes re-emission safe and what makes refinement re-emit cleanly.

### Soft vs. hard gates

- **Soft gates** warn you and offer a recovery path (typically handing off to another slash command). Example: `/wiki-spec` warns when no `accepted` ADR governs the spec's domain, and offers to hand control to `/wiki-adr`. You can proceed without one; the choice is recorded in the spec's `## Sources`.
- **Hard gates** refuse to proceed. Example: `/wiki-adr` refuses to open an ADR without an architecturally-significant-requirement (ASR) named in `## Context`. Example: `/wiki-kanban-emit` aborts if `hermes` is not on `PATH`.

### Orchestrator discipline

`/wiki-kanban-emit` is the orchestrator. It creates kanban rows and steps back. It does **not** claim, run, or shell out to do worker tasks; it does **not** poll the board for completion. Workers are Hermes profiles running off-screen. The extension is the orchestrator, never a worker.

## When to skip the pipeline entirely

The pipeline is not always the right tool. Skip it when:

- The work is exploratory research with no built artifact at the end — stay in the knowledge-graph loop.
- The work is one-shot and not worth pinning a decision for — just run the change.
- The team is one person and the wiki is the audience — ADRs are still useful, but the kanban round-trip is overkill.

The pipeline pays off when there is a *running disagreement between intent and outcome* — when specs need to survive multiple implementation attempts, when decisions need to survive personnel turnover, when the wiki has to stay honest with a board of tasks that someone else (or some other agent) executes.
