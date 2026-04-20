#!/bin/sh
set -e

DATA_DIR="${OPENHOST_APP_DATA_DIR:-/data/app_data/filestash}"
STATE_DIR="$DATA_DIR/state"

mkdir -p "$STATE_DIR"

# Copy default config on first run
if [ ! -d "$STATE_DIR/config" ]; then
    cp -r /app/data/state/config "$STATE_DIR/config"
fi

# Symlink state to persistent storage
rm -rf /app/data/state
ln -sf "$STATE_DIR" /app/data/state

# Set Filestash's external URL from OpenHost env vars
if [ -n "$OPENHOST_ZONE_DOMAIN" ] && [ -n "$OPENHOST_APP_NAME" ]; then
    export APPLICATION_URL="https://${OPENHOST_APP_NAME}.${OPENHOST_ZONE_DOMAIN}"
fi

exec "$@"
