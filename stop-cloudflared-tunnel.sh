#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUDFLARED_DIR="$SCRIPT_DIR/cloudflared-config"

for TUNNEL_DIR in "$CLOUDFLARED_DIR"/*/; do
    [ -d "$TUNNEL_DIR" ] || continue

    NAME="$(basename "$TUNNEL_DIR")"

    case "$NAME" in
        *.disabled)
            echo "[$NAME] Skipping disabled tunnel."
            continue
            ;;
    esac

    CONFIG="${TUNNEL_DIR}config.yml"
    [ -f "$CONFIG" ] || continue

    PIDFILE="${TUNNEL_DIR}cloudflared.pid"

    if [ ! -f "$PIDFILE" ]; then
        echo "[$NAME] Not running."
        continue
    fi

    PID="$(cat "$PIDFILE")"

    if kill -0 "$PID" 2>/dev/null; then
        echo "[$NAME] Stopping Cloudflared (PID $PID)..."

        kill "$PID"

        for i in {1..10}; do
            if ! kill -0 "$PID" 2>/dev/null; then
                break
            fi
            sleep 1
        done

        if kill -0 "$PID" 2>/dev/null; then
            echo "[$NAME] Did not stop gracefully, sending SIGKILL..."
            kill -9 "$PID"
        fi

        echo "[$NAME] Stopped."
    else
        echo "[$NAME] Process $PID no longer exists."
    fi

    rm -f "$PIDFILE"

    echo
done
