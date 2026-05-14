# Tutorial: a knowledge graph from raw sources

This is the minimum viable workflow for `pi-llm-wiki`. By the end you will have a wiki that ingests articles into a cross-linked concept graph, answers questions against the graph with citations, and lints itself for orphans and contradictions.

We use a running example of a knowledge base on **espresso extraction**. Swap the domain for whatever you care about — the steps are identical.

No Hermes, no kanban, no ADRs. This is the "research / knowledge graph only" path. The [R&D pipeline tutorial](./tutorial-rd-pipeline.md) layers strategy, decisions, and round-trip task execution on top of what you build here.

## 0. Install

```bash
npm install -g pi-llm-wiki
```

pi auto-discovers the package and installs the prompts and skill. The init binary `pi-llm-wiki-init` lands on your `PATH`, and a snapshot of the wiki template is bundled at `template/` inside the npm package.

## 1. Bootstrap the wiki

Start in an empty directory. `/wiki-new` will drop the bundled template into place and customize it for your domain.

```bash
mkdir espresso-kb && cd espresso-kb
pi
```

Inside pi:

```
/wiki-new a knowledge base on espresso extraction — grinder, dose, yield, time, temperature, pressure, and the relationships between them
```

pi will:

1. Detect that `AGENTS.md` is missing and run `pi-llm-wiki-init` to drop the template (`AGENTS.md`, `CLAUDE.md`, `raw/`, `wiki/`, `.gitignore`).
2. Walk through every `<!--` customization marker in `AGENTS.md`. The Purpose paragraph is filled mechanically from the description above. The Tagging Taxonomy is a judgement call — pi will propose categories and tags, confirm them with you, then commit.
3. Verify zero markers remain (`grep -n '<!--' AGENTS.md` returns nothing) before declaring done.
4. Commit `Customize llm-wiki for espresso extraction` if the directory is a git repo.

After `/wiki-new` finishes, you will have:

```
espresso-kb/
├── AGENTS.md              # customized schema — the source of truth
├── CLAUDE.md              # one-line pointer to AGENTS.md
├── raw/                   # drop your source documents here
└── wiki/
    ├── index.md           # master catalog (empty tables to start)
    ├── log.md             # append-only activity log
    ├── concepts/          # one page per concept
    ├── entities/          # one page per person/tool/org
    ├── summaries/         # one page per raw source
    ├── syntheses/         # cross-cutting analyses
    ├── specs/             # populated by /wiki-spec (covered later)
    ├── flashcards/        # populated by /wiki-flashcards
    ├── presentations/     # populated by /wiki-present
    ├── books/             # populated by /pdf-to-mdbook
    ├── vision/            # R&D pipeline — empty until /wiki-strategy
    ├── contexts/          # R&D pipeline — empty until /wiki-strategy
    ├── context-maps/      # R&D pipeline — empty until /wiki-strategy
    ├── decisions/         # R&D pipeline — empty until /wiki-adr
    └── journal/           # ad-hoc research notes
```

## 2. Add a source

Anything text-like is fair game: a transcript, a blog post, your own notes, a PDF that has already been OCRed (use `/pdf-to-mdbook` first if it has not).

For this tutorial, save the article below as `raw/scott-rao-extraction-2019.md`:

```markdown
# Scott Rao on espresso extraction (2019)

Espresso extraction quality is dominated by four variables: dose, yield,
time, and temperature. Dose and yield define the ratio — a 1:2 ratio
means 18 g in, 36 g out. Time anchors the contact period; under-extracted
shots run too short, over-extracted too long. Temperature controls the
solubility curve.

Channeling — uneven water flow through the puck — is the dominant defect
mode. It produces an underextracted shot regardless of ratio or time
because the water bypasses the coffee. Counter-measures: WDT (Weiss
Distribution Technique), level tamping, fresh basket.

The grinder matters more than the machine. A flat-burr grinder produces
a tighter particle distribution than a conical-burr grinder, which
reduces channeling at the cost of clarity.
```

The Ingest workflow promises *never to modify files in `raw/`*. Treat the source as immutable.

## 3. Run `/wiki-ingest`

```
/wiki-ingest raw/scott-rao-extraction-2019.md
```

The agent will:

1. Read the source completely.
2. Write `wiki/summaries/scott-rao-extraction-2019.md` with `## Key Points`, `## Relevant Concepts`, and `## Source Metadata` sections.
3. Identify every concept, entity, strategy, and framework mentioned. For each, create the page if it does not exist or update it if it does. From this source you will get pages like `wiki/concepts/extraction-ratio.md`, `wiki/concepts/channeling.md`, `wiki/concepts/weiss-distribution-technique.md`, `wiki/entities/flat-burr-grinder.md`.
4. Add bidirectional `[[concepts/...]]` cross-links between every touched page.
5. **Verify zero dangling links.** This is a hard acceptance gate: every `[[wiki-link]]` must resolve to a real file. The agent lists every link it wrote, checks each target on disk, and either creates the missing page (with `confidence: low` if the source only mentions it in passing) or removes the link. It re-scans until zero remain.
6. Update `wiki/index.md` with rows for new and updated pages.
7. Append a dated entry to `wiki/log.md` recording the source, pages created, and pages updated. If anything in the new source contradicts an existing wiki page, the contradiction is flagged in the log.

A representative concept page looks like:

```markdown
---
title: "Channeling"
type: concept
tags: [defect-mode, extraction]
created: 2026-05-14
updated: 2026-05-14
sources: ["raw/scott-rao-extraction-2019.md"]
confidence: high
---

## Definition
Uneven water flow through the coffee puck during espresso extraction…

## How It Works
…

## Key Parameters
- Puck preparation (WDT, level tamping)
- Basket condition
- Grind uniformity (see [[entities/flat-burr-grinder]])

## When To Use
N/A — this is a defect, not a technique.

## Risks & Pitfalls
- Channeling produces an under-extracted shot regardless of ratio or time…

## Related Concepts
- [[concepts/extraction-ratio]]
- [[concepts/weiss-distribution-technique]]

## Sources
- [[summaries/scott-rao-extraction-2019]]
```

Re-running `/wiki-ingest` on the same source is safe — the agent prefers updating existing pages over duplicating them.

### Add a second source

Now save `raw/lance-hedrick-channeling-2023.md` with a contrasting take — say, a video transcript that argues puck screens matter more than WDT — and run:

```
/wiki-ingest raw/lance-hedrick-channeling-2023.md
```

The same workflow now sees existing pages on `channeling` and `extraction-ratio` and *updates* them rather than rewriting. If the new source contradicts the prior one, the contradiction is recorded both on the affected concept page (under low confidence with notes) and in `wiki/log.md`. The wiki accumulates disagreement honestly instead of last-write-wins.

## 4. Run `/wiki-query`

```
/wiki-query what causes channeling, and which counter-measure has the most evidence behind it?
```

The agent will:

1. Read `wiki/index.md` to find relevant pages.
2. Read those pages in full (not just the index entries).
3. Synthesize an answer that cites specific pages with `[[concepts/...]]` and `[[entities/...]]` links.
4. If the answer reveals a *novel cross-cutting insight* — say, a comparison between WDT and puck-screens that did not exist in any single source — create a synthesis page in `wiki/syntheses/`, update `wiki/index.md`, and append to `wiki/log.md`.

If the wiki lacks the information to answer well, the agent says so explicitly and suggests which raw sources would fill the gap. **It will not invent claims.** That is a load-bearing property of the workflow — sources lie behind every claim, and gaps are flagged rather than papered over.

## 5. Run `/wiki-lint`

After a few ingests, run a health check:

```
/wiki-lint
```

The agent reads every page under `wiki/` and checks for:

- **Orphan pages** — pages with no inbound `[[...]]` links.
- **Stale claims and contradictions** — assertions in one page that conflict with another.
- **Missing cross-links** — page A mentions "channeling" in prose but does not link `[[concepts/channeling]]`.
- **Incomplete required sections** — a concept page missing `## Definition` or `## Risks & Pitfalls`.
- **Low-confidence pages that could be strengthened** — pages flagged `confidence: low` whose source set has grown since.

Whatever can be fixed automatically gets fixed. The rest is reported back to you as a list of decisions to make, and a `lint` entry goes into `wiki/log.md` summarizing what changed and what is left.

If you have not yet used the R&D pipeline (strategy, ADRs, kanban), Lint will skip the R&D-pipeline-specific checks. They activate the moment you have pages under `wiki/decisions/`, `wiki/contexts/`, etc.

## 6. Optional side-trips

These are pull-on-demand workflows. You do not have to run them — none of the core ingest / query / lint loop depends on them — but they are useful when you want to extract value *from* the wiki in different shapes.

### `/wiki-flashcards <page>`

Generate [obsidian-spaced-repetition](https://github.com/st3v3nmw/obsidian-spaced-repetition)-compatible flashcards from a single wiki page.

```
/wiki-flashcards concepts/extraction-ratio
```

The agent reads `wiki/concepts/extraction-ratio.md`, derives cards from its required sections (`## Definition`, `## How It Works`, `## Key Parameters`, `## When To Use`, `## Risks & Pitfalls`), picks a format per card (Basic `Q / ? / A`, Reversed `Q / ?? / A`, or Cloze `==hidden==`), and writes `wiki/flashcards/extraction-ratio.md`. The `flashcards` tag is mandatory — without it the Obsidian plugin will not discover the cards.

### `/wiki-present <topic>`

Generate a [Marp](https://marp.app/) slide deck from wiki content on a topic.

```
/wiki-present espresso extraction fundamentals
```

The agent does the same retrieval as `/wiki-query`, then stitches the relevant pages into a deck at `wiki/presentations/espresso-extraction-fundamentals.md`. The frontmatter merges Marp config (`marp: true`, `theme: default`, `paginate: true`) with the standard wiki frontmatter so the file renders as a deck *and* fits in the wiki schema. Every cited page appears on a `## References` slide as a `[[wiki/...]]` link.

### `/pdf-to-mdbook <path>`

Convert a PDF into a runnable [mdBook](https://rust-lang.github.io/mdBook/). This is a *conversion-only* workflow — it does not ingest the book's content into the wiki graph. If you want concept pages from the book, run `/wiki-ingest` on the source PDF or the rendered book afterwards.

```
/pdf-to-mdbook raw/scott-rao-the-professional-barista-handbook.pdf
```

The agent auto-OCRs scanned PDFs, recovers structure from the embedded outline or via vision, reconstructs chapter prose, validates with `mdbook build`, and records the book in `wiki/index.md` + `wiki/log.md`. For books >25 pages it dispatches per-chapter subagents to stay under the vision-API image cap. Requires `poppler`, `ocrmypdf`, `tesseract`, `mdbook`, and `python3`+`pypdf` on `PATH`.

## 7. The shape of the artifacts you just built

After a few ingests, queries, and a lint, you have:

- **A summary** for every source you fed in, stored in `wiki/summaries/<source-slug>.md`.
- **A concept page** for every claim, mechanism, or distinction the sources made. These are the *nodes* of the knowledge graph.
- **An entity page** for every person, tool, or organization named.
- **Bidirectional links** between pages — these are the *edges*. No page is an orphan; every `[[wiki-link]]` resolves to a real file (the zero-dangling-links acceptance gate is what keeps the graph honest).
- **A master index** at `wiki/index.md` listing every page, used by `/wiki-query` and `/wiki-present` for retrieval.
- **An activity log** at `wiki/log.md` that is append-only and dated. This is your research diary; it is what you read to remember what happened and why.

That is the full basic loop. Drop a source, ingest, query, lint, repeat.

## Where to go next

- If your goal is research and you just want to *know things*, this is the whole workflow. Loop on it. The wiki gets denser and more useful as you ingest more sources.
- If your goal is to *build something* using the wiki as the source of truth — turn concepts into formal specs, pin architectural commitments via ADRs, hand work off to a multi-agent kanban board, and feed results back in — read the [R&D pipeline tutorial](./tutorial-rd-pipeline.md) next.
