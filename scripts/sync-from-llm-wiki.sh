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

# Stash pi-llm-wiki-only directories (project/, kanban/) before wiping the
# template tree. They are not part of upstream llm-wiki and must survive any
# upstream sync. The post-sync assertion below catches accidental removal.
STASH="$(mktemp -d)"
trap 'rm -rf "$STASH"' EXIT
for dir in project kanban; do
  if [[ -d "$TEMPLATE/$dir" ]]; then
    cp -a "$TEMPLATE/$dir" "$STASH/"
  fi
done

rm -rf "$TEMPLATE"
mkdir -p "$TEMPLATE"
rsync -a \
  --exclude='.git' \
  --exclude='LICENSE' \
  --exclude='README.md' \
  --exclude='/project/' \
  --exclude='/kanban/' \
  "$LLM_WIKI"/ "$TEMPLATE"/

# Restore stashed pi-llm-wiki-only directories.
for dir in project kanban; do
  if [[ -d "$STASH/$dir" ]]; then
    cp -a "$STASH/$dir" "$TEMPLATE/"
  fi
done

# Safety assertion — these directories are pi-llm-wiki-only and must always exist.
if [[ ! -d "$TEMPLATE/project" || ! -d "$TEMPLATE/kanban" ]]; then
  echo "FATAL: sync removed template/project or template/kanban — investigate." >&2
  echo "These directories are pi-llm-wiki-only and the rsync should have skipped them." >&2
  exit 1
fi

echo "Done. Review the diff and bump pi-llm-wiki version before publishing:"
echo "  git diff template/"
