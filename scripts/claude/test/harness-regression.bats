#!/usr/bin/env bats
# scripts/claude/test/harness-regression.bats
#
# Harness regression suite (Issue #67 / Wave 6-1).
#
# Continuously asserts the *invariants* of the .claude/ harness so that
# silent degradation (missing frontmatter, broken settings.json, unbound
# hooks, terminology drift) fails CI instead of slipping through.
#
# Invariant catalog (Issue #67 verification def V6, items 1-10):
#   1.  commands frontmatter passes strict        (validate_claude_frontmatter.py --strict --dir .claude/commands)
#   2.  skills   frontmatter passes strict         (name == parent dir; required in strict)
#   3.  validate-claude-config.sh --strict e2e     (whole .claude/ passes strict)
#   4.  make validate-claude-strict exists & exit0  (and actually runs STRICT mode)
#   5.  settings.json valid JSON + permissions/hooks arrays
#   6.  every hook script exists & is executable
#   7.  required hook bindings (Bash PreToolUse / Write|Edit PostToolUse)
#   8.  strict-promotion false-GREEN guard, 2 negative tracks:
#         8a python --dir fixture           (frontmatter promotion)
#         8b temp .claude/ skeleton + cd    (shell-level invariant promotion)
#   9.  prompt files contain no suspicious invisible Unicode
#   10. terminology.md canonical /<cmd>  <=>  .claude/commands/<cmd>.md exists
#
# false-GREEN guard (learned from upstream #347/#349):
#   Never assert a strict FAIL by "exit code != 0" alone. A missing helper /
#   absent python can also exit non-zero; that must NOT be read as GREEN.
#   So output markers (`no frontmatter` / `FAIL (strict)`) are grep'd too
#   (cases 8a/8b).
#
# SSOT: Issue #67 verification def / .claude/rules/terminology.md / .claude/rules/tdd-gate.md

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
  VALIDATOR_SH="$REPO_ROOT/scripts/claude/validate-claude-config.sh"
  FRONTMATTER_PY="$REPO_ROOT/scripts/claude/validate_claude_frontmatter.py"
  SETTINGS_JSON="$REPO_ROOT/.claude/settings.json"
  TERMINOLOGY_MD="$REPO_ROOT/.claude/rules/terminology.md"

  PYTHON="python3"
  command -v python3 >/dev/null 2>&1 || PYTHON="python"

  TMPDIR_BATS="$(mktemp -d)"
}

teardown() {
  if [[ -n "${TMPDIR_BATS:-}" && -d "$TMPDIR_BATS" ]]; then
    rm -rf "$TMPDIR_BATS"
  fi
}

# --- 1. commands frontmatter passes strict --------------------

@test "catalog 1: .claude/commands/*.md all pass --strict frontmatter" {
  run bash -c "cd '$REPO_ROOT' && '$PYTHON' '$FRONTMATTER_PY' --strict --dir .claude/commands"
  [ "$status" -eq 0 ]
  # false-GREEN guard: a command file silently losing frontmatter must surface.
  ! echo "$output" | grep -q "no frontmatter"
}

# --- 2. skills frontmatter passes strict (name == dir) --------

@test "catalog 2: .claude/skills/**/SKILL.md all pass --strict (name matches dir)" {
  run bash -c "cd '$REPO_ROOT' && '$PYTHON' '$FRONTMATTER_PY' --strict --dir .claude/skills"
  [ "$status" -eq 0 ]
  ! echo "$output" | grep -q "no frontmatter (required in strict mode)"
  ! echo "$output" | grep -q "does not match parent directory"
}

# --- 3. validate-claude-config.sh --strict e2e ---------------

@test "catalog 3: validate-claude-config.sh --strict passes for current .claude/" {
  run bash -c "cd '$REPO_ROOT' && ./scripts/claude/validate-claude-config.sh --strict"
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "Mode: STRICT"
  echo "$output" | grep -q "0 failed"
}

# --- 4. make validate-claude-strict exists & runs STRICT -----

@test "catalog 4: make validate-claude-strict exists, exit 0, runs STRICT" {
  run bash -c "cd '$REPO_ROOT' && make validate-claude-strict"
  [ "$status" -eq 0 ]
  # false-GREEN guard: a stub target that does not actually go STRICT must fail.
  echo "$output" | grep -q "Mode: STRICT"
}

# --- 5. settings.json valid JSON + array shapes --------------

@test "catalog 5: settings.json is valid JSON with array permissions/hooks" {
  run jq empty "$SETTINGS_JSON"
  [ "$status" -eq 0 ]

  for key in allow ask deny; do
    run jq -r ".permissions.${key} | type" "$SETTINGS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "array" ]
  done

  for evt in PreToolUse PostToolUse; do
    run jq -r ".hooks.${evt} | type" "$SETTINGS_JSON"
    [ "$status" -eq 0 ]
    [ "$output" = "array" ]
  done
}

# --- 6. hook scripts exist & are executable ------------------

@test "catalog 6: every settings.json hook script exists and is executable" {
  local scripts
  scripts="$(jq -r '.hooks | to_entries[] | .value[] | .hooks[] | .command' "$SETTINGS_JSON")"
  [ -n "$scripts" ]

  while IFS= read -r raw; do
    [ -z "$raw" ] && continue
    local resolved="${raw//\$CLAUDE_PROJECT_DIR/$REPO_ROOT}"
    [ -f "$resolved" ] || { echo "missing hook script: $resolved"; return 1; }
    [ -x "$resolved" ] || { echo "not executable: $resolved"; return 1; }
  done <<<"$scripts"
}

# --- 7. required hook bindings present -----------------------

@test "catalog 7: Bash PreToolUse and Write|Edit PostToolUse bindings exist" {
  run jq -r '.hooks.PreToolUse // [] | map(select(.matcher | test("Bash"))) | length' "$SETTINGS_JSON"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]

  run jq -r '.hooks.PostToolUse // [] | map(select(.matcher | test("Write|Edit"))) | length' "$SETTINGS_JSON"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

# --- 8a strict-promotion false-GREEN guard: python --dir -----

@test "catalog 8a: frontmatter promotion — baseline exit0, strict exit1 + marker" {
  printf '# No Frontmatter Here\n\nbody only\n' >"$TMPDIR_BATS/nofm.md"

  run "$PYTHON" "$FRONTMATTER_PY" --dir "$TMPDIR_BATS"
  [ "$status" -eq 0 ]

  run "$PYTHON" "$FRONTMATTER_PY" --strict --dir "$TMPDIR_BATS"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "no frontmatter"
}

# --- 8b strict-promotion false-GREEN guard: shell skeleton ---

@test "catalog 8b: shell invariant promotion — baseline exit0, strict exit1 + marker" {
  # validate-claude-config.sh pins CLAUDE_DIR=".claude" (cwd-relative, no --dir):
  # build a minimal .claude/ skeleton and `cd` into it. settings.json = {}
  # keeps JSON valid (baseline passes) but leaves permissions/hooks undefined
  # -> record WARN -> promoted to FAIL (strict).
  local sk="$TMPDIR_BATS/skel"
  mkdir -p "$sk/.claude/commands" "$sk/.claude/rules" "$sk/.claude/skills"
  printf '{}\n' >"$sk/.claude/settings.json"
  printf '# skeleton\n' >"$sk/.claude/CLAUDE.md"
  printf '# commands\n' >"$sk/.claude/commands/README.md"
  printf '# rules\n' >"$sk/.claude/rules/README.md"
  printf '# skills\n' >"$sk/.claude/skills/README.md"

  run bash -c "cd '$sk' && '$VALIDATOR_SH'"
  [ "$status" -eq 0 ]

  run bash -c "cd '$sk' && '$VALIDATOR_SH' --strict"
  [ "$status" -ne 0 ]
  echo "$output" | grep -q "FAIL (strict)"
}

# --- 9. no suspicious invisible Unicode in prompt files ------

@test "catalog 9: prompt files contain no suspicious invisible Unicode" {
  # The forbidden codepoints are built at runtime from hex integers via
  # chr(); the test source stays pure ASCII so it never embeds the very
  # characters it forbids. Ranges mirror validate-claude-config.sh Check 6.
  local checker="$TMPDIR_BATS/uni_scan.py"
  cat >"$checker" <<'PY'
import sys, re

RANGES = [
    (0x200B, 0x200F),  # zero-width space .. RLM
    (0x2028, 0x202F),  # line/para sep, bidi embeddings/overrides
    (0x2060, 0x2069),  # word joiner, invisible ops, bidi isolates
    (0xFEFF, 0xFEFF),  # BOM / zero-width no-break space
    (0xFFF9, 0xFFFB),  # interlinear annotation anchors
]
cls = "".join(chr(lo) + "-" + chr(hi) for lo, hi in RANGES)
pattern = re.compile("[" + cls + "]")

bad = 0
for fp in sys.argv[1:]:
    try:
        with open(fp, encoding="utf-8", errors="replace") as fh:
            for n, line in enumerate(fh, 1):
                if pattern.search(line):
                    print(f"{fp}:{n}: suspicious unicode")
                    bad += 1
    except OSError:
        pass
sys.exit(1 if bad else 0)
PY

  run bash -c "
    cd '$REPO_ROOT' &&
    find .claude/commands .claude/rules .claude/skills -name '*.md' -print0 2>/dev/null |
    xargs -0 '$PYTHON' '$checker'
  "
  [ "$status" -eq 0 ]
}

# --- 10. terminology.md canonical /<cmd> <=> commands/<cmd>.md -

@test "catalog 10: every canonical command in terminology.md has commands/<cmd>.md" {
  [ -f "$TERMINOLOGY_MD" ]
  local cmds
  cmds="$(grep -oE 'commands/[a-z-]+\.md' "$TERMINOLOGY_MD" | sed 's#commands/##' | sort -u)"
  [ -n "$cmds" ]

  while IFS= read -r f; do
    [ -z "$f" ] && continue
    [ -f "$REPO_ROOT/.claude/commands/$f" ] || {
      echo "terminology references commands/$f but file is missing"
      return 1
    }
  done <<<"$cmds"
}
