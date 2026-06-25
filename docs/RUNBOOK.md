# Operations Runbook

## Daily checks

```bash
./scripts/healthcheck.sh        # overall health
docker compose ps               # container state
docker compose logs --tail=50 odoo  # recent Odoo errors
```

## Common operations

### Restart a single service

```bash
docker compose restart odoo
```

### Enter a running container

```bash
docker compose exec odoo bash
docker compose exec postgres psql -U $POSTGRES_USER -d $POSTGRES_DB
docker compose exec redis redis-cli -a $REDIS_PASSWORD
```

### Run an Odoo shell (Python REPL)

```bash
docker compose exec odoo odoo shell -d odoo
```

### Force-update all installed modules

```bash
docker compose exec odoo odoo -u all -d odoo --stop-after-init
docker compose restart odoo odoo-longpolling
```

### Manual backup

```bash
./scripts/backup.sh
```

### Restore from a dump

```bash
./scripts/restore.sh /path/to/db_20260101_020000.dump
```

## Incident response

### Odoo is down / 502 from NGINX

1. `docker compose ps` — check which container is stopped/unhealthy
2. `docker compose logs --tail=100 odoo` — look for Python tracebacks
3. If OOM: increase `limit_memory_hard` in `odoo/odoo.conf.template` and rebuild
4. Restart: `docker compose restart odoo odoo-longpolling`

### Postgres is full / slow

1. Check disk: `docker system df`
2. Check long-running queries:

   ```sql
   SELECT pid, now() - pg_stat_activity.query_start AS duration, query
   FROM pg_stat_activity
   WHERE state = 'active' AND duration > interval '5 minutes';
   ```

3. Kill stuck query: `SELECT pg_terminate_backend(<pid>);`
4. Run `VACUUM ANALYZE` on large tables if needed.

### Redis memory pressure

1. `docker compose exec redis redis-cli -a $REDIS_PASSWORD INFO memory`
2. If usage > 80 %: `docker compose exec redis redis-cli -a $REDIS_PASSWORD FLUSHDB` (clears sessions — users will be logged out)
3. Long term: increase `maxmemory` in `redis/redis.conf`

## Monitoring URLs (production)

| Service    | URL                         |
|------------|-----------------------------|
| Odoo       | https://yourdomain.com      |
| Grafana    | https://yourdomain.com/grafana/  |
| Portainer  | https://yourdomain.com/portainer/ |
| Prometheus | internal only (port 9090)   |
