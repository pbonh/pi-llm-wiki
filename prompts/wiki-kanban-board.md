---
description: Bind a Hermes Kanban board to this wiki — write kanban/board.yaml and customize the Kanban Board section of AGENTS.md
argument-hint: "<slug> [--orchestrator <profile>] [--worker <profile>] [--reviewer <profile>] [--workspace-default dir:./project|worktree]"
---
Read `AGENTS.md` and follow the **Kanban Board** section to bind a Hermes Kanban board to this wiki. Replaces the placeholder `kanban/board.yaml` written by `/wiki-project-init` with a real, validated configuration.

**Preflight 1 (hard) — project_init satisfied.** Run `scripts/check-prereqs.sh board_bound --quiet --json` from the wiki root. (We deliberately query `board_bound`, not `project_init` — `check-prereqs.sh` validates an artifact's **requires** chain; `project_init` has empty requires and would falsely report OK even if its `produces` is unsatisfied. Querying `board_bound` makes the helper test whether `project_init`'s produces is satisfied.) Treat the response:

- `{"missing": "project_init", ...}` → abort: *"`project_init` not satisfied — run `/wiki-project-init` first."* Print the helper's `missing` + `hint` and stop.
- `{"missing": "board_bound", ...}` → `project_init` is satisfied; `board_bound` is what this command produces. Proceed.
- `{"ok": true}` → already bound (idempotent re-bind path; continue to step 1).
- Manifest absent → helper exits 0 silently; still confirm `kanban/board.yaml` exists on disk (the bundled template ships it via `/wiki-project-init` or `pi-llm-wiki-init`). If absent, abort with the `/wiki-project-init` hint.

**Preflight 2 (hard) — Hermes.** Invoke `hermes kanban assignees`. If `hermes` is not on `PATH` or the command fails, abort with: *"Hermes is not installed or no profiles are configured. See https://github.com/NousResearch/hermes. Binding a kanban board requires Hermes; the rest of this wiki works without it."*

**Preflight 3 (hard) — slug shape.** Auto-lowercase `$1`, then validate against `^[a-z0-9][a-z0-9_-]{0,63}$`. On mismatch, abort with the regex and the input. Reserved characters (slashes, dots, spaces, uppercase) are not negotiable — Hermes uses the slug as a board key and a path component.

Steps:

1. **Discover or create the board.** `hermes kanban boards list --json`. If `<slug>` is present, this is an idempotent re-bind — note the existing board id and proceed without creating. If absent, run `hermes kanban boards create $1` (no `--switch` — this wiki does not need to be the operator's active board). On `boards create` failure, surface stderr and abort.
2. **Resolve role assignments.** For each role (`orchestrator`, `worker`, `reviewer`):
   - If a `--<role>` flag was passed on the CLI, use it.
   - Else, if `kanban/board.yaml` already has a non-empty value for that role (re-bind case), use that.
   - Else, prompt the user. Show the discovered profile list from `hermes kanban assignees --json` as suggestions; the operator can pick one or type a profile name not yet listed (Hermes profiles are configurable).
3. **Verify each profile has the required skills.**
   - `orchestrator` → `kanban-orchestrator`
   - `worker` → `kanban-worker`
   - `reviewer` → `kanban-worker`
   For each, run `hermes -p <profile> skills list`. On missing skill, abort with: *"profile `<profile>` is missing required skill `<skill>`. Restore via `hermes -p <profile> skills reset <skill> --restore` and re-run."* Do not silently downgrade.
4. **Resolve `workspace_default`.** If `--workspace-default` was passed, use it. Else, if `board.yaml` has a non-empty existing value, keep it. Else, default to `dir:./project` (the convention) and confirm with the user. Accepted values: `dir:./project` or `worktree`. Anything else aborts.
5. **Write `kanban/board.yaml`.** Overwrite the file in place, preserving the leading comment block (the explanatory header about what edits this file). Drop the `<!-- CUSTOMIZE -->` marker line entirely. Populate `board:`, `workspace_default:`, `project_root: ./project`, `profiles.{orchestrator,worker,reviewer}` with the resolved values. Leave `patterns: {}` as-is.
6. **Rewrite the customization marker in `## Kanban Board` of `AGENTS.md`** with the chosen values (slug, workspace_default, profile-per-role). The block is gone after the rewrite.
7. **Verify the produces is satisfied.** Re-run `grep -c '<!--' kanban/board.yaml` — must return `0`. Then run `scripts/check-prereqs.sh kanban_emit --slug <any> --json` from the wiki root: it must NOT report `missing: board_bound` (it will report some other missing artifact like `spec`, which is fine — that proves `board_bound` is now seen as produced).
8. **Smoke-test the binding.** Run `hermes kanban --board $1 list` — must exit 0 (a board with zero tasks still lists cleanly). On non-zero, surface stderr and abort.
9. Append a dated entry to `wiki/log.md`: `kanban-board: bound <slug>, workspace_default=<...>, orchestrator=<...>, worker=<...>, reviewer=<...>`.

**Acceptance gates (hard):**
- `grep -c '<!--' kanban/board.yaml` returns `0`.
- The `## Kanban Board` section of `AGENTS.md` no longer contains a `<!--` block.
- `yq eval '.board' kanban/board.yaml` returns the slug; the three `profiles.*` keys are non-empty.
- `hermes kanban --board <slug> list` exits 0.

**Idempotency.** Re-running with the same slug and unchanged profiles is a no-op (re-writes the same bytes; the manifest gate stays green). Running with a different slug rewrites the binding and **warns** the user: *"previously emitted tasks live on the old board (`<old-slug>`). `/wiki-kanban-emit` will emit new tasks against `<new-slug>`; old tasks are not migrated. Run `/wiki-refine` if the rebinding invalidates prior work."*

**Failure modes:**
- `hermes` missing → preflight aborts with install hint.
- `<slug>` invalid → preflight aborts with the regex.
- `boards create` fails → abort with stderr (often "board already exists" — handled in step 1; or "permission denied").
- A profile is missing the required skill → abort with the `skills reset --restore` hint.
- The user cancels mid-prompt → leave `kanban/board.yaml` untouched, exit non-zero.
- `wiki/.pipeline.yaml` absent **and** `kanban/board.yaml` absent → abort with `/wiki-project-init` hint (the manifest can't gate, but the file must exist for `/wiki-kanban-emit` and `/wiki-kanban-ingest` to read).

After a clean run, hint: *"Board `<slug>` bound. `/wiki-kanban-emit` and `/wiki-kanban-ingest` will now use it (and the manifest gate `board_bound` is satisfied)."*
