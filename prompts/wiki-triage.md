---
description: Park a wiki-side open question as a Hermes triage-column task
argument-hint: "<one-liner> [--from <page>]"
---
Read `AGENTS.md` and follow the **Triage** workflow to park `$@` as a Hermes triage-column task.

`$@` is a single-line question or note. `--from <page>` (optional) cites the originating wiki page (typically a grill or architecture `## Open Questions` entry) for traceability.

**Preflight (hard) — Hermes.** Invoke `hermes kanban assignees`. If `hermes` is not on `PATH`, abort with: *"Hermes is not installed. See https://github.com/NousResearch/hermes. The triage workflow requires Hermes."* Do not silently degrade.

Steps:

1. **Parse args.** Split `$@` into `<note>` and an optional `--from <page>` tail. Reject if `<note>` is empty.
2. **Compose the task body.** Body must include:
   - The note verbatim under `## Question`.
   - If `--from <page>` was given, a `## Source` section linking the page (`[[<page>]]`) and quoting the surrounding context (the question's `## Open Questions` bullet, if locatable).
   - A `@wiki-source: <page>` traceability tag at the top of the body (and in metadata if Hermes supports it).
   - Status note: *"Triage column. Run `/wiki-triage-promote <task-id>` to expand into a spec."*
3. **Create the task.** Call `hermes kanban create --triage --skill wiki-maintainer --skill kanban-worker --tenant <bounded-context-slug>`. Derive the tenant from `--from <page>`'s context tag if present; fall back to `triage`.
4. **Cross-link back.** If `--from <page>` was given, append a line to the source page's `## Open Questions` bullet: `→ triage:<task-id>`. Idempotent — if the bullet already has a `→ triage:` tail with the same task id, leave it.
5. Append a dated entry to `wiki/log.md` recording the task id, the originating page (if any), the tenant, and the note.

After a clean run, hint: *"Question parked as triage task <task-id>. Run `/wiki-triage-promote <task-id>` when you're ready to expand it into a real spec."*

**Discipline:** triage is the *one place* where the wiki accepts an unresolved question without forcing it down the pipeline. Do not skip the `--from` cross-link when one is available — orphan triage rows that no wiki page knows about defeat the purpose.
