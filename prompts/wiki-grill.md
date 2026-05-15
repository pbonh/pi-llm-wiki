---
description: Grill open design questions before specs — decision-tree, depth-first, one question per turn
argument-hint: "<topic>"
---
Read `AGENTS.md` and follow the **Grill** workflow to surface and resolve open design questions for: $@

Derive the topic slug from `$@` (kebab-case, the same slug used by `/wiki-strategy`).

Steps (from AGENTS.md):

1. **Preflight.** Run `scripts/check-prereqs.sh grill --slug <topic-slug>` from the wiki root. On exit 1, print the helper's `missing` + `hint` verbatim (e.g. `missing: strategy — run /wiki-strategy first`) and **abort without writing anything**. On exit 0, continue. If `wiki/.pipeline.yaml` is absent, the helper exits 0 and grill proceeds (back-compat).

2. **Context load.** Read `wiki/vision/<topic-slug>.md` in full. Read every `wiki/contexts/*.md` it cites and every `wiki/concepts/*.md` reachable via `[[wikilinks]]` from those. Do not invent context that is not on the page; if the vision page is too thin, say so and suggest `/wiki-strategy <topic>` to enrich it before grilling.

3. **Resume check.** If `wiki/grills/<topic-slug>.md` already exists, read it. The existing `## Decision Tree`, `## Q&A Log`, `## Decisions Made`, and `## Open Questions` are authoritative — do not rewrite past entries. The next `## Q&A Log` entry continues the global `Q<n>` numbering. If `## Status: in progress` is set, resume from the next unanswered question in the existing tree.

4. **Decision-tree elicitation (first run only).** Identify **3–7** top-level decisions that need making for this topic, grounded in the vision/contexts you just read. Print them as a numbered list under a candidate `## Decision Tree`. Then ask the user **which one to grill first**. Do not proceed until the user picks. Do not pre-write the grill file at this step.

5. **Depth-first interrogation.** For the chosen subtree, ask exactly **one question at a time**. Each question MUST include **2–4 concrete options** numbered, plus an `other` escape ("`5. other → free text`"). After each user answer, branch into follow-up sub-questions until the subtree is exhausted, then return to the next top-level decision the user selects. **One question per turn is a hard rule** — do not batch.

6. **Park open questions.** If the user replies "I don't know yet", "park this", "skip", or equivalent, copy the question verbatim into `## Open Questions` and move on. Parking never blocks; never re-ask a parked question in the same run.

7. **Output write.** Emit `wiki/grills/<topic-slug>.md` with frontmatter:

   ```yaml
   ---
   title: "Grill: <topic>"
   type: grill
   tags: [grill, design]
   sources: [<related strategy / context / concept slugs>]
   last_updated: <today, ISO 8601>
   ---
   ```

   Required sections, in this order:

   - `## Decision Tree` — numbered top-level decisions, with indented sub-questions surfaced during interrogation.
   - `## Q&A Log` — numbered `Q<n>` / `A<n>` pairs, exact wording preserved, oldest-first. Re-runs **append** to this log; never rewrite past entries.
   - `## Decisions Made` — one bullet per resolved decision, keyed by decision title: `**<title>** — <picked option>. <one-line rationale>.` Same title on re-run rewrites that bullet in place; new titles append.
   - `## Open Questions` — parked items, verbatim, append-only across runs.
   - `## Cross-Links` — backlinks to `[[wiki/vision/<topic-slug>]]` and cited contexts/concepts; forward placeholders for `[[wiki/architecture/<topic-slug>]]`, `[[wiki/decisions/...]]`, `[[wiki/specs/<topic-slug>]]` even if those pages do not yet exist (resolve them via the dangling-links gate by stubbing or removing).

8. **Cross-link back.** Append (or update in place) a `## Grill Notes` section to `wiki/vision/<topic-slug>.md` linking `[[wiki/grills/<topic-slug>]]`. Do not rewrite the rest of the vision page.

9. **Abandonment handling.** If the user ends the session mid-grill, leave `## Q&A Log` and `## Decisions Made` intact and append/update `## Status: in progress (resume with /wiki-grill <topic>)`. On a clean exit with no open subtree, set `## Status: done` (or omit the section).

10. **Zero-dangling-links acceptance gate.** Same rule as the rest of the wiki: every `[[...]]` reference must resolve. Stub (`confidence: low`) or remove.

11. **Index + log.** Update `wiki/index.md` (add a row under a `## Grills` table; create the table if absent; bump Statistics) and append a dated entry to `wiki/log.md`.

After a clean run, `scripts/check-prereqs.sh architecture --slug <topic-slug>` is expected to succeed — `/wiki-architecture <topic>` is the next step in the pipeline.

If the vision page is missing or too thin to ground decisions, say so and stop — do not invent decisions the wiki cannot support.
