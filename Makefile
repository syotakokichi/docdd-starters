.PHONY: up down backend-shell

up:
	docker compose up --build

down:
	docker compose down

backend-shell:
	docker compose exec backend /bin/bash
