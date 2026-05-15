---
name: wiki-grill
description: Run the Grill workflow against an llm-wiki — surface and resolve open design questions before specs are written. Decision tree, depth-first interrogation, one question per turn. Use in any directory containing an AGENTS.md that follows the llm-wiki schema. Composes with wiki-strategy (upstream) and wiki-architecture / wiki-adr / wiki-spec (downstream).
---

# wiki-grill

Surface and resolve open design questions **before** specs are written. Modeled on [Matt Pocock's `grill-me` skill](https://github.com/mattpocock/skills/blob/main/skills/productivity/grill-me/SKILL.md): build a decision tree, interrogate depth-first, ask **one question at a time** with concrete options.

The wiki schema and workflow details live in `AGENTS.md` at the repo root. Read `### Grill` and follow the steps there. The [pipeline manifest](../../docs/rd-pipeline/pipeline-manifest.md) is the source of truth for ordering.

## Where this fits

```
strategy ──> grill ──> architecture ──> adr ──> spec ──> kanban-emit ──> ...
```

`scripts/check-prereqs.sh grill --slug <topic>` walks `grill → strategy`. A missing vision page hard-fails.

## Usage

```
/skill:wiki-grill <topic>
```

Re-runnable — resumes at the next unanswered question; `## Q&A Log` is globally numbered and append-only across runs.

## Hard rules

- **One question per turn.** Never batch. Each question has 2–4 concrete options plus an `other → free text` escape.
- **Park what you can't answer.** `## Open Questions` is append-only; never re-asked in the same run.
- **Decisions Made bullets are keyed by short title.** Same title rewrites; new titles append.

Downstream: `/wiki-architecture` reads the grill to know which questions the diagrams should answer; `/wiki-adr` cites `## Decisions Made` bullets as rationale.

After a clean run, hint: *"Next: `/wiki-architecture <topic>`."*
