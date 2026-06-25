#!/usr/bin/env bash
# Usage: ./scripts/healthcheck.sh
# Prints the health status of all compose services and exits 1 if any are unhealthy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== ERP Stack Health Check — $(date) ==="
echo ""

SERVICES=(nginx odoo odoo-longpolling postgres pgbouncer redis prometheus grafana loki)
ALL_OK=true

for SERVICE in "${SERVICES[@]}"; do
    STATUS=$(docker compose -f "$ROOT_DIR/docker-compose.yml" ps --format json "$SERVICE" 2>/dev/null \
        | python3 -c "import sys,json; data=sys.stdin.read(); obj=json.loads(data) if data.strip() else {}; print(obj.get('Health', obj.get('State','unknown')))" 2>/dev/null \
        || echo "not_found")

    if [[ "$STATUS" == "healthy" || "$STATUS" == "running" ]]; then
        printf "  %-22s  OK   (%s)\n" "$SERVICE" "$STATUS"
    else
        printf "  %-22s  FAIL (%s)\n" "$SERVICE" "$STATUS"
        ALL_OK=false
    fi
done

echo ""

# Quick HTTP smoke test
HTTP_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" http://localhost/web/health 2>/dev/null || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    echo "  HTTP smoke test          OK   (Odoo /web/health → 200)"
else
    echo "  HTTP smoke test          FAIL (Odoo /web/health → ${HTTP_STATUS})"
    ALL_OK=false
fi

echo ""

if $ALL_OK; then
    echo "All services are healthy."
    exit 0
else
    echo "One or more services are unhealthy. Run: docker compose logs <service>"
    exit 1
fi
