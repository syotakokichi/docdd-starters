.PHONY: up down backend-shell test test-backend test-frontend traceability install install-dev
.PHONY: bootstrap
.PHONY: tf-init tf-plan tf-apply tf-destroy tf-output
.PHONY: deploy-backend-stg deploy-frontend-stg deploy-stg deploy-backend-prod deploy-frontend-prod deploy-prod
.PHONY: ecs-status ecs-logs-backend ecs-logs-frontend ecs-sh
.PHONY: shell-lint shell-format-check test-hooks verify-issue-detect verify-issue verify-issue-fixture test-harness
.PHONY: validate-claude validate-claude-strict

PYTHON ?= python3

# ─── Bootstrap ───────────────────────────────────────────

bootstrap:
	@./scripts/bootstrap.sh

# ─── Local Development ───────────────────────────────────

up:
	docker compose up --build

down:
	docker compose down

backend-shell:
	docker compose exec backend /bin/bash

# ─── Testing ─────────────────────────────────────────────

traceability:
	$(PYTHON) scripts/test/validate_traceability_map.py --map docs/testing/traceability/sample_map.json

validate-claude:
	./scripts/claude/validate-claude-config.sh

# strict mode: warnings (missing frontmatter etc.) are promoted to failures.
# CI safety-net (backstop); local proof paths intentionally stay on baseline
# (see scripts/claude/README.md "strict モード運用").
validate-claude-strict:
	./scripts/claude/validate-claude-config.sh --strict

test-backend:
	PYTHONPATH=apps/backend pytest tests/backend

test-frontend:
	cd apps/frontend && npm run lint:biome && npm run check:segments && npm run test:unit

test:
	PYTHONPATH=apps/backend pytest tests/backend
	cd apps/frontend && npm run lint:biome
	cd apps/frontend && npm run check:segments
	cd apps/frontend && npm run test:unit

install:
	npm --prefix apps/frontend install
	pip install -r apps/backend/requirements-dev.txt

install-dev:
	npm --prefix apps/frontend install
	pip install -r apps/backend/requirements-dev.txt

# ─── Shell QA ────────────────────────────────────────────

SHELL_FILES := .claude/hooks/block-dangerous.sh \
	.claude/hooks/protect-files.sh \
	.claude/hooks/detect-quality-issues.sh \
	scripts/bootstrap.sh \
	scripts/claude/detect-capabilities.sh \
	scripts/claude/validate-claude-config.sh \
	scripts/claude/verify-issue-detect.sh \
	scripts/claude/verify-issue.sh \
	scripts/deploy/terraform.sh \
	scripts/deploy/build-and-deploy.sh \
	scripts/github/bootstrap-labels.sh

shell-lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck --severity=warning $(SHELL_FILES); \
	else \
		echo "WARN: shellcheck not found, skipping shell-lint"; \
	fi

shell-format-check:
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -i 2 -ci -bn -d $(SHELL_FILES); \
	else \
		echo "WARN: shfmt not found, skipping shell-format-check"; \
	fi

test-hooks:
	@if command -v bats >/dev/null 2>&1; then \
		bats scripts/claude/test-hooks.bats; \
	else \
		echo "WARN: bats not found, skipping test-hooks"; \
	fi

verify-issue-detect:
	@if command -v bats >/dev/null 2>&1; then \
		bats scripts/claude/test/verify-issue-detect.bats; \
	elif [ "$$CI" = "true" ] || [ "$$VERIFY_DETECT_REQUIRE_BATS" = "1" ]; then \
		echo "ERROR: bats not found (required when CI=true or VERIFY_DETECT_REQUIRE_BATS=1)"; \
		exit 1; \
	else \
		echo "WARN: bats not found, skipping verify-issue-detect"; \
	fi

verify-issue:
	@scripts/claude/verify-issue.sh $(ISSUE) $(ARGS)

verify-issue-fixture:
	@if command -v bats >/dev/null 2>&1; then \
		bats scripts/claude/test/verify-issue.bats; \
	elif [ "$$CI" = "true" ] || [ "$$VERIFY_ISSUE_FIXTURE_REQUIRE_BATS" = "1" ]; then \
		echo "ERROR: bats not found (required when CI=true or VERIFY_ISSUE_FIXTURE_REQUIRE_BATS=1)"; \
		exit 1; \
	else \
		echo "WARN: bats not found, skipping verify-issue-fixture"; \
	fi

# Harness regression suite: asserts .claude/ configuration invariants
# (frontmatter strict, settings.json shape, hook bindings, terminology drift).
test-harness:
	@if command -v bats >/dev/null 2>&1; then \
		bats scripts/claude/test/harness-regression.bats; \
	elif [ "$$CI" = "true" ] || [ "$$HARNESS_REQUIRE_BATS" = "1" ]; then \
		echo "ERROR: bats not found (required when CI=true or HARNESS_REQUIRE_BATS=1)"; \
		exit 1; \
	else \
		echo "WARN: bats not found, skipping test-harness"; \
	fi

# ─── Terraform ───────────────────────────────────────────

ENV ?= stg

tf-init:
	./scripts/deploy/terraform.sh $(ENV) init

tf-plan:
	./scripts/deploy/terraform.sh $(ENV) plan

tf-apply:
	./scripts/deploy/terraform.sh $(ENV) apply

tf-destroy:
	./scripts/deploy/terraform.sh $(ENV) destroy

tf-output:
	./scripts/deploy/terraform.sh $(ENV) output

# ─── Deploy ──────────────────────────────────────────────

deploy-backend-stg:
	./scripts/deploy/build-and-deploy.sh backend stg

deploy-frontend-stg:
	./scripts/deploy/build-and-deploy.sh frontend stg

deploy-stg: deploy-backend-stg deploy-frontend-stg

deploy-backend-prod:
	./scripts/deploy/build-and-deploy.sh backend prod

deploy-frontend-prod:
	./scripts/deploy/build-and-deploy.sh frontend prod

deploy-prod: deploy-backend-prod deploy-frontend-prod

# ─── ECS Operations ─────────────────────────────────────

ECS_CLUSTER ?= $(PROJECT_NAME)-$(ENV)

ecs-status:
	aws ecs describe-services \
		--cluster $(ECS_CLUSTER) \
		--services backend frontend \
		--query 'services[].{name:serviceName,running:runningCount,desired:desiredCount,status:status}' \
		--output table

ecs-logs-backend:
	aws logs tail /ecs/$(ECS_CLUSTER)/backend --follow

ecs-logs-frontend:
	aws logs tail /ecs/$(ECS_CLUSTER)/frontend --follow

ecs-sh:
	aws ecs execute-command \
		--cluster $(ECS_CLUSTER) \
		--task $$(aws ecs list-tasks --cluster $(ECS_CLUSTER) --service-name backend --query 'taskArns[0]' --output text) \
		--container backend \
		--interactive \
		--command "/bin/sh"
