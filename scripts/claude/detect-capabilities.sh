#!/usr/bin/env bash
# scripts/claude/detect-capabilities.sh
#
# Detect the availability of tools / integrations used by the DocDD flow and
# print a schema-v1 JSON document to stdout. Logs and warnings go to stderr.
#
# Contract:
#   stdout = valid JSON, 1 object, parseable by `jq`
#   exit 0 on success (even when some capabilities are unknown/unavailable)
#
# Three-valued state per capability:
#   "available"   : detected and usable
#   "unavailable" : explicitly not installed / not configured
#   "unknown"     : detection failed or was ambiguous (e.g. missing scope)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

warn() { printf 'warn: %s\n' "$*" >&2; }

detected_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# ─── Repo owner / name (primary: gh, fallback: git remote parse) ────

repo_owner="unknown"
repo_name="unknown"
if command -v gh >/dev/null 2>&1 && gh repo view --json owner,name >/dev/null 2>&1; then
  repo_owner=$(gh repo view --json owner -q .owner.login 2>/dev/null || echo "unknown")
  repo_name=$(gh repo view --json name -q .name 2>/dev/null || echo "unknown")
else
  if command -v git >/dev/null 2>&1; then
    url=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "")
    case "$url" in
      https://github.com/*)
        rest="${url#https://github.com/}"
        repo_owner="${rest%%/*}"
        tail="${rest#*/}"
        repo_name="${tail%.git}"
        ;;
      git@github.com:*)
        rest="${url#git@github.com:}"
        repo_owner="${rest%%/*}"
        tail="${rest#*/}"
        repo_name="${tail%.git}"
        ;;
    esac
  fi
fi

# ─── gh_installed / gh_authenticated ─────────────────────

gh_installed_state="unavailable"
if command -v gh >/dev/null 2>&1; then
  gh_installed_state="available"
fi

gh_auth_state="unknown"
if [ "$gh_installed_state" = "available" ]; then
  if gh auth status >/dev/null 2>&1; then
    gh_auth_state="available"
  else
    gh_auth_state="unavailable"
  fi
fi

# ─── repo_write_access ───────────────────────────────────

repo_write_state="unknown"
if [ "$gh_auth_state" = "available" ] && [ "$repo_owner" != "unknown" ] && [ "$repo_name" != "unknown" ]; then
  push=$(gh api "repos/$repo_owner/$repo_name" -q .permissions.push 2>/dev/null || echo "")
  case "$push" in
    true) repo_write_state="available" ;;
    false) repo_write_state="unavailable" ;;
    *) repo_write_state="unknown" ;;
  esac
fi

# ─── projects_api_available / owner_projects_count ───────

projects_api_state="unknown"
owner_projects_state="unknown"
owner_projects_value="null"
if [ "$gh_auth_state" = "available" ] && [ "$repo_owner" != "unknown" ]; then
  # gh project list は `read:project` scope が無いと失敗する
  if projects_json=$(gh project list --owner "$repo_owner" --limit 200 --format json 2>/dev/null); then
    projects_api_state="available"
    if count=$(printf '%s' "$projects_json" | jq '.projects | length' 2>/dev/null); then
      owner_projects_state="available"
      owner_projects_value="$count"
    fi
  fi
fi

# ─── codex_cli ───────────────────────────────────────────

codex_state="unavailable"
if command -v codex >/dev/null 2>&1; then
  if codex --version >/dev/null 2>&1; then
    codex_state="available"
  else
    codex_state="unknown"
  fi
fi

# ─── mcp_servers / pencil_mcp / computer_use ─────────────
#
# Detection sources (only existing files are scanned):
#   .claude/settings.json
#   .claude/settings.local.json
#   ~/.claude.json

mcp_sources_json="[]"
mcp_state="unknown"
pencil_state="unknown"
computer_use_state="unknown"

declare -a sources=()
[ -f "$REPO_ROOT/.claude/settings.json" ] && sources+=("$REPO_ROOT/.claude/settings.json")
[ -f "$REPO_ROOT/.claude/settings.local.json" ] && sources+=("$REPO_ROOT/.claude/settings.local.json")
[ -f "$HOME/.claude.json" ] && sources+=("$HOME/.claude.json")

if [ "${#sources[@]}" -gt 0 ]; then
  mcp_sources_json=$(printf '%s\n' "${sources[@]}" | jq -R . | jq -s .)

  mcp_names=""
  for f in "${sources[@]}"; do
    names=$(jq -r '
      (.mcpServers // {} | keys[]?),
      (.projects // {} | to_entries[]? | .value.mcpServers // {} | keys[]?)
    ' "$f" 2>/dev/null || true)
    if [ -n "$names" ]; then
      mcp_names+="$names"$'\n'
    fi
  done

  if [ -n "$mcp_names" ]; then
    mcp_state="available"
    if printf '%s' "$mcp_names" | grep -qi 'pencil'; then
      pencil_state="available"
    else
      pencil_state="unavailable"
    fi
  else
    mcp_state="unavailable"
    pencil_state="unavailable"
  fi

  # computer-use: 設定ファイル内のキーワード検出（permissions/tools 等に登場）
  if grep -ql 'computer' "${sources[@]}" 2>/dev/null; then
    if grep -q 'computer[-_]use\|computer_20\|anthropic.*computer' "${sources[@]}" 2>/dev/null; then
      computer_use_state="available"
    fi
  fi
  if [ "$computer_use_state" = "unknown" ]; then
    computer_use_state="unavailable"
  fi
fi

# ─── Build JSON ──────────────────────────────────────────

jq -n \
  --arg detected_at "$detected_at" \
  --arg repo_owner "$repo_owner" \
  --arg repo_name "$repo_name" \
  --arg gh_installed "$gh_installed_state" \
  --arg gh_auth "$gh_auth_state" \
  --arg repo_write "$repo_write_state" \
  --arg projects_api "$projects_api_state" \
  --arg owner_projects_state "$owner_projects_state" \
  --argjson owner_projects_value "$owner_projects_value" \
  --arg codex "$codex_state" \
  --arg mcp "$mcp_state" \
  --argjson mcp_sources "$mcp_sources_json" \
  --arg pencil "$pencil_state" \
  --arg computer_use "$computer_use_state" \
  '{
    schema_version: 1,
    detected_at: $detected_at,
    repo_owner: $repo_owner,
    repo_name: $repo_name,
    capabilities: {
      gh_installed: {
        state: $gh_installed,
        detection_source: "command -v gh"
      },
      gh_authenticated: {
        state: $gh_auth,
        detection_source: "gh auth status"
      },
      repo_write_access: {
        state: $repo_write,
        detection_source: "gh api repos/:owner/:repo -q .permissions.push"
      },
      projects_api_available: {
        state: $projects_api,
        detection_source: "gh project list --owner :login --limit 200 --format json"
      },
      owner_projects_count: {
        state: $owner_projects_state,
        value: $owner_projects_value,
        detection_source: "gh project list --owner :login --limit 200 --format json | jq .projects | length (observed ceiling: 200)"
      },
      codex_cli: {
        state: $codex,
        detection_source: "command -v codex && codex --version"
      },
      mcp_servers: {
        state: $mcp,
        sources: $mcp_sources,
        detection_source: ".claude/settings.json + .claude/settings.local.json + ~/.claude.json (.mcpServers keys)"
      },
      pencil_mcp: {
        state: $pencil,
        detection_source: "mcp_servers names matched against /pencil/i"
      },
      computer_use: {
        state: $computer_use,
        detection_source: ".claude/settings.json + .claude/settings.local.json grep computer-use"
      }
    }
  }'
