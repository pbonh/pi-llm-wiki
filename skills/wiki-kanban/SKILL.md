---
name: wiki-kanban
description: Run the Kanban workflows against an llm-wiki — bind a Hermes board (kanban/board.yaml), decompose specs into Hermes tasks with parent + per-scenario children + aggregator, round-trip completed runs as living documentation (with per-attempt handoff JSON files), and park open questions onto the triage column. Requires hermes on PATH. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
---

# wiki-kanban

Operate the kanban round-trip of an llm-wiki: decompose specs onto a [Hermes Kanban](https://github.com/NousResearch/hermes) board, round-trip completed runs back as `## Implementation Evidence`, and use the triage column as a parking inbox for open questions.

The wiki schema and workflow details live in `AGENTS.md`. Read `## Kanban Board`, `### Kanban Emit`, `### Kanban Ingest`, `### Triage`, and `### Triage Promote`, plus `prompts/_handoff-schema.md` for the required JSON shape on every task's `metadata`.

**Preflight (hard for all subcommands).** `hermes kanban assignees` must succeed. If `hermes` is not on `PATH`, abort with the install hint. The rest of the wiki works without Hermes; these subcommands don't.

## Where this fits

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban_emit ──> kanban_ingest ──> refine
                                                          ↑                  ↑
                                                          git:spec-on-trunk  git:worker-branch-merged
```

The [pipeline manifest](../../docs/rd-pipeline/pipeline-manifest.md) wires `git:spec-on-trunk` into emit and `git:worker-branch-merged` into ingest. Both abort loudly when the git invariant fails — idempotency keys must hash stable values, and evidence must point at trunk code.

## Subcommands

### `kanban-board <slug>`

Bind a Hermes Kanban board to this wiki — write `kanban/board.yaml` with the board slug, the `orchestrator`/`worker`/`reviewer` profile mapping, and the default workspace shape (`dir:./project` or `worktree`). Replaces the placeholder shipped by `pi-llm-wiki-init`. Satisfies the manifest artifact `board_bound`, which gates `emit` and `ingest`.

**Preflight (hard).** `scripts/check-prereqs.sh project_init` exit 0 (run `/wiki-project-init` first); `hermes kanban assignees` succeeds; `<slug>` matches `^[a-z0-9][a-z0-9_-]{0,63}$`.

1. `hermes kanban boards list --json`; create the board with `hermes kanban boards create <slug>` if absent (no `--switch`).
2. Resolve roles — CLI flags > existing `board.yaml` values > prompt the user (with `hermes kanban assignees --json` as suggestions).
3. Verify required skills via `hermes -p <profile> skills list`: `kanban-orchestrator` for orchestrator, `kanban-worker` for worker and reviewer. Missing → abort with the `skills reset --restore` hint.
4. Resolve `workspace_default` (`dir:./project` default; `worktree` opt-in).
5. Write `kanban/board.yaml` (preserve top comment block; drop the `<!-- CUSTOMIZE -->` marker). Rewrite the matching marker in `## Kanban Board` of `AGENTS.md`.
6. Smoke-test with `hermes kanban --board <slug> list` (must exit 0). Append a dated entry to `wiki/log.md`.

Re-runnable. Same slug + unchanged profiles → no-op. Different slug → rewrites binding and warns that previously emitted tasks live on the old board.

### `emit <spec-slug>`

Decompose a `wiki/specs/<slug>.md` page into one parent task + one child task per Gherkin scenario + one aggregator. Per-task metadata pins `--board <slug>` (from `kanban/board.yaml`), `--workspace dir:$(realpath ./project)` or `--workspace worktree` (from `workspace_default`), `--skill wiki-maintainer --skill kanban-worker --tenant <bounded-context>`. Roles map to real profiles via `board.yaml`'s `profiles:` section. Each task body includes the inlined glossary, the wiki backlink, the ADR ids, and the verbatim `## Required Handoff` schema.

**Idempotency:** parent key is `<spec-slug>:<adr-id>:<sha256(spec-body)>`; each child is `<spec-slug>:<adr-id>:<scenario-slug>:<sha256(scenario-body)>`. Editing one scenario re-emits only that child.

### `ingest <task-id | run-id>`

Round-trip a completed Hermes run back to the originating wiki page. Reads `--board <slug>` from `kanban/board.yaml`. Walks every attempt (`hermes kanban runs --board <slug> --json`), validates the `## Required Handoff` schema, sanitizes secrets, runs the `git:worker-branch-merged` check on `metadata.branch_head`, **writes `kanban/handoffs/<task-id>.<run-id>.json` per attempt**, and appends a `## Implementation Evidence` section with per-attempt subsections.

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
