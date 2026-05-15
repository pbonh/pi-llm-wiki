---
description: Emit a wiki spec onto the Hermes Kanban board
argument-hint: "<spec-slug>"
---
Read `AGENTS.md` and follow the **Kanban Emit** workflow to decompose `wiki/specs/$1.md` into Hermes Kanban tasks.

**Preflight 1 (hard) — pipeline manifest.** Run `scripts/check-prereqs.sh kanban_emit --slug $1` from the wiki root. The helper walks the manifest's `requires: [spec, board_bound, "git:spec-on-trunk"]` and aborts on the first missing prerequisite. Treat exit codes:

- `0` — proceed.
- `1` — print the helper's `missing` + `hint` verbatim and abort without touching the board. (When `missing` is `board_bound`, the hint points at `/wiki-kanban-board <slug>`; when `project_init`, at `/wiki-project-init`.)
- `3` — git_check failed (e.g. spec edits are not on `origin/<trunk>` yet). Print the helper's full error, including the rendered `git merge-base` command, and abort. **Do not emit kanban tasks while the spec body is a moving target** — idempotency keys would hash a value that is about to change on push.

If `wiki/.pipeline.yaml` is absent, the helper exits 0 and emit proceeds (back-compat with pre-Phase-0 wikis). In that case, also confirm `kanban/board.yaml` exists on disk before step 4 — without it the per-tenant board binding is undefined.

**Preflight 2 (hard) — Hermes.** Invoke `hermes kanban assignees`. If `hermes` is not on `PATH` or the command fails, abort with: *"Hermes is not installed or no profiles are configured. See https://github.com/NousResearch/hermes. Kanban emission requires Hermes; the rest of this wiki works without it."*

**Preflight 3 (hard) — board binding.** Read `kanban/board.yaml` with `yq` and capture `board`, `workspace_default`, `profiles.orchestrator`, `profiles.worker`, `profiles.reviewer`. If `board` is empty or `<!--` markers remain, abort with the `/wiki-kanban-board <slug>` hint (the manifest preflight should have caught this; this is a belt-and-braces check for back-compat wikis without `.pipeline.yaml`).

**ADR gate (soft).** If the spec cites no `accepted` ADR governing its domain, warn the user and offer to hand control to `/wiki-adr` to draft a Y-Statement first. Record any proceed-without-ADR choice in the spec's `## Sources` section.

Steps (from AGENTS.md):
1. Read `wiki/specs/$1.md` in full — frontmatter, every story, every Gherkin scenario, glossary, sources.
2. For every cited ADR, confirm `## Status: accepted`. Read the relevant `wiki/contexts/<context>.md` `## Ubiquitous Language` glossary — this gets inlined into each task body.
3. Compute the idempotency key: `<spec-slug>:<adr-id>:<sha256(spec-body-excluding-frontmatter-and-Kanban-Tasks-section)>` per [[concepts/idempotency-key]]. Per scenario, extend the key to `<spec-slug>:<adr-id>:<scenario-slug>:<sha256(scenario-body)>`.
4. **Map roles via `kanban/board.yaml`'s `profiles:` section** (captured in Preflight 3) to real Hermes profile names — `orchestrator` runs the fan-out, `worker` runs implementation tasks, `reviewer` runs review/aggregator tasks. Fail loudly on missing mappings — do not pick a "default" profile. (The legacy `implementer`/`reviewer`/`integrator` triple maps to `worker`/`reviewer`/`reviewer` against the new schema.)
5. Pick the [[concepts/collaboration-pattern]] from ADR status: `accepted` → P2 pipeline (`worker` → `reviewer`); `proposed` → P5 human-in-the-loop (first task to `worker`, comments to operator); multiple feature files → P1 fan-out parent (siblings to `worker`); P3 quorum (when applicable) → N `worker` siblings + 1 `reviewer` aggregator; `deprecated`/`superseded` without successor → refuse to emit.
6. **Decompose into parent + per-scenario children + aggregator.** Emit one parent task per spec (idempotency key `<spec-slug>:<adr-id>:<sha256(spec-body)>`), one child task per Gherkin scenario (extended key as above) with `parents=[parent_id]`, and a final aggregator task with `parents=[<every child id>]` whose job is to synthesize the `## Implementation Evidence` block the wiki ingests. Re-running with unchanged scenarios returns existing task ids; editing one scenario re-emits only that scenario's task.
7. **Per-task metadata (hard).** Every `kanban_create` call MUST pass:
   - `--board <slug>` from `kanban/board.yaml`'s `board:` field. Without this, tasks land on the operator's currently-active board, which is rarely what you want.
   - `--skill wiki-maintainer`, `--skill kanban-worker` — closes the loop with the wiki-maintainer workflows.
   - `--tenant <bounded-context-slug>` — derive from the spec's `frontmatter.context`; fall back to `default` only when the spec has no context tag.
   - `--workspace` — resolve from `kanban/board.yaml`'s `workspace_default`:
     - `dir:./project` → pass `--workspace dir:$(realpath ./project)`. Hermes rejects relative `dir:` paths, so absolute is mandatory.
     - `worktree` → pass `--workspace worktree` and append a one-line comment to the task body: *"Create your git worktree under `kanban/.worktrees/<id>/` rooted at the `project/` repo."* (Hermes does not enforce the location; the worker skill is the authority.)
8. Each task body MUST include: goal, approach, acceptance criteria verbatim, Gherkin block fenced, inlined glossary excerpt (not just a link), wiki backlink, ADR id(s), a `@wiki-spec` traceability tag, **and the `## Required Handoff` schema inlined verbatim from `prompts/_handoff-schema.md`** so the worker knows the exact JSON keys to return.
9. Express ordering with `parents=[...]`. Reject relative `workspace=dir:` paths — use absolute paths or `workspace=worktree` per [[concepts/task-specification]] (already enforced by step 7's `realpath` resolution).
10. Append a `## Kanban Tasks` section to `wiki/specs/$1.md` listing: board slug, idempotency keys (parent + each child + aggregator), ADR ids, pattern, profile mapping (orchestrator/worker/reviewer), tenant, workspace shape, skill pin, and each task's id + role + assignee.
11. **Verify zero dangling links — acceptance gate** on the updated spec page.
12. Append a dated entry to `wiki/log.md` with spec slug, idempotency key(s), ADR ids, pattern, task ids, tenant, and assignees.

**Discipline:** the extension creates rows and steps back. Do not claim, run, or shell out to do worker tasks — that violates [[concepts/orchestrator-pattern]] and [[concepts/three-plane-architecture]]. Fire and forget; do not poll for completion.

After a clean run, hint: *"Tasks emitted. When the worker(s) merge and you're ready to round-trip results, run `/wiki-kanban-ingest <aggregator-task-id>`."*
