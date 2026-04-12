#!/usr/bin/env bash
# scripts/github/bootstrap-labels.sh
#
# Create/update GitHub labels from .github/labels.json idempotently via
# `gh label create --force`.
#
# This script is normally invoked by `scripts/bootstrap.sh` after preflight
# has passed. It can also be run standalone, in which case only minimal
# checks (`gh`, `jq`) are performed.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() { printf '%s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v gh >/dev/null 2>&1 || die "gh CLI が見つかりません"
command -v jq >/dev/null 2>&1 || die "jq が見つかりません"

LABELS_JSON="$REPO_ROOT/.github/labels.json"
[ -f "$LABELS_JSON" ] || die ".github/labels.json が見つかりません: $LABELS_JSON"

count=0
while IFS= read -r row; do
  name=$(jq -r '.name' <<<"$row")
  color=$(jq -r '.color' <<<"$row")
  desc=$(jq -r '.description' <<<"$row")
  gh label create "$name" --color "$color" --description "$desc" --force >&2
  count=$((count + 1))
done < <(jq -c '.managed_labels[]' "$LABELS_JSON")

log "bootstrap-labels: $count labels reconciled"
