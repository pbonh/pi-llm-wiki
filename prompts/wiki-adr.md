---
description: Open a new Architectural Decision Record
argument-hint: "<decision title>"
---
Read `AGENTS.md` and follow the **ADR** workflow to open a new Architectural Decision Record for: $@

Derive the topic slug from the surrounding work — typically the slug of the architecture page where the surfaced decision lives. Pass it to the helper below.

**Preflight (hard).** Run `scripts/check-prereqs.sh adr --slug <topic-slug>` from the wiki root. On exit 1, print the helper's `missing` + `hint` verbatim and abort without writing anything. The manifest walks `adr → architecture (optional_in_v1) → grill (optional_in_v1) → strategy (required)`. A missing vision hard-fails; a missing architecture page degrades to a warning while `optional_in_v1: true`, but you should still warn the user that the ADR will lack a `## Decisions Surfaced` anchor. Exit 0 → proceed. Manifest absent → back-compat, proceeds.

**Decisions-surfaced gate (hard when architecture page exists).** If `wiki/architecture/<topic-slug>.md` exists, the short title `$@` must match (case-insensitive, on the leading bold span) at least one bullet under that page's `## Decisions Surfaced`. If no matching bullet exists, abort with: *"missing: surfaced-decision — the ADR title `$@` doesn't match any bullet under `wiki/architecture/<topic-slug>.md` `## Decisions Surfaced`. Add a bullet via `/wiki-architecture <topic>` first, or pick an existing surfaced decision."* Skip this gate cleanly when the architecture page is absent (back-compat with pre-Phase-2 wikis).

Steps (from AGENTS.md):
1. Scan `wiki/decisions/NNNN-*.md` and pick the next four-digit number (monotonic, never reused).
2. **Ask the user for the triggering [[concepts/architecturally-significant-requirement]] (ASR).** Refuse to proceed if none can be named — ADRs without an ASR are the AKM log-bloat failure mode. The ASR goes in `## Context`. When an architecture page exists, the surfaced-decision bullet is the *anchor* for the ASR; the ASR itself is still the requirement that made the decision load-bearing.
3. Pick a template: default **Nygard** (Status, Context, Decision, Consequences, Related Decisions); **MADR** when multiple realistic alternatives deserve preserved analysis (adds Decision Drivers + Considered Options); **Y-Statement** for one-liners.
4. Write `wiki/decisions/NNNN-<kebab-title>.md` with `type: decision`, `## Status: proposed`, the ASR citation, and the rest of the required sections. Tags must include `decision`.
5. Cross-link the ADR to every wiki page it governs; update those pages' Related Concepts / Related Decisions sections.
6. **Upsert the architecture page's surfaced-decision bullet.** If `wiki/architecture/<topic-slug>.md` exists, find the matching `## Decisions Surfaced` bullet and append ` → ADR-NNNN` to its line in place (idempotent — same ADR id rewrites the same suffix; no duplication on re-run). Use a sed/awk pattern that matches the bullet's bold-title span and replaces the line so re-runs converge.
7. **Refuse to edit an `accepted` ADR.** Instead open a new ADR that supersedes it; with the user's permission, flip the predecessor's `## Status` to `superseded by NNNN+1` and link the successor.
8. **Verify zero dangling links — acceptance gate.**
9. Update `wiki/index.md` Decisions table + Statistics, and append a dated entry to `wiki/log.md`.

The status field is load-bearing: `/wiki-spec` warns when no `accepted` ADR governs a domain, and `/wiki-kanban-emit` picks the collaboration pattern from ADR status.

After a clean run, hint: *"ADR NNNN written. When you're ready to convert this commitment into Gherkin, run `/wiki-spec <goal>`. Flip `## Status` to `accepted` before emitting kanban tasks for the spec."*
