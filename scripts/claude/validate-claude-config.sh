#!/usr/bin/env bash
# validate-claude-config.sh — Claude Code configuration baseline validator
#
# Checks:
#   1. jq availability
#   2. Required files exist
#   3. Hooks JSON validity + script existence + exec permissions + settings structure
#   4. settings.local.json lint (if present)
#   5. Commands frontmatter (delegated to validate_claude_frontmatter.py)
#   6. Suspicious invisible Unicode characters
#
# Exit codes:
#   0 — all checks passed (warnings are OK)
#   1 — one or more checks failed
#
# Flags:
#   --strict    Promote warnings to failures (Phase 6+)

set -uo pipefail

# ─── Globals ─────────────────────────────────────────────
CLAUDE_DIR=".claude"
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
STRICT=false

# ─── Argument parsing ────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=true ;;
    *)
      echo "Unknown flag: $arg" >&2
      exit 1
      ;;
  esac
done

# ─── Helpers ─────────────────────────────────────────────

record() {
  local status="$1"
  local message="$2"
  case "$status" in
    PASS)
      echo "  ✅ PASS: $message"
      PASS_COUNT=$((PASS_COUNT + 1))
      ;;
    FAIL)
      echo "  ❌ FAIL: $message"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      ;;
    WARN)
      if [[ "$STRICT" == "true" ]]; then
        echo "  ❌ FAIL (strict): $message"
        FAIL_COUNT=$((FAIL_COUNT + 1))
      else
        echo "  ⚠️  WARN: $message"
        WARN_COUNT=$((WARN_COUNT + 1))
      fi
      ;;
  esac
}

check_file() {
  local filepath="$1"
  local label="${2:-$filepath}"
  if [[ -f "$filepath" ]]; then
    record PASS "$label exists"
    return 0
  else
    record FAIL "$label is missing"
    return 1
  fi
}

# ─── Check 1: jq availability ───────────────────────────
check_1_jq() {
  echo ""
  echo "Check 1: jq availability"
  if command -v jq >/dev/null 2>&1; then
    record PASS "jq is available ($(jq --version 2>&1))"
  else
    record FAIL "jq is not installed"
  fi
}

# ─── Check 2: Required files ────────────────────────────
check_2_required_files() {
  echo ""
  echo "Check 2: Required files"

  local required_files=(
    "${CLAUDE_DIR}/settings.json"
    "${CLAUDE_DIR}/CLAUDE.md"
    "${CLAUDE_DIR}/commands/README.md"
    "${CLAUDE_DIR}/rules/README.md"
    "${CLAUDE_DIR}/skills/README.md"
  )

  for f in "${required_files[@]}"; do
    check_file "$f"
  done
}

# ─── Check 3: Hooks & settings structure ────────────────
check_3_hooks_and_settings() {
  echo ""
  echo "Check 3: Hooks JSON validity & settings structure"

  local settings="${CLAUDE_DIR}/settings.json"

  # 3a: JSON validity
  if ! jq empty "$settings" 2>/dev/null; then
    record FAIL "$settings is not valid JSON"
    return
  fi
  record PASS "$settings is valid JSON"

  # 3b: permissions structure — allow/ask/deny should be arrays
  for key in allow ask deny; do
    local ptype
    ptype=$(jq -r ".permissions.${key} | type" "$settings" 2>/dev/null || echo "null")
    if [[ "$ptype" == "array" ]]; then
      record PASS "permissions.${key} is an array"
    elif [[ "$ptype" == "null" ]]; then
      record WARN "permissions.${key} is not defined"
    else
      record FAIL "permissions.${key} should be an array, got ${ptype}"
    fi
  done

  # 3c: hooks structure — PreToolUse and PostToolUse should be arrays
  for hook_event in PreToolUse PostToolUse; do
    local htype
    htype=$(jq -r ".hooks.${hook_event} | type" "$settings" 2>/dev/null || echo "null")
    if [[ "$htype" == "array" ]]; then
      record PASS "hooks.${hook_event} is an array"
    elif [[ "$htype" == "null" ]]; then
      record WARN "hooks.${hook_event} is not defined"
    else
      record FAIL "hooks.${hook_event} should be an array, got ${htype}"
    fi
  done

  # 3d: Hook scripts exist and are executable
  local hook_scripts
  hook_scripts=$(jq -r '
    .hooks | to_entries[]
    | .value[]
    | .hooks[]
    | .command
  ' "$settings" 2>/dev/null || true)

  if [[ -z "$hook_scripts" ]]; then
    record WARN "No hook scripts defined in settings.json"
    return
  fi

  while IFS= read -r script_path; do
    # Expand $CLAUDE_PROJECT_DIR to current directory
    local resolved
    resolved="${script_path//\$CLAUDE_PROJECT_DIR/.}"

    if [[ ! -f "$resolved" ]]; then
      record FAIL "Hook script not found: $resolved"
    elif [[ ! -x "$resolved" ]]; then
      record FAIL "Hook script not executable: $resolved"
    else
      record PASS "Hook script OK: $resolved"
    fi
  done <<<"$hook_scripts"

  # 3e: Required hook bindings — Bash PreToolUse and Write|Edit PostToolUse
  local bash_pre
  bash_pre=$(jq -r '
    .hooks.PreToolUse // []
    | map(select(.matcher == "Bash"))
    | length
  ' "$settings" 2>/dev/null || echo "0")
  if [[ "$bash_pre" -gt 0 ]]; then
    record PASS "Bash PreToolUse hook binding exists"
  else
    record WARN "No Bash PreToolUse hook binding found"
  fi

  local write_post
  write_post=$(jq -r '
    .hooks.PostToolUse // []
    | map(select(.matcher | test("Write|Edit")))
    | length
  ' "$settings" 2>/dev/null || echo "0")
  if [[ "$write_post" -gt 0 ]]; then
    record PASS "Write/Edit PostToolUse hook binding exists"
  else
    record WARN "No Write/Edit PostToolUse hook binding found"
  fi
}

# ─── Check 4: settings.local.json ───────────────────────
check_4_settings_local() {
  echo ""
  echo "Check 4: settings.local.json"

  local local_settings="${CLAUDE_DIR}/settings.local.json"

  if [[ ! -f "$local_settings" ]]; then
    record PASS "settings.local.json not present (OK — optional)"
    return
  fi

  if jq empty "$local_settings" 2>/dev/null; then
    record PASS "settings.local.json is valid JSON"
  else
    record FAIL "settings.local.json is not valid JSON"
  fi
}

# ─── Check 5: Commands frontmatter ──────────────────────
check_5_frontmatter() {
  echo ""
  echo "Check 5: Commands frontmatter"

  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  local validator="${script_dir}/validate_claude_frontmatter.py"

  if [[ ! -f "$validator" ]]; then
    record WARN "validate_claude_frontmatter.py not found, skipping"
    return
  fi

  local python_cmd="python3"
  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    python_cmd="python"
  fi

  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    record WARN "Python not available, skipping frontmatter check"
    return
  fi

  local output
  local exit_code=0
  if [[ "$STRICT" == "true" ]]; then
    output=$("$python_cmd" "$validator" --strict 2>&1) || exit_code=$?
  else
    output=$("$python_cmd" "$validator" 2>&1) || exit_code=$?
  fi

  # Print validator output
  echo "$output" | while IFS= read -r line; do
    echo "  $line"
  done

  # Parse Python warning/error counts into shell totals
  local py_warnings
  py_warnings=$(echo "$output" | grep ' warnings' | sed 's/.*[^0-9]\([0-9]*\) warnings.*/\1/' | tail -1)
  py_warnings="${py_warnings:-0}"
  WARN_COUNT=$((WARN_COUNT + py_warnings))

  if [[ $exit_code -eq 0 ]]; then
    record PASS "Commands frontmatter validation passed"
  else
    record FAIL "Commands frontmatter validation failed"
  fi
}

# ─── Check 6: Suspicious Unicode ────────────────────────
check_6_unicode() {
  echo ""
  echo "Check 6: Suspicious invisible Unicode characters"

  # Scan security-sensitive files + prompt files
  local scan_targets=()

  # settings.json
  if [[ -f "${CLAUDE_DIR}/settings.json" ]]; then
    scan_targets+=("${CLAUDE_DIR}/settings.json")
  fi

  # Hook scripts
  while IFS= read -r f; do
    [[ -f "$f" ]] && scan_targets+=("$f")
  done < <(find "${CLAUDE_DIR}/hooks" -name "*.sh" 2>/dev/null)

  # Prompt files: commands, rules, skills markdown
  while IFS= read -r f; do
    [[ -f "$f" ]] && scan_targets+=("$f")
  done < <(find "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/rules" "${CLAUDE_DIR}/skills" -name "*.md" 2>/dev/null)

  if [[ ${#scan_targets[@]} -eq 0 ]]; then
    record WARN "No files to scan for Unicode"
    return
  fi

  # Python one-liner to detect suspicious Unicode
  local python_cmd="python3"
  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    python_cmd="python"
  fi

  if ! command -v "$python_cmd" >/dev/null 2>&1; then
    record WARN "Python not available, skipping Unicode check"
    return
  fi

  local found=0
  for target in "${scan_targets[@]}"; do
    local hits
    hits=$("$python_cmd" -c "
import sys, re
# Suspicious Unicode: zero-width chars, directional overrides, homoglyphs
pattern = re.compile(r'[\u200b-\u200f\u2028-\u202f\u2060-\u2069\ufeff\ufff9-\ufffb]')
with open(sys.argv[1], 'r', errors='replace') as f:
    for i, line in enumerate(f, 1):
        for m in pattern.finditer(line):
            print(f'{sys.argv[1]}:{i}: U+{ord(m.group()):04X}')
" "$target" 2>/dev/null || true)

    if [[ -n "$hits" ]]; then
      found=1
      while IFS= read -r hit; do
        record FAIL "Suspicious Unicode: $hit"
      done <<<"$hits"
    fi
  done

  if [[ $found -eq 0 ]]; then
    record PASS "No suspicious Unicode characters found (${#scan_targets[@]} files scanned)"
  fi
}

# ─── Main ────────────────────────────────────────────────
main() {
  echo "═══════════════════════════════════════════════════════"
  echo " Claude Code Configuration Validator (baseline)"
  if [[ "$STRICT" == "true" ]]; then
    echo " Mode: STRICT (warnings → failures)"
  fi
  echo "═══════════════════════════════════════════════════════"

  check_1_jq
  check_2_required_files
  check_3_hooks_and_settings
  check_4_settings_local
  check_5_frontmatter
  check_6_unicode

  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo " Results: ✅ ${PASS_COUNT} passed | ❌ ${FAIL_COUNT} failed | ⚠️  ${WARN_COUNT} warnings"
  echo "═══════════════════════════════════════════════════════"

  if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
  fi
  exit 0
}

main
