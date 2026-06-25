#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/var/lib/postgresql/data/pgdata"

# Wait until primary is accepting connections
until pg_isready -h postgres -U "$PGUSER"; do
    echo "[replica] Waiting for primary postgres..."
    sleep 3
done

# Only do base backup if this is a fresh volume
if [ ! -f "$DATA_DIR/PG_VERSION" ]; then
    echo "[replica] Running initial pg_basebackup from primary..."
    pg_basebackup \
        -h postgres \
        -U "$PGUSER" \
        -D "$DATA_DIR" \
        -P \
        -Xs \
        -R \
        --checkpoint=fast
    echo "[replica] Base backup complete."
fi

# Hand off to the standard postgres entrypoint
exec docker-entrypoint.sh postgres \
    -c hot_standby=on \
    -c wal_level=replica
