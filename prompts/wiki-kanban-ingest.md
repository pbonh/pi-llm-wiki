---
description: Round-trip a completed Hermes kanban run back into the wiki as living documentation
argument-hint: "<task-id | run-id>"
---
Read `AGENTS.md` and follow the **Kanban Ingest** workflow to round-trip the Hermes run at `$1` back into the wiki.

**Preflight (hard).** Invoke `hermes kanban assignees`. If `hermes` is not on `PATH` or the command fails, abort with the same install-hint message as `/wiki-kanban-emit`. Do not proceed without Hermes.

Steps (from AGENTS.md):
1. Fetch the completed run via `hermes kanban show $1` (or db-layer equivalent). Capture `summary`, `verification`, `changed_files`, `residual_risk`, and the [[concepts/structured-handoff]] payload.
2. **Sanitize metadata.** [[concepts/structured-handoff]] forbids tokens, OAuth material, raw logs, and unrelated transcripts. Copy summaries and pointers (file paths, commit hashes, run ids, URLs) — refuse to copy secrets or raw logs. If the metadata is dirty, surface the issue to the user and stop. Do not silently scrub-and-copy.
3. Locate the originating wiki page from the task body's `@wiki-spec` tag or wiki backlink (normally `wiki/specs/<spec-slug>.md`).
4. Append a `## Implementation Evidence` section to the target page with: run id, completion timestamp, assignee profile, `verification` command(s) + result, `changed_files`, `residual_risk`, one-paragraph summary. On re-ingest, append a new dated subheading rather than overwriting.
5. Update the target's frontmatter `updated` field and any `## Sources` row that points at the spec or concept.
6. **Verify zero dangling links — acceptance gate.**
7. Append a dated entry to `wiki/log.md` recording the run id, target page, verification outcome, and any residual risk.

If the run failed, still ingest — mark the section `Result: failed` and quote the failure reason from the handoff. Documenting failures honestly is the point of [[concepts/living-documentation]].
