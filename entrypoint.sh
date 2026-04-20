#!/bin/sh
set -e

DATA_DIR="${OPENHOST_APP_DATA_DIR:-/data/app_data/filestash}"
STATE_DIR="$DATA_DIR/state"

mkdir -p "$STATE_DIR"

# Generate config on first run
if [ ! -f "$STATE_DIR/config/config.json" ]; then
    mkdir -p "$STATE_DIR/config"

    SECRET_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 16)

    cat > "$STATE_DIR/config/config.json" << EOCFG
{
    "general": {
        "secret_key": "$SECRET_KEY",
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

# Symlink state to persistent storage
rm -rf /app/data/state
ln -sf "$STATE_DIR" /app/data/state

# Skip setup wizard (non-empty value bypasses the redirect)
export ADMIN_PASSWORD="openhost-managed"

# Keep middleware params as plaintext in config
export CONFIG_ENCRYPT=false

exec "$@"
