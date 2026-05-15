---
name: wiki-kanban
description: Run the Kanban Emit + Ingest + Triage workflows against an llm-wiki — decompose specs into Hermes tasks with parent + per-scenario children + aggregator, round-trip completed runs as living documentation, and park open questions onto the triage column. Requires hermes on PATH. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
---

# wiki-kanban

Operate the kanban round-trip of an llm-wiki: decompose specs onto a [Hermes Kanban](https://github.com/NousResearch/hermes) board, round-trip completed runs back as `## Implementation Evidence`, and use the triage column as a parking inbox for open questions.

The wiki schema and workflow details live in `AGENTS.md`. Read `### Kanban Emit`, `### Kanban Ingest`, `### Triage`, and `### Triage Promote`, plus `prompts/_handoff-schema.md` for the required JSON shape on every task's `metadata`.

**Preflight (hard for all subcommands).** `hermes kanban assignees` must succeed. If `hermes` is not on `PATH`, abort with the install hint. The rest of the wiki works without Hermes; these subcommands don't.

## Where this fits

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban_emit ──> kanban_ingest ──> refine
                                                          ↑                  ↑
                                                          git:spec-on-trunk  git:worker-branch-merged
```

The [pipeline manifest](../../docs/rd-pipeline/pipeline-manifest.md) wires `git:spec-on-trunk` into emit and `git:worker-branch-merged` into ingest. Both abort loudly when the git invariant fails — idempotency keys must hash stable values, and evidence must point at trunk code.

## Subcommands

### `emit <spec-slug>`

Decompose a `wiki/specs/<slug>.md` page into one parent task + one child task per Gherkin scenario + one aggregator. Per-task metadata pins `--skill wiki-maintainer --skill kanban-worker --tenant <bounded-context>`. Each task body includes the inlined glossary, the wiki backlink, the ADR ids, and the verbatim `## Required Handoff` schema.

**Idempotency:** parent key is `<spec-slug>:<adr-id>:<sha256(spec-body)>`; each child is `<spec-slug>:<adr-id>:<scenario-slug>:<sha256(scenario-body)>`. Editing one scenario re-emits only that child.

### `ingest <task-id | run-id>`

Round-trip a completed Hermes run back to the originating wiki page. Walks every attempt (`hermes kanban runs --json`), validates the `## Required Handoff` schema, sanitizes secrets, runs the `git:worker-branch-merged` check on `metadata.branch_head`, and appends a `## Implementation Evidence` section with per-attempt subsections.

### `triage <note> [--from <page>]`

Park a wiki-side open question onto the Hermes triage column. The task body carries a `@wiki-source` tag pointing back to the originating page. The wiki is the source of truth for *answered* questions; triage is the durable inbox for *unanswered* ones.

### `triage-promote <task-id>`

Expand a triage one-liner into a real spec via `hermes kanban specify` (Hermes P9 specifier), then hand the structured output to `/wiki-spec`. On success, the triage task is closed with a comment linking forward; the originating wiki page's `## Open Questions` bullet has its `→ triage:<id>` tail replaced with `→ spec:<slug>`.

## Discipline

The extension creates rows and steps back. It does not claim, run, or shell out to do worker tasks. It does not poll the board for completion. This is the [orchestrator pattern](https://en.wikipedia.org/wiki/Orchestrator_pattern) discipline — pi-llm-wiki is the orchestrator, Hermes profiles are the workers, the two planes never blur.

## Failure modes

- **`hermes` not on PATH** → preflight aborts loudly with an install hint. Never silently degrades.
- **Spec unmerged** → `/wiki-kanban-emit` aborts with the rendered `git merge-base` command.
- **Worker branch unmerged** → `/wiki-kanban-ingest` aborts with the rendered `git merge-base` command.
- **Handoff missing required keys** → ingest aborts with `missing keys: [...]`.
- **Secrets in metadata** → ingest surfaces the problem to the user and stops; does not silently scrub.
