---
description: Round-trip a completed Hermes kanban run back into the wiki as living documentation
argument-hint: "<task-id | run-id>"
---
Read `AGENTS.md` and follow the **Kanban Ingest** workflow to round-trip the Hermes run at `$1` back into the wiki.

**Preflight 1 (hard) — Hermes.** Invoke `hermes kanban assignees`. If `hermes` is not on `PATH` or the command fails, abort with the same install-hint message as `/wiki-kanban-emit`. Do not proceed without Hermes.

**Preflight 2 (hard) — git discipline.** Fetch the task's run metadata via `hermes kanban runs $1 --json` (the durable `task_runs` table — every attempt, oldest-first). For each completed run, read `metadata.branch_head` from the structured handoff. Then run `scripts/check-prereqs.sh kanban_ingest --branch-head <branch_head>` from the wiki root. The helper renders the `git:worker-branch-merged` check (`git fetch --quiet origin <trunk> && git merge-base --is-ancestor <branch_head> origin/<trunk>`) and fails with exit 3 when the worker's branch is not on trunk. On failure, print *"Run $1's branch <branch_head> is not on <trunk>; merge before ingesting."* plus the rendered `git merge-base` command, and abort. **Do not write any `## Implementation Evidence` section while the worker's branch is unmerged** — the wiki would record evidence pointing at code that is not yet trunk.

If `wiki/.pipeline.yaml` is absent, the helper exits 0 and ingest proceeds (back-compat).

Steps (from AGENTS.md):
1. **Fetch attempt history.** `hermes kanban runs $1 --json` returns every run for the task, oldest-first. Walk all of them — not just the latest. Capture per run: `summary`, `verification`, `changed_files`, `residual_risk`, the [[concepts/structured-handoff]] payload, and `metadata.branch_head`.
2. **Validate the handoff schema.** Every run's `metadata` MUST contain the keys declared in `prompts/_handoff-schema.md`: `changed_files`, `verification`, `dependencies`, `blocked_reason`, `retry_notes`, `residual_risk`, `branch_head`, `wiki_spec`, `wiki_adr_ids`. Missing keys → abort with `missing keys: [...]`. Do not partially ingest.
3. **Sanitize metadata.** [[concepts/structured-handoff]] forbids tokens, OAuth material, raw logs, and unrelated transcripts. Copy summaries and pointers (file paths, commit hashes, run ids, URLs) — refuse to copy secrets or raw logs. If the metadata is dirty, surface the issue to the user and stop. Do not silently scrub-and-copy.
4. **Locate the originating wiki page** from the task body's `@wiki-spec` tag or wiki backlink (normally `wiki/specs/<spec-slug>.md`).
5. **Append `## Implementation Evidence`** to the target page. For multi-attempt tasks, emit one `### Attempt N: <outcome>` subsection per non-final run (with `retry_notes` and `blocked_reason`), then a final block with: run id, completion timestamp, assignee profile, `verification` command(s) + result, `changed_files`, `residual_risk`, `branch_head`, and a one-paragraph summary. On re-ingest of a different run, append a new dated subheading rather than overwriting.
6. Update the target's frontmatter `updated` field and any `## Sources` row that points at the spec or concept.
7. **Verify zero dangling links — acceptance gate.**
8. Append a dated entry to `wiki/log.md` recording the run id, target page, verification outcome, attempt count, and any residual risk.

If the run failed, still ingest — mark the section `Result: failed` and quote the failure reason from the handoff. Documenting failures honestly is the point of [[concepts/living-documentation]].
