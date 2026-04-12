#!/usr/bin/env bash
# block-dangerous.sh — PreToolUse hook for Bash commands
# Hard-blocks destructive operations, asks for confirmation on risky ones.
#
# Hook output format:
#   block:  {"decision": "block", "reason": "..."}
#   ask:    {"hookSpecificOutput": {"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"..."}}
#   allow:  (empty or no output — hook exits 0)

set -euo pipefail

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
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force($|\s|[;&|])' && \
   ! echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
  echo '{"decision":"block","reason":"git push --force is blocked. Use --force-with-lease instead."}'
  exit 0
fi

# git push -f (short flag, but NOT -fl or --force-with-lease)
if echo "$COMMAND" | grep -qE 'git\s+push\s+(.*\s)?-f($|\s|[;&|])' && \
   ! echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force-with-lease'; then
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
