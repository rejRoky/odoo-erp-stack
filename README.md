# odoo-erp-stack

Production-grade Odoo 17 ERP on Docker — PostgreSQL 16, PgBouncer, Redis, NGINX, and a full observability stack.

---

## Stack

| Service | Technology | Role |
|---|---|---|
| ERP | Odoo 17 | Application server |
| Database | PostgreSQL 16 | Primary (RW) + optional replica (RO) |
| Connection pool | PgBouncer | Transaction-mode pooling |
| Cache / Sessions | Redis 7 | ORM cache + session store |
| Reverse proxy | NGINX 1.25 | SSL termination, rate limiting, gzip |
| Metrics | Prometheus + Grafana | Dashboards and alerting |
| Logs | Loki + Promtail | Log aggregation |
| Containers | Portainer CE | Container management UI |

---

## Quick start (development)

```bash
# 1. Clone
git clone https://github.com/rejRoky/odoo-erp-stack.git
cd odoo-erp-stack

# 2. Configure environment
cp .env.example .env
# Edit .env — change all CHANGE_ME values

# 3. Build custom Odoo image
docker compose build

# 4. Start dev stack (HTTP, ports exposed)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# 5. Follow logs until ready (~60 s)
docker compose logs -f odoo

# 6. Open http://localhost — create the first database
```

---

## Production deployment

See [docs/DEPLOY.md](docs/DEPLOY.md) for the full guide.

```bash
# Pull, build, start with resource limits and SSL
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Directory structure

```
odoo-erp-stack/
├── docker-compose.yml          # Base services
├── docker-compose.prod.yml     # Production overrides (resource limits, SSL)
├── docker-compose.dev.yml      # Dev overrides (exposed ports, HTTP only)
├── .env.example                # Environment variable template
├── Makefile                    # Convenience commands
├── nginx/                      # NGINX reverse proxy config
├── postgres/                   # PostgreSQL tuning, pg_hba, init scripts
├── redis/                      # Redis config
├── odoo/                       # Dockerfile, entrypoint, odoo.conf template
├── addons/                     # Custom Odoo modules
│   ├── custom_accounting/
│   ├── custom_hr/
│   ├── custom_inventory/
│   ├── custom_reports/
│   └── custom_api/
├── monitoring/
│   ├── prometheus/
│   ├── grafana/
│   ├── loki/
│   └── promtail/
├── scripts/                    # backup.sh, restore.sh, healthcheck.sh
└── docs/                       # DEPLOY.md, ARCHITECTURE.md, RUNBOOK.md
```

---

## Makefile commands

```bash
make up              # Start all services
make down            # Stop all services
make dev-up          # Start with dev overrides
make prod-up         # Start with prod overrides
make logs            # Tail logs
make ps              # Service status
make build           # Rebuild Odoo image
make shell           # Bash into Odoo container
make psql            # psql into PostgreSQL
make backup          # Run backup script
make health          # Run healthcheck
make update-addons   # Update all Odoo modules (DB=odoo)
```

---

## Environment variables

Copy `.env.example` to `.env` and set:

| Variable | Description |
|---|---|
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `REDIS_PASSWORD` | Redis password |
| `ODOO_MASTER_PASSWORD` | Odoo master (database manager) password |
| `GRAFANA_PASSWORD` | Grafana admin password |
| `DOMAIN` | Production domain name |
| `S3_BUCKET` | S3 bucket name for backups |

---

## Scaling

**More Odoo workers** — increase `workers` in `odoo/odoo.conf.template`, rebuild.

**Read replica** — `docker compose --profile replica up -d postgres-replica`

**Horizontal scale** — add a second Odoo container and include it in the NGINX upstream block.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

---

## Docs

- [Deployment guide](docs/DEPLOY.md)
- [Architecture overview](docs/ARCHITECTURE.md)
- [Operations runbook](docs/RUNBOOK.md)

---

## License

MIT
