# `/wiki-kanban-board`

Bind a [Hermes Kanban](https://github.com/NousResearch/hermes) board to this wiki — write `kanban/board.yaml` with the board slug, the profile-to-role mapping (orchestrator / worker / reviewer), and the default workspace shape. Replaces the placeholder shipped by `pi-llm-wiki-init` (or written by [`/wiki-project-init`](./project-workspace.md)). Satisfies the manifest artifact `board_bound`, which gates [`/wiki-kanban-emit`](./kanban-emit.md) and [`/wiki-kanban-ingest`](./kanban-ingest.md).

**Requires `hermes` on `PATH`.** Preflights `hermes kanban assignees` and aborts with an install hint if missing.

## Usage

```
/wiki-kanban-board <slug>
                   [--orchestrator <profile>]
                   [--worker <profile>]
                   [--reviewer <profile>]
                   [--workspace-default dir:./project|worktree]
```

`<slug>` matches `^[a-z0-9][a-z0-9_-]{0,63}$`. Uppercase input is auto-lowercased before validation.

## Inputs

- `kanban/board.yaml` placeholder file — created by `/wiki-project-init` or `pi-llm-wiki-init`.
- `AGENTS.md` with a `## Kanban Board` section (still bearing its `<!--` marker).
- A working Hermes installation with at least one configured profile.

## Outputs

- `kanban/board.yaml` — non-empty `board:`, `workspace_default:`, `project_root:`, `profiles.{orchestrator,worker,reviewer}`. The `<!--` marker is gone.
- `AGENTS.md` — `## Kanban Board` section with the chosen values inlined; `<!--` block stripped.
- A Hermes board (created if absent; idempotent re-bind if present).
- `wiki/log.md` — dated entry recording the slug, workspace_default, and three profile assignments.

## Gates

### Preflight 1 (hard) — `project_init` satisfied

`scripts/check-prereqs.sh project_init --quiet --json` must exit 0. Otherwise abort with the helper's hint pointing at `/wiki-project-init`.

### Preflight 2 (hard) — Hermes

`hermes kanban assignees` must succeed. Otherwise abort with the install hint pointing at https://github.com/NousResearch/hermes.

### Preflight 3 (hard) — slug shape

`<slug>` must match `^[a-z0-9][a-z0-9_-]{0,63}$`. Reserved characters (slashes, dots, spaces, uppercase) are not negotiable — Hermes uses the slug as a board key and a path component.

### Per-profile skill verification

For each declared profile, `hermes -p <profile> skills list` must include:

| Role | Required skill |
|---|---|
| orchestrator | `kanban-orchestrator` |
| worker | `kanban-worker` |
| reviewer | `kanban-worker` |

Missing → abort with: *"profile `<profile>` is missing required skill `<skill>`. Restore via `hermes -p <profile> skills reset <skill> --restore` and re-run."*

### Acceptance gates

- `grep -c '<!--' kanban/board.yaml` returns `0`.
- `## Kanban Board` in `AGENTS.md` no longer contains a `<!--` block.
- `yq eval '.board' kanban/board.yaml` returns the slug; `profiles.*` are non-empty.
- `hermes kanban --board <slug> list` exits 0.

## `kanban/board.yaml` schema

| Key | Purpose |
|---|---|
| `board` | Slug passed to every `hermes kanban --board <slug>` invocation. Created via `hermes kanban boards create`; reused on re-bind. |
| `workspace_default` | Shape passed via `--workspace` to every `kanban_create`. Either `dir:./project` (resolved to absolute via `realpath` at emit time — Hermes rejects relative `dir:` paths) or `worktree` (workers are expected to root worktrees under `kanban/.worktrees/<id>/`). |
| `project_root` | Where evidence paths must resolve. Hard-coded to `./project`; the `## Implementation Evidence` lint check (see [`/wiki-lint`](./lint.md)) uses this. |
| `profiles.orchestrator` | Hermes profile that runs `kanban_create` fan-outs. Required skill: `kanban-orchestrator`. |
| `profiles.worker` | Hermes profile that implements one task per spawn. Required skill: `kanban-worker`. P1 fan-out and P2 pipeline implementation steps run as this profile. |
| `profiles.reviewer` | Hermes profile that reviews and aggregates. Required skill: `kanban-worker` (plus any code-review skills). P3 quorum aggregator and P2 pipeline review step run as this profile. |
| `patterns` | Optional override map: collaboration pattern → profile-set. Empty `{}` means use the default mapping above based on ADR status. |

## Idempotency

- Same slug + unchanged profiles → no-op (re-writes identical bytes; manifest gate stays green).
- Different slug → rewrites the binding and warns: *"previously emitted tasks live on the old board (`<old-slug>`). `/wiki-kanban-emit` will emit new tasks against `<new-slug>`; old tasks are not migrated. Run `/wiki-refine` if the rebinding invalidates prior work."*
- Existing board (slug already present in `hermes kanban boards list`) → reuses without `boards create`.

## Failure modes

- **`hermes` missing** → preflight aborts with install hint.
- **`<slug>` invalid** → preflight aborts with the regex.
- **`hermes kanban boards create` fails** → abort with stderr (often "board already exists" — handled by the idempotent re-bind path; or "permission denied").
- **A profile is missing the required skill** → abort with the `skills reset --restore` hint.
- **User cancels mid-prompt** → `kanban/board.yaml` is left untouched, exit non-zero.

## `kanban/` directory layout

```
kanban/
├── README.md
├── board.yaml              ← bound by /wiki-kanban-board
├── profiles/
│   └── README.md
├── handoffs/               ← per-attempt JSON written by /wiki-kanban-ingest
│   └── .gitkeep
├── .worktrees/             ← gitignored; root for --workspace worktree runs
│   └── .gitignore
└── logs/                   ← gitignored; operator-stashed run logs
    └── .gitignore
```

The `handoffs/` directory accumulates `<task-id>.<run-id>.json` files — one per attempt — written by `/wiki-kanban-ingest`. These mirror the `### Attempt N` subsections on the spec page's `## Implementation Evidence` and feed `/wiki-refine` and the `handoff completeness` check in `/wiki-lint`.
