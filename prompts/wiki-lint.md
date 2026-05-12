---
description: Audit the wiki for orphans, contradictions, and missing links
---
Read `AGENTS.md` and run the **Lint** workflow on the entire wiki.

Steps (from AGENTS.md):
1. Read every page under `wiki/`.
2. Check for:
   - Orphan pages (no inbound links).
   - Stale claims or contradictions between pages.
   - Missing cross-links where a page mentions a concept that has its own page.
   - Incomplete required sections per page type.
   - Low-confidence pages that could be strengthened with existing sources.
3. Fix what can be fixed automatically (missing links, incomplete sections you can fill from existing sources).
4. Report issues that need human judgment — list them clearly so the user can decide.
5. Suggest new sources or topics worth investigating to fill known gaps.
6. Append a dated `lint` entry to `wiki/log.md` summarizing what was fixed and what remains.
