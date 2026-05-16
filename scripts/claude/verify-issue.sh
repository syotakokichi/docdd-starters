#!/usr/bin/env bash
# scripts/claude/verify-issue.sh
#
# Wave 5-2 orchestrator: `make verify-issue ISSUE=<N>` runs 6 steps serially:
#   0. prerequisite check (jq)
#   1. Issue -> PR resolution + ISSUE-PR linkage verification
#   2. change-aware category detection (delegates to verify-issue-detect.sh, 5-1)
#   3. per-category verification execution (deduped make targets)
#   4. result aggregation (PASS / FAIL / SKIP, 5 summary stats)
#   5. structured JSON output (contract for Wave 5-3) + .latest.json symlink
#   6. exit code (0 pass / 1 fail / 2 arg invalid / 3 prerequisite failure)
#
# SubsCore-style positional model: verify-issue.sh <ISSUE> [args]
# ISSUE env is used when the positional arg is absent.
#
# JSON safety: built with `jq -n --arg/--argjson` only (never string concat).
# Step stdout/stderr bodies are spooled to side files; JSON stores paths only.
#
# 真の SSOT (category mapping): .claude/templates/issue-implementation-plan.md
#   「🗺️ 証跡マッピング表」. The category -> make-target table below is an
#   orchestrator-own derived table that follows it (never the reverse).
# JSON schema SSOT: .claude/templates/verify-issue-result.json (5-3 contract).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGDIR="${TMPDIR:-/tmp}"

# Capture the inherited ISSUE env BEFORE the globals block resets it, so the
# `ISSUE=<N> make verify-issue` form (no positional arg) keeps working.
ENV_ISSUE="${ISSUE:-}"

# ─── State (globals; orchestrator has no -e so failing steps don't abort) ───
ISSUE=""
PID="$$"
RUN_ID=""
STARTED_AT=""
OUTPUT_PATH=""
ABS_OUTPUT=""
LATEST=""
STEPS_FILE=""
SOURCE_VAL=""
RESOLVED_PR=""
ISSUE_PR_MATCH="false"
WARNINGS_JSON="[]"
ERR_CODE=""
ERR_MSG=""
ERR_DETECTOR_STDERR=""
DETECTED=""
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
MANUAL_REQUIRED_COUNT=0
PARTIAL_COUNT=0
TOTAL_COUNT=0

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

in_list() {
  local needle="$1" hay=" $2 "
  [[ "$hay" == *" $needle "* ]]
}

# Emit a JSON array of strings from a space-separated list (empty -> []).
csv_to_json_array() {
  local s="$1"
  if [[ -z "$s" ]]; then
    printf '[]'
    return
  fi
  local arr
  read -ra arr <<<"$s"
  printf '%s\n' "${arr[@]}" | jq -R . | jq -sc .
}

add_warning() {
  WARNINGS_JSON="$(printf '%s' "$WARNINGS_JSON" | jq -c --arg w "$1" '. + [$w]')"
}

known_category() {
  case "$1" in
    backend-unit | backend-integration | api-route | api-contract | backend-core | migration-safety)
      return 0
      ;;
    frontend-ui | frontend-logic | frontend-shared | frontend-style)
      return 0
      ;;
    docdd | dx-config | dx-docs)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

append_step() {
  local name="$1" command="$2" status="$3" exit_code="$4" so="$5" se="$6"
  local skip_reason="$7" partial="$8" notes="$9" cats_json="${10}"
  local started="${11}" finished="${12}"
  jq -nc \
    --arg name "$name" \
    --arg command "$command" \
    --arg status "$status" \
    --argjson exit_code "$exit_code" \
    --arg so "$so" \
    --arg se "$se" \
    --arg skip_reason "$skip_reason" \
    --argjson partial "$partial" \
    --arg notes "$notes" \
    --argjson categories "$cats_json" \
    --arg started "$started" \
    --arg finished "$finished" \
    '{
      name: $name,
      categories: $categories,
      command: (if $command == "" then null else $command end),
      status: $status,
      exit_code: $exit_code,
      stdout_path: (if $so == "" then null else $so end),
      stderr_path: (if $se == "" then null else $se end),
      skip_reason: (if $skip_reason == "" then null else $skip_reason end),
      partial: $partial,
      notes: (if $notes == "" then null else $notes end),
      started_at: $started,
      finished_at: $finished
    }' >>"$STEPS_FILE"
}

# Write the result JSON atomically, refresh the .latest.json symlink, echo the
# SubsCore-style summary line, and exit. Used for both success and (most)
# prerequisite failures. NOT used for arg errors (exit 2) or jq_not_found.
finish() {
  local code="$1"
  local steps_json resolved_pr_json source_json error_json finished_at
  if [[ -s "$STEPS_FILE" ]]; then
    steps_json="$(jq -sc . "$STEPS_FILE")"
  else
    steps_json='[]'
  fi
  if [[ -n "$RESOLVED_PR" ]]; then
    resolved_pr_json="$RESOLVED_PR"
  else
    resolved_pr_json='null'
  fi
  source_json="$(jq -nc --arg s "$SOURCE_VAL" 'if $s == "" then null else $s end')"
  error_json="$(jq -nc \
    --arg c "$ERR_CODE" --arg m "$ERR_MSG" --arg d "$ERR_DETECTOR_STDERR" \
    '{
      code: (if $c == "" then null else $c end),
      message: (if $m == "" then null else $m end),
      detector_stderr: (if $d == "" then null else $d end)
    }')"
  finished_at="$(now)"

  mkdir -p "$(dirname "$ABS_OUTPUT")"
  jq -n \
    --argjson requested_issue "$ISSUE" \
    --argjson resolved_pr "$resolved_pr_json" \
    --argjson issue_pr_match "$ISSUE_PR_MATCH" \
    --argjson source "$source_json" \
    --arg run_id "$RUN_ID" \
    --argjson pid "$PID" \
    --arg output_path "$ABS_OUTPUT" \
    --arg started_at "$STARTED_AT" \
    --arg finished_at "$finished_at" \
    --argjson steps "$steps_json" \
    --argjson pass_count "$PASS_COUNT" \
    --argjson fail_count "$FAIL_COUNT" \
    --argjson skip_count "$SKIP_COUNT" \
    --argjson manual_required_count "$MANUAL_REQUIRED_COUNT" \
    --argjson partial_count "$PARTIAL_COUNT" \
    --argjson total_count "$TOTAL_COUNT" \
    --argjson error "$error_json" \
    --argjson warnings "$WARNINGS_JSON" \
    --argjson exit_code "$code" \
    '{
      inputs: {
        requested_issue: $requested_issue,
        resolved_pr: $resolved_pr,
        issue_pr_match: $issue_pr_match,
        source: $source,
        run_id: $run_id,
        pid: $pid,
        output_path: $output_path,
        started_at: $started_at,
        finished_at: $finished_at
      },
      steps: $steps,
      summary: {
        pass_count: $pass_count,
        fail_count: $fail_count,
        skip_count: $skip_count,
        manual_required_count: $manual_required_count,
        partial_count: $partial_count,
        total_count: $total_count
      },
      error: $error,
      warnings: $warnings,
      exit_code: $exit_code
    }' >"${ABS_OUTPUT}.tmp.${PID}"
  mv -f "${ABS_OUTPUT}.tmp.${PID}" "$ABS_OUTPUT"
  ln -sf "$ABS_OUTPUT" "$LATEST"

  if [[ "$code" -eq 0 ]]; then
    printf '✅ verify-issue #%s PASSED (pass=%s skip=%s)\n' \
      "$ISSUE" "$PASS_COUNT" "$SKIP_COUNT"
  else
    printf '❌ verify-issue #%s FAILED (fail=%s pass=%s skip=%s)\n' \
      "$ISSUE" "$FAIL_COUNT" "$PASS_COUNT" "$SKIP_COUNT"
  fi
  exit "$code"
}

# ─── Step 0: argument validation (exit 2, no JSON) ───
issue_arg="${1:-}"
if [[ -n "$issue_arg" ]]; then
  shift
fi
# Forward-compat: remaining positionals are reserved for future opt-in flags
# (e.g. --stop-on-first-fail). SubsCore EXTRA_ARGS parity.
# shellcheck disable=SC2034
EXTRA_ARGS=("$@")

ISSUE="${issue_arg:-$ENV_ISSUE}"
if [[ -z "$ISSUE" ]]; then
  printf 'ERROR: ISSUE required (usage: verify-issue.sh <ISSUE> | ISSUE=<N> make verify-issue)\n' >&2
  exit 2
fi
if [[ ! "$ISSUE" =~ ^[0-9]+$ ]]; then
  printf 'ERROR: ISSUE must be digits-only (got: %s)\n' "$ISSUE" >&2
  exit 2
fi
if [[ "$ISSUE" -eq 0 ]]; then
  printf 'ERROR: ISSUE must be a positive integer (got: 0)\n' >&2
  exit 2
fi

# ─── Step 0: prerequisite — jq (exit 3, no JSON: cannot build it without jq) ───
if ! jq --version >/dev/null 2>&1; then
  printf 'ERROR: jq_not_found — jq is required to build the result JSON; install jq and retry\n' >&2
  exit 3
fi

RUN_ID="${PID}-$(date -u +%s)"
STARTED_AT="$(now)"
STEPS_FILE="${LOGDIR}/verify-issue-${ISSUE}.${PID}.steps.ndjson"
: >"$STEPS_FILE"

# Resolve output path (env override > mktemp default) + absolute + latest ptr.
if [[ -n "${VERIFY_ISSUE_OUTPUT:-}" ]]; then
  OUTPUT_PATH="$VERIFY_ISSUE_OUTPUT"
else
  _base="$(mktemp "${LOGDIR}/verify-issue-${ISSUE}.XXXXXX")"
  OUTPUT_PATH="${_base}.json"
  rm -f "$_base"
fi
_odir="$(dirname "$OUTPUT_PATH")"
mkdir -p "$_odir"
ABS_OUTPUT="$(cd "$_odir" && pwd)/$(basename "$OUTPUT_PATH")"
LATEST="${LOGDIR}/verify-issue-${ISSUE}.latest.json"

# ─── Step 1: Issue -> PR resolution (2-state separation) ───
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
gh_err="${LOGDIR}/verify-issue-${ISSUE}.${PID}.gh.stderr"
pr_raw="$(gh pr list --head "$branch" --state all --json number --jq '.[0].number' 2>"$gh_err")"
gh_rc=$?
if [[ "$gh_rc" -ne 0 ]]; then
  ERR_CODE="gh_pr_lookup_failed"
  ERR_MSG="gh pr list failed (rc=${gh_rc}); not falling back (cannot confirm PR)"
  finish 3
fi

pr_num="$(printf '%s' "$pr_raw" | tr -d '[:space:]')"
if [[ "$pr_num" == "null" ]]; then
  pr_num=""
fi

if [[ -z "$pr_num" ]]; then
  # PR not created yet (normal): use detector --git merge-base fallback.
  SOURCE_VAL="merge-base-fallback"
  RESOLVED_PR=""
  ISSUE_PR_MATCH="false"
else
  SOURCE_VAL="pr-diff"
  RESOLVED_PR="$pr_num"
  pr_text="$(gh pr view "$pr_num" --json body,title -q '.body + " " + .title' 2>/dev/null || true)"
  if printf '%s' "$pr_text" | grep -Eq "#${ISSUE}([^0-9]|$)"; then
    ISSUE_PR_MATCH="true"
  else
    ISSUE_PR_MATCH="false"
    add_warning "pr_issue_mismatch"
    if [[ "${VERIFY_REQUIRE_PR_MATCH:-1}" != "0" ]]; then
      ERR_CODE="pr_issue_mismatch"
      ERR_MSG="PR #${pr_num} body/title does not reference #${ISSUE} (set VERIFY_REQUIRE_PR_MATCH=0 to downgrade to warning)"
      finish 3
    fi
  fi
fi

# ─── Step 2: change-aware category detection (delegate to 5-1 detector) ───
DETECTOR="${VERIFY_ISSUE_DETECTOR:-${SCRIPT_DIR}/verify-issue-detect.sh}"
det_err="${LOGDIR}/verify-issue-${ISSUE}.${PID}.detector.stderr"
if [[ ! -e "$DETECTOR" ]]; then
  ERR_CODE="detector_failed"
  ERR_MSG="detector not found: ${DETECTOR}"
  finish 3
fi

if [[ "$SOURCE_VAL" == "pr-diff" ]]; then
  det_out="$(gh pr diff "$RESOLVED_PR" --name-only 2>/dev/null | "$DETECTOR" --stdin --format flat 2>"$det_err")"
  det_rc=$?
else
  det_out="$("$DETECTOR" --git --format flat 2>"$det_err")"
  det_rc=$?
fi
if [[ "$det_rc" -ne 0 ]]; then
  ERR_CODE="detector_failed"
  ERR_MSG="verify-issue-detect.sh exited ${det_rc}"
  if [[ -s "$det_err" ]]; then
    ERR_DETECTOR_STDERR="$(cat "$det_err")"
  fi
  finish 3
fi

# Dedup categories, preserving first-seen order.
while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  if ! in_list "$line" "$DETECTED"; then
    DETECTED="${DETECTED:+$DETECTED }$line"
  fi
done <<<"$det_out"

# Reject any category the orchestrator's derived table does not know.
if [[ -n "$DETECTED" ]]; then
  read -ra _cats <<<"$DETECTED"
  for c in "${_cats[@]}"; do
    if ! known_category "$c"; then
      ERR_CODE="unknown_category"
      ERR_MSG="detector emitted an unknown category: ${c}"
      finish 3
    fi
  done
fi

# ─── Step 3-4: per-category verification (deduped make targets) + aggregate ───
run_make_step() {
  local name="$1" target="$2" cats="$3" partial="$4" notes="$5"
  local started so se rc finished status cats_json
  started="$(now)"
  so="${LOGDIR}/verify-issue-${ISSUE}.${PID}.${name}.stdout"
  se="${LOGDIR}/verify-issue-${ISSUE}.${PID}.${name}.stderr"
  if make "$target" >"$so" 2>"$se"; then
    rc=0
  else
    rc=$?
  fi
  finished="$(now)"
  if [[ "$rc" -eq 0 ]]; then
    status="pass"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    status="fail"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
  if [[ "$partial" == "true" ]]; then
    PARTIAL_COUNT=$((PARTIAL_COUNT + 1))
  fi
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  cats_json="$(csv_to_json_array "$cats")"
  append_step "$name" "make $target" "$status" "$rc" "$so" "$se" \
    "" "$partial" "$notes" "$cats_json" "$started" "$finished"
}

maybe_step() {
  local name="$1" target="$2" triggers="$3"
  local matched="" t partial="false" notes=""
  local trig_arr
  read -ra trig_arr <<<"$triggers"
  for t in "${trig_arr[@]}"; do
    if in_list "$t" "$DETECTED"; then
      matched="${matched:+$matched }$t"
    fi
  done
  [[ -z "$matched" ]] && return 0
  if [[ "$name" == "test-backend" ]] && in_list "migration-safety" "$matched"; then
    partial="true"
    notes="up/down not validated (migration-safety: CI-only scope)"
  fi
  run_make_step "$name" "$target" "$matched" "$partial" "$notes"
}

maybe_manual() {
  local name="$1" trigger="$2"
  in_list "$trigger" "$DETECTED" || return 0
  local started cats_json
  started="$(now)"
  cats_json="$(csv_to_json_array "$trigger")"
  SKIP_COUNT=$((SKIP_COUNT + 1))
  MANUAL_REQUIRED_COUNT=$((MANUAL_REQUIRED_COUNT + 1))
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  append_step "$name" "" "skip" "null" "" "" \
    "manual_required" "false" "" "$cats_json" "$started" "$(now)"
}

# Canonical order. One step per unique make target => dedup is structural
# (e.g. backend-unit + backend-integration + backend-core all share one
# `make test-backend` invocation).
maybe_step "test-backend" "test-backend" \
  "backend-unit backend-integration api-route api-contract backend-core migration-safety"
maybe_step "test-frontend" "test-frontend" \
  "api-contract frontend-ui frontend-logic frontend-shared"
maybe_step "traceability" "traceability" "docdd"
maybe_step "shell-lint" "shell-lint" "dx-config"
maybe_step "shell-format-check" "shell-format-check" "dx-config"
maybe_step "validate-claude" "validate-claude" "dx-docs"
maybe_manual "frontend-style-manual" "frontend-style"

# ─── Step 5-6: exit code + structured JSON output ───
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  finish 1
fi
finish 0
