---
name: wiki-adr
description: Run the ADR workflow against an llm-wiki — open a new Architectural Decision Record (Nygard / MADR / Y-Statement). Refuses without an ASR; refuses to edit accepted ADRs (supersede instead). Use in any directory containing an AGENTS.md that follows the llm-wiki schema. Composes with wiki-architecture (upstream) and wiki-spec (downstream).
---

# wiki-adr

Open a new [Architectural Decision Record](https://martinfowler.com/articles/decision-records.html) in `wiki/decisions/NNNN-<kebab-title>.md`. ADRs pin commitments before they are encoded in code, carry their rationale forward, and survive [breakthroughs](https://example.org) via the write-once / supersede-don't-edit discipline.

The wiki schema and workflow details live in `AGENTS.md`. Read `### ADR` and follow the steps there. The [pipeline manifest](../../docs/rd-pipeline/pipeline-manifest.md) is the source of truth for ordering.

## Where this fits

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> ...
```

`scripts/check-prereqs.sh adr --slug <topic>` walks `adr → architecture (optional) → grill (optional) → strategy`. The vision page is required; `architecture` and `grill` are optional in v1.

When `wiki/architecture/<topic>.md` exists, the ADR title must match a bullet under that page's `## Decisions Surfaced` (Phase 3 enforcement). The agent upserts ` → ADR-NNNN` onto the matching bullet after writing.

## Usage

```
/skill:wiki-adr <decision title>
```

## Hard rules

- **Refuse without an ASR.** The triggering [architecturally-significant requirement](https://en.wikipedia.org/wiki/Architecturally_significant_requirements) goes in `## Context`. ADRs without an ASR are the AKM log-bloat failure mode.
- **Refuse to edit an `accepted` ADR.** Open a new ADR that supersedes it; the predecessor's body stays intact.
- **Numbers are monotonic across the wiki.** Never reuse a deleted draft's number.
- **One decision per ADR.** Do not bundle multiple commitments.

Template choice: Nygard (default), MADR (when alternatives deserve preserved analysis), Y-Statement (one-liners).

After a clean run, hint: *"ADR written. Flip `## Status` to `accepted` before `/wiki-spec` emits Gherkin against it."*
