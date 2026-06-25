# Deployment Guide

## First-time setup (local / dev)

```bash
# 1. Copy and fill in environment variables
cp .env.example .env
# Edit .env — change ALL passwords before proceeding

# 2. Build the custom Odoo image
docker compose build

# 3. Start the dev stack (HTTP only, ports exposed)
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# 4. Watch the logs until Odoo is ready (~60 s)
docker compose logs -f odoo

# 5. Open http://localhost and create the first database
```

## Production deployment

### Prerequisites

- Ubuntu 22.04 LTS server (min 8 GB RAM, 4 vCPU, 100 GB SSD)
- Docker 24+ and Docker Compose v2
- Domain DNS A-record pointing to server IP
- Port 80 and 443 open in firewall

### Steps

```bash
# 1. Clone the repo
git clone git@github.com:your-org/erpEBLICT.git /opt/erp
cd /opt/erp

# 2. Fill .env
cp .env.example .env && nano .env

# 3. Obtain SSL certificate (first run — before nginx starts)
certbot certonly --standalone -d $DOMAIN --email $CERTBOT_EMAIL --agree-tos

# 4. Pull all images and build
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull
docker compose -f docker-compose.yml -f docker-compose.prod.yml build

# 5. Start stack
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# 6. Verify health
./scripts/healthcheck.sh
```

### Enabling the read replica (optional)

```bash
docker compose --profile replica up -d postgres-replica
docker compose logs -f postgres-replica   # wait for "Base backup complete"
```

## Updating Odoo

```bash
# Pull latest base image and rebuild
docker compose build --no-cache odoo odoo-longpolling
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d odoo odoo-longpolling

# If modules need updating
docker compose exec odoo odoo -u all -d odoo --stop-after-init
docker compose start odoo odoo-longpolling
```

## Rollback

```bash
# Tag images before each deploy:
docker tag erp-odoo:17.0 erp-odoo:17.0-prev

# Rollback:
docker tag erp-odoo:17.0-prev erp-odoo:17.0
docker compose up -d odoo odoo-longpolling
```
