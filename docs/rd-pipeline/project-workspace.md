# `/wiki-project-init`

Scaffold the implementation workspace (`project/`) and the kanban staging area (`kanban/`) inside a wiki, then walk the customization marker on `## Implementation Workspace` of `AGENTS.md`. Bootstrap-only — does **not** bind a Hermes board (that is [`/wiki-kanban-board`](./kanban-staging.md)).

The wiki documents *about* a project; `project/` *is* the project. Every changed-file path written back into a spec's `## Implementation Evidence` section by [`/wiki-kanban-ingest`](./kanban-ingest.md) must resolve under `project/`. [`/wiki-lint`](./lint.md) enforces this.

## Usage

```
/wiki-project-init [--language <name>]
```

`--language` is optional and only seeds the prompt — the marker walk asks for `language`, `build`, `test`, and `entry` regardless.

## Inputs

- A wiki bootstrapped via `/wiki-new` (or a manual `pi-llm-wiki-init` + edit). `AGENTS.md` must contain a `## Implementation Workspace` section.
- A bundled `template/project/` and `template/kanban/` (shipped with `pi-llm-wiki`).

## Outputs

- `project/` — `README.md` (with the customization marker filled in), `.gitignore` (with language-appropriate entries appended), `.gitkeep`.
- `kanban/` — `README.md`, `board.yaml` (placeholder; `/wiki-kanban-board` rewrites it), `profiles/README.md`, `handoffs/.gitkeep`, `.worktrees/.gitignore`, `logs/.gitignore`.
- `AGENTS.md` — `## Implementation Workspace` section with its `<!--` marker stripped and replaced with the chosen `language` / `build` / `test` / `entry`.
- `wiki/log.md` — dated entry recording the four chosen values.

## Gates

### Already-initialized check (soft)

The command tests whether `project_init` is already satisfied by inspecting its produces directly: `project/README.md` exists **and** contains no `<!--` markers. If so, print *"already initialized"* and stop. Otherwise proceed.

(Note: `scripts/check-prereqs.sh project_init` is **not** the right test here — the helper validates an artifact's `requires:` chain, and `project_init` has an empty `requires:`, so it always returns OK regardless of whether `project/README.md` exists or has unfilled markers. To test "is `project_init`'s produces satisfied," query a downstream artifact like `board_bound` and check whether the helper reports `missing: project_init` in its JSON output.)

### Hard preflight

`AGENTS.md` must exist and contain a `## Implementation Workspace` section. Missing → abort with: *"AGENTS.md has no Implementation Workspace section — re-run `/wiki-new` against the latest template, or restore the section from `template/AGENTS.md`."*

### Acceptance gates

- `grep -c '<!--' project/README.md` returns `0`.
- `## Implementation Workspace` in `AGENTS.md` no longer contains a `<!--` block (other markers are untouched).
- `kanban/` exists with the full subtree.
- `kanban/board.yaml` is **untouched** (still has its marker — that is `/wiki-kanban-board`'s job).

## Idempotency

Re-running on a satisfied `project_init` artifact reports "already initialized" and exits 0 without prompting. Re-running on a partially-scaffolded directory copies only missing files and re-walks the marker only if either marker is still present. Operator edits to copied files are never overwritten.

## Failure modes

- **Missing template files in the `pi-llm-wiki` install** — abort with the same packaging-bug message `pi-llm-wiki-init` prints.
- **`AGENTS.md` missing the `## Implementation Workspace` section** — abort with the re-run hint above.
- **User cancels mid-prompt** — leave both files untouched, exit non-zero.

## Where it sits in the pipeline

```
pi-llm-wiki-init  ─►  /wiki-new  ─►  /wiki-project-init  ─►  /wiki-kanban-board <slug>  ─►  ...rest of pipeline
                                            │                            │
                                            └─ satisfies project_init    └─ satisfies board_bound
                                                                            (which gates kanban-emit / ingest)
```

The two infrastructure artifacts (`project_init`, `board_bound`) sit in the [pipeline manifest](./pipeline-manifest.md) alongside the content artifacts. They are the manifest's only artifacts whose `produces` paths live outside `wiki/`.
