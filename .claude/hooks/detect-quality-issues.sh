#!/usr/bin/env bash
# detect-quality-issues.sh — PostToolUse hook for Write/Edit/MultiEdit
# Warns when diff content contains quality-degrading patterns.
# Inspects tool_input only (new/changed content), not existing file content.
#
# Hook output format:
#   warning: {"systemMessage": "..."}
#   clean:   (empty — exit 0)

set -euo pipefail

INPUT=$(cat)

# Extract the content that was written/edited
# For Write: tool_input.content
# For Edit: tool_input.new_string
# For MultiEdit: tool_input.edits[].new_string
DIFF_CONTENT=$(echo "$INPUT" | jq -r '
  (.tool_input.content // empty),
  (.tool_input.new_string // empty),
  ((.tool_input.edits // [])[] | .new_string // empty)
' 2>/dev/null || true)

if [[ -z "$DIFF_CONTENT" ]]; then
  exit 0
fi

# ─── Quality pattern detection ────────────────────────────────
WARNINGS=""

# test.skip / describe.skip / it.skip
if echo "$DIFF_CONTENT" | grep -qE '\b(test|describe|it)\.skip\b'; then
  WARNINGS="${WARNINGS}\n- test.skip detected: skipped tests reduce coverage"
fi

# .only (test.only / describe.only / it.only)
if echo "$DIFF_CONTENT" | grep -qE '\b(test|describe|it)\.only\b'; then
  WARNINGS="${WARNINGS}\n- .only detected: this limits test execution to a single case"
fi

# eslint-disable
if echo "$DIFF_CONTENT" | grep -qE 'eslint-disable'; then
  WARNINGS="${WARNINGS}\n- eslint-disable detected: lint rules are disabled"
fi

# @ts-ignore / @ts-nocheck
if echo "$DIFF_CONTENT" | grep -qE '@ts-ignore|@ts-nocheck'; then
  WARNINGS="${WARNINGS}\n- @ts-ignore/@ts-nocheck detected: TypeScript type checking is bypassed"
fi

# strict: false (in config files)
if echo "$DIFF_CONTENT" | grep -qE '"strict"\s*:\s*false|strict:\s*false'; then
  WARNINGS="${WARNINGS}\n- strict: false detected: strict mode is being disabled"
fi

# pytest.mark.skip without reason
if echo "$DIFF_CONTENT" | grep -qE '@pytest\.mark\.skip($|\s*\()' && \
   ! echo "$DIFF_CONTENT" | grep -qE '@pytest\.mark\.skip\(reason='; then
  WARNINGS="${WARNINGS}\n- pytest.mark.skip without reason: add a reason for skipping"
fi

# noqa without specific code
if echo "$DIFF_CONTENT" | grep -qE '#\s*noqa($|\s)' && \
   ! echo "$DIFF_CONTENT" | grep -qE '#\s*noqa:\s*[A-Z]'; then
  WARNINGS="${WARNINGS}\n- noqa without specific code: use noqa: E501 format instead of blanket noqa"
fi

# ─── Unicode detection (prompt injection defense) ─────────────
# Only run if python3 is available
if command -v python3 &>/dev/null; then
  UNICODE_ISSUES=$(echo "$DIFF_CONTENT" | python3 -c "
import sys

# Zero-width and invisible characters
INVISIBLE = set(range(0x200B, 0x200E)) | {0x2060, 0xFEFF}
# Bidirectional control characters
BIDI = set(range(0x202A, 0x202F)) | set(range(0x2066, 0x206A))
SUSPICIOUS = INVISIBLE | BIDI

found = []
for i, line in enumerate(sys.stdin, 1):
    for j, ch in enumerate(line):
        cp = ord(ch)
        if cp in SUSPICIOUS:
            found.append(f'  line {i}, col {j}: U+{cp:04X}')
if found:
    print('\n'.join(found[:5]))  # limit to 5 hits
" 2>/dev/null || true)

  if [[ -n "$UNICODE_ISSUES" ]]; then
    WARNINGS="${WARNINGS}\n- Suspicious Unicode characters detected (possible prompt injection):\n${UNICODE_ISSUES}"
  fi
fi

# ─── Output ───────────────────────────────────────────────────
if [[ -n "$WARNINGS" ]]; then
  MSG=$(printf 'Quality warnings in this change:%b' "$WARNINGS")
  echo "$MSG" | jq -Rsc '{systemMessage: .}'
  exit 0
fi

# Clean — no output
exit 0
