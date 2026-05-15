# Required Handoff schema (canonical)

Source of truth for the JSON shape every Hermes kanban worker must return in its task `metadata`. Both `/wiki-kanban-emit` (which inlines this section into every emitted task body) and `/wiki-kanban-ingest` (which validates it before round-tripping evidence into the wiki) reference this file.

## Inlined into each emitted task body

```markdown
## Required Handoff

Return your run's evidence as a JSON object on `metadata`. Every key below is required; ingest will refuse to round-trip a task whose handoff is missing any of them.

| Key | Type | Purpose |
|---|---|---|
| `changed_files` | `string[]` | Paths to every file your run created or modified. Empty list if none. |
| `verification` | `string[]` | The exact shell command(s) that prove the work is correct (tests, builds, lints). Multiple commands allowed; each is a single string. |
| `dependencies` | `string[]` | Task ids of prerequisite work this run depended on. Use `parents` ids when applicable. |
| `blocked_reason` | `string \| null` | One-sentence blocker description if you could not finish; `null` if you completed. |
| `retry_notes` | `string` | What you tried that did not work this attempt. Empty string on first-attempt success. |
| `residual_risk` | `string[]` | Untested edge cases, deferred work, or known soft spots. Empty list if none. |
| `branch_head` | `string` | Full commit sha of the branch tip where your changes live. **Load-bearing:** `/wiki-kanban-ingest` runs `git merge-base --is-ancestor` against trunk on this value and refuses to ingest until your branch is merged. |
| `wiki_spec` | `string` | Relative path to the originating spec page (e.g. `wiki/specs/foo.md`). |
| `wiki_adr_ids` | `string[]` | Every ADR id the spec depends on, four-digit strings (e.g. `["0042", "0051"]`). |

Forbidden in `metadata`: tokens, OAuth material, raw logs, unrelated transcripts. Copy pointers (file paths, commit hashes, urls), not secrets.

Example:

```json
{
  "changed_files": ["src/limiter/token_bucket.py", "tests/test_token_bucket.py"],
  "verification": ["pytest tests/test_token_bucket.py -q", "ruff check src/"],
  "dependencies": ["t_8a1c2"],
  "blocked_reason": null,
  "retry_notes": "first attempt missed the burst-refill clamp; second attempt added the clamp and tightened the assertion",
  "residual_risk": ["concurrent writes across processes untested"],
  "branch_head": "abc123def456789...",
  "wiki_spec": "wiki/specs/token-bucket-limiter.md",
  "wiki_adr_ids": ["0042"]
}
```
```

## Ingest validation contract

`/wiki-kanban-ingest` MUST:

1. Refuse to round-trip a run whose `metadata` is missing any of the keys above. Error message: `missing keys: [<list>]`.
2. Refuse to round-trip a run whose `branch_head` is not yet an ancestor of `origin/<trunk>` (enforced by `scripts/check-prereqs.sh kanban_ingest --branch-head <sha>`).
3. Refuse to copy any value that looks like a secret (regex hits on bearer-token / OAuth / cookie patterns) or any value over ~4KB that looks like a raw log.

## Why this is locked in

Without a stable handoff shape, every worker invents its own keys and ingest becomes a guessing game. Locking in the schema:

- Makes ingest a syntactic check, not a semantic one.
- Lets `/wiki-refine` reason about `changed_files` and `wiki_adr_ids` without re-parsing free-form prose.
- Feeds Phase 4's `worker-branch-merged` git-check via `branch_head`.
- Makes attempt history (Phase 5d) safe to walk — `retry_notes` and `blocked_reason` always exist.
