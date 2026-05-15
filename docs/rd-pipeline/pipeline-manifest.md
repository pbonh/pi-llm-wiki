# Pipeline manifest (`wiki/.pipeline.yaml`)

The pipeline manifest is the **single source of truth** for which artifacts make up the R&D pipeline and which prerequisites each phase requires. Slash commands query the manifest via `scripts/check-prereqs.sh` before doing any work; adding a new artifact to the pipeline is one edit to this file, not a refactor of every prompt.

If you have not read the [R&D pipeline reference](./README.md) or the [tutorial](../tutorial-rd-pipeline.md) yet, start with one of those. This page covers the manifest schema and the precondition helper script in detail.

## Where it lives

```
wiki/.pipeline.yaml
```

One manifest per wiki. The default copy ships in `template/wiki/.pipeline.yaml` and lands in your wiki when you run `/wiki-new` (or `pi-llm-wiki-init`).

**Absence is allowed.** If `wiki/.pipeline.yaml` does not exist, the precondition helper exits 0 and the slash commands run as if there were no enforcement. Existing wikis from before Phase 0 continue to work unchanged.

## Schema

```yaml
version: 1

defaults:
  trunk_branch: main           # branch the kanban round-trip gates on
  enforcement: strict          # strict | warn | off

artifacts:
  <name>:
    produces: <path-or-uri>    # file path with {slug}/NNNN placeholders, OR
                               # a non-file URI (kanban://...), OR
                               # a fragment (file#section)
    also_produces:             # optional — additional outputs, informational only
      - <path-or-glob>
    requires: [<name|git:check-name>, ...]
    command: /wiki-<slash>     # surfaced in error hints
    optional_in_v1: false      # true means "not-produced is not a failure"
    cardinality: one           # informational: one | many

git_checks:
  <check-name>:
    description: <one-line>
    test: |
      <shell snippet that exits 0 on success>
```

### `defaults.enforcement`

| Value | Effect |
|---|---|
| `strict` | Missing prereqs exit non-zero. Default. |
| `warn` | Missing prereqs print to stderr but exit 0. Use during migration. |
| `off` | Helper exits 0 immediately, no checks run. |

### `artifacts.<name>.produces`

A path with placeholders. Supported substitutions:

| Placeholder | Meaning |
|---|---|
| `{slug}` | Replaced with `--slug` arg if given; otherwise expands to `*` (glob). |
| `NNNN` | Numeric sequence in ADR filenames; always expands to `*`. |
| `{anything-else}` | Unknown placeholders expand to `*`. |

Three forms are recognised:

1. **Plain file path** (e.g. `wiki/vision/{slug}.md`) — the file must exist and must not contain unfilled `<!-- ... -->` customization markers.
2. **Section fragment** (e.g. `wiki/specs/{slug}.md#implementation-evidence`) — the file must exist and contain a heading matching the section name (kebab-case converted to title case, prefixed with `## `).
3. **URI** (e.g. `kanban://{board}/{tenant}/{slug}`) — out of scope for the file-based helper; treated as satisfied. Downstream commands (e.g. `/wiki-kanban-emit`) must add their own checks.

### `artifacts.<name>.requires`

A list of either:

- **Artifact names** (e.g. `adr`) — the named artifact's `produces` must resolve to a real output.
- **Git check references** (e.g. `git:spec-on-trunk`) — the named entry under `git_checks` must run and exit 0.

The helper walks `requires` depth-first. The first missing prerequisite short-circuits.

### `artifacts.<name>.optional_in_v1`

When `true`, the artifact is treated as "satisfied even when not produced" during the v1 rollout. Used today for `grill` and `architecture`, which are recommended but not yet required between `strategy` and `adr`. Tighten to `false` (or remove the key) in v2.

### `git_checks.<name>.test`

A bash snippet. The helper substitutes these placeholders before running:

| Placeholder | Source |
|---|---|
| `{{trunk_branch}}` | `defaults.trunk_branch` |
| `{{spec_path}}` | `wiki/specs/<slug>.md` (from `--slug`) |
| `{{branch_head}}` | `--branch-head <sha>`, or `HEAD` if not given |

The snippet runs under `bash -c`. Exit 0 = pass, anything else = fail.

## The helper: `scripts/check-prereqs.sh`

```
Usage: check-prereqs.sh <artifact> [--slug <slug>] [--task-id <id>]
                       [--branch-head <sha>] [--json] [--quiet]
```

### Exit codes

| Code | Meaning |
|---|---|
| `0` | All prereqs satisfied. Also returned when the manifest is absent, when `enforcement: off`, or when `enforcement: warn` downgrades a failure. |
| `1` | Missing file-based prerequisite. The failing artifact name is reported. |
| `2` | Manifest malformed, missing dependency (yq), or invalid invocation (unknown artifact, unknown flag). |
| `3` | A `git_check` failed (e.g. spec not yet on trunk). |

### Output

By default the helper writes a single-line human-readable diagnostic to stderr on failure. With `--json`, it writes a single JSON object to stdout:

```json
{"artifact":"spec","missing":"adr","hint":"run /wiki-adr first"}
```

For `git_check` failures, the JSON includes the rendered command and any captured stderr:

```json
{"artifact":"kanban_emit","missing":"spec-on-trunk","hint":"git_check failed: git fetch ...","stderr":"..."}
```

### Idempotency and safety

The helper is **read-only**. It never mutates wiki content, branches, or remotes (a `git_check` may `git fetch`, which is a remote read but does not alter local refs). Re-running it is always safe and produces the same result for the same wiki state.

### Failure modes

- **Manifest invalid YAML** — exit 2, the underlying yq diagnostic is printed.
- **`git` not on PATH** — `git_check`s log a hint and pass (the slash command degrades to "trust on faith" rather than blocking work).
- **Not in a git repo** — `git_check`s log a hint and pass.
- **Glob pattern matches zero files** — treated as "not produced" → missing prereq.
- **All matching files contain unfilled `<!--` markers** — treated as "not produced" (the template was copied but not customized).

## Authoring a new artifact

1. Add an entry under `artifacts:` with a unique key, a `produces` path, the upstream `requires`, and the `command` users should run.
2. Add the slash command's prompt under `prompts/`, prepending a call to `scripts/check-prereqs.sh <new-artifact>`.
3. Update `docs/rd-pipeline/README.md` if the new artifact changes the pipeline at-a-glance picture.

That's it. The slash commands query the manifest dynamically — no other files reference the artifact list directly.

## Authoring a new `git_check`

1. Add an entry under `git_checks:` with a `description` and a `test` shell snippet that exits 0 on success.
2. Use `{{trunk_branch}}`, `{{spec_path}}`, or `{{branch_head}}` placeholders where you need run-time substitution.
3. Reference the check from an artifact's `requires` as `git:<check-name>`.

## Migration

- **From a pre-Phase-0 wiki:** copy `template/wiki/.pipeline.yaml` into your wiki, optionally set `defaults.enforcement: warn` to see what the helper would have caught without yet blocking work, and flip to `strict` once the warnings clear.
- **Disabling for one command:** invoke the slash command with `--no-prereqs` if the prompt supports it, or set `enforcement: off` in the manifest. There is no per-artifact override yet; that is on the v2 list.
