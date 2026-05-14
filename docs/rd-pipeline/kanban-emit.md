# `/wiki-kanban-emit`

Decompose a `wiki/specs/<slug>.md` page into one or more task rows on a [Hermes Kanban](https://github.com/NousResearch/hermes) board. The wiki is the source of truth; the board is the execution substrate.

**Requires `hermes` on `PATH`.** Preflights `hermes kanban assignees` and aborts with an install hint if missing.

## Usage

```
/wiki-kanban-emit <spec-slug>
```

`<spec-slug>` is the slug of an existing `wiki/specs/<slug>.md` page.

## Gates

### Preflight (hard)

`hermes kanban assignees`. If Hermes is not on `PATH` or the command fails, abort with:

> *"Hermes is not installed or no profiles are configured. See https://github.com/NousResearch/hermes for installation. Kanban emission requires Hermes; the rest of this wiki — ingest, query, spec, ADR, strategy — works without it."*

No silent degradation; the rest of the workflow is skipped.

### ADR gate (soft)

If the spec cites no `accepted` ADR, warn and offer to hand control to `/wiki-adr` to draft a Y-Statement first. On confirm-to-proceed-without-ADR, record the choice in the spec's `## Sources` and continue.

## Workflow

1. **Read the spec.** Open `wiki/specs/<spec-slug>.md` in full — frontmatter, every user story, every Gherkin scenario, every glossary entry, every cited source.
2. **Read governing context.** For every ADR id cited on the spec page, open `wiki/decisions/<id>-*.md` and confirm `## Status: accepted`. For the relevant `wiki/contexts/<context>.md` page(s), read the inline `## Ubiquitous Language` glossary — this is what gets inlined into each task body.
3. **Compute the idempotency key.** Triple: `<spec-slug>:<adr-id>:<sha256(spec-body)>`. The sha256 is computed over the spec body *excluding* frontmatter and the auto-generated `## Kanban Tasks` section (if present from a prior run).
4. **Enumerate Hermes profiles.** `hermes kanban assignees` output is the exhaustive list of legal `assignee` values; unknown assignees silently fail to spawn. Map logical roles (`implementer`, `reviewer`, `integrator`) to real profile names — using a wiki-side mapping if one exists, or by asking the user. **Fail loudly on missing mappings — do not pick a "default" profile.**
5. **Pick the collaboration pattern from ADR status.** See [Collaboration patterns](#collaboration-patterns) below.
6. **Decompose.** Emit one `kanban_create` per user story or feature file. Each task body MUST include:
   - The story's `## Goal` verbatim from the spec, scoped to this story.
   - **Approach** — the story narrative if the spec has an opinion; otherwise left open.
   - **Acceptance criteria verbatim** — preserves the executable-specification contract end-to-end.
   - **Gherkin block fenced** inside ```` ```gherkin ```` so the worker can write it to disk and invoke a runner.
   - **Inlined glossary excerpt** from the bounded-context page — *not* just a link. Inlined to prevent false-cognate drift across workers.
   - **Wiki backlink** to `wiki/specs/<spec-slug>.md`.
   - **ADR id(s)** cited by the spec.
   - **`@wiki-spec` traceability tag** in the task title or metadata.
7. **Express ordering** with `parents=[...]` on each `kanban_create`:
   - The reviewer task's `parents` is the implementer task.
   - The integrator task's `parents` is the reviewer task.
   - The human-gate task's `parents` is whatever it gates.
8. **Workspace selection.**
   - Tasks that mutate the wiki itself → `workspace=dir:<absolute path to wiki repo>`.
   - Tasks that touch a code repo → `worktree`.
   - **Reject relative paths at dispatch.** This is the [confused-deputy](https://en.wikipedia.org/wiki/Confused_deputy_problem) guard.
9. **Record task ids on the spec page.** Append a `## Kanban Tasks` section to `wiki/specs/<spec-slug>.md` listing: idempotency key, ADR ids, collaboration pattern, profile mapping, and each task's id + role + assignee.
10. **Zero-dangling-links acceptance gate** on the updated spec page.
11. Append a dated entry to `wiki/log.md` recording spec slug, idempotency key, ADR ids, pattern, task ids, and assignees.

## Collaboration patterns

The pattern is picked from the cited ADR(s) `## Status`:

| ADR status | Pattern | Shape |
|---|---|---|
| `accepted` | **P2 pipeline** | `implementer → reviewer → integrator` |
| `proposed` | **P5 human-in-the-loop** | implementer + reviewer + a final human-gate task before integration |
| any (override) | **P3 quorum** | two reviewers + aggregator; used when reviewer agreement matters more than throughput |
| multiple independent feature files on the spec | **P1 fan-out** | wrap the chosen pattern in a fan-out parent |
| `deprecated` or `superseded` without a successor in `accepted` state | **refuse to emit** | report the governing ADR is no longer current |

## Idempotency semantics

The triple `<spec-slug>:<adr-id>:<sha256(spec-body)>` is the cross-system identity of the task set.

| Change | Triple change | Result |
|---|---|---|
| Re-run with no edits | same triple | updates existing task (no-op in practice) |
| Spec edited | new sha256 | updates existing task |
| ADR superseded → spec re-emitted with new ADR id | new ADR id | **new task row.** The old row is closed by `/wiki-refine` with a `kanban_comment` pointing forward. |
| Spec split into multiple files | new slug(s) | one new task row per new slug |

This is what makes `/wiki-refine` re-emission clean: a new ADR id forces a new task row rather than mutating an in-flight one.

## Orchestrator discipline

**The extension creates rows and steps back.**

- Do not claim, run, or shell out to do worker tasks. That violates the [orchestrator pattern](https://en.wikipedia.org/wiki/Orchestrator_pattern) / three-plane-architecture discipline.
- Do not poll the board for completion. Fire and forget.
- Workers are Hermes profiles running off-screen, in their own sandboxes.
- The wiki is updated by `/wiki-kanban-ingest` when runs complete — pulled in deliberately, not streamed.

## Mid-execution edits

If the spec is updated while tasks are running:

- **Prefer pushing the diff onto the task thread** via `kanban_comment` — the worker sees the comment and can respond.
- **Do not silently edit a `running` task's body.** That is invisible to the worker.

If the spec change is large enough to warrant re-decomposition, re-run `/wiki-kanban-emit`. The new sha256 will update the task body in place; subsequent comments and runs continue against the updated task.

## Failure modes to watch for

- **`hermes kanban assignees` returns an empty list.** No profiles configured — emission aborts. Configure at least one profile before retrying.
- **A cited ADR is not `accepted`.** The workflow picks the corresponding pattern (`proposed` → P5, etc.) but if the ADR is `deprecated`/`superseded` without a successor, emission is refused. Resolve the ADR first.
- **Missing role-to-profile mapping.** The workflow fails loudly — do not let it pick a default profile silently. Add the mapping under `wiki/contexts/` (or wherever your wiki-side mapping lives) and retry.
- **Relative `workspace=dir:` path.** Rejected at dispatch — use an absolute path or `worktree`.
- **Glossary excerpts not inlined.** If a task body only links to the context page rather than inlining the relevant glossary, the worker may read a stale or unrelated version of the term. Inlining is the protection against false cognates at the worker scale.
