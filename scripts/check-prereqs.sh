#!/usr/bin/env bash
# scripts/check-prereqs.sh — verify an artifact's prerequisites in wiki/.pipeline.yaml.
#
# See docs/rd-pipeline/pipeline-manifest.md for the manifest schema and exit codes.

set -uo pipefail

usage() {
  cat <<'EOF'
Usage: check-prereqs.sh <artifact> [--slug <slug>] [--task-id <id>]
                       [--branch-head <sha>] [--json] [--quiet]

Exit codes:
  0  prereqs satisfied (or manifest absent, or enforcement=off, or enforcement=warn)
  1  missing prerequisite
  2  manifest malformed, missing dependency (yq), or invalid invocation
  3  git_check failed
EOF
}

ARTIFACT=""
SLUG=""
TASK_ID=""
BRANCH_HEAD=""
JSON=0
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug)         SLUG="${2:-}"; shift 2 ;;
    --task-id)      TASK_ID="${2:-}"; shift 2 ;;
    --branch-head)  BRANCH_HEAD="${2:-}"; shift 2 ;;
    --json)         JSON=1; shift ;;
    --quiet)        QUIET=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    --)             shift; break ;;
    -*)
      echo "check-prereqs: unknown flag: $1" >&2
      exit 2
      ;;
    *)
      if [[ -z "$ARTIFACT" ]]; then
        ARTIFACT="$1"
      else
        echo "check-prereqs: unexpected extra argument: $1" >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$ARTIFACT" ]]; then
  usage >&2
  exit 2
fi

MANIFEST="wiki/.pipeline.yaml"

# Back-compat: absence == no enforcement.
if [[ ! -f "$MANIFEST" ]]; then
  exit 0
fi

if ! command -v yq >/dev/null 2>&1; then
  echo "check-prereqs: 'yq' not found on PATH; install https://github.com/mikefarah/yq" >&2
  exit 2
fi

TMPERR="$(mktemp)"
trap 'rm -f "$TMPERR"' EXIT

if ! yq eval '.' "$MANIFEST" >/dev/null 2>"$TMPERR"; then
  echo "check-prereqs: $MANIFEST is invalid YAML" >&2
  cat "$TMPERR" >&2
  exit 2
fi

ENFORCEMENT="$(yq eval '.defaults.enforcement // "strict"' "$MANIFEST")"
TRUNK="$(yq eval '.defaults.trunk_branch // "main"' "$MANIFEST")"

if [[ "$ENFORCEMENT" == "off" ]]; then
  exit 0
fi

# Confirm requested artifact exists in manifest.
if [[ "$(yq eval ".artifacts | has(\"$ARTIFACT\")" "$MANIFEST")" != "true" ]]; then
  echo "check-prereqs: artifact '$ARTIFACT' not declared in $MANIFEST" >&2
  exit 2
fi

# Emit a structured failure and exit with the appropriate code.
emit_failure() {
  local missing="$1" hint="$2" exit_code="$3"
  if [[ $JSON -eq 1 ]]; then
    jq -cn --arg a "$ARTIFACT" --arg m "$missing" --arg h "$hint" \
      '{artifact:$a, missing:$m, hint:$h}'
  fi
  if [[ "$ENFORCEMENT" == "warn" ]]; then
    if [[ $QUIET -eq 0 && $JSON -eq 0 ]]; then
      echo "check-prereqs (warn): $ARTIFACT missing prereq '$missing' — $hint" >&2
    fi
    exit 0
  fi
  if [[ $QUIET -eq 0 && $JSON -eq 0 ]]; then
    echo "check-prereqs: $ARTIFACT missing prereq '$missing' — $hint" >&2
  fi
  exit "$exit_code"
}

# Resolve {slug} (and any remaining {placeholder}/NNNN segments) in a produces path.
# Unknown placeholders become glob wildcards.
resolve_path() {
  local path="$1"
  if [[ -n "$SLUG" ]]; then
    path="${path//\{slug\}/$SLUG}"
  fi
  path="${path//NNNN/*}"
  while [[ "$path" =~ \{[^}]+\} ]]; do
    path="${path//${BASH_REMATCH[0]}/*}"
  done
  printf '%s' "$path"
}

# Return 0 if an artifact's primary `produces` resolves to at least one real file
# (with no unfilled <!-- --> customization markers). Return 1 otherwise.
# Non-file produces values (e.g. kanban:// URIs) return 0 — file-based gating
# does not apply; downstream commands must add their own checks.
artifact_produced() {
  local art="$1"
  local produces
  produces="$(yq eval ".artifacts.\"$art\".produces // \"\"" "$MANIFEST")"
  [[ -z "$produces" || "$produces" == "null" ]] && return 1

  # Non-file producers: treat as satisfied; this script only gates on files.
  if [[ "$produces" == *"://"* ]]; then
    return 0
  fi

  # Section-fragment producer (file#section): require both the file and the heading.
  local section=""
  if [[ "$produces" == *"#"* ]]; then
    section="${produces#*#}"
    produces="${produces%%#*}"
  fi

  local resolved
  resolved="$(resolve_path "$produces")"

  local matches=()
  shopt -s nullglob
  # shellcheck disable=SC2206
  matches=( $resolved )
  shopt -u nullglob

  if (( ${#matches[@]} == 0 )); then
    return 1
  fi

  local f
  for f in "${matches[@]}"; do
    [[ -f "$f" ]] || continue
    if grep -q '<!--' "$f"; then
      continue
    fi
    if [[ -n "$section" ]]; then
      # Section names like "implementation-evidence" map to "## Implementation Evidence".
      local heading
      heading="$(echo "$section" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
      grep -qi "^## *${heading}\$" "$f" || continue
    fi
    return 0
  done
  return 1
}

# Run a named git_check from the manifest. Echoes nothing on success.
# On failure: emits structured error and exits 3 (or 0 under warn).
run_git_check() {
  local name="$1"
  local desc test_template
  desc="$(yq eval ".git_checks.\"$name\".description // \"$name\"" "$MANIFEST")"
  test_template="$(yq eval ".git_checks.\"$name\".test // \"\"" "$MANIFEST")"
  if [[ -z "$test_template" || "$test_template" == "null" ]]; then
    echo "check-prereqs: git_check '$name' not defined in $MANIFEST" >&2
    exit 2
  fi

  if ! command -v git >/dev/null 2>&1; then
    if [[ $QUIET -eq 0 ]]; then
      echo "check-prereqs: git required for trunk gating; install git or set enforcement: off" >&2
    fi
    if [[ "$ENFORCEMENT" == "warn" ]]; then
      return 0
    fi
    return 0
  fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    if [[ $QUIET -eq 0 ]]; then
      echo "check-prereqs: not in a git repo; skipping git_check '$name'" >&2
    fi
    return 0
  fi

  local rendered="$test_template"
  rendered="${rendered//\{\{trunk_branch\}\}/$TRUNK}"
  rendered="${rendered//\{\{spec_path\}\}/wiki/specs/${SLUG}.md}"
  rendered="${rendered//\{\{branch_head\}\}/${BRANCH_HEAD:-HEAD}}"

  if bash -c "$rendered" >/dev/null 2>"$TMPERR"; then
    return 0
  fi
  local err
  err="$(cat "$TMPERR" 2>/dev/null || true)"

  if [[ $JSON -eq 1 ]]; then
    jq -cn --arg a "$ARTIFACT" --arg c "$name" --arg cmd "$rendered" --arg e "$err" \
      '{artifact:$a, missing:$c, hint:("git_check failed: " + $cmd), stderr:$e}'
  fi
  if [[ "$ENFORCEMENT" == "warn" ]]; then
    if [[ $QUIET -eq 0 && $JSON -eq 0 ]]; then
      echo "check-prereqs (warn): git_check '$name' failed: $desc" >&2
    fi
    exit 0
  fi
  if [[ $QUIET -eq 0 && $JSON -eq 0 ]]; then
    echo "check-prereqs: git_check '$name' failed: $desc" >&2
    echo "  command: $rendered" >&2
  fi
  exit 3
}

# Walk the requires graph depth-first; first missing prereq short-circuits.
VISITED=""
check_artifact() {
  local art="$1"
  case ":$VISITED:" in
    *":$art:"*) return 0 ;;
  esac
  VISITED="$VISITED:$art"

  local requires_count
  requires_count="$(yq eval ".artifacts.\"$art\".requires | length" "$MANIFEST")"
  [[ "$requires_count" == "null" || -z "$requires_count" ]] && requires_count=0

  local i req
  for ((i=0; i<requires_count; i++)); do
    req="$(yq eval ".artifacts.\"$art\".requires[$i]" "$MANIFEST")"
    if [[ "$req" == git:* ]]; then
      run_git_check "${req#git:}"
      continue
    fi

    if [[ "$(yq eval ".artifacts | has(\"$req\")" "$MANIFEST")" != "true" ]]; then
      echo "check-prereqs: unknown required artifact '$req' for '$art'" >&2
      exit 2
    fi

    local optional
    optional="$(yq eval ".artifacts.\"$req\".optional_in_v1 // false" "$MANIFEST")"

    if artifact_produced "$req"; then
      check_artifact "$req"
      continue
    fi

    if [[ "$optional" == "true" ]]; then
      # Optional artifact not produced: skip without failing, but still walk
      # transitively to surface required upstreams (strategy etc.).
      check_artifact "$req"
      continue
    fi

    local cmd
    cmd="$(yq eval ".artifacts.\"$req\".command // \"\"" "$MANIFEST")"
    local hint
    if [[ -z "$cmd" || "$cmd" == "null" ]]; then
      hint="run /wiki-$req first"
    else
      hint="run $cmd first"
    fi
    emit_failure "$req" "$hint" 1
  done
}

check_artifact "$ARTIFACT"

if [[ $JSON -eq 1 ]]; then
  jq -cn --arg a "$ARTIFACT" '{artifact:$a, ok:true}'
fi
exit 0
