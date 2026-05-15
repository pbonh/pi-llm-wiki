---
name: wiki-lint
description: Run the Lint workflow against an llm-wiki — audit for orphans, contradictions, missing cross-links, incomplete sections, pipeline-manifest compliance, Mermaid validation, ADR backlinks, and triage cross-link integrity. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
---

# wiki-lint

Audit the wiki for orphans, contradictions, missing links, incomplete sections, and pipeline-manifest compliance.

The wiki schema and workflow details live in `AGENTS.md`. Read `### Lint` and follow the steps there.

## Usage

```
/skill:wiki-lint
```

## What it checks

- **General health:** orphan pages (no inbound links), contradictions, missing cross-links, incomplete required sections, low-confidence pages that could be strengthened.
- **Pipeline-manifest compliance** (when `wiki/.pipeline.yaml` exists): `scripts/check-prereqs.sh <artifact> --slug <slug>` per spec; Mermaid validation per architecture page when `mmdc` is on PATH; ADR-architecture and spec-ADR backlinks; surfaced-decisions-without-ADRs heuristic; triage cross-link integrity.
- **R&D-pipeline schema:** every spec cites at least one accepted ADR; no two accepted ADRs contradict each other; every context is referenced by a context map; every ADR cites an ASR; every superseded ADR links its successor; every deprecated ADR has no active kanban references.

## Behavior

- **Skips cleanly when external tools are absent.** `mmdc` not installed → Mermaid validation warns rather than fails. `hermes` not installed → kanban-aware checks warn rather than fail. The lint never fails for missing optional dependencies.
- Fixes what can be fixed automatically (missing cross-links, simple incomplete sections from existing sources).
- Reports the rest as items needing human judgment.
- Appends a dated `lint` entry to `wiki/log.md`, broken out by category.
