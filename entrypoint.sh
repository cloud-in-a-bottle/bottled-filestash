#!/bin/sh
set -e

DATA_DIR="${OPENHOST_APP_DATA_DIR:-/data/app_data/filestash}"
STATE_DIR="$DATA_DIR/state"

mkdir -p "$STATE_DIR"

EXTERNAL_HOST="${OPENHOST_APP_NAME}.${OPENHOST_ZONE_DOMAIN}"

# Generate Filestash config on first run
if [ ! -f "$STATE_DIR/config/config.json" ]; then
    mkdir -p "$STATE_DIR/config"

    SECRET_KEY=$(dd if=/dev/urandom bs=32 count=1 2>/dev/null | od -A n -t x1 | tr -d ' \n')

    # Use jq so special characters in values can never corrupt the JSON
    jq -n \
      --arg secret_key "$SECRET_KEY" \
      --arg css ".component_sidebar h3, .component_sidebar a > div { text-transform: none !important; }" \
      '{
        "general": {
          "secret_key": $secret_key,
          "port": 8335,
          "display_hidden": true,
          "filepage_default_view": "list",
          "custom_css": $css
        },
        "log": {
          "enable": true,
          "level": "INFO",
          "telemetry": false
        },
        "middleware": {
          "identity_provider": {
            "type": "passthrough",
            "params": ({"type":"passthrough","strategy":"direct"} | tostring)
          },
          "attribute_mapping": {
            "related_backend": "Files",
            "params": ({"Files":{"type":"local","password":$secret_key,"path":"/data/"}} | tostring)
          }
        },
        "connections": [
          {"type": "local", "label": "Files", "path": "/data/"}
        ]
      }' > "$STATE_DIR/config/config.json"
fi

# Extract the secret key the local backend will receive via attribute_mapping;
# the local backend's Init() rejects it unless it matches LOCAL_BACKEND_SECRET
# (the bcrypt-against-auth.admin path doesn't apply since auth.admin is plaintext).
LOCAL_BACKEND_SECRET=$(jq -r '.middleware.attribute_mapping.params | fromjson | .Files.password' "$STATE_DIR/config/config.json")
export LOCAL_BACKEND_SECRET

# Symlink state to persistent storage; guard against accidentally clobbering
# a real directory if the container ever ran without the persistent volume.
if [ -e /app/data/state ] && [ ! -L /app/data/state ]; then
    if [ -n "$(find /app/data/state -mindepth 1 -maxdepth 1 2>/dev/null)" ]; then
        echo "ERROR: /app/data/state is a non-empty directory; refusing to overwrite" >&2
        exit 1
    fi
    rm -rf /app/data/state
fi
rm -f /app/data/state
ln -sf "$STATE_DIR" /app/data/state

# Caddy reverse proxy: rewrite Host header so Filestash's SecureOrigin check passes
cat > /etc/caddy/Caddyfile << EOCADDY
:8334 {
    reverse_proxy 127.0.0.1:8335 {
        header_up Host ${EXTERNAL_HOST}
    }
}
EOCADDY
caddy validate --config /etc/caddy/Caddyfile
caddy start --config /etc/caddy/Caddyfile

# Set hostname and skip setup wizard
export APPLICATION_URL="https://$EXTERNAL_HOST"
export FILESTASH_PORT=8335
export ADMIN_PASSWORD="openhost-managed"
export CONFIG_ENCRYPT=false

exec "$@"
