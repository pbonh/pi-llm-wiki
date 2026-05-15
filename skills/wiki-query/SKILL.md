---
name: wiki-query
description: Run the Query workflow against an llm-wiki — search the graph, synthesize an answer with [[wiki-link]] citations, optionally drop a synthesis page when the answer reveals novel cross-cutting insight. Use in any directory containing an AGENTS.md that follows the llm-wiki schema.
---

# wiki-query

Search the wiki and synthesize an answer with `[[wiki-link]]` citations. If the answer reveals novel cross-cutting insight, create a synthesis page in `wiki/syntheses/`.

The wiki schema and workflow details live in `AGENTS.md`. Read `### Query` and follow the steps there.

## Usage

```
/skill:wiki-query <question>
```

## Hard rules

- Cite specific pages with wiki links — every claim should be traceable.
- If the wiki can't support a confident answer, say so and suggest sources that would fill the gap. **Do not invent claims.**
- A synthesis page is appropriate only when the answer is genuinely cross-cutting (combines content from multiple pages into a new framing). Most queries don't need one.
