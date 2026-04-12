#!/usr/bin/env bats
# scripts/claude/test-hooks.bats
#
# Fixture tests for .claude/hooks/ scripts.
# Each test pipes a JSON payload (matching Claude Code hook input format)
# into the hook script and asserts the output.

HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.claude/hooks" && pwd)"

# ─── block-dangerous.sh ──────────────────────────────────

@test "block-dangerous: sudo rm -rf / is blocked" {
  input='{"tool_name":"Bash","tool_input":{"command":"sudo rm -rf /"}}'
  result=$(echo "$input" | "$HOOKS_DIR/block-dangerous.sh")
  echo "$result" | grep -q '"decision":"block"'
}

@test "block-dangerous: git reset --hard HEAD~1 triggers ask" {
  input='{"tool_name":"Bash","tool_input":{"command":"git reset --hard HEAD~1"}}'
  result=$(echo "$input" | "$HOOKS_DIR/block-dangerous.sh")
  echo "$result" | grep -q '"permissionDecision":"ask"'
}

@test "block-dangerous: gh api is blocked" {
  input='{"tool_name":"Bash","tool_input":{"command":"gh api repos/owner/repo"}}'
  result=$(echo "$input" | "$HOOKS_DIR/block-dangerous.sh")
  echo "$result" | grep -q '"decision":"block"'
}

@test "block-dangerous: safe git command is allowed" {
  input='{"tool_name":"Bash","tool_input":{"command":"git status"}}'
  result=$(echo "$input" | "$HOOKS_DIR/block-dangerous.sh")
  [ -z "$result" ]
}

# ─── protect-files.sh ────────────────────────────────────

@test "protect-files: .env write is blocked" {
  input='{"tool_name":"Write","tool_input":{"file_path":".env","content":"SECRET=xxx"}}'
  result=$(echo "$input" | "$HOOKS_DIR/protect-files.sh")
  echo "$result" | grep -q '"decision":"block"'
}

@test "protect-files: .env.example write is allowed" {
  input='{"tool_name":"Write","tool_input":{"file_path":".env.example","content":"KEY=value"}}'
  result=$(echo "$input" | "$HOOKS_DIR/protect-files.sh")
  [ -z "$result" ]
}

@test "protect-files: .git/config write is blocked" {
  input='{"tool_name":"Write","tool_input":{"file_path":".git/config","content":"[core]"}}'
  result=$(echo "$input" | "$HOOKS_DIR/protect-files.sh")
  echo "$result" | grep -q '"decision":"block"'
}

# ─── detect-quality-issues.sh ────────────────────────────

@test "detect-quality-issues: test.skip triggers warning" {
  input='{"tool_name":"Edit","tool_input":{"new_string":"test.skip(\"reason\")"}}'
  result=$(echo "$input" | "$HOOKS_DIR/detect-quality-issues.sh")
  echo "$result" | grep -q 'systemMessage'
  echo "$result" | grep -q 'test.skip'
}

@test "detect-quality-issues: clean code produces no output" {
  input='{"tool_name":"Write","tool_input":{"content":"const x = 1;"}}'
  result=$(echo "$input" | "$HOOKS_DIR/detect-quality-issues.sh")
  [ -z "$result" ]
}
