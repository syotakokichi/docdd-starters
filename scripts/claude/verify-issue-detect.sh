#!/usr/bin/env bash
# scripts/claude/verify-issue-detect.sh
#
# Change-aware verification detector. Maps changed paths to required
# evidence categories used by `/verify` and `make verify-issue` (5-2 / 5-3).
#
# 真の SSOT: .claude/templates/issue-implementation-plan.md「🗺️ 証跡マッピング表」
# 派生表 (human-readable): scripts/claude/README.md
# 実装 (this file) は派生表に従う。drift 検知の自動化は Phase F 後続。
#
# Usage:
#   verify-issue-detect.sh --stdin [--format flat|manifest]
#   verify-issue-detect.sh --files <path...> [--format flat|manifest]
#   verify-issue-detect.sh --git [--format flat|manifest]
#
# Env (--git mode):
#   VERIFY_BASE_REF  Override base ref for `git merge-base ... HEAD`.
#                    Resolution order: VERIFY_BASE_REF -> main -> origin/main.
#                    All-miss => exit 1 with a clear error.
#
# Output:
#   --format flat (default): one category per line, deduped, no path context.
#   --format manifest:       `<path>: <cat1> <cat2> ...` per matched path.

set -uo pipefail

usage() {
  cat <<'EOF'
Usage:
  verify-issue-detect.sh --stdin [--format flat|manifest]
  verify-issue-detect.sh --files <path...> [--format flat|manifest]
  verify-issue-detect.sh --git [--format flat|manifest]

Reads changed paths and emits required evidence categories.

Env (--git mode):
  VERIFY_BASE_REF  Override base ref. Resolution: VERIFY_BASE_REF -> main -> origin/main.
EOF
}

err() { printf 'ERROR: %s\n' "$*" >&2; }

# ─── Categorize a single path. Echoes 0..N category names, one per line. ───
categorize_path() {
  local path="$1"
  local re

  # 1. backend-unit
  re='^apps/backend/app/modules/[^/]+/(domain|services)/'
  if [[ "$path" =~ $re ]]; then
    echo "backend-unit"
  fi

  # 2. backend-integration
  re='^apps/backend/app/modules/[^/]+/(repositories|infrastructure)/'
  if [[ "$path" =~ $re ]] || [[ "$path" =~ ^apps/backend/app/infrastructure/ ]]; then
    echo "backend-integration"
  fi

  # 3. api-route
  re='^apps/backend/app/modules/[^/]+/(api|presentation)/'
  if [[ "$path" =~ $re ]] \
    || [[ "$path" =~ ^apps/backend/app/middlewares/ ]] \
    || [[ "$path" =~ ^apps/backend/app/shared/.*/routes\.py$ ]]; then
    echo "api-route"
  fi

  # 4. api-contract
  if [[ "$path" =~ ^apps/backend/app/.*/schemas/ ]] \
    || [[ "$path" =~ ^apps/backend/app/contracts/ ]] \
    || [[ "$path" =~ ^apps/frontend/app/.*/_types/ ]] \
    || [[ "$path" =~ ^apps/frontend/app/_types/ ]] \
    || [[ "$path" =~ ^apps/frontend/src/types/ ]]; then
    echo "api-contract"
  fi

  # 5. backend-core
  if [[ "$path" =~ ^apps/backend/app/kernel/ ]] \
    || [[ "$path" =~ ^apps/backend/app/shared/ ]]; then
    echo "backend-core"
  fi

  # 6. migration-safety
  if [[ "$path" =~ ^apps/backend/alembic/versions/ ]]; then
    echo "migration-safety"
  fi

  # 7. frontend-ui
  re='^apps/frontend/app/(.*/)?(page|layout)\.tsx$'
  if [[ "$path" =~ $re ]] \
    || [[ "$path" =~ ^apps/frontend/app/.*/_(containers|components)/ ]] \
    || [[ "$path" =~ ^apps/frontend/app/_(containers|components)/ ]] \
    || [[ "$path" =~ ^apps/frontend/src/components/ ]]; then
    echo "frontend-ui"
  fi

  # 8. frontend-logic
  if [[ "$path" =~ ^apps/frontend/app/.*/_(hooks|lib|actions)/ ]] \
    || [[ "$path" =~ ^apps/frontend/app/_(hooks|lib|actions)/ ]]; then
    echo "frontend-logic"
  fi

  # 9. frontend-shared
  if [[ "$path" =~ ^apps/frontend/src/(lib|store|hooks)/ ]]; then
    echo "frontend-shared"
  fi

  # 10. frontend-style
  re='^apps/frontend/app/(.*/)?globals\.css$'
  if [[ "$path" =~ $re ]] \
    || [[ "$path" =~ ^apps/frontend/tailwind\.config\. ]] \
    || [[ "$path" =~ ^apps/frontend/postcss\.config\. ]]; then
    echo "frontend-style"
  fi

  # 11. docdd
  if [[ "$path" =~ ^docs/7-axis/ ]] \
    || [[ "$path" =~ ^docs/testing/traceability/ ]]; then
    echo "docdd"
  fi

  # 12. dx-config
  if [[ "$path" =~ ^scripts/ ]] \
    || [[ "$path" =~ ^Makefile ]] \
    || [[ "$path" =~ ^[^/]+\.config\. ]] \
    || [[ "$path" =~ ^\.claude/hooks/ ]] \
    || [[ "$path" == ".claude/settings.json" ]] \
    || [[ "$path" =~ ^\.github/ ]] \
    || [[ "$path" =~ ^terraform/ ]]; then
    echo "dx-config"
  fi

  # 13. dx-docs
  if [[ "$path" =~ ^\.claude/(commands|rules|skills|templates|references)/ ]]; then
    echo "dx-docs"
  fi
}

# ─── Resolve --git base ref. Echoes ref to stdout; errors to stderr. ───
resolve_base_ref() {
  if [[ -n "${VERIFY_BASE_REF:-}" ]]; then
    if git rev-parse --verify --quiet "$VERIFY_BASE_REF" >/dev/null; then
      echo "$VERIFY_BASE_REF"
      return 0
    fi
    err "VERIFY_BASE_REF='$VERIFY_BASE_REF' not found in repo"
    return 1
  fi
  if git rev-parse --verify --quiet main >/dev/null; then
    echo "main"
    return 0
  fi
  if git rev-parse --verify --quiet origin/main >/dev/null; then
    echo "origin/main"
    return 0
  fi
  err "cannot resolve base ref (tried VERIFY_BASE_REF / main / origin/main)"
  return 1
}

# ─── Collect input paths into stdout (newline-separated). ───
collect_paths() {
  case "$INPUT_MODE" in
    stdin)
      cat
      ;;
    files)
      local f
      for f in "${FILES[@]}"; do
        printf '%s\n' "$f"
      done
      ;;
    git)
      local base_ref merge_base
      if ! base_ref=$(resolve_base_ref); then
        return 1
      fi
      if ! merge_base=$(git merge-base "$base_ref" HEAD 2>/dev/null); then
        err "git merge-base $base_ref HEAD failed"
        return 1
      fi
      git diff --name-only "$merge_base" HEAD
      ;;
  esac
}

# ─── Argument parsing ───
INPUT_MODE=""
FORMAT="flat"
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stdin)
      INPUT_MODE="stdin"
      shift
      ;;
    --files)
      INPUT_MODE="files"
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        FILES+=("$1")
        shift
      done
      ;;
    --git)
      INPUT_MODE="git"
      shift
      ;;
    --format)
      if [[ $# -lt 2 ]]; then
        err "--format requires a value (flat|manifest)"
        exit 1
      fi
      FORMAT="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      err "unknown argument: $1"
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT_MODE" ]]; then
  err "input mode required (--stdin / --files / --git)"
  usage >&2
  exit 1
fi

if [[ "$FORMAT" != "flat" && "$FORMAT" != "manifest" ]]; then
  err "--format must be 'flat' or 'manifest' (got '$FORMAT')"
  exit 1
fi

# ─── Run ───
if ! ALL_PATHS=$(collect_paths); then
  exit 1
fi

case "$FORMAT" in
  flat)
    {
      while IFS= read -r p; do
        [[ -z "$p" ]] && continue
        categorize_path "$p"
      done <<<"$ALL_PATHS"
    } | awk 'NF && !seen[$0]++'
    ;;
  manifest)
    while IFS= read -r p; do
      [[ -z "$p" ]] && continue
      cats=$(categorize_path "$p" | awk 'NF && !seen[$0]++' | tr '\n' ' ' | sed 's/[[:space:]]*$//')
      if [[ -n "$cats" ]]; then
        printf '%s: %s\n' "$p" "$cats"
      fi
    done <<<"$ALL_PATHS"
    ;;
esac
