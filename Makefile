.PHONY: up down backend-shell test test-backend test-frontend traceability install install-dev
.PHONY: bootstrap
.PHONY: tf-init tf-plan tf-apply tf-destroy tf-output
.PHONY: deploy-backend-stg deploy-frontend-stg deploy-stg deploy-backend-prod deploy-frontend-prod deploy-prod
.PHONY: ecs-status ecs-logs-backend ecs-logs-frontend ecs-sh

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
	python scripts/test/validate_traceability_map.py --map docs/testing/traceability/sample_map.json

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
