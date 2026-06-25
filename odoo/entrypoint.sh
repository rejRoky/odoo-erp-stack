#!/usr/bin/env bash
set -euo pipefail

# Substitute environment variables into the config template
# and write to the location the official Odoo entrypoint expects.
envsubst < /etc/odoo/odoo.conf.template > /etc/odoo/odoo.conf

# Hand off to the official Odoo Docker entrypoint
exec /entrypoint.sh "$@"
