.PHONY: up down backend-shell

up:
	docker compose up --build

down:
	docker compose down

backend-shell:
	docker compose exec backend /bin/bash

traceability:
	python scripts/test/validate_traceability_map.py --map docs/testing/traceability/sample_map.json

test-backend:
	PYTHONPATH=apps/backend pytest tests/backend

install:
	npm --prefix apps/frontend install
	pip install -r apps/backend/requirements-dev.txt

install-dev:
	npm --prefix apps/frontend install
	pip install -r apps/backend/requirements-dev.txt

test:
	PYTHONPATH=apps/backend pytest tests/backend
	cd apps/frontend && npm run lint:biome
	cd apps/frontend && npm run check:segments
	cd apps/frontend && npm run test:unit
