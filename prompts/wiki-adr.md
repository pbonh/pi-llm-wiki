---
description: Open a new Architectural Decision Record
argument-hint: "<decision title>"
---
Read `AGENTS.md` and follow the **ADR** workflow to open a new Architectural Decision Record for: $@

Steps (from AGENTS.md):
1. Scan `wiki/decisions/NNNN-*.md` and pick the next four-digit number (monotonic, never reused).
2. **Ask the user for the triggering [[concepts/architecturally-significant-requirement]] (ASR).** Refuse to proceed if none can be named — ADRs without an ASR are the AKM log-bloat failure mode. The ASR goes in `## Context`.
3. Pick a template: default **Nygard** (Status, Context, Decision, Consequences, Related Decisions); **MADR** when multiple realistic alternatives deserve preserved analysis (adds Decision Drivers + Considered Options); **Y-Statement** for one-liners.
4. Write `wiki/decisions/NNNN-<kebab-title>.md` with `type: decision`, `## Status: proposed`, the ASR citation, and the rest of the required sections. Tags must include `decision`.
5. Cross-link the ADR to every wiki page it governs; update those pages' Related Concepts / Related Decisions sections.
6. **Refuse to edit an `accepted` ADR.** Instead open a new ADR that supersedes it; with the user's permission, flip the predecessor's `## Status` to `superseded by NNNN+1` and link the successor.
7. **Verify zero dangling links — acceptance gate.**
8. Update `wiki/index.md` Decisions table + Statistics, and append a dated entry to `wiki/log.md`.

The status field is load-bearing: `/wiki-spec` warns when no `accepted` ADR governs a domain, and `/wiki-kanban-emit` picks the collaboration pattern from ADR status.
