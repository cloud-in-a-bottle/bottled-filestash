#!/bin/sh
set -e

DATA_DIR="${OPENHOST_APP_DATA_DIR:-/data/app_data/filestash}"
STATE_DIR="$DATA_DIR/state"

mkdir -p "$STATE_DIR"

EXTERNAL_HOST="${OPENHOST_APP_NAME}.${OPENHOST_ZONE_DOMAIN}"

# Generate Filestash config on first run
if [ ! -f "$STATE_DIR/config/config.json" ]; then
    mkdir -p "$STATE_DIR/config"

    SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)

    cat > "$STATE_DIR/config/config.json" << EOCFG
{
    "general": {
        "secret_key": "$SECRET_KEY",
        "port": 8335,
        "display_hidden": true,
        "filepage_default_view": "list",
        "custom_css": ".component_sidebar h3, .component_sidebar a > div { text-transform: none !important; }"
    },
    "log": {
        "enable": true,
        "level": "INFO",
        "telemetry": false
    },
    "middleware": {
        "identity_provider": {
            "type": "passthrough",
            "params": "{\"type\":\"passthrough\",\"strategy\":\"direct\"}"
        },
        "attribute_mapping": {
            "related_backend": "Files",
            "params": "{\"Files\":{\"type\":\"local\",\"password\":\"$SECRET_KEY\",\"path\":\"/data/\"}}"
        }
    },
    "connections": [
        {"type": "local", "label": "Files", "path": "/data/"}
    ]
}
EOCFG
fi

# Extract password the local backend will receive via attribute_mapping; the
# local backend's Init() rejects it unless it matches LOCAL_BACKEND_SECRET (the
# bcrypt-against-auth.admin path doesn't apply since auth.admin is plaintext).
LOCAL_BACKEND_SECRET=$(sed -n 's/.*\\"password\\":\\"\([^\\]*\)\\".*/\1/p' "$STATE_DIR/config/config.json" | head -n1)
export LOCAL_BACKEND_SECRET

# Symlink state to persistent storage
rm -rf /app/data/state
ln -sf "$STATE_DIR" /app/data/state

# Caddy reverse proxy: rewrite Host header so Filestash's SecureOrigin check passes
cat > /etc/caddy/Caddyfile << EOCADDY
:8334 {
    reverse_proxy 127.0.0.1:8335 {
        header_up Host ${EXTERNAL_HOST}
    }
}
EOCADDY
caddy start --config /etc/caddy/Caddyfile

# Set hostname and skip setup wizard
export APPLICATION_URL="$EXTERNAL_HOST"
export FILESTASH_PORT=8335
export ADMIN_PASSWORD="openhost-managed"
export CONFIG_ENCRYPT=false

exec "$@"
