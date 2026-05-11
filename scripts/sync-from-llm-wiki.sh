#!/usr/bin/env bash
# Re-sync template/ from a local clone of github.com/pbonh/llm-wiki.
# Run this when the upstream schema changes, before bumping pi-llm-wiki's version.
#
# Usage: scripts/sync-from-llm-wiki.sh [path-to-llm-wiki-clone]
#        Default path: ../llm-wiki

set -euo pipefail

LLM_WIKI="${1:-../llm-wiki}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$HERE/template"

if [[ ! -f "$LLM_WIKI/AGENTS.md" ]]; then
  echo "error: $LLM_WIKI does not look like an llm-wiki clone (no AGENTS.md)" >&2
  echo "usage: $0 [path-to-llm-wiki-clone]" >&2
  exit 1
fi

echo "Syncing template/ from $LLM_WIKI"
rm -rf "$TEMPLATE"
mkdir -p "$TEMPLATE"
rsync -a --exclude='.git' --exclude='LICENSE' --exclude='README.md' "$LLM_WIKI"/ "$TEMPLATE"/

echo "Done. Review the diff and bump pi-llm-wiki version before publishing:"
echo "  git diff template/"
