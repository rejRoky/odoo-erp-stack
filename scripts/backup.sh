#!/usr/bin/env bash
# Usage: ./scripts/backup.sh
# Backs up PostgreSQL database + Odoo filestore, then uploads to S3.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/erp_backup_${TIMESTAMP}"

# Load env vars if .env exists
[ -f "$ROOT_DIR/.env" ] && source "$ROOT_DIR/.env"

mkdir -p "$BACKUP_DIR"
echo "[backup] Starting ERP backup — ${TIMESTAMP}"

# ── PostgreSQL dump ────────────────────────────────────────────────
echo "[backup] Dumping PostgreSQL..."
docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres \
    pg_dump \
        --username="${POSTGRES_USER}" \
        --dbname="${POSTGRES_DB}" \
        --format=custom \
        --compress=9 \
    > "${BACKUP_DIR}/db_${TIMESTAMP}.dump"
echo "[backup] DB dump: ${BACKUP_DIR}/db_${TIMESTAMP}.dump"

# ── Odoo filestore ─────────────────────────────────────────────────
echo "[backup] Archiving Odoo filestore..."
docker compose -f "$ROOT_DIR/docker-compose.yml" run --rm --no-deps \
    -v "${BACKUP_DIR}:/backup" \
    odoo \
    tar czf "/backup/filestore_${TIMESTAMP}.tar.gz" /var/lib/odoo
echo "[backup] Filestore: ${BACKUP_DIR}/filestore_${TIMESTAMP}.tar.gz"

# ── Upload to S3 ──────────────────────────────────────────────────
if [ -n "${S3_BUCKET:-}" ]; then
    echo "[backup] Uploading to s3://${S3_BUCKET}/backups/ ..."
    for FILE in "$BACKUP_DIR"/*; do
        aws s3 cp "$FILE" "s3://${S3_BUCKET}/backups/$(basename "$FILE")" \
            ${S3_ENDPOINT:+--endpoint-url "$S3_ENDPOINT"}
    done
    echo "[backup] Upload complete."
else
    echo "[backup] S3_BUCKET not set — skipping upload."
fi

# ── Local rotation: keep 7 days ──────────────────────────────────
find /tmp -maxdepth 1 -name "erp_backup_*" -mtime +7 -exec rm -rf {} + 2>/dev/null || true

echo "[backup] Done. Files in: ${BACKUP_DIR}"
