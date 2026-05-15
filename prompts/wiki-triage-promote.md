---
description: Promote a Hermes triage task into a real spec via the kanban specifier
argument-hint: "<triage-task-id>"
---
Read `AGENTS.md` and follow the **Triage Promote** workflow on triage task `$1`.

**Preflight (hard) — Hermes.** Invoke `hermes kanban assignees`. If `hermes` is not on `PATH`, abort with the same install-hint message as `/wiki-triage`. Do not silently degrade.

Steps:

1. **Fetch the triage task.** `hermes kanban show $1 --json` to read its body, `@wiki-source` tag, tenant, and current column. Refuse if the column is not `triage` (this command only promotes from triage; tasks already in `todo`/`ready` are past promotion).
2. **Specify the task.** Call `hermes kanban specify $1` — Hermes' P9 specifier collaboration pattern. The specifier expands the one-liner into a structured spec body (problem statement, acceptance criteria, glossary). Capture the specifier's output.
3. **Derive a spec slug.** Use the task's title (kebab-case). If the title is a verbatim question, the slug is the noun-phrase form (e.g. *"should X support Y?"* → `x-support-y`). Confirm with the user before writing.
4. **Hand off to `/wiki-spec`.** Invoke the `/wiki-spec` workflow with the specifier's output seeded as the goal. The Spec workflow's normal gates apply — including the accepted-ADR check; the specifier output may not name an ADR, in which case `/wiki-spec` will offer to hand off to `/wiki-adr` first.
5. **Cross-link back.** After the spec is written:
   - Update the triage task's body via `hermes kanban comment $1 --message "Promoted to wiki/specs/<slug>.md"`.
   - Move the triage task to `done` (or `cancelled` if the user decides the question is not worth speccing after seeing the specifier output).
   - On the originating wiki page (from the `@wiki-source` tag, if present), update the `## Open Questions` bullet to point at the new spec: `→ spec:<slug>` (replace any prior `→ triage:<id>` tag).
6. Append a dated entry to `wiki/log.md` recording the triage task id, the resulting spec slug, and the wiki-source page.

If the specifier output cannot be turned into a coherent goal — e.g. the question is too ambiguous, or it splits into multiple unrelated specs — say so and stop; do not invent a goal. The triage task stays in `triage`.

After a clean run, hint: *"Spec `<slug>` written from triage <task-id>. Next: `/wiki-adr` if no governing ADR yet, otherwise `/wiki-kanban-emit <slug>` once the spec is on trunk."*
