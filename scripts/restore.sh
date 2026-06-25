#!/usr/bin/env bash
# Usage: ./scripts/restore.sh <path-to-dump-file>
# Restores a pg_dump (custom-format) to the running postgres container.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

[ -f "$ROOT_DIR/.env" ] && source "$ROOT_DIR/.env"

DUMP_FILE="${1:-}"
if [ -z "$DUMP_FILE" ]; then
    echo "Usage: $0 <path-to-dump-file>"
    exit 1
fi

if [ ! -f "$DUMP_FILE" ]; then
    echo "File not found: $DUMP_FILE"
    exit 1
fi

echo ""
echo "  Restore target : ${POSTGRES_DB} on postgres container"
echo "  Dump file      : ${DUMP_FILE}"
echo ""
echo "WARNING: This will DROP and recreate the database."
read -rp "Type 'yes' to continue: " CONFIRM
[ "$CONFIRM" = "yes" ] || { echo "Aborted."; exit 0; }

# Stop Odoo workers to prevent connections during restore
echo "[restore] Stopping Odoo workers..."
docker compose -f "$ROOT_DIR/docker-compose.yml" stop odoo odoo-longpolling

# Terminate any remaining connections
echo "[restore] Terminating existing connections..."
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres \
    psql -U "${POSTGRES_USER}" -c \
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${POSTGRES_DB}' AND pid <> pg_backend_pid();" \
    postgres

# Drop and recreate
echo "[restore] Recreating database..."
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres \
    psql -U "${POSTGRES_USER}" -c "DROP DATABASE IF EXISTS ${POSTGRES_DB};" postgres
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres \
    psql -U "${POSTGRES_USER}" -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};" postgres

# Restore
echo "[restore] Restoring dump..."
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres \
    pg_restore \
        --username="${POSTGRES_USER}" \
        --dbname="${POSTGRES_DB}" \
        --no-owner \
        --role="${POSTGRES_USER}" \
    < "$DUMP_FILE"

# Restart Odoo
echo "[restore] Starting Odoo workers..."
docker compose -f "$ROOT_DIR/docker-compose.yml" start odoo odoo-longpolling

echo "[restore] Restore complete."
