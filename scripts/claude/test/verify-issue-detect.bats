#!/usr/bin/env bats
# scripts/claude/test/verify-issue-detect.bats
#
# Fixture tests for scripts/claude/verify-issue-detect.sh (Issue #61).
#
# Coverage matrix (per /plan):
#   - All 13 evidence categories x 1+ case each
#   - Input modes: --stdin / --files / --git
#   - Shape variation: presentation/ + infrastructure/ (old SubsCore)
#                  vs. api/ + repositories/ (new docdd-starters)
#   - Default-branch fallback (main missing -> origin/main)
#   - --format manifest (path: categories) and --format flat dedup
#
# 真の SSOT: .claude/templates/issue-implementation-plan.md「🗺️ 証跡マッピング表」

DETECTOR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)/verify-issue-detect.sh"

setup() {
  TMPDIR_BATS="$(mktemp -d)"
}

teardown() {
  if [[ -n "${TMPDIR_BATS:-}" && -d "$TMPDIR_BATS" ]]; then
    rm -rf "$TMPDIR_BATS"
  fi
}

# ─── 1. backend-unit ──────────────────────────────────────

@test "category: backend-unit (modules/<domain>/domain/)" {
  result=$(echo "apps/backend/app/modules/example/domain/foo.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "backend-unit"
}

@test "category: backend-unit (modules/<domain>/services/)" {
  result=$(echo "apps/backend/app/modules/example/services/foo.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "backend-unit"
}

# ─── 2. backend-integration ───────────────────────────────

@test "category: backend-integration (modules/<domain>/repositories/)" {
  result=$(echo "apps/backend/app/modules/example/repositories/repo.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "backend-integration"
}

@test "category: backend-integration (apps/backend/app/infrastructure/)" {
  result=$(echo "apps/backend/app/infrastructure/db.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "backend-integration"
}

# ─── 3. api-route ─────────────────────────────────────────

@test "category: api-route (modules/<domain>/api/)" {
  result=$(echo "apps/backend/app/modules/example/api/routes.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-route"
}

@test "category: api-route (middlewares/)" {
  result=$(echo "apps/backend/app/middlewares/auth.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-route"
}

# ─── 4. api-contract ──────────────────────────────────────

@test "category: api-contract (modules/<domain>/schemas/)" {
  result=$(echo "apps/backend/app/modules/example/schemas/user.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-contract"
}

@test "category: api-contract (contracts/)" {
  result=$(echo "apps/backend/app/contracts/dto.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-contract"
}

@test "category: api-contract (frontend src/types/)" {
  result=$(echo "apps/frontend/src/types/user.ts" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-contract"
}

@test "category: api-contract (frontend route-local _types/)" {
  result=$(echo "apps/frontend/app/(main)/dashboard/_types/user.ts" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-contract"
}

# ─── 5. backend-core ──────────────────────────────────────

@test "category: backend-core (kernel/)" {
  result=$(echo "apps/backend/app/kernel/config.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "backend-core"
}

@test "category: backend-core (shared/)" {
  result=$(echo "apps/backend/app/shared/utils.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "backend-core"
}

# ─── 6. migration-safety ──────────────────────────────────

@test "category: migration-safety (alembic/versions/)" {
  result=$(echo "apps/backend/alembic/versions/abc123_add_users.py" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "migration-safety"
}

# ─── 7. frontend-ui ───────────────────────────────────────

@test "category: frontend-ui (app/**/page.tsx)" {
  result=$(echo "apps/frontend/app/(main)/dashboard/page.tsx" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-ui"
}

@test "category: frontend-ui (app/**/_components/)" {
  result=$(echo "apps/frontend/app/(main)/dashboard/_components/Header.tsx" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-ui"
}

@test "category: frontend-ui (src/components/)" {
  result=$(echo "apps/frontend/src/components/ui/Button.tsx" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-ui"
}

# ─── 8. frontend-logic ────────────────────────────────────

@test "category: frontend-logic (app/**/_hooks/)" {
  result=$(echo "apps/frontend/app/(main)/dashboard/_hooks/use-foo.ts" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-logic"
}

@test "category: frontend-logic (app/**/_actions/)" {
  result=$(echo "apps/frontend/app/(main)/dashboard/_actions/save.ts" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-logic"
}

# ─── 9. frontend-shared ───────────────────────────────────

@test "category: frontend-shared (src/lib/)" {
  result=$(echo "apps/frontend/src/lib/api-client.ts" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-shared"
}

@test "category: frontend-shared (src/store/)" {
  result=$(echo "apps/frontend/src/store/user.ts" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-shared"
}

# ─── 10. frontend-style ───────────────────────────────────

@test "category: frontend-style (app/globals.css)" {
  result=$(echo "apps/frontend/app/globals.css" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-style"
}

@test "category: frontend-style (tailwind.config.ts)" {
  result=$(echo "apps/frontend/tailwind.config.ts" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "frontend-style"
}

# ─── 11. docdd ────────────────────────────────────────────

@test "category: docdd (docs/7-axis/)" {
  result=$(echo "docs/7-axis/3_DM/DM-User.md" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "docdd"
}

@test "category: docdd (docs/testing/traceability/)" {
  result=$(echo "docs/testing/traceability/sample_map.json" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "docdd"
}

# ─── 12. dx-config ────────────────────────────────────────

@test "category: dx-config (scripts/)" {
  result=$(echo "scripts/bootstrap.sh" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "dx-config"
}

@test "category: dx-config (Makefile)" {
  result=$(echo "Makefile" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "dx-config"
}

@test "category: dx-config (.claude/hooks/)" {
  result=$(echo ".claude/hooks/block-dangerous.sh" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "dx-config"
}

# ─── 13. dx-docs ──────────────────────────────────────────

@test "category: dx-docs (.claude/commands/)" {
  result=$(echo ".claude/commands/plan.md" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "dx-docs"
}

@test "category: dx-docs (.claude/skills/)" {
  result=$(echo ".claude/skills/agent-teams/SKILL.md" | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "dx-docs"
}

# ─── Input modes ──────────────────────────────────────────

@test "input mode: --stdin (multi-line)" {
  result=$(printf 'apps/backend/app/modules/example/domain/foo.py\ndocs/7-axis/3_DM/DM-User.md\n' | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "backend-unit"
  echo "$result" | grep -qx "docdd"
}

@test "input mode: --files (multiple args)" {
  result=$("$DETECTOR" --files "apps/backend/app/modules/example/domain/foo.py" "docs/7-axis/3_DM/DM-User.md")
  echo "$result" | grep -qx "backend-unit"
  echo "$result" | grep -qx "docdd"
}

@test "input mode: --git (with VERIFY_BASE_REF override)" {
  cd "$TMPDIR_BATS"
  git init -q
  git config user.email "bats@test"
  git config user.name "bats"
  mkdir -p apps/backend/app/modules/example/domain
  echo "v1" > apps/backend/app/modules/example/domain/foo.py
  git add -A
  git commit -q -m "init"
  echo "v2" > apps/backend/app/modules/example/domain/foo.py
  git add -A
  git commit -q -m "change"

  result=$(VERIFY_BASE_REF=HEAD~1 "$DETECTOR" --git)
  echo "$result" | grep -qx "backend-unit"
}

# ─── Shape variation ──────────────────────────────────────

@test "shape variation: old SubsCore (presentation/ + infrastructure/) detected" {
  result=$(printf 'apps/backend/app/modules/example/presentation/route.py\napps/backend/app/modules/example/infrastructure/repo.py\n' | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-route"
  echo "$result" | grep -qx "backend-integration"
}

@test "shape variation: new docdd-starters (api/ + repositories/) detected" {
  result=$(printf 'apps/backend/app/modules/example/api/routes.py\napps/backend/app/modules/example/repositories/repo.py\n' | "$DETECTOR" --stdin)
  echo "$result" | grep -qx "api-route"
  echo "$result" | grep -qx "backend-integration"
}

# ─── Default-branch fallback (--git) ──────────────────────

@test "default-branch fallback: missing main, falls back to origin/main" {
  cd "$TMPDIR_BATS"
  git init -q -b feature
  git config user.email "bats@test"
  git config user.name "bats"
  mkdir -p apps/backend/app/modules/example/domain
  echo "v1" > apps/backend/app/modules/example/domain/foo.py
  git add -A
  git commit -q -m "init"

  # Simulate origin/main pointing to the initial commit; no local main branch.
  git update-ref refs/remotes/origin/main HEAD

  echo "v2" > apps/backend/app/modules/example/domain/foo.py
  git add -A
  git commit -q -m "change"

  unset VERIFY_BASE_REF || true
  result=$("$DETECTOR" --git)
  echo "$result" | grep -qx "backend-unit"
}

# ─── Output format ────────────────────────────────────────

@test "format: --format manifest emits 'path: categories'" {
  result=$(echo "apps/backend/app/modules/example/domain/foo.py" | "$DETECTOR" --stdin --format manifest)
  echo "$result" | grep -qx "apps/backend/app/modules/example/domain/foo.py: backend-unit"
}

@test "format: --format flat dedupes categories" {
  result=$(printf 'apps/backend/app/modules/example/domain/a.py\napps/backend/app/modules/example/domain/b.py\n' | "$DETECTOR" --stdin)
  count=$(echo "$result" | grep -cx "backend-unit")
  [ "$count" -eq 1 ]
}
