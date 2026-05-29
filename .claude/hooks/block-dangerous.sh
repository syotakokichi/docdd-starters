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
#   - arbitrary readers/interpreters that walk the directory (awk, python, a
#     custom script): the read/transfer verb list in 3b is best-effort, not
#     exhaustive.
# Conversely, 3b errs toward blocking: it does not distinguish .codex as a command
# SOURCE from .codex as a DESTINATION (operand position is command-specific — last
# is the destination for cp/mv but the source for tar — so it cannot be resolved
# statically). A bulk op writing INTO .codex (e.g. `cp -R tmpl ~/.codex/`) may
# therefore be blocked; for credential protection, a false block is the safe side.
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

# 3b / 3c are evaluated PER COMMAND SEGMENT. The command is split on shell control
# operators (; && || | &) so an operation in one segment is not matched against a
# .codex / auth.json reference in another — e.g. `echo ~/.codex && mv foo bar` and
# `git add -f README.md && cat x/auth.json` are NOT blocked. (3a above is checked
# on the whole command because its cd-into-.codex branch intentionally spans
# segments: the cd changes the directory the next segment runs in.)
while IFS= read -r segment || [ -n "$segment" ]; do
  # 3b: exposure of the WHOLE .codex directory, which contains the credential.
  # Triggered by either:
  #   (i)  a glob or dir-self reference — .codex/* (any) or .codex/. at a boundary.
  #        The shell expands these to every file incl auth.json, so ANY consuming
  #        command (cat / grep / cp / tar / ...) exposes the credential; block
  #        regardless of the verb. A single named dotfile (.codex/.config) is not
  #        matched. OR
  #   (ii) the .codex directory itself (optional trailing slash then a boundary)
  #        targeted by a recursive flag (-R/-r/-a/--recursive/--archive) or a
  #        recursive/bulk verb (tar/rsync/scp/zip/mv/find) — e.g.
  #        `grep -R . ~/.codex/`, `tar ~/.codex`, `find ~/.codex -exec cat {} +`.
  # A single named non-auth child file (.codex/config.toml) is NOT matched here;
  # the credential file itself is covered by 3a. The verb list is best-effort:
  # arbitrary readers/interpreters that walk the directory (awk, python, custom
  # scripts) and runtime indirection are out of scope (see the header note).
  if echo "$segment" | grep -qiE '\.codex/(\*|\.($|\s|["'\''<>()]))' \
    || { echo "$segment" | grep -qiE '\.codex/?($|\s|["'\''<>()])' \
      && { echo "$segment" | grep -qE '(\s-[a-zA-Z]*[rRa]|--recursive|--archive)' \
        || echo "$segment" | grep -qE '\b(tar|rsync|scp|zip|mv|find)\b'; }; }; then
    emit_block "Reading, archiving, or transferring the whole .codex/ directory is blocked. It contains the local CLI auth credential, which must not be exposed, bundled, copied recursively, or sent off-host."
    exit 0
  fi

  # 3c: force-adding the canonical auth.json into the repository. The `git ... add`
  # match tolerates global options between `git` and `add` (e.g. `git -C . add`,
  # `git -c k=v add`, `git --git-dir=... add`). The force flag matches a standalone
  # -f, a bundled short-option group containing f (e.g. -Af), or --force. The
  # filename, force flag, and `git add` must all be in this same segment.
  if echo "$segment" | grep -qE '\bgit\s+((-[Cc]\s+\S+|--?[A-Za-z]\S*|[A-Za-z][A-Za-z0-9_.-]*=\S+)\s+)*add\b' \
    && echo "$segment" | grep -qE '(^|\s)(-[a-zA-Z]*f[a-zA-Z]*|--force)($|\s|["'\''])' \
    && echo "$segment" | grep -qiE '(^|[[:space:]/"'\''=])auth\.json([[:space:]"'\''<>()]|$)'; then
    emit_block "Force-adding auth.json into the repository is blocked. This is the CLI auth credential file and must never be committed, even with --force."
    exit 0
  fi
done < <(printf '%s\n' "$COMMAND" | sed -E 's/(&&|\|\||[;&|])/\n/g')

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
