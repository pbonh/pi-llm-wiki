# pi-llm-wiki docs

End-user documentation for the slash commands and skill that `pi-llm-wiki` adds to [pi](https://pi.dev/docs/latest). The `README.md` at the repo root is the install + command-list quick reference; this `docs/` tree is the long-form material.

## Reading order

If you have never used the wiki before, start with the knowledge-graph tutorial. The R&D pipeline tutorial assumes you are already comfortable with the basics.

1. **[tutorial-knowledge-graph.md](./tutorial-knowledge-graph.md)** — the minimum viable workflow: bootstrap a wiki, drop a source in `raw/`, run `/wiki-ingest`, run `/wiki-query`, run `/wiki-lint`. Optional side-trips into flashcards, presentations, and PDF→mdBook conversion. This is the "research / knowledge graph only" path — no ADRs, no kanban, no Hermes dependency.

2. **[tutorial-rd-pipeline.md](./tutorial-rd-pipeline.md)** — the full research-and-development pipeline: strategic design → ADRs → Gherkin specs → kanban emission → ingest of completed runs → refinement loop on breakthroughs. Runs against an example software R&D effort end-to-end and shows the artifacts each step produces.

3. **[rd-pipeline/](./rd-pipeline/)** — per-feature reference pages. One file per R&D slash command, covering inputs, outputs, soft/hard gates, idempotency rules, and failure modes. Read these when you are mid-flow and need to look up exactly what `/wiki-kanban-emit` does with a `proposed` ADR, or what `/wiki-refine` will *not* edit on its own.

## What lives where

| Topic | Where |
|---|---|
| Install + one-line command list | repo-root `README.md` |
| Wiki schema (frontmatter, sections, link rules) | `template/AGENTS.md` (also dropped into every user wiki on `/wiki-new`) |
| Slash-command prompts (the actual instructions pi reads) | `prompts/*.md` |
| Worked tutorials | this directory |
| Per-feature R&D reference | `docs/rd-pipeline/` |

The slash commands and skill are thin wrappers — they delegate to `AGENTS.md` rather than restating the rules. If a tutorial here disagrees with `template/AGENTS.md`, `AGENTS.md` wins; please file an issue.

## Optional runtime dependency

The basic knowledge-graph workflows (ingest, query, lint, spec, ADR, strategy, refine-as-documentary, flashcards, presentations, PDF→mdBook) run with no extra binaries beyond what `/pdf-to-mdbook` needs (`poppler`, `ocrmypdf`, `tesseract`, `mdbook`, `python3`+`pypdf`).

The kanban round-trip (`/wiki-kanban-emit`, `/wiki-kanban-ingest`, and the kanban-aware checks inside `/wiki-lint`) additionally requires [`hermes`](https://github.com/NousResearch/hermes) on `PATH`. Both kanban prompts preflight `hermes kanban assignees` and abort with an install hint if it is missing; they never silently degrade.
