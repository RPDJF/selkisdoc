#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUDFLARED_DIR="$SCRIPT_DIR/cloudflared-config"

if ! command -v cloudflared >/dev/null 2>&1; then
    echo "ERROR: cloudflared is not installed or not in PATH"
    exit 1
fi

for TUNNEL_DIR in "$CLOUDFLARED_DIR"/*/; do
    [ -d "$TUNNEL_DIR" ] || continue

    NAME="$(basename "$TUNNEL_DIR")"

    # Ignore disabled folders
    case "$NAME" in
        *.disabled)
            echo "[$NAME] Skipping disabled tunnel."
            continue
            ;;
    esac

    CONFIG="${TUNNEL_DIR}config.yml"

    [ -f "$CONFIG" ] || continue

    PIDFILE="${TUNNEL_DIR}cloudflared.pid"
    LOGFILE="${TUNNEL_DIR}cloudflared.log"

    TUNNEL_ID="$(
        grep -E '^[[:space:]]*tunnel:' "$CONFIG" |
        head -n 1 |
        sed -E 's/^[[:space:]]*tunnel:[[:space:]]*//'
    )"

    if [ -z "$TUNNEL_ID" ]; then
        echo "[$NAME] ERROR: No tunnel ID found in $CONFIG"
        continue
    fi

    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "[$NAME] Already running (PID $(cat "$PIDFILE"))"
        continue
    fi

    rm -f "$PIDFILE"

    echo "[$NAME] Starting Cloudflared..."
    echo "[$NAME] Tunnel: $TUNNEL_ID"
    echo "[$NAME] Config: $CONFIG"

    nohup cloudflared tunnel \
        --config "$CONFIG" \
        run "$TUNNEL_ID" \
        > "$LOGFILE" 2>&1 &

    PID=$!
    echo "$PID" > "$PIDFILE"

    sleep 1

    if kill -0 "$PID" 2>/dev/null; then
        echo "[$NAME] Started successfully."
        echo "[$NAME] PID: $PID"
        echo "[$NAME] Log: $LOGFILE"
    else
        echo "[$NAME] FAILED to start."
        rm -f "$PIDFILE"
        echo "[$NAME] Check: $LOGFILE"
    fi

    echo
done
