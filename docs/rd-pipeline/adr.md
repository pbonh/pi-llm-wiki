# `/wiki-adr`

Open a new [Architectural Decision Record](https://github.com/joelparkerhenderson/architecture-decision-record). Pins an architectural commitment with its rationale, before the commitment is encoded in code. Carries forward across personnel turnover and survives breakthroughs via the [decision log](https://martinfowler.com/articles/decision-records.html) discipline: write-once, supersede-don't-edit.

## Usage

```
/wiki-adr <decision title>
```

`<decision title>` is a short title for the decision, kebab-friendly (e.g. *"Use the wiki page slug as the cross-system identifier"*).

## What it writes

`wiki/decisions/NNNN-<kebab-title>.md` where `NNNN` is the next monotonic four-digit number (never reused, not even for deleted drafts).

Frontmatter: `type: decision`, tags including `decision` plus a domain tag.

### Templates

- **Nygard** (default) — five sections: `## Status`, `## Context`, `## Decision`, `## Consequences`, `## Related Decisions`.
- **MADR** — when the user mentions multiple realistic alternatives whose trade-off analysis deserves preservation. Adds `## Decision Drivers` and `## Considered Options`.
- **Y-Statement** — one-liner. *"In the context of `<X>`, facing `<Y>`, we decided for `<Z>` to achieve `<Q>`, accepting `<W>`."* Can stand alone or sit at the top of a Nygard ADR as an executive summary.

### `## Status` is load-bearing

One of `proposed | accepted | deprecated | superseded by NNNN`. Downstream workflows gate on this:

- `/wiki-spec` warns when no `accepted` ADR governs the spec's domain.
- `/wiki-kanban-emit` picks the [collaboration pattern](#downstream-collaboration-pattern-mapping) based on cited ADRs' status.
- `/wiki-lint` fails if a `superseded` ADR's successor link is missing or stale.

### `## Context` must cite a triggering ASR

The ASR — [architecturally-significant requirement](https://en.wikipedia.org/wiki/Architecturally_significant_requirements) — is the structural or quality-attribute requirement whose effect on the system makes this decision load-bearing. Without one, the ADR is decoration and contributes to the AKM log-bloat failure mode (write-only knowledge repositories that nobody reads).

## Workflow

1. Scan `wiki/decisions/NNNN-*.md` for the highest used number; pick the next one. Monotonic, never reused.
2. **Ask the user to name the triggering ASR.** Refuse to proceed if none can be named. The ASR goes in `## Context`.
3. Pick a template — Nygard by default, MADR or Y-Statement on signal.
4. Write the ADR with `## Status: proposed`, ASR citation in `## Context`, and required sections. Tags include `decision`.
5. **Cross-link** every wiki page the decision governs. Update those pages' `## Related Concepts` / `## Related Decisions` sections to link back.
6. **Refuse to edit an `accepted` ADR.** If the user is trying to change a decision that is already accepted, open a new ADR that supersedes the old one instead — see [Supersession](#supersession) below.
7. Run the zero-dangling-links acceptance gate.
8. Update `wiki/index.md` Decisions table and Statistics counts; append a dated entry to `wiki/log.md`.

## Refusal modes

- **No ASR named.** The agent refuses to write the ADR. This is the hard gate. ADRs without ASRs are decoration; do not promote them.
- **Editing an `accepted` ADR.** The agent refuses. The path forward is supersession.
- **Renumbering, deleting, or reusing an ADR number.** The agent refuses. Numbers are monotonic and permanent.

## Lifecycle

```
   /wiki-adr opens
        |
        v
   ## Status: proposed
        |
   user accepts <-- edit the body freely up to here; after acceptance, body is write-once
        |
        v
   ## Status: accepted
        |
        +--> normal end-of-life --> deprecated
        |
        +--> invalidated --> /wiki-refine opens a successor --> superseded by NNNN
```

You move `proposed → accepted` by editing the `## Status` line yourself when the decision is committed. Once accepted, the body does not change.

## Supersession

When an `accepted` ADR is invalidated (typically surfaced by `/wiki-refine` after a kanban run), open a new ADR:

```
/wiki-adr <new title>
```

The new ADR cites the predecessor in `## Related Decisions`. With your permission, the agent flips the predecessor's `## Status: accepted` to `## Status: superseded by NNNN` and links the successor. **The predecessor's body stays intact** — supersede, never edit. The decision history is preserved.

## Downstream collaboration-pattern mapping

`/wiki-kanban-emit` reads cited ADRs' `## Status` and picks a collaboration pattern:

| ADR status | Collaboration pattern |
|---|---|
| `accepted` | P2 pipeline (`implementer → reviewer → integrator`) |
| `proposed` | P5 human-in-the-loop (adds a final human-gate task) |
| `deprecated` or `superseded` without a successor in `accepted` state | **refuse to emit** |

Multiple independent feature files on the spec → wrap whichever pattern is chosen in a P1 fan-out parent. Reviewer agreement matters more than throughput → P3 voting/quorum (two reviewers + aggregator).

## Discipline rules

- **Write-once.** Once `## Status` is `accepted`, the body does not get edited — fix the wording before acceptance.
- **Numbered, never deleted.** Superseded and deprecated ADRs stay in `wiki/decisions/`; the log is the history.
- **One decision per ADR.** Do not bundle multiple commitments. Bundling defeats supersession (you cannot supersede half a decision).
- **ASR-first.** No ASR, no ADR. Decoration ADRs become noise.
