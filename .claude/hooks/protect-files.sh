#!/usr/bin/env bash
# protect-files.sh — PreToolUse hook for Write/Edit/MultiEdit
# Blocks writes to sensitive files: .env*, .git/, *.pem, *.key, id_rsa*
# Exception: .env.example, .env.sample are allowed.
#
# Hook output format:
#   block: {"decision": "block", "reason": "..."}
#   allow: (empty — exit 0)

set -euo pipefail

INPUT=$(cat)

# Extract file path from tool_input (Write/Edit use file_path)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Normalize: get the basename for pattern matching
BASENAME=$(basename "$FILE_PATH")
# Sanitize for safe JSON embedding
SAFE_BASENAME=$(echo "$BASENAME" | sed 's/["\\/]/\\&/g')

# ─── .env files (block, except .env.example and .env.sample) ─
if echo "$BASENAME" | grep -qE '^\.env'; then
  if echo "$BASENAME" | grep -qE '^\.env\.(example|sample)$'; then
    exit 0 # allowed
  fi
  echo "{\"decision\":\"block\",\"reason\":\"Writing to $SAFE_BASENAME is blocked. Secrets files (.env*) must be managed manually. Use .env.example for templates.\"}"
  exit 0
fi

# ─── .git/ directory ─────────────────────────────────────────
if echo "$FILE_PATH" | grep -qE '(^|/)\.git/'; then
  echo "{\"decision\":\"block\",\"reason\":\"Writing to .git/ internals is blocked. Use git commands instead.\"}"
  exit 0
fi

# ─── Private keys: *.pem, *.key ──────────────────────────────
if echo "$BASENAME" | grep -qE '\.(pem|key)$'; then
  echo "{\"decision\":\"block\",\"reason\":\"Writing to $SAFE_BASENAME is blocked. Private key files must be managed manually.\"}"
  exit 0
fi

# ─── SSH keys: id_rsa* ───────────────────────────────────────
if echo "$BASENAME" | grep -qE '^id_rsa'; then
  echo "{\"decision\":\"block\",\"reason\":\"Writing to $SAFE_BASENAME is blocked. SSH key files must be managed manually.\"}"
  exit 0
fi

# No match — allow
exit 0
