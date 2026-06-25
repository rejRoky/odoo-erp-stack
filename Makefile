.PHONY: up down restart logs ps build pull shell odoo-shell update-addons \
        dev-up prod-up backup restore health init-env

# ── Core ──────────────────────────────────────────────────────────
up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f --tail=100

ps:
	docker compose ps

# ── Build ──────────────────────────────────────────────────────────
build:
	docker compose build --no-cache

pull:
	docker compose pull

# ── Environments ──────────────────────────────────────────────────
dev-up:
	docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

prod-up:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# ── Shells ────────────────────────────────────────────────────────
shell:
	docker compose exec odoo bash

odoo-shell:
	docker compose exec odoo odoo shell -d $(DB)

psql:
	docker compose exec postgres psql -U $$POSTGRES_USER -d $$POSTGRES_DB

redis-cli:
	docker compose exec redis redis-cli -a $$REDIS_PASSWORD

# ── Odoo ──────────────────────────────────────────────────────────
update-addons:
	docker compose exec odoo odoo -u all -d $(DB) --stop-after-init

install-addon:
	docker compose exec odoo odoo -i $(MODULE) -d $(DB) --stop-after-init

# ── Maintenance ───────────────────────────────────────────────────
backup:
	./scripts/backup.sh

restore:
	./scripts/restore.sh $(FILE)

health:
	./scripts/healthcheck.sh

# ── First-time setup ──────────────────────────────────────────────
init-env:
	@if [ ! -f .env ]; then cp .env.example .env && echo ".env created — edit it before running make up"; else echo ".env already exists"; fi

replica-up:
	docker compose --profile replica up -d postgres-replica
