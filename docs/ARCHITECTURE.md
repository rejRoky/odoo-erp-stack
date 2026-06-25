# Architecture Overview

## Stack

```
Internet → NGINX (SSL, rate-limit, gzip)
              ├── /               → Odoo HTTP workers  (port 8069)
              ├── /longpolling/   → Odoo gevent worker (port 8072)
              ├── /grafana/       → Grafana
              └── /portainer/     → Portainer

Odoo workers → PgBouncer (pool) → PostgreSQL 16 primary
                                → PostgreSQL 16 replica (read, optional)

Odoo workers → Redis 7 (sessions + ORM cache)

Prometheus ← postgres-exporter, redis-exporter, nginx-exporter
Grafana    ← Prometheus (metrics), Loki (logs)
Loki       ← Promtail (Docker logs + Odoo log files)
```

## Key decisions

| Decision | Reason |
|---|---|
| PgBouncer in transaction mode | Odoo opens many short-lived connections; pooling reduces Postgres overhead |
| Redis for sessions | Allows multiple Odoo workers to share sessions without sticky sessions in NGINX |
| Odoo gevent as a separate container | Keeps long-polling from consuming HTTP worker slots |
| `list_db = False` | Hides the DB selector on the login page — production security requirement |
| `proxy_mode = True` | Tells Odoo to trust `X-Forwarded-*` headers from NGINX |
| Replica under a Docker profile | Keeps dev simple; enable only when replication is needed |

## Scaling playbook

### Horizontal Odoo workers

Add a second Odoo instance and add it to the NGINX upstream:

```nginx
upstream odoo_backend {
    server odoo:8069;
    server odoo2:8069;   # new container
    keepalive 16;
}
```

### Vertical DB

Adjust `postgresql.conf` memory values to match the new server RAM and restart:

```bash
docker compose restart postgres
```

### Redis Sentinel (HA)

Replace the single Redis container with three containers using
`redis:7-alpine` in Sentinel mode. Update `REDIS_ADDR` in the
redis-exporter service accordingly.
