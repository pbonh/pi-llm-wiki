---
description: Scaffold the implementation workspace (project/) and kanban staging area (kanban/), then customize the Implementation Workspace section of AGENTS.md
argument-hint: "[--language <name>]"
---
Read `AGENTS.md` and follow the **Implementation Workspace** + **Kanban Board** sections to scaffold `project/` and `kanban/` for this wiki, then walk the customization marker on `## Implementation Workspace`.

This command is bootstrap-only — it does not bind a Hermes board (that is `/wiki-kanban-board <slug>`).

**Already-initialized check (soft).** Test whether the artifact `project_init` is already satisfied by inspecting its `produces`: if `project/README.md` exists **and** `grep -c '<!--' project/README.md` returns `0`, the marker is already filled in — print *"already initialized — `project/` and `kanban/` are scaffolded and `## Implementation Workspace` has no unfilled customization marker. Run `/wiki-kanban-board <slug>` next."* and stop. (Note: `scripts/check-prereqs.sh project_init` checks `project_init`'s **requires** chain, which is empty — it returns OK regardless of whether the produces is satisfied. The grep above is the right check for self-state.)

**Preflight (hard) — AGENTS.md sanity.** Confirm `AGENTS.md` exists and contains a `## Implementation Workspace` section. If missing, abort: *"AGENTS.md has no Implementation Workspace section — re-run `/wiki-new` against the latest template, or restore the section from `template/AGENTS.md`."* Do **not** create the section yourself; that path is a recipe for schema drift.

Steps:

1. **Copy missing template files.** For each path under `project/` and `kanban/` that the bundled template ships (`project/README.md`, `project/.gitignore`, `project/.gitkeep`, `kanban/README.md`, `kanban/board.yaml`, `kanban/profiles/README.md`, `kanban/handoffs/.gitkeep`, `kanban/.worktrees/.gitignore`, `kanban/logs/.gitignore`): if the destination file does **not** exist, copy it from the bundled `template/` (resolve via the `pi-llm-wiki` install root the way `pi-llm-wiki-init` does); if it already exists, skip and report `kept`. Never overwrite — operator edits win.
2. **Walk the customization marker** in `project/README.md` (the `<!-- CUSTOMIZE ... -->` block immediately under the title). Prompt the user one field at a time:
   - `language` — primary language(s). Accept either a single name (`rust`, `python`, `typescript`, `go`) or a comma-separated list.
   - `build` — single shell command Hermes workers will run to build (`cargo build`, `npm run build`, `uv run python -m project`, `go build ./...`, …).
   - `test` — single shell command `/wiki-lint` and Hermes workers will run to verify (`cargo test`, `pytest -q`, `npm test`, `go test ./...`, …).
   - `entry` — path to main / start command (`src/main.rs`, `python -m project`, `npm run start`, `cmd/server/main.go`, …).
   Confirm the four values back to the user before writing. On cancel, leave both files untouched and exit non-zero.
3. **Rewrite the marker in `project/README.md`** with the chosen values inline (replace the entire `<!-- ... -->` block with a one-paragraph description that names language, build, test, and entry). The block is gone after the rewrite.
4. **Rewrite the matching marker in `## Implementation Workspace` of `AGENTS.md`** coherently — same four values, same wording style. The two files agree by construction. The block is gone after the rewrite.
5. **Append language-appropriate ignores to `project/.gitignore`** via a small lookup table keyed on the declared `language`:
   - `rust` → `Cargo.lock` (only if user opts in for libraries; default keep), `target/` (already present)
   - `python` → `*.egg-info/`, `.pytest_cache/`, `.mypy_cache/`, `.ruff_cache/`
   - `typescript` / `javascript` → `*.tsbuildinfo`, `.next/`, `coverage/`
   - `go` → `vendor/` (opt-in), `*.test`, `*.out`
   Unknown languages get no extra lines. Append only — never replace the base ignores.
6. **Verify the produces is satisfied.** Re-run `grep -c '<!--' project/README.md` — must return `0`. Then run `scripts/check-prereqs.sh board_bound --json` from the wiki root: it must report `missing: board_bound` (NOT `missing: project_init`) — that's the proof that downstream gates now see `project_init` as produced. (`board_bound` itself is unsatisfied because we have not bound a board yet; that's `/wiki-kanban-board`'s job.)
7. Append a dated entry to `wiki/log.md`: `project-init: scaffolded project/ and kanban/, language=<...>, build=<...>, test=<...>, entry=<...>`.

**Acceptance gates (hard):**
- `grep -c '<!--' project/README.md` returns `0`.
- The `## Implementation Workspace` section of `AGENTS.md` no longer contains a `<!--` block (other AGENTS.md customization markers are untouched).
- `kanban/` exists with the full subtree (`README.md`, `board.yaml`, `profiles/README.md`, `handoffs/.gitkeep`, `.worktrees/.gitignore`, `logs/.gitignore`).
- `kanban/board.yaml` is **untouched** (still has its `<!--` marker — that is `/wiki-kanban-board`'s job).

**Idempotency.** Re-running on a satisfied `project_init` artifact prints "already initialized" and exits 0 without prompting. Re-running on a partially-scaffolded directory copies only the missing files and re-runs the marker walk only if either marker is still present.

**Failure modes:**
- Missing template files in the `pi-llm-wiki` install — abort with the same packaging-bug message `pi-llm-wiki-init` prints.
- `AGENTS.md` missing or has no `## Implementation Workspace` section — abort with the message above.
- User cancels the marker walk — leave both files untouched, exit non-zero.

After a clean run, hint: *"Project workspace ready. Run `/wiki-kanban-board <slug>` to bind a Hermes board (the manifest gate `board_bound` requires it before `/wiki-kanban-emit` will run)."*
