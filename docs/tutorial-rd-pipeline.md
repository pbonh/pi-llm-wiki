# Tutorial: the full R&D pipeline

This tutorial walks through every step of the R&D pipeline against a single example effort, from "we have ingested some sources on the domain" to "completed implementation runs are flowing back into the wiki as living documentation." If you have not used the wiki at all yet, read the [knowledge-graph tutorial](./tutorial-knowledge-graph.md) first — this one assumes you are comfortable with `/wiki-ingest`, `/wiki-query`, and `/wiki-lint`.

The example we will use: **a shipping-rate API** that aggregates carrier quotes (USPS, UPS, FedEx) behind a single endpoint. Concrete enough to have real bounded contexts (rating, carrier integration, cache), real architectural decisions (which timeout strategy, whether to share a rate schema across carriers), and real Gherkin-shaped behavior. Swap it for whatever you are actually building.

The seven slash commands you will use, in the order they appear:

1. `/wiki-ingest` — same as the basic tutorial, but used to seed the domain knowledge the pipeline runs on.
2. `/wiki-strategy` — distill vision, bounded contexts, and a context map from the ingested wiki.
3. `/wiki-adr` — pin an architecturally-significant commitment as a write-once Architectural Decision Record.
4. `/wiki-spec` — synthesize Gherkin scenarios from a user goal, gated softly on having an `accepted` ADR.
5. `/wiki-kanban-emit` — decompose the spec onto a [Hermes Kanban](https://github.com/NousResearch/hermes) board with idempotent task identity.
6. `/wiki-kanban-ingest` — round-trip a completed kanban run back into the wiki as an `## Implementation Evidence` section.
7. `/wiki-refine` — close the loop when a run outcome invalidates a prior model: supersede the ADR, re-emit affected tasks, update the upstream concept pages.

Steps 5–7 require [`hermes`](https://github.com/NousResearch/hermes) on `PATH`. Steps 1–4 do not.

## 0. Pre-flight

Install per the basic tutorial, plus Hermes if you intend to run kanban steps:

```bash
npm install -g pi-llm-wiki
# Hermes — required for steps 5–7 only
# follow install instructions at https://github.com/NousResearch/hermes
hermes kanban assignees   # should list at least one profile
```

Bootstrap a wiki for the domain:

```bash
mkdir shipping-rate-api && cd shipping-rate-api
pi
```

In pi:

```
/wiki-new an R&D knowledge base for a multi-carrier shipping-rate aggregation API — carriers (USPS, UPS, FedEx), rate cards, address normalization, caching, SLAs
```

## 1. Seed the wiki with domain knowledge

Drop a few sources into `raw/` — vendor docs (carrier API references), prior architecture writeups, transcripts of design conversations — and ingest each:

```
/wiki-ingest raw/ups-rating-api-v1.md
/wiki-ingest raw/usps-priority-mail-zones.md
/wiki-ingest raw/internal-design-conversation-2026-04.md
```

The strategy and spec workflows that follow are *retrieval-driven*: they read `wiki/index.md` and the relevant concept/entity pages. They cannot identify bounded contexts the wiki does not yet contain, and they refuse to invent them. Seed enough material first.

You can check whether you have enough by running:

```
/wiki-query what bounded contexts seem to exist in this domain?
```

If the answer is concrete (three or four distinct vocabularies, distinct entities, distinct invariants), proceed. If it is generic, ingest more sources first.

## 2. `/wiki-strategy` — distill vision + bounded contexts + context map

```
/wiki-strategy shipping-rate-api
```

This runs the [domain-driven design](https://martinfowler.com/bliki/BoundedContext.html) strategic-design phase against the wiki's existing knowledge. It produces three artifacts:

- **`wiki/vision/shipping-rate-api.md`** — what the R&D effort delivers that is differentiating. Required sections: `## Value Proposition`, `## In Scope`, `## Out of Scope`, `## Differentiation`, `## Revisions` (append-only dated log of scope changes).
- **`wiki/contexts/<context-slug>.md`** for every bounded context identified — typically three or four pages for an effort like this one (e.g. `rating-context`, `carrier-integration-context`, `cache-context`, `address-normalization-context`). Each page has `## Model`, `## Boundary`, `## Ubiquitous Language` (inline glossary — **not** just links out, the per-context dictionary is what prevents drift), and `## Relationships`.
- **`wiki/context-maps/shipping-rate-api.md`** — `## Contexts`, `## Translations` table (one row per cross-boundary term), `## False Cognates` (terms that look identical across contexts but mean different things — e.g. *Rate* in the carrier-integration context is a tariff response; *Rate* in the rating context is a normalized customer-facing quote), and `## Integration Patterns` (shared-kernel / customer-supplier / conformist / anticorruption-layer / published-language / open-host-service / separate-ways for each context pair).

The workflow is **re-runnable**. Later `/wiki-strategy shipping-rate-api` runs *update* the existing pages by slug rather than duplicating — same way `/wiki-ingest` updates concept pages.

If the wiki does not have enough material to identify distinct bounded contexts, the agent says so and points you back to `/wiki-ingest`. **It will not invent contexts.** A single bounded context is a valid outcome; in that case the context map is a one-row map of the context against the outside world.

The Glossary entries you accumulate on each `wiki/contexts/<slug>.md` page are **load-bearing for `/wiki-kanban-emit`** — those glossary excerpts get inlined into kanban task bodies later to prevent false-cognate drift across workers.

## 3. `/wiki-adr` — pin a load-bearing architectural commitment

Pick one decision you are about to make whose effect on structure or quality attributes is large enough that you want a written, immutable rationale. A good candidate from our example: "Rate responses are cached by `(origin_zip, destination_zip, weight_bucket, carrier)` — we do **not** cache by literal address."

```
/wiki-adr cache-key-uses-zip-and-weight-bucket-not-address
```

The agent will:

1. Scan `wiki/decisions/NNNN-*.md` and pick the next monotonic four-digit number — say `0003`.
2. **Ask you to name the triggering [architecturally-significant requirement (ASR)](https://en.wikipedia.org/wiki/Architecturally_significant_requirements).** It will *refuse to proceed* without one. ADRs without an ASR are the [AKM](https://www.iaria.org/conferences2011/SOFTENG11/) log-bloat failure mode — they accumulate without anchoring anything. The ASR for our example might be: *"P99 latency on cache hits must be <50ms, and the cache must survive a 10× spike in unique address inputs that all resolve to the same zip pair."* That requirement is what makes the decision load-bearing.
3. Pick a template:
   - **Nygard** (default) — Status / Context / Decision / Consequences / Related Decisions.
   - **MADR** — when multiple realistic alternatives deserve preserved analysis. Adds `## Decision Drivers` and `## Considered Options` sections.
   - **Y-Statement** — when you want a one-liner. *"In the context of `<X>`, facing `<Y>`, we decided for `<Z>` to achieve `<Q>`, accepting `<W>`."* Can stand alone or sit at the top of a Nygard ADR.
4. Write `wiki/decisions/0003-cache-key-uses-zip-and-weight-bucket-not-address.md` with `## Status: proposed`, the ASR citation in `## Context`, and the rest of the required sections. Tags include `decision`.
5. Cross-link the ADR to every wiki page it governs (the cache context page, the rating context page, the relevant concept pages). Those pages get updated to link back.
6. Run the zero-dangling-links acceptance gate.
7. Update `wiki/index.md` Decisions table and append to `wiki/log.md`.

When you are ready to commit to the decision, flip the status:

- Open the ADR.
- Change `## Status: proposed` to `## Status: accepted`.
- Commit.

**Once `## Status` is `accepted`, the ADR body is write-once.** To change an accepted decision, you do not edit it — you open a new ADR (`/wiki-adr <new title>`) that supersedes it. The new ADR cites the predecessor in `## Related Decisions`; with your permission the agent flips the predecessor's status to `superseded by 0007` and links the successor. The predecessor's body stays intact. This is the [decision log](https://martinfowler.com/articles/decision-records.html) discipline that survives breakthroughs.

The status field is **load-bearing for downstream workflows**:

- `/wiki-spec` warns when no `accepted` ADR governs the spec's domain.
- `/wiki-kanban-emit` picks the collaboration pattern from the cited ADRs' status (`accepted` → pipeline, `proposed` → human-in-the-loop, `deprecated`/`superseded`-without-successor → refuse).

## 4. `/wiki-spec` — synthesize Gherkin from a user goal

```
/wiki-spec a customer-facing endpoint that returns the cheapest of all carrier quotes for an origin, destination, and weight, falling back to a cached quote within the last hour if a carrier times out
```

The Spec workflow runs an automated specification-by-example workshop:

1. Reads `wiki/index.md` and the relevant concept/entity/context pages.
2. **ADR check (soft gate).** Scans `wiki/decisions/` for an `accepted` ADR governing this domain — heuristic: an ADR whose `## Context` cites the same context page or concept pages the goal touches. For our example, the cache-key ADR (`0003`) and any rating-context ADR are candidates. If none has been accepted yet, the agent warns you and offers to hand control to `/wiki-adr` to draft a Y-Statement first. You can proceed without one — the choice is recorded in the spec's `## Sources`.
3. **Vagueness check.** If the goal lacks a clear *actor + outcome*, the agent emits only the `## Scope` impact map (a table of `Actor | Impact | Deliverable`) and asks you to confirm scope before writing scenarios. Our goal above is clear enough to skip this.
4. Derives user stories with **binary pass/fail** acceptance criteria.
5. Translates each acceptance criterion into Gherkin scenarios inside fenced ```` ```gherkin ```` blocks. Quality rules:
   - **Business-readable.** No UI buttons, no DB tables, no CSS selectors. Steps describe outcomes ("the cheapest quote is returned"), not interactions ("she clicks Submit").
   - **Single `When` per scenario.** Behaviors stay decoupled.
   - **Realistic data.** Named personas, concrete numbers — not `customer1` and `value1`.
   - **`Scenario Outline` + `Examples`** for parameterized cases (e.g. one outline covering FedEx / UPS / USPS timeouts with one row each).
6. Extracts a `## Glossary` of every ubiquitous-language term used. Terms that already exist as `concepts/<term>` get linked; new terms get flagged (and stubbed as low-confidence concept pages by the zero-dangling-links gate).
7. Writes `wiki/specs/cheapest-quote-with-cache-fallback.md` with full frontmatter (`type: spec`, tags including `spec` and `gherkin`) and required sections (`## Goal`, optional `## Scope`, `## User Stories`, `## Scenarios`, `## Glossary`, `## Sources`).
8. Runs the zero-dangling-links acceptance gate. Same rule as Ingest: every `[[...]]` must resolve, missing pages get stubbed (`confidence: low`), or the link is removed.
9. Updates `wiki/index.md` and `wiki/log.md`.

The Gherkin in the spec page is the executable contract end-to-end. It is also the unit that `/wiki-kanban-emit` will copy verbatim into each kanban task — preserving the [executable-specification](https://en.wikipedia.org/wiki/Specification_by_example) chain from intent to implementation.

A specification-by-example scenario for our example will look something like:

````markdown
```gherkin
Scenario: Cheapest quote returned across three carriers
  Given Carla is shipping a 4 lb package from 94110 to 02139
  And USPS quotes $14.20, UPS quotes $18.50, FedEx quotes $16.10
  When Carla requests a shipping rate
  Then the response carrier is USPS
  And the response amount is $14.20
```
````

## 5. `/wiki-kanban-emit` — decompose onto a Hermes Kanban board

**Requires `hermes` on `PATH`.** The prompt preflights `hermes kanban assignees` and aborts with an install hint if it is missing.

```
/wiki-kanban-emit cheapest-quote-with-cache-fallback
```

The workflow:

1. **Preflight (hard).** `hermes kanban assignees`. If Hermes is missing or no profiles are configured, abort with: *"Hermes is not installed or no profiles are configured. See https://github.com/NousResearch/hermes. Kanban emission requires Hermes; the rest of this wiki works without it."*
2. **ADR gate (soft).** If the spec cites no `accepted` ADR, warn and offer to hand control to `/wiki-adr`. Record any proceed-without-ADR choice in `## Sources`.
3. Read `wiki/specs/cheapest-quote-with-cache-fallback.md` in full — frontmatter, every story, every scenario, glossary, sources.
4. For every cited ADR, confirm `## Status: accepted`. For the relevant `wiki/contexts/<context>.md` pages, read the inline `## Ubiquitous Language` glossary — these excerpts get **inlined into each task body** to prevent false-cognate drift across workers.
5. **Compute the idempotency key:** `<spec-slug>:<adr-id>:<sha256(spec-body-excluding-frontmatter-and-Kanban-Tasks-section)>`. This triple is the cross-system identity of the task set. Re-emission semantics:
   - Same triple → updates the existing task.
   - Spec edited → new sha256 → updates the existing task.
   - ADR superseded → new ADR id → **new task row** (the old one gets closed with a `kanban_comment` pointing forward, by `/wiki-refine`).
   - Spec split into multiple slugs → multiple new task rows.
6. **Enumerate profiles.** The output of `hermes kanban assignees` is the *exhaustive* list of legal `assignee` values; unknown assignees silently fail to spawn. Map logical roles (`implementer`, `reviewer`, `integrator`) to real profile names. Fail loudly on missing mappings — do not pick a "default" profile.
7. **Pick the collaboration pattern from ADR status:**
   - `accepted` → **P2 pipeline** (`implementer → reviewer → integrator`).
   - `proposed` → **P5 human-in-the-loop** (implementer + reviewer + a final human-gate task before integration).
   - Multiple independent feature files → wrap the pipeline in a **P1 fan-out** parent.
   - When reviewer agreement matters more than throughput → **P3 voting/quorum** (two reviewers + aggregator).
   - `deprecated` / `superseded` without a successor in `accepted` state → **refuse to emit**.
8. **Decompose.** One `kanban_create` per user story. Each task body MUST include:
   - The story's goal, verbatim from the spec.
   - Approach (the story narrative when the spec has one; otherwise left open).
   - Acceptance criteria verbatim.
   - The Gherkin block fenced inside ```` ```gherkin ````.
   - The relevant glossary excerpt **inlined** from the bounded-context page (not just a link — inline, to prevent drift).
   - A wiki backlink to `wiki/specs/<spec-slug>.md`.
   - The ADR id(s) cited by the spec.
   - A `@wiki-spec` traceability tag.
9. **Express ordering** with `parents=[...]` on each `kanban_create`. The reviewer task's `parents` is the implementer; the integrator's `parents` is the reviewer; the human-gate's `parents` is whatever it gates.
10. **Workspace selection.** Tasks that mutate the wiki use `workspace=dir:<absolute path>`. Tasks that touch a code repo prefer `worktree`. Relative paths are rejected at dispatch (the [confused-deputy](https://en.wikipedia.org/wiki/Confused_deputy_problem) guard).
11. **Record task ids on the spec page.** Append a `## Kanban Tasks` section listing: idempotency key, ADR ids, collaboration pattern, profile mapping, and each task's id + role + assignee.
12. Run the zero-dangling-links acceptance gate on the updated spec page.
13. Append to `wiki/log.md` with the same metadata.

**Discipline: the extension is the orchestrator, never a worker.** It creates rows and steps back. It does not claim, run, or shell out to do worker tasks (that violates the [orchestrator pattern](https://en.wikipedia.org/wiki/Orchestrator_pattern) / three-plane-architecture discipline). It does not poll the board for completion — fire and forget.

If the spec is updated mid-execution, push the diff onto the task thread via `kanban_comment`; do not silently edit a `running` task's body.

## 6. The workers run, off-screen

This step is not a slash command. Hermes profiles claim their assigned tasks and execute them in whatever sandbox you have configured. The wiki/extension does not orchestrate the runtime — that is Hermes' job. When a run completes (success or failure), Hermes records a [structured handoff](https://hermes.docs/structured-handoff) payload with `summary`, `verification`, `changed_files`, and `residual_risk` fields.

You will normally know a run is done because you are watching the board, you got a Slack notification, or someone tagged you. The wiki itself does not poll.

## 7. `/wiki-kanban-ingest` — round-trip the run as living documentation

```
/wiki-kanban-ingest <task-id-or-run-id>
```

**Requires `hermes` on `PATH`.** Same preflight as Emit.

The workflow:

1. Fetch the completed run via `hermes kanban show <id>`. Capture `summary`, `verification`, `changed_files`, `residual_risk`, and the structured-handoff payload.
2. **Sanitize metadata.** The structured-handoff contract forbids tokens, OAuth material, raw logs, and unrelated transcripts. The agent copies summaries and pointers (file paths, commit hashes, run ids, URLs) and **refuses to copy secrets or raw logs even if they appear in the payload.** If the metadata is dirty, the agent surfaces the problem to you and stops — it does not silently scrub-and-copy.
3. Locate the originating wiki page from the task body's `@wiki-spec` tag or the wiki backlink. Normally `wiki/specs/<spec-slug>.md`; for refinement-driven re-runs it may be a concept page.
4. Append an `## Implementation Evidence` section to the target page with: run id, completion timestamp, assignee profile, `verification` command(s) + their result, `changed_files` (linked to the repo when possible), `residual_risk`, and a one-paragraph summary from the structured handoff.
   - **On re-ingest, append a new dated subheading rather than overwriting.** The evidence section accumulates honestly.
5. Update frontmatter `updated` on the target page and any `## Sources` row that points at the spec or concept.
6. Run the zero-dangling-links acceptance gate.
7. Append to `wiki/log.md` with run id, target page, verification outcome, and any residual risk.

**Failed runs are still ingested.** A section is appended with `Result: failed` and the failure reason quoted from the handoff. Documenting failures honestly is the whole point — the next attempt has the prior failure's context.

After `/wiki-kanban-ingest`, the spec page is no longer just an intent — it carries a verifiable record of every attempt to satisfy it, what shipped, and what is still risky. That is what living documentation looks like in practice.

## 8. `/wiki-refine` — close the loop when a run invalidates a prior model

Most run outcomes are documentary — `/wiki-kanban-ingest` handles them. But sometimes a run surfaces something *structural*: an architectural commitment was invalidated, a new false cognate emerged, a context boundary moved, a new concept needs its own page. That is what `/wiki-refine` is for.

Concrete trigger from our example: the cache-key ADR (`0003`) said "cache by zip-pair + weight-bucket + carrier." The implementer's run shows that under real load this misses a 30% slice — packages crossing zone boundaries route differently depending on origin city, even within the same origin zip. The decision is invalidated.

```
/wiki-refine <run-id>
```

(or `/wiki-refine "cache key needs city granularity, not just zip — see <run-id> notes"`)

The workflow:

1. **Classify the trigger.** Read the structured handoff (or the user's note). Decide:
   - **Documentary only** → hand off to `/wiki-kanban-ingest` and stop. Refine is not the right tool.
   - **Structural** → at least one of: an architectural commitment was invalidated; a new false cognate surfaced; a bounded-context boundary moved; a new concept emerged. Continue.
2. **Update the upstream model.**
   - Concept-page-level fact → open or update `wiki/concepts/<term>.md`. New concept → create a new page.
   - Bounded-context boundary moved → update `wiki/contexts/<context>.md` `## Boundary` and add a dated `## Revisions`-style note.
   - New false cognate surfaced → update `wiki/context-maps/<topic>.md` `## False Cognates` list and `## Translations` table.
3. **Open a superseding ADR.** Hand off to `/wiki-adr` to open a new ADR that supersedes the prior one. **The agent will not edit the accepted predecessor** — supersede, never edit. The new ADR's `## Context` cites the originating run id (or breakthrough note). The predecessor's `## Status` is flipped to `superseded by 0007` with a link to the successor; the predecessor body stays intact.
4. **Re-emit affected kanban tasks.** For every active kanban task whose spec page cites the now-superseded ADR, hand off to `/wiki-kanban-emit` with that spec's slug. The fresh `<spec-slug>:<new-adr-id>:<sha256>` triple — with the new ADR id — produces a **new task row** rather than updating the old one. The old row is closed with a `kanban_comment` pointing forward to the successor.
5. Run the zero-dangling-links acceptance gate on every page touched.
6. Update `wiki/index.md` and append to `wiki/log.md` recording the trigger, the model changes, the new ADR id, the superseded ADR id, and the re-emitted task ids.

**Use Refine sparingly** — most outcomes are documentary, not structural. But use it without hesitation when an ADR is invalidated; an unrecorded supersession is worse than an explicit one.

## 9. The full loop, recap

```
                 +-------------------------+
                 |  raw sources in raw/    |
                 +------------+------------+
                              |
                              v
                       /wiki-ingest
                              |
                              v
              +----- wiki concept graph -----+
              |                              |
              v                              v
        /wiki-query                  /wiki-strategy
                                            |
                                            v
                                vision + contexts + map
                                            |
                                            v
                                       /wiki-adr
                                            |
                                            v
                                  decisions/ accepted
                                            |
                                            v
                                       /wiki-spec
                                            |
                                            v
                              specs/<slug>.md with Gherkin
                                            |
                                            v
                                  /wiki-kanban-emit
                                            |
                                            v
                                  Hermes Kanban board
                                            |
                                  (workers run, off-screen)
                                            |
                                            v
                                /wiki-kanban-ingest
                                            |
                                  +---------+---------+
                                  |                   |
                              (documentary)     (structural)
                                  |                   |
                              evidence            /wiki-refine
                              appended                |
                                                      v
                                              new ADR + re-emit
```

`/wiki-lint` cuts across every box — run it whenever you want a health check on the graph.

## Common questions

**Do I have to use every step?** No. The pipeline degrades gracefully:

- Strategy without ADRs → fine, you just have no architectural pins.
- ADRs without specs → fine, ADRs stand alone as decision history.
- Specs without kanban → fine, the spec page is a perfectly usable executable specification by itself; `hermes` is unnecessary.
- Kanban without refinement → fine, every run is documentary by default.

**Can I run the steps out of order?** Mostly no. The dependencies are real:

- `/wiki-kanban-emit` reads a spec that must already exist.
- `/wiki-spec` softly gates on an `accepted` ADR (warns; lets you proceed).
- `/wiki-strategy` reads existing concept/entity pages — `/wiki-ingest` should happen first.
- `/wiki-refine` requires the prior ADR + spec + kanban row it is superseding.

**What if I do not have Hermes installed?** Everything except kanban-emit, kanban-ingest, and the kanban-aware lint checks works. Those three abort loudly with an install hint and never silently degrade.

**Where do the per-feature reference pages live?** [`docs/rd-pipeline/`](./rd-pipeline/). One file per slash command, with inputs / outputs / gates / failure modes spelled out.
