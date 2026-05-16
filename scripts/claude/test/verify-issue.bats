#!/usr/bin/env bats
# scripts/claude/test/verify-issue.bats
#
# RED fixture for scripts/claude/verify-issue.sh (Issue #62, /tdd phase).
# The orchestrator does NOT exist yet — every test here MUST fail until
# /develop implements scripts/claude/verify-issue.sh + the Makefile targets.
#
# Encoded orchestrator contract (the GREEN target /develop must satisfy):
#
#   Invocation
#     verify-issue.sh <ISSUE> [args]      # SubsCore-style positional model
#     ISSUE env is used when the positional arg is absent.
#
#   Exit codes (orchestrator-own regime; NOT the detector's regime)
#     0  all steps pass (or skip-only)
#     1  at least one step failed (stop-on-fail = CONTINUE: all steps still run)
#     2  argument invalid (ISSUE missing / non-digits / "0")
#     3  prerequisite failure (jq absent / detector absent / detector error /
#        unknown_category / gh pr lookup failed / ISSUE-PR mismatch)
#
#   Output JSON
#     default path : $(mktemp -t "verify-issue-<ISSUE>.XXXXXX").json
#     override     : $VERIFY_ISSUE_OUTPUT (absolute path)
#     latest ptr   : ${TMPDIR:-/tmp}/verify-issue-<ISSUE>.latest.json  (symlink)
#     schema       : inputs{requested_issue,resolved_pr,issue_pr_match,source,...}
#                    steps[]{name,status,skip_reason,partial,...}
#                    summary{pass_count,fail_count,skip_count,
#                            manual_required_count,partial_count,total_count}
#                    error{code,message,detector_stderr}  warnings[]  exit_code
#     JSON is written even on exit-3 prereq failures EXCEPT jq_not_found
#     (no jq → cannot build JSON; reported on stderr) and exit-2 arg errors.
#
#   Detector resolution
#     ${VERIFY_ISSUE_DETECTOR:-<sibling>/verify-issue-detect.sh}
#     detector non-zero exit  → orchestrator exit 3, error.code=detector_failed
#     detector missing        → orchestrator exit 3, error.code=detector_failed
#
#   opt-in env
#     VERIFY_REQUIRE_PR_MATCH (default 1): 0 downgrades ISSUE-PR mismatch to a
#     warning (exit 0 if steps pass) instead of exit 3.
#
#   category → make target mapping (orchestrator-own derived table; SSOT is
#   .claude/templates/issue-implementation-plan.md「🗺️ 証跡マッピング表」):
#     backend-* / api-* / migration-safety  → make test-backend
#     api-contract                          → + make test-frontend
#     frontend-{ui,logic,shared}            → make test-frontend
#     frontend-style                        → no automated step; always SKIP
#     docdd                                 → make traceability
#     dx-config                             → make shell-lint + shell-format-check
#     dx-docs                               → make validate-claude
#   Same make target is invoked AT MOST ONCE per run (dedup).
#
#   Manual-required placeholders (ADDITIVE to automated steps): every detected
#   category whose SSOT mapping requires manual evidence also emits a separate
#   skip step named <category>-manual (skip_reason manual_required, command
#   null), counted in summary.manual_required_count. Applies to api-route,
#   api-contract, backend-core, frontend-ui, frontend-style, docdd, dx-config,
#   dx-docs. migration-safety is the lone exception: its manual aspect is the
#   partial+notes flag on test-backend, NOT a separate placeholder.
#
# 真の SSOT: .claude/templates/issue-implementation-plan.md「🗺️ 証跡マッピング表」

ORCH="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/verify-issue.sh"

setup() {
  TMPDIR_BATS="$(mktemp -d)"
  BIN="$TMPDIR_BATS/bin"
  mkdir -p "$BIN"
  MAKE_LOG="$TMPDIR_BATS/make.log"
  : >"$MAKE_LOG"

  # ── fake make: log every invocation; fail targets listed in FAKE_MAKE_FAIL ──
  cat >"$BIN/make" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$MAKE_LOG"
for t in "$@"; do
  case " ${FAKE_MAKE_FAIL:-} " in
    *" $t "*) exit 1 ;;
  esac
done
exit 0
EOF
  chmod +x "$BIN/make"

  # ── fake gh: pr list / pr view / pr diff, controlled by FAKE_GH_* env ──
  cat >"$BIN/gh" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
  if [ "${FAKE_GH_PR_LIST_FAIL:-0}" = "1" ]; then
    echo "gh: could not authenticate" >&2
    exit 1
  fi
  bare=0
  for a in "$@"; do
    [ "$a" = "--jq" ] && bare=1
    [ "$a" = "-q" ] && bare=1
  done
  if [ -z "${FAKE_GH_PR_NUMBER:-}" ]; then
    if [ "$bare" = "1" ]; then printf ''; else echo "[]"; fi
  else
    if [ "$bare" = "1" ]; then
      printf '%s\n' "$FAKE_GH_PR_NUMBER"
    else
      printf '[{"number":%s}]\n' "$FAKE_GH_PR_NUMBER"
    fi
  fi
  exit 0
fi
if [ "$1" = "pr" ] && [ "$2" = "view" ]; then
  printf '%s' "${FAKE_GH_PR_BODY:-}"
  exit 0
fi
if [ "$1" = "pr" ] && [ "$2" = "diff" ]; then
  echo "scripts/claude/verify-issue.sh"
  exit 0
fi
exit 0
EOF
  chmod +x "$BIN/gh"

  # ── fake detector: emit FAKE_DETECTOR_CATEGORIES (space-sep) one per line ──
  cat >"$TMPDIR_BATS/detector.sh" <<'EOF'
#!/usr/bin/env bash
if [ "${FAKE_DETECTOR_EXIT:-0}" != "0" ]; then
  echo "verify-issue-detect: simulated failure" >&2
  exit "${FAKE_DETECTOR_EXIT}"
fi
for c in ${FAKE_DETECTOR_CATEGORIES:-}; do
  echo "$c"
done
exit 0
EOF
  chmod +x "$TMPDIR_BATS/detector.sh"

  export MAKE_LOG
  export PATH="$BIN:$PATH"
  export TMPDIR="$TMPDIR_BATS"
  export VERIFY_ISSUE_OUTPUT="$TMPDIR_BATS/out.json"
  export VERIFY_ISSUE_DETECTOR="$TMPDIR_BATS/detector.sh"
  unset ISSUE || true
}

teardown() {
  if [[ -n "${TMPDIR_BATS:-}" && -d "$TMPDIR_BATS" ]]; then
    rm -rf "$TMPDIR_BATS"
  fi
}

# ─── 1. Acceptance: 3 mandated cases (all PASS / partial FAIL / SKIP only) ───

@test "acceptance: all PASS -> exit 0, fail_count 0" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Wave 5-2 orchestrator. Closes #62"
  export FAKE_DETECTOR_CATEGORIES="backend-unit docdd dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [ "$(jq -r '.summary.fail_count' "$VERIFY_ISSUE_OUTPUT")" -eq 0 ]
  [ "$(jq -r '.summary.pass_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
}

@test "acceptance: partial FAIL -> exit 1, fail_count >=1, pass_count >=1" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="backend-unit docdd"
  export FAKE_MAKE_FAIL="traceability"
  run "$ORCH" 62
  [ "$status" -eq 1 ]
  [ "$(jq -r '.summary.fail_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
  [ "$(jq -r '.summary.pass_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
}

@test "acceptance: SKIP only (frontend-style) -> exit 0, skip_count >=1, pass_count 0" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="frontend-style"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [ "$(jq -r '.summary.skip_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
  [ "$(jq -r '.summary.pass_count' "$VERIFY_ISSUE_OUTPUT")" -eq 0 ]
  jq -e '.steps[] | select(.name == "frontend-style-manual") | .skip_reason == "manual_required"' "$VERIFY_ISSUE_OUTPUT"
}

# ─── 2. Argument validation -> exit 2 ───────────────────────

@test "argv: ISSUE missing -> exit 2" {
  run "$ORCH"
  [ "$status" -eq 2 ]
}

@test "argv: ISSUE=abc (non-digits) -> exit 2" {
  run "$ORCH" abc
  [ "$status" -eq 2 ]
}

@test "argv: ISSUE=0 -> exit 2" {
  run "$ORCH" 0
  [ "$status" -eq 2 ]
}

# ─── 3. Prerequisite failures -> exit 3 ─────────────────────

@test "prereq: jq absent -> exit 3 + jq_not_found on stderr" {
  cat >"$BIN/jq" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$BIN/jq"
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 3 ]
  [[ "$output" == *"jq_not_found"* ]]
}

@test "prereq: detector missing -> exit 3 + error.code detector_failed" {
  export VERIFY_ISSUE_DETECTOR="$TMPDIR_BATS/no-such-detector.sh"
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  run "$ORCH" 62
  [ "$status" -eq 3 ]
  [ "$(jq -r '.error.code' "$VERIFY_ISSUE_OUTPUT")" = "detector_failed" ]
}

@test "prereq: detector exits non-zero -> exit 3 + error.code detector_failed" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_EXIT=1
  run "$ORCH" 62
  [ "$status" -eq 3 ]
  [ "$(jq -r '.error.code' "$VERIFY_ISSUE_OUTPUT")" = "detector_failed" ]
}

@test "prereq: unknown category from detector -> exit 3 + error.code unknown_category" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="bogus-category"
  run "$ORCH" 62
  [ "$status" -eq 3 ]
  [ "$(jq -r '.error.code' "$VERIFY_ISSUE_OUTPUT")" = "unknown_category" ]
}

# ─── 4. ISSUE-PR linkage verification ───────────────────────

@test "pr-match: mismatched PR with PR_MATCH=1 -> exit 3 + pr_issue_mismatch" {
  export FAKE_GH_PR_NUMBER=999
  export FAKE_GH_PR_BODY="Unrelated PR title and body, no closes keyword"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 3 ]
  [ "$(jq -r '.error.code' "$VERIFY_ISSUE_OUTPUT")" = "pr_issue_mismatch" ]
  [ "$(jq -r '.inputs.issue_pr_match' "$VERIFY_ISSUE_OUTPUT")" = "false" ]
  jq -e '.warnings | index("pr_issue_mismatch") != null' "$VERIFY_ISSUE_OUTPUT"
}

@test "pr-match: mismatched PR with VERIFY_REQUIRE_PR_MATCH=0 -> exit 0 + warning only" {
  export FAKE_GH_PR_NUMBER=999
  export FAKE_GH_PR_BODY="Unrelated PR title and body, no closes keyword"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  export VERIFY_REQUIRE_PR_MATCH=0
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [ "$(jq -r '.inputs.issue_pr_match' "$VERIFY_ISSUE_OUTPUT")" = "false" ]
  jq -e '.warnings | index("pr_issue_mismatch") != null' "$VERIFY_ISSUE_OUTPUT"
}

@test "pr-match: matched PR (Closes #62) -> source pr-diff + issue_pr_match true" {
  export FAKE_GH_PR_NUMBER=100
  export FAKE_GH_PR_BODY="feat: orchestrator. Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [ "$(jq -r '.inputs.source' "$VERIFY_ISSUE_OUTPUT")" = "pr-diff" ]
  [ "$(jq -r '.inputs.resolved_pr' "$VERIFY_ISSUE_OUTPUT")" = "100" ]
  [ "$(jq -r '.inputs.issue_pr_match' "$VERIFY_ISSUE_OUTPUT")" = "true" ]
}

# ─── 5. PR lookup: 2-state separation (no PR vs. lookup failure) ───

@test "pr-lookup: no PR (empty) -> merge-base-fallback + resolved_pr null" {
  export FAKE_GH_PR_NUMBER=""
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [ "$(jq -r '.inputs.source' "$VERIFY_ISSUE_OUTPUT")" = "merge-base-fallback" ]
  [ "$(jq -r '.inputs.resolved_pr' "$VERIFY_ISSUE_OUTPUT")" = "null" ]
}

@test "pr-lookup: gh failure -> exit 3 + error.code gh_pr_lookup_failed (no fallback)" {
  export FAKE_GH_PR_LIST_FAIL=1
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 3 ]
  [ "$(jq -r '.error.code' "$VERIFY_ISSUE_OUTPUT")" = "gh_pr_lookup_failed" ]
}

# ─── 6. dedup: same make target invoked at most once ────────

@test "dedup: 3 categories -> test-backend, make invoked exactly once" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="backend-unit backend-integration backend-core"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [ "$(wc -l <"$MAKE_LOG" | tr -d ' ')" -eq 1 ]
  grep -q "test-backend" "$MAKE_LOG"
}

@test "dedup: dx-config -> both shell-lint and shell-format-check invoked" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-config"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  grep -q "shell-lint" "$MAKE_LOG"
  grep -q "shell-format-check" "$MAKE_LOG"
}

# ─── 7. stop-on-fail = CONTINUE ─────────────────────────────

@test "stop-on-fail: first step fails, later steps still run + aggregated" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="backend-unit docdd"
  export FAKE_MAKE_FAIL="test-backend"
  run "$ORCH" 62
  [ "$status" -eq 1 ]
  grep -q "test-backend" "$MAKE_LOG"
  grep -q "traceability" "$MAKE_LOG"
  [ "$(jq -r '.summary.fail_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
  [ "$(jq -r '.summary.pass_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
}

# ─── 8. JSON schema integrity ───────────────────────────────

@test "schema: all required keys present" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="backend-unit docdd dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  jq -e '.inputs.requested_issue == 62' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.inputs | has("resolved_pr")' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.inputs | has("issue_pr_match")' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.inputs | has("source")' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.steps | type == "array"' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.steps[0] | has("name") and has("status")' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.summary | has("pass_count") and has("fail_count") and has("skip_count") and has("manual_required_count") and has("partial_count") and has("total_count")' "$VERIFY_ISSUE_OUTPUT"
  jq -e 'has("error") and has("warnings") and has("exit_code")' "$VERIFY_ISSUE_OUTPUT"
}

# ─── 9. Output path override + .latest.json symlink ─────────

@test "output: VERIFY_ISSUE_OUTPUT override writes to that path" {
  export VERIFY_ISSUE_OUTPUT="$TMPDIR_BATS/custom-out.json"
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [ -f "$TMPDIR_BATS/custom-out.json" ]
  jq -e '.inputs.requested_issue == 62' "$TMPDIR_BATS/custom-out.json"
}

@test "output: .latest.json symlink points at the run output" {
  export VERIFY_ISSUE_OUTPUT="$TMPDIR_BATS/custom-out.json"
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  link="$TMPDIR_BATS/verify-issue-62.latest.json"
  [ -L "$link" ]
  # Contract: the .latest.json symlink resolves to THIS run's output file.
  # `-ef` (same device+inode) expresses that intent and is symlink-transparent
  # on both macOS and Linux. The previous form string-compared
  # `realpath "$(readlink ...)"` against the logical "$TMPDIR_BATS" path; on
  # macOS realpath canonicalizes /var -> /private/var while $TMPDIR_BATS keeps
  # the logical /var/folders form, so the equality could never hold there
  # regardless of the orchestrator (tests 20 & 22 prove the symlink mechanism).
  [ "$link" -ef "$VERIFY_ISSUE_OUTPUT" ]
}

@test "output: default path used when VERIFY_ISSUE_OUTPUT unset + latest symlink" {
  unset VERIFY_ISSUE_OUTPUT
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  link="$TMPDIR_BATS/verify-issue-62.latest.json"
  [ -L "$link" ]
  jq -e '.inputs.requested_issue == 62' "$link"
}

# ─── 10. stdout summary echo (CI log readability) ───────────

@test "summary-echo: PASS run ends with the SubsCore-style PASSED line" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  [[ "$output" == *"verify-issue #62 PASSED"* ]]
}

@test "summary-echo: FAIL run ends with the SubsCore-style FAILED line" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  export FAKE_MAKE_FAIL="validate-claude"
  run "$ORCH" 62
  [ "$status" -eq 1 ]
  [[ "$output" == *"verify-issue #62 FAILED"* ]]
}

# ─── 11. ISSUE via env when positional arg absent ───────────

@test "argv: ISSUE env used when positional arg absent" {
  export ISSUE=62
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.inputs.requested_issue' "$VERIFY_ISSUE_OUTPUT")" -eq 62 ]
}

# ─── 12. manual_required placeholders are additive to automated steps ───
# A category that also has an automated make target must STILL emit a
# <category>-manual skip step so 5-3 surfaces pending manual evidence even
# when the automated target passes (exit 0).

@test "manual: backend-core passes automated step AND emits backend-core-manual" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="backend-core"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  grep -q "test-backend" "$MAKE_LOG"
  [ "$(jq -r '.summary.pass_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
  jq -e '.steps[] | select(.name == "backend-core-manual") | .status == "skip" and .skip_reason == "manual_required" and .command == null' "$VERIFY_ISSUE_OUTPUT"
  [ "$(jq -r '.summary.manual_required_count' "$VERIFY_ISSUE_OUTPUT")" -ge 1 ]
}

@test "manual: manual_required_count counts every manual-bearing category" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="api-route dx-docs"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  jq -e '.steps[] | select(.name == "api-route-manual") | .skip_reason == "manual_required"' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.steps[] | select(.name == "dx-docs-manual") | .skip_reason == "manual_required"' "$VERIFY_ISSUE_OUTPUT"
  [ "$(jq -r '.summary.manual_required_count' "$VERIFY_ISSUE_OUTPUT")" -eq 2 ]
}

@test "manual: migration-safety does NOT emit a separate manual placeholder (partial only)" {
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="migration-safety"
  run "$ORCH" 62
  [ "$status" -eq 0 ]
  jq -e '[.steps[] | select(.name == "migration-safety-manual")] | length == 0' "$VERIFY_ISSUE_OUTPUT"
  jq -e '.steps[] | select(.name == "test-backend") | .partial == true' "$VERIFY_ISSUE_OUTPUT"
}

# ─── 13. result-JSON write failure must fail loudly (Codex /review P2) ───
# The result JSON is the contract 5-3 consumes. An unwritable
# VERIFY_ISSUE_OUTPUT location must yield exit 3 (not a PASSED echo with the
# original success code) so downstream never trusts a stale/absent file.
# Assumes the suite runs as a NON-root user: root bypasses the read-only dir;
# both GH Actions runners and local macOS dev run non-root.

@test "output: unwritable VERIFY_ISSUE_OUTPUT -> exit 3, not PASSED" {
  mkdir -p "$TMPDIR_BATS/ro"
  chmod 500 "$TMPDIR_BATS/ro"
  export VERIFY_ISSUE_OUTPUT="$TMPDIR_BATS/ro/out.json"
  export FAKE_GH_PR_NUMBER=62
  export FAKE_GH_PR_BODY="Closes #62"
  export FAKE_DETECTOR_CATEGORIES="dx-docs"
  run "$ORCH" 62
  chmod 700 "$TMPDIR_BATS/ro"
  [ "$status" -eq 3 ]
  [[ "$output" == *"output_write_failed"* ]]
  [[ "$output" != *"PASSED"* ]]
}
