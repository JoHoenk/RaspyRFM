#!/bin/bash
set -e

# Detect Raspberry Pi revision and set environment variable if not already set
if [ -z "$RPI_LGPIO_REVISION" ]; then
    if [ -f "/proc/device-tree/system/linux,revision" ]; then
        # Read binary revision from device tree and convert to hex
        REVISION=$(od -A n -t x1 /proc/device-tree/system/linux,revision | tr -d ' ')
        if [ ! -z "$REVISION" ]; then
            export RPI_LGPIO_REVISION="$REVISION"
            echo "Detected RPi revision: $RPI_LGPIO_REVISION"
        fi
    else
        echo "Warning: Could not detect RPi revision from device tree"
        # For Raspberry Pi 5, use a default revision
        export RPI_LGPIO_REVISION="c04170"
        echo "Using default RPi5 revision: $RPI_LGPIO_REVISION"
    fi
fi

# Default app is rcpulsegw
APP="${1:-rcpulsegw.py}"

# Make sure it has .py extension if not already
if [[ ! "$APP" == *.py ]]; then
    APP="${APP}.py"
fi

# Check if the app exists
if [ ! -f "/app/apps/$APP" ]; then
    echo "Error: App $APP not found in /app/apps/"
    echo "Available apps:"
    ls -la /app/apps/*.py 2>/dev/null | awk '{print "  - " $NF}' || echo "  (no apps found)"
    exit 1
fi

echo "Starting RaspyRFM app: $APP"
cd /app/apps
# Shift to remove the first argument (app name) and only pass additional args if present
shift || true
exec python3 "$APP" "$@"
