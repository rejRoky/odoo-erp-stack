# ERP Software Plan — Odoo Production-Grade Stack

## Project Overview

A scalable, high-data-capacity ERP system built on Odoo 17 Community/Enterprise,
containerized with Docker, backed by PostgreSQL with caching, load balancing, and
full observability. Designed for production from day one.

---

## Phase 0 — Prerequisites & Tooling Setup

- [ ] Install Docker Desktop (Windows) + WSL2 backend
- [ ] Install Docker Compose v2
- [ ] Install Git + configure SSH key for repo
- [ ] Install VS Code + Remote Containers extension
- [ ] Set up a private Git repository (GitHub / GitLab)
- [ ] Install `make` (via chocolatey or WSL2) for Makefile automation
- [ ] Install `pgAdmin 4` or `DBeaver` for DB inspection
- [ ] Register a domain name (for production SSL)
- [ ] Obtain wildcard SSL certificate (Let's Encrypt / Certbot)

---

## Phase 1 — Core Infrastructure Design

### 1.1 Docker Stack Architecture

```text
┌───────────────────────────────────────────────────────┐
│                    NGINX Reverse Proxy                │
│              (SSL termination, load balancing)        │
└──────────────┬────────────────────┬───────────────────┘
               │                    │
       ┌───────▼──────┐    ┌────────▼──────┐
       │  Odoo App 1  │    │  Odoo App 2   │  ← horizontal scale
       └───────┬──────┘    └────────┬──────┘
               └────────┬───────────┘
                        │
          ┌─────────────▼──────────────┐
          │     Redis (Cache + Session) │
          └─────────────┬──────────────┘
                        │
          ┌─────────────▼──────────────┐
          │  PostgreSQL Primary (RW)   │
          └─────────────┬──────────────┘
                        │
          ┌─────────────▼──────────────┐
          │  PostgreSQL Replica (RO)   │  ← read replicas
          └────────────────────────────┘
```

- [ ] Design `docker-compose.yml` with the above services
- [ ] Design `docker-compose.prod.yml` override for production
- [ ] Design `docker-compose.dev.yml` override for local development
- [ ] Create `.env.example` with all required environment variables
- [ ] Create `Makefile` with commands: `up`, `down`, `logs`, `shell`, `backup`, `restore`

### 1.2 Service Inventory

| Service          | Image                  | Role                        |
|------------------|------------------------|-----------------------------|
| nginx            | nginx:1.25-alpine      | Reverse proxy / SSL         |
| odoo             | odoo:17.0              | ERP application server      |
| postgres         | postgres:16-alpine     | Primary database (RW)       |
| postgres-replica | postgres:16-alpine     | Read replica (RO)           |
| redis            | redis:7-alpine         | Session + ORM cache         |
| certbot          | certbot/certbot        | SSL certificate renewal     |
| pgbouncer        | bitnami/pgbouncer      | Connection pooling          |
| portainer        | portainer/portainer-ce | Container management UI     |
| prometheus       | prom/prometheus        | Metrics collection          |
| grafana          | grafana/grafana        | Metrics dashboard           |
| loki             | grafana/loki           | Log aggregation             |
| promtail         | grafana/promtail       | Log shipping                |

---

## Phase 2 — PostgreSQL Setup (High-Data Optimized)

- [ ] Configure `postgresql.conf` for high-throughput:
  - `max_connections = 200`
  - `shared_buffers = 4GB` (25% of RAM)
  - `effective_cache_size = 12GB`
  - `work_mem = 64MB`
  - `maintenance_work_mem = 1GB`
  - `wal_level = replica`
  - `max_wal_senders = 5`
  - `checkpoint_completion_target = 0.9`
  - `random_page_cost = 1.1` (SSD tuning)
- [ ] Configure `pg_hba.conf` for replica and app access
- [ ] Set up streaming replication (primary → replica)
- [ ] Configure PgBouncer connection pooling (transaction mode)
  - Pool size: 20 per database
  - Max client connections: 500
- [ ] Configure automated WAL archiving for PITR backups
- [ ] Create dedicated DB user for Odoo (least privilege)
- [ ] Enable `pg_stat_statements` extension for query profiling
- [ ] Create indexes strategy document per Odoo module

---

## Phase 3 — Redis Cache Configuration

- [ ] Deploy Redis 7 with `maxmemory-policy allkeys-lru`
- [ ] Configure `maxmemory = 2gb`
- [ ] Enable Redis persistence (RDB snapshots every 5 min)
- [ ] Configure Redis password authentication
- [ ] Wire Odoo to use Redis for:
  - HTTP sessions (`--db_maxconn` + session store)
  - ORM cache (via `--limit-memory-hard`)
  - Long-polling / bus (Odoo live chat, notifications)
- [ ] Set up Redis Sentinel or Redis Cluster for HA (production)
- [ ] Configure Redis monitoring via prometheus redis_exporter

---

## Phase 4 — Odoo Application Server

### 4.1 Odoo Configuration

- [ ] Create custom `odoo.conf`:

  ```ini
  [options]
  db_host = pgbouncer
  db_port = 5432
  db_user = odoo
  db_password = <from env>
  db_maxconn = 32
  workers = 4              ; (2 * CPU cores) + 1
  max_cron_threads = 2
  limit_memory_hard = 2684354560
  limit_memory_soft = 2147483648
  limit_request = 8192
  limit_time_cpu = 60
  limit_time_real = 120
  longpolling_port = 8072
  proxy_mode = True
  logfile = /var/log/odoo/odoo.log
  log_level = warn
  ```

- [ ] Configure Odoo multi-worker mode (gevent for long-polling)
- [ ] Mount `/var/lib/odoo` as named Docker volume (persistent filestore)
- [ ] Mount `/mnt/extra-addons` for custom modules

### 4.2 Custom Addons Structure

- [ ] Create `addons/` directory in project root
- [ ] Create `addons/__manifest__.py` scaffold for each custom module
- [ ] Planned custom modules:
  - [ ] `custom_accounting` — localized accounting rules
  - [ ] `custom_hr` — HR extensions
  - [ ] `custom_inventory` — warehouse logic
  - [ ] `custom_reports` — PDF/XLSX report templates
  - [ ] `custom_api` — REST API bridge (JSON-RPC wrapper)

### 4.3 Odoo Modules to Install

- [ ] **Accounting & Finance** — Invoicing, Payments, Bank Sync
- [ ] **Sales** — CRM, Sales Orders, Quotations
- [ ] **Purchase** — Purchase Orders, Vendor Bills
- [ ] **Inventory** — Stock, Warehouses, Logistics
- [ ] **Manufacturing** — BOM, Work Orders (if needed)
- [ ] **HR & Payroll** — Employees, Leaves, Payslips
- [ ] **Project** — Tasks, Timesheets
- [ ] **Point of Sale** — (if retail)
- [ ] **Discuss** — Internal messaging
- [ ] **Sign** — Digital signatures

---

## Phase 5 — NGINX Reverse Proxy

- [ ] Create `nginx/nginx.conf` with:
  - HTTP → HTTPS redirect
  - SSL/TLS with TLS 1.2/1.3 only
  - HSTS headers
  - Gzip compression
  - Upstream block pointing to Odoo workers
  - `/longpolling/` proxied to port 8072 (gevent worker)
  - Static file serving (`/web/static/`) with aggressive caching
  - Rate limiting (login endpoint: 10 req/min)
  - `proxy_read_timeout 720s`
- [ ] Configure Let's Encrypt auto-renewal via Certbot container
- [ ] Add security headers: `X-Frame-Options`, `X-Content-Type-Options`, `CSP`
- [ ] Configure upstream health checks

---

## Phase 6 — Backup & Disaster Recovery

- [ ] Write `scripts/backup.sh`:
  - `pg_dump` → gzip → upload to S3/Backblaze B2
  - Odoo filestore tar → upload to S3/Backblaze B2
  - Rotate backups: keep 7 daily, 4 weekly, 3 monthly
- [ ] Write `scripts/restore.sh` with interactive DB selection
- [ ] Configure cron inside container for automated backups (2 AM daily)
- [ ] Test restore procedure — document RTO/RPO targets
- [ ] Enable PostgreSQL PITR (Point-in-Time Recovery) via WAL archiving
- [ ] Store backup credentials in `.env` / Docker secrets
- [ ] Set up offsite backup destination (S3-compatible bucket)

---

## Phase 7 — Observability & Monitoring

### 7.1 Metrics (Prometheus + Grafana)

- [ ] Deploy Prometheus — scrape targets:
  - `postgres_exporter` (DB metrics)
  - `redis_exporter` (Redis metrics)
  - `nginx-prometheus-exporter` (request rates, errors)
  - `node_exporter` (host CPU/RAM/disk)
- [ ] Deploy Grafana — import dashboards:
  - PostgreSQL dashboard (ID: 9628)
  - Redis dashboard (ID: 763)
  - NGINX dashboard (ID: 12708)
  - Node Exporter dashboard (ID: 1860)
- [ ] Configure Grafana alerting → email / Slack webhook

### 7.2 Logging (Loki + Promtail)

- [ ] Deploy Loki as log aggregation backend
- [ ] Deploy Promtail to ship logs from:
  - Odoo container (`/var/log/odoo/odoo.log`)
  - NGINX access + error logs
  - PostgreSQL logs
- [ ] Configure Grafana Loki datasource
- [ ] Create log-based alerts (error rate, slow queries)

### 7.3 Health Checks

- [ ] Add `HEALTHCHECK` to all Dockerfiles / compose services
- [ ] Write `scripts/healthcheck.sh` for smoke testing
- [ ] Configure Portainer for container restart policies

---

## Phase 8 — Security Hardening

- [ ] Run all containers as non-root users
- [ ] Set `read_only: true` on containers where possible
- [ ] Use Docker secrets for DB passwords, API keys
- [ ] Configure UFW / Windows Firewall — expose only 80, 443
- [ ] Disable Odoo master password in production (or use strong password)
- [ ] Disable Odoo database manager UI in production (`dbfilter`, `list_db = False`)
- [ ] Enable fail2ban for NGINX (brute force on `/web/login`)
- [ ] Scan images with `docker scout` or Trivy before deployment
- [ ] Set `Content-Security-Policy` headers in NGINX
- [ ] Rotate all secrets before go-live

---

## Phase 9 — CI/CD Pipeline

- [ ] Create `.github/workflows/` (or GitLab CI `.gitlab-ci.yml`):
  - `lint.yml` — run `flake8` + `eslint` on custom addons
  - `test.yml` — run Odoo unit tests in isolated container
  - `build.yml` — build and push custom Docker image to registry
  - `deploy.yml` — SSH into server, `docker compose pull && docker compose up -d`
- [ ] Tag Docker images with git SHA (`odoo-erp:abc1234`)
- [ ] Store secrets in GitHub Actions / GitLab CI variables
- [ ] Set up staging environment (mirrors production stack)
- [ ] Write deployment runbook in `docs/DEPLOY.md`

---

## Phase 10 — Scalability & Performance

- [ ] Tune Odoo workers based on load testing results
- [ ] Configure horizontal scaling: add Odoo worker containers behind NGINX upstream
- [ ] Set up PostgreSQL read routing (analytics queries → replica)
- [ ] Add Redis Cluster for session store at scale
- [ ] Run `pgBadger` on PostgreSQL logs for slow query analysis
- [ ] Use `EXPLAIN ANALYZE` on top-10 slowest Odoo queries
- [ ] Consider Odoo.sh or cloud migration path (AWS ECS / GCP GKE) if needed
- [ ] Load test with `locust` or `k6` before go-live

---

## Phase 11 — Go-Live Checklist

- [ ] All services healthy (`docker compose ps`)
- [ ] SSL certificate valid and auto-renewing
- [ ] Backup tested and verified (restore dry-run passed)
- [ ] Monitoring dashboards active and alerting configured
- [ ] Security scan passed (no critical CVEs in images)
- [ ] Admin password changed from default
- [ ] Database manager UI disabled
- [ ] Odoo master password secured
- [ ] DNS records pointing to production server
- [ ] Load test completed (target: 200 concurrent users)
- [ ] Runbook documented and shared with team
- [ ] Rollback procedure tested

---

## Directory Structure

```text
erpEBLICT/
├── docker-compose.yml            # Base services
├── docker-compose.prod.yml       # Production overrides
├── docker-compose.dev.yml        # Dev overrides
├── Makefile                      # Convenience commands
├── .env.example                  # Environment template
├── .env                          # Local secrets (gitignored)
├── nginx/
│   ├── nginx.conf
│   └── ssl/
├── postgres/
│   ├── postgresql.conf
│   ├── pg_hba.conf
│   └── init.sql
├── pgbouncer/
│   └── pgbouncer.ini
├── redis/
│   └── redis.conf
├── odoo/
│   ├── odoo.conf
│   └── Dockerfile                # Custom Odoo image
├── addons/                       # Custom Odoo modules
│   ├── custom_accounting/
│   ├── custom_hr/
│   ├── custom_inventory/
│   ├── custom_reports/
│   └── custom_api/
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   └── healthcheck.sh
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── grafana/
│   │   └── provisioning/
│   └── loki/
│       └── loki-config.yml
├── docs/
│   ├── DEPLOY.md
│   ├── ARCHITECTURE.md
│   └── RUNBOOK.md
└── to-do-list.md
```

---

## Tech Stack Summary

| Layer           | Technology                        |
|-----------------|-----------------------------------|
| ERP Application | Odoo 17 (Community or Enterprise) |
| Language        | Python 3.11 / JavaScript          |
| Database        | PostgreSQL 16                     |
| Connection Pool | PgBouncer                         |
| Cache / Session | Redis 7                           |
| Reverse Proxy   | NGINX 1.25                        |
| Containerization| Docker + Docker Compose           |
| SSL             | Let's Encrypt (Certbot)           |
| Monitoring      | Prometheus + Grafana              |
| Logging         | Loki + Promtail                   |
| CI/CD           | GitHub Actions / GitLab CI        |
| Backup Storage  | S3-compatible (Backblaze B2 / AWS)|
| Container Mgmt  | Portainer CE                      |

---

## Priority Order (Start Here)

1. Phase 0 — Install all tools
2. Phase 1 — Write `docker-compose.yml` skeleton
3. Phase 2 — PostgreSQL + PgBouncer configuration
4. Phase 3 — Redis configuration
5. Phase 4 — Odoo container + `odoo.conf`
6. Phase 5 — NGINX + SSL
7. Phase 6 — Backup scripts
8. Phase 7 — Monitoring stack
9. Phase 8 — Security hardening
10. Phase 9 — CI/CD pipeline
11. Phase 10 — Scalability tuning
12. Phase 11 — Go-live
