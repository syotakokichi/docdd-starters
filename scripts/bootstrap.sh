#!/usr/bin/env bash
# scripts/bootstrap.sh
#
# DocDD starters bootstrap wrapper.
# Runs preflight checks, then delegates to capability detection and label
# bootstrap. All logs and JSON pretty-print go to stderr; stdout is empty.
#
# Depth note: this script lives at `scripts/` (depth 1), so REPO_ROOT is one
# directory up. Sibling scripts under `scripts/github/` or `scripts/claude/`
# (depth 2) must use `$SCRIPT_DIR/../..` instead. See ADR-06 in the Issue #24
# implementation plan.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log() { printf '%s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# ─── Preflight ───────────────────────────────────────────

command -v gh  >/dev/null 2>&1 || die "gh CLI が見つかりません。https://cli.github.com/ からインストールしてください"
command -v jq  >/dev/null 2>&1 || die "jq が見つかりません。\`brew install jq\` または \`apt install jq\` を実行してください"
command -v git >/dev/null 2>&1 || die "git が見つかりません。git をインストールしてください"

if ! gh auth status >/dev/null 2>&1; then
  die "gh auth login を実行して GitHub にログインしてください"
fi

LABELS_JSON="$REPO_ROOT/.github/labels.json"
[ -f "$LABELS_JSON" ] || die ".github/labels.json が見つかりません: $LABELS_JSON"

# origin が自分の fork を指すか検証
origin_url=""
if ! origin_url=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null); then
  die "git remote 'origin' が設定されていません。\`git remote add origin <fork-url>\` を実行してください"
fi

# HTTPS / SSH いずれの形式も owner を抽出
origin_owner=""
case "$origin_url" in
  https://github.com/*)
    rest="${origin_url#https://github.com/}"
    origin_owner="${rest%%/*}"
    ;;
  git@github.com:*)
    rest="${origin_url#git@github.com:}"
    origin_owner="${rest%%/*}"
    ;;
  ssh://git@github.com/*)
    rest="${origin_url#ssh://git@github.com/}"
    origin_owner="${rest%%/*}"
    ;;
  *)
    die "origin URL の形式を認識できません: $origin_url"
    ;;
esac

gh_login=""
gh_login=$(gh api user -q .login 2>/dev/null) || die "gh api user が失敗しました。scope を確認してください"

if [ "$origin_owner" != "$gh_login" ]; then
  die "origin owner ($origin_owner) が gh ログインユーザー ($gh_login) と一致しません。意図しない repo への label 変更を防ぐため停止します。\`git remote set-url origin <your-fork-url>\` を実行してください"
fi

# labels.json 構文検証
jq -e '.version == 1 and (.managed_labels | type == "array") and (.managed_labels | length > 0)' \
  "$LABELS_JSON" >/dev/null || die ".github/labels.json の構文が不正です (version != 1 または managed_labels 空)"

# legacy_alias_map の各 value が managed_labels に存在するか検証
missing=$(jq -r '
  .managed_labels as $m
  | (.legacy_alias_map // {})
  | to_entries[]
  | select((.value as $v | ($m | map(.name) | index($v))) | not)
  | "\(.key) -> \(.value)"
' "$LABELS_JSON")
if [ -n "$missing" ]; then
  die "legacy_alias_map の target が managed_labels に存在しません:"$'\n'"$missing"
fi

# managed_labels の name 重複検出
duplicates=$(jq -r '.managed_labels | group_by(.name) | map(select(length > 1) | .[0].name) | .[]' "$LABELS_JSON")
if [ -n "$duplicates" ]; then
  die "managed_labels に重複する name が存在します:"$'\n'"$duplicates"
fi

log "preflight OK (owner=$gh_login, labels=$(jq '.managed_labels | length' "$LABELS_JSON"))"

# ─── Execute phases ──────────────────────────────────────

CAPABILITY_FILE="${DOCDD_CAPABILITY_FILE:-/tmp/docdd-capabilities.json}"

"$REPO_ROOT/scripts/claude/detect-capabilities.sh" > "$CAPABILITY_FILE"

log "=== capabilities ==="
jq . "$CAPABILITY_FILE" >&2

"$REPO_ROOT/scripts/github/bootstrap-labels.sh"

log "=== bootstrap complete (capabilities: $CAPABILITY_FILE) ==="
