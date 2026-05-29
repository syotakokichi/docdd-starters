#!/usr/bin/env bash
# block-dangerous.sh — PreToolUse hook for Bash commands
# Hard-blocks destructive operations, asks for confirmation on risky ones.
#
# Hook output format:
#   block:  {"decision": "block", "reason": "..."}
#   ask:    {"hookSpecificOutput": {"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"..."}}
#   allow:  (empty or no output — hook exits 0)

set -euo pipefail

# ─── Output helpers ──────────────────────────────────────────
# Build the block/ask JSON via jq so multi-line reasons are escaped safely.
# -n: no input, -c: compact (keeps the legacy `"decision":"block"` shape intact).
emit_block() {
  jq -nc --arg reason "$1" '{decision:"block",reason:$reason}'
}
emit_ask() {
  jq -nc --arg reason "$1" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$reason}}'
}

# Read tool input from stdin
INPUT=$(cat)

# Extract the command string from tool_input.command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || true)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# ─── Hard Block ───────────────────────────────────────────────
# These are ALWAYS blocked, no exceptions.

# sudo
if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)sudo\b'; then
  echo '{"decision":"block","reason":"sudo is not allowed. Run commands without elevated privileges."}'
  exit 0
fi

# git push --force (but NOT --force-with-lease)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force($|\s|[;&|])' \
  && ! echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
  echo '{"decision":"block","reason":"git push --force is blocked. Use --force-with-lease instead."}'
  exit 0
fi

# git push -f (short flag, but NOT -fl or --force-with-lease)
if echo "$COMMAND" | grep -qE 'git\s+push\s+(.*\s)?-f($|\s|[;&|])' \
  && ! echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
  echo '{"decision":"block","reason":"git push -f is blocked. Use --force-with-lease instead."}'
  exit 0
fi

# rm -rf / or rm -rf /* or rm --recursive --force / (root filesystem)
if echo "$COMMAND" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r|--recursive\s+--force|--force\s+--recursive)[a-zA-Z]*\s+/(\.?\*)?($|\s)'; then
  echo '{"decision":"block","reason":"rm -rf / is blocked. This would destroy the entire filesystem."}'
  exit 0
fi

# gh api (arbitrary API calls)
if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)gh\s+api\b'; then
  echo '{"decision":"block","reason":"gh api is blocked. Use specific gh subcommands (gh issue, gh pr, etc.) instead."}'
  exit 0
fi

# ─── Codex auth credential protection (3 layers) ─────────────
# Blocks attempts to exfiltrate the local CLI auth credential. This guards the
# raw command string only and matches case-insensitively (case-insensitive
# filesystems resolve .CODEX to the same directory). The following are out of
# scope BY DESIGN — they need runtime resolution a static string match cannot do:
#   - variable expansion / command substitution ($HOME, $(...), `...`)
#   - string concatenation, aliases, and obfuscation (base64 etc.)
#   - parent-directory traversal that cancels out (e.g. .codex/sub/../auth.json)
# Read-tool access to the credential file is likewise out of scope (this hook
# binds the Bash matcher only). File-level protection is handled separately.
#
# The detection is intentionally asymmetric:
#   3a/3b anchor on the `.codex/` directory and `auth*` glob (auth.json/.toml/...).
#   3c anchors on the canonical `auth.json` basename so a force-add of unrelated
#   files (e.g. authors.txt) is not falsely blocked.

# 3a: read / copy / move of a .codex/auth* credential file. Two forms:
#   - a contiguous path, tolerating redundant noise (.codex//auth, .codex/./auth);
#   - cd/pushd INTO the .codex directory, then a bare auth.<ext> token — this
#     catches the change-then-relative form `cd ~/.codex && cat auth.json`.
# The bare-token branch is tied to a cd into .codex (not just any .codex mention)
# so an unrelated auth.<ext> elsewhere in the command is not falsely blocked.
# Both forms require a boundary after `auth` (a non-letter or end) so unrelated
# names that merely start with auth (author.py, authors.txt) are not blocked.
if echo "$COMMAND" | grep -qiE '\.codex/+(\./+)*auth([^a-zA-Z]|$)' \
  || { echo "$COMMAND" | grep -qiE '\b(cd|pushd)\s+[^;|&]*\.codex' \
    && echo "$COMMAND" | grep -qiE '(^|[[:space:]/"'\''=])auth\.[a-z]'; }; then
  emit_block "Accessing the .codex/auth* credential file via Bash is blocked. This file holds local CLI auth tokens and must not be read, copied, or moved by automated commands."
  exit 0
fi

# 3b: bulk archive / transfer / move of the WHOLE .codex directory. The operation
# must target the directory itself — .codex with an optional trailing slash then a
# boundary (whitespace, end, quote, or a shell separator ;, &, |, <, >, parens) —
# so transferring or renaming a single non-auth child file (e.g.
# .codex/config.toml) is NOT blocked here; the credential file is covered by 3a.
# Quoted forms ("~/.codex") and chained commands (tar ... ~/.codex; curl ...) are
# caught. The cp clause matches a recursive/archive flag in ANY position: short
# -R/-r/-a (alone, bundled like -pR, or split like -p -R) and long --recursive/--archive.
if echo "$COMMAND" | grep -qiE '\.codex/?($|\s|["'\'';&|<>()])' \
  && { echo "$COMMAND" | grep -qE '\b(tar|rsync|scp|zip|mv)\b' \
    || { echo "$COMMAND" | grep -qE '\bcp\b' \
      && echo "$COMMAND" | grep -qE '(\s-[a-zA-Z]*[rRa]|--recursive|--archive)'; }; }; then
  emit_block "Archiving or transferring the .codex/ directory is blocked. It contains local CLI auth credentials that must not be bundled, copied recursively, or sent off-host."
  exit 0
fi

# 3c: force-adding the canonical auth.json into the repository. The force flag
# matches a standalone -f, a bundled short-option group containing f (e.g. -Af),
# or --force. The trailing boundary of the filename accepts whitespace, a quote,
# end-of-string, or a shell separator (;, &, |, <, >, parens) so chained commands
# like `git add -f auth.json; git commit ...` cannot bypass the block.
if echo "$COMMAND" | grep -qE '\bgit\s+add\b' \
  && echo "$COMMAND" | grep -qE '(^|\s)(-[a-zA-Z]*f[a-zA-Z]*|--force)($|\s|["'\''])' \
  && echo "$COMMAND" | grep -qiE '(^|[[:space:]/"'\''=])auth\.json([[:space:]"'\'';&|<>()]|$)'; then
  emit_block "Force-adding auth.json into the repository is blocked. This is the CLI auth credential file and must never be committed, even with --force."
  exit 0
fi

# ─── Ask Escalation ──────────────────────────────────────────
# These require user confirmation before proceeding.

ask_reason=""

# git reset --hard
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
  ask_reason="git reset --hard discards uncommitted changes. Please confirm."
fi

# git push --delete / --mirror / :refspec (branch/tag deletion)
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--(delete|mirror)'; then
  ask_reason="This push operation may delete remote refs. Please confirm."
fi
if echo "$COMMAND" | grep -qE 'git\s+push\s+\S+\s+:'; then
  ask_reason="Pushing a :refspec deletes a remote branch/tag. Please confirm."
fi

# SQL destructive operations via psql/mysql
if echo "$COMMAND" | grep -qiE '(psql|mysql).*\b(DROP|TRUNCATE)\b'; then
  ask_reason="SQL DROP/TRUNCATE detected. This permanently destroys data. Please confirm."
fi

# rm targeting home, root-adjacent, or parent paths
if echo "$COMMAND" | grep -qE 'rm\s+.*(\s|/)(\.\.|~|/home|/etc|/var|/usr)\b'; then
  ask_reason="rm targeting a sensitive path. Please confirm."
fi

# make deploy-* (any deployment)
if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)make\s+deploy'; then
  ask_reason="Deployment command detected. Please confirm."
fi

# gh pr merge
if echo "$COMMAND" | grep -qE '(^|[;&|]\s*)gh\s+pr\s+merge'; then
  ask_reason="PR merge via CLI. Please confirm."
fi

if [[ -n "$ask_reason" ]]; then
  cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"$ask_reason"}}
EOF
  exit 0
fi

# No match — allow
exit 0
