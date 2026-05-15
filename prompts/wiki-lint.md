---
description: Audit the wiki for orphans, contradictions, missing links, and pipeline-manifest compliance
---
Read `AGENTS.md` and run the **Lint** workflow on the entire wiki.

Steps (from AGENTS.md):
1. Read every page under `wiki/`.
2. **General checks:**
   - Orphan pages (no inbound links).
   - Stale claims or contradictions between pages.
   - Missing cross-links where a page mentions a concept that has its own page.
   - Incomplete required sections per page type.
   - Low-confidence pages that could be strengthened with existing sources.
3. **Pipeline-manifest checks** (run when `wiki/.pipeline.yaml` exists; skip cleanly when absent):
   - **Manifest compliance.** For every spec page under `wiki/specs/`, run `scripts/check-prereqs.sh spec --slug <slug> --quiet --json`. Treat exit 1 as a lint warning (`spec missing upstream <missing>`). For every ADR, verify the topic slug it traces back to has an architecture page (when `optional_in_v1: false`) or warn (when `optional_in_v1: true`).
   - **Mermaid validation.** For every page under `wiki/architecture/`, parse each fenced ` ```mermaid ` block. If `mmdc` (`@mermaid-js/mermaid-cli`) is on PATH, run `mmdc --parseOnly` on each block; on failure, report the page + block index + the parser error. **Skip with a warning when `mmdc` is not installed** — do not fail the lint.
   - **`## Purpose` non-empty.** Every architecture page's `## Purpose` section must contain at least one non-empty sentence. Headings that exist but are empty (or contain only *"general system architecture"*-style placeholders) are flagged.
   - **ADR ↔ architecture backlinks.** Every accepted ADR should be referenced from at least one architecture page's `## Decisions Surfaced` bullet with `→ ADR-NNNN`. Missing back-references are flagged.
   - **Spec ↔ ADR backlinks.** For every spec, every entry in `frontmatter.adr_ids` must resolve to an existing ADR file with `## Status: accepted`. Dangling adr_ids are flagged.
   - **Kanban ↔ spec backlinks.** When `hermes` is on PATH, list any task in `running` or `blocked` columns whose `@wiki-spec` tag points at a spec lacking a `## Kanban` (or `## Kanban Tasks`) section listing the task id. Skip with a warning when `hermes` is not installed.
   - **Surfaced decisions without ADRs.** Every bullet in any architecture page's `## Decisions Surfaced` should eventually carry a `→ ADR-NNNN` tail; report bullets that have been pending for more than one lint run (heuristic: the bullet exists, no `→` tail, and the architecture page's `last_updated` is older than 7 days).
   - **Triage cross-link integrity.** Every `→ triage:<id>` annotation on a `## Open Questions` bullet should resolve to a Hermes triage task with the same id (or a `→ spec:<slug>` if it's been promoted). Skip when `hermes` is not installed.
   - **Handoff completeness.** When `kanban/board.yaml` exists and `hermes` is on PATH, read `board:` from `board.yaml`, then for every spec emitted to that board (detect via `hermes kanban list --board <slug> --json | jq` filtering on tasks whose body carries the `@wiki-spec` tag), assert that every completed run has a matching `kanban/handoffs/<task-id>.<run-id>.json`. Missing files indicate `/wiki-kanban-ingest` was never (or only partially) run for that task. Attempt auto-fix by re-running the ingest workflow for the affected task; if the auto-fix still leaves files missing, report. Skip cleanly when `kanban/board.yaml` is absent (back-compat with wikis that have not been bound).
   - **Evidence path validity.** Parse every `## Implementation Evidence` section in the wiki. Assert that every entry under `changed_files` (per-attempt and final) resolves to a path under `project/`. Report violations; do **not** auto-fix — the operator may have intentionally moved a file, and the right correction is in the next ingest cycle, not in lint.
   - **Board drift.** When `kanban/board.yaml` exists and `hermes` is on PATH, run `hermes kanban boards list --json` and confirm `board.yaml`'s `board:` slug is present. If absent, the board was deleted out from under the wiki — abort lint with loud red text: *"Board `<slug>` from `kanban/board.yaml` is not in `hermes kanban boards list`. Restore the board, or run `/wiki-kanban-board <new-slug>` to re-bind. Previously emitted tasks live on the missing board and cannot be ingested until it is restored."* Skip cleanly when `kanban/board.yaml` is absent.
4. **R&D-pipeline schema checks** (always run):
   - Every page under `wiki/specs/` cites at least one `accepted` ADR (warn, do not block — this matches the soft gate in the Spec workflow).
   - No two `accepted` ADRs contradict each other on the same decision (same title, or overlapping `## Decision` statements).
   - Every page under `wiki/contexts/` is referenced by at least one `wiki/context-maps/` page.
   - Every ADR cites an [[concepts/architecturally-significant-requirement]] (ASR) in `## Context`.
   - Every ADR with status `superseded by NNNN` links the successor file in `## Related Decisions`, and the successor file exists.
   - Every ADR with status `deprecated` has no inbound references from *active* kanban tasks (skip with a warning if `hermes` is not on `PATH`).
5. Fix what can be fixed automatically (missing links, incomplete sections you can fill from existing sources).
6. Report issues that need human judgment — list them clearly so the user can decide.
7. Suggest new sources or topics worth investigating to fill known gaps.
8. Append a dated `lint` entry to `wiki/log.md` summarizing what was fixed and what remains, broken out by category (orphans / sections / pipeline compliance / Mermaid / ADR backlinks / triage / Hermes-skipped).
