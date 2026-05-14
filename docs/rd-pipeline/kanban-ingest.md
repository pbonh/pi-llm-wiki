# `/wiki-kanban-ingest`

Round-trip a completed [Hermes Kanban](https://github.com/NousResearch/hermes) run back into the originating wiki page as an `## Implementation Evidence` section. This is the *documentary* half of the refinement loop — the *structural* half (new ADRs, re-emission) is [`/wiki-refine`](./refine.md).

**Requires `hermes` on `PATH`.** Same preflight as `/wiki-kanban-emit`.

## Usage

```
/wiki-kanban-ingest <task-id-or-run-id>
```

`<task-id-or-run-id>` is a Hermes task id or run id whose status is `done` or `failed`. Both are ingested — see [Failed runs](#failed-runs) below.

## Workflow

1. **Fetch the completed run.** `hermes kanban show <id>` (or the equivalent db-layer call). Capture:
   - `summary`
   - `verification` (commands + their results)
   - `changed_files` (paths, ideally with repo URLs)
   - `residual_risk`
   - The structured-handoff payload
2. **Sanitize metadata.** The structured-handoff contract forbids tokens, OAuth material, raw logs, and unrelated transcripts.
   - Copy summaries and pointers (file paths, commit hashes, run ids, URLs).
   - **Refuse to copy secrets or raw logs even if they appear in the payload.**
   - If the metadata is dirty, surface the issue to the user and stop. **Do not silently scrub-and-copy.**
3. **Locate the originating wiki page** from the task body's `@wiki-spec` tag or the wiki backlink. Normally `wiki/specs/<spec-slug>.md`; for refinement-driven re-runs it may be a concept page.
4. **Append `## Implementation Evidence`** to the target page with:
   - Run id
   - Completion timestamp
   - Assignee profile
   - `verification` command(s) + their result
   - `changed_files` (linked to the repo when possible)
   - `residual_risk`
   - One-paragraph summary derived from the structured handoff
5. **On re-ingest, append a new dated subheading rather than overwriting.** Evidence accumulates honestly.
6. Update frontmatter `updated` on the target page and any `## Sources` row that points at the spec or concept.
7. **Zero-dangling-links acceptance gate** on the updated page.
8. Update `wiki/index.md` if any new pages were referenced (rare). Append a dated entry to `wiki/log.md` recording the run id, target page, verification outcome, and any residual risk.

## Failed runs

Failed runs are **still ingested**. The section is appended with `Result: failed` and the failure reason quoted from the handoff. Documenting failures honestly is the whole point — the next attempt has the prior failure's context.

## What `## Implementation Evidence` looks like

```markdown
## Implementation Evidence

### 2026-05-14 — run hermes/run/abc123 (implementer: cody-impl-01)

**Verification.** `cargo test --workspace -p shipping-rate-api`
exited 0 (148/148 passing).

**Changed files.**
- [`crates/rating/src/cheapest.rs`](https://github.com/org/repo/blob/<sha>/crates/rating/src/cheapest.rs)
- [`crates/rating/tests/cheapest_quote.rs`](https://github.com/org/repo/blob/<sha>/crates/rating/tests/cheapest_quote.rs)

**Residual risk.** Cache fallback was implemented for FedEx and UPS but
not for USPS — the upstream client does not yet support a hint header.
Tracked separately in spec [[specs/usps-cache-fallback]].

**Summary.** The cheapest-quote endpoint now returns the minimum of
all three carrier quotes within a 600ms budget, falling back to the
last hourly cached quote on carrier timeout. Verification scenarios
match the spec's Gherkin block exactly.
```

## What this section is *not*

- **Not a synthesis page.** It is a section appended to the originating spec / concept page.
- **Not a substitute for the structured handoff.** The handoff is the canonical record on the Hermes side; this section is the wiki-side index that points at it.
- **Not auto-discovered by re-emission.** `/wiki-kanban-emit` does not read `## Implementation Evidence` when computing the idempotency triple. The triple is over the spec *body*, deliberately — so evidence accumulation does not trigger re-emission.

## Refusal modes

- **Dirty metadata.** If the structured-handoff payload contains tokens, raw logs, or unrelated transcripts, the workflow stops and asks the user to resolve. The agent **will not** scrub silently — the user must see what was in the payload and decide.
- **Hermes missing.** Hard abort with the same install hint as `/wiki-kanban-emit`.
- **Task is not yet `done`.** If the run is still in progress, the ingest stops without writing anything. Wait or check the board.

## When to use this vs. `/wiki-refine`

Default to `/wiki-kanban-ingest`. It documents what happened.

Hand off to `/wiki-refine` when the run outcome surfaces something *structural*:

- An architectural commitment was invalidated (the cited ADR is wrong).
- A new false cognate emerged.
- A bounded-context boundary moved.
- A new concept needs its own page.

`/wiki-refine` classifies the trigger and falls back to `/wiki-kanban-ingest` if the change is documentary-only. So when in doubt, run Refine — it will ingest and stop if there is nothing structural to do.

## Failure modes to watch for

- **Silent overwrite of prior evidence.** Re-ingesting the same run id should append a new dated subheading, not replace the prior section. If you see prior evidence disappear, the workflow has a bug — file an issue.
- **Stale `updated` timestamp.** The frontmatter `updated` field on the target page should move on every ingest. If it does not, downstream `/wiki-lint` heuristics will misread the page as stale.
- **Missing `@wiki-spec` tag on the task.** If the kanban task body has no traceability tag and no wiki backlink, the agent cannot locate the originating page. Resolve by editing the task body to add a backlink, then re-run ingest. (Future emit runs should include the tag by default per the `/wiki-kanban-emit` contract.)
