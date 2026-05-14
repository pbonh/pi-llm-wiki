---
description: Emit a wiki spec onto the Hermes Kanban board
argument-hint: "<spec-slug>"
---
Read `AGENTS.md` and follow the **Kanban Emit** workflow to decompose `wiki/specs/$1.md` into Hermes Kanban tasks.

**Preflight (hard).** Invoke `hermes kanban assignees`. If `hermes` is not on `PATH` or the command fails, abort with: *"Hermes is not installed or no profiles are configured. See https://github.com/NousResearch/hermes. Kanban emission requires Hermes; the rest of this wiki works without it."* Do not proceed without Hermes.

**ADR gate (soft).** If the spec cites no `accepted` ADR governing its domain, warn the user and offer to hand control to `/wiki-adr` to draft a Y-Statement first. Record any proceed-without-ADR choice in the spec's `## Sources` section.

Steps (from AGENTS.md):
1. Read `wiki/specs/$1.md` in full — frontmatter, every story, every Gherkin scenario, glossary, sources.
2. For every cited ADR, confirm `## Status: accepted`. Read the relevant `wiki/contexts/<context>.md` `## Ubiquitous Language` glossary — this gets inlined into each task body.
3. Compute the idempotency key: `<spec-slug>:<adr-id>:<sha256(spec-body-excluding-frontmatter-and-Kanban-Tasks-section)>` per [[concepts/idempotency-key]].
4. Enumerate Hermes profiles via the preflight output; map logical roles (`implementer`/`reviewer`/`integrator`) to real profile names. Fail loudly on missing mappings — do not pick a "default" profile.
5. Pick the [[concepts/collaboration-pattern]] from ADR status: `accepted` → P2 pipeline; `proposed` → P5 human-in-the-loop; multiple feature files → P1 fan-out parent; `deprecated`/`superseded` without successor → refuse to emit.
6. Decompose into one `kanban_create` per user story. Each task body MUST include: goal, approach, acceptance criteria verbatim, Gherkin block fenced, inlined glossary excerpt (not just a link), wiki backlink, ADR id(s), and a `@wiki-spec` traceability tag.
7. Express ordering with `parents=[...]`. Reject relative `workspace=dir:` paths — use absolute paths or `workspace=worktree` per [[concepts/task-specification]].
8. Append a `## Kanban Tasks` section to `wiki/specs/$1.md` listing: idempotency key, ADR ids, pattern, profile mapping, and each task's id + role + assignee.
9. **Verify zero dangling links — acceptance gate** on the updated spec page.
10. Append a dated entry to `wiki/log.md` with spec slug, idempotency key, ADR ids, pattern, task ids, and assignees.

**Discipline:** the extension creates rows and steps back. Do not claim, run, or shell out to do worker tasks — that violates [[concepts/orchestrator-pattern]] and [[concepts/three-plane-architecture]]. Fire and forget; do not poll for completion.
