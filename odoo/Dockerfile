FROM odoo:17.0

USER root

# gettext-base provides envsubst for config templating
RUN apt-get update && apt-get install -y --no-install-recommends \
        gettext-base \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies for custom modules
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Odoo config (built from template at startup)
COPY odoo.conf.template /etc/odoo/odoo.conf.template

# Persistent log directory
RUN mkdir -p /var/log/odoo && chown odoo:odoo /var/log/odoo

# Custom entrypoint injects env vars then delegates to the official one
COPY entrypoint.sh /entrypoint-custom.sh
RUN chmod +x /entrypoint-custom.sh

USER odoo

ENTRYPOINT ["/entrypoint-custom.sh"]
CMD ["odoo"]
