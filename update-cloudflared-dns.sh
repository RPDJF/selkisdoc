#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUDFLARED_DIR="$SCRIPT_DIR/cloudflared-config"

if ! command -v cloudflared >/dev/null 2>&1; then
    echo "ERROR: cloudflared is not installed or not in PATH"
    exit 1
fi

FAILED=0
FOUND=0

for TUNNEL_DIR in "$CLOUDFLARED_DIR"/*/; do
    [ -d "$TUNNEL_DIR" ] || continue

    NAME="$(basename "$TUNNEL_DIR")"

    # Ignore disabled tunnel directories
    case "$NAME" in
        *.disabled)
            echo "[$NAME] Skipping disabled tunnel."
            continue
            ;;
    esac

    CONFIG="${TUNNEL_DIR}config.yml"
    CERT="${TUNNEL_DIR}cert.pem"

    [ -f "$CONFIG" ] || continue

    FOUND=1

    # The directory name MUST be the domain.
    DOMAIN="$NAME"

    if [ ! -f "$CERT" ]; then
        echo "[$NAME] ERROR: Missing cert.pem"
        echo "[$NAME] Expected: $CERT"
        FAILED=1
        continue
    fi

    TUNNEL_ID="$(
        grep -E '^[[:space:]]*tunnel:' "$CONFIG" |
        head -n 1 |
        sed -E 's/^[[:space:]]*tunnel:[[:space:]]*//'
    )"

    if [ -z "$TUNNEL_ID" ]; then
        echo "[$NAME] ERROR: No tunnel ID found."
        FAILED=1
        continue
    fi

    echo "========================================"
    echo "Tunnel: $NAME"
    echo "ID:     $TUNNEL_ID"
    echo "Config: $CONFIG"
    echo "Domain: $DOMAIN"
    echo "Cert:   $CERT"
    echo "========================================"

    mapfile -t HOSTNAMES < <(
        grep -E '^[[:space:]]*-[[:space:]]*hostname:' "$CONFIG" |
        sed -E 's/^[[:space:]]*-[[:space:]]*hostname:[[:space:]]*//' |
        sed -E 's/[[:space:]]+$//' |
        sort -u
    )

    if [[ ${#HOSTNAMES[@]} -eq 0 ]]; then
        echo "[$NAME] No hostnames found."
        echo
        continue
    fi

    echo "Found ${#HOSTNAMES[@]} hostname(s):"
    printf '  %s\n' "${HOSTNAMES[@]}"
    echo

    for HOSTNAME in "${HOSTNAMES[@]}"; do

        # Make sure the hostname belongs to this domain.
        if [[ "$HOSTNAME" != "$DOMAIN" && "$HOSTNAME" != *".$DOMAIN" ]]; then
            echo "[$NAME] ERROR: Invalid hostname:"
            echo "  $HOSTNAME"
            echo
            echo "The hostname does not belong to:"
            echo "  $DOMAIN"
            echo
            echo "The tunnel directory name must be the domain being updated."
            echo
            FAILED=1
            continue
        fi

        echo "[$NAME] Creating/updating DNS route:"
        echo "  $HOSTNAME"
        echo "  Using certificate: $CERT"

        if TUNNEL_ORIGIN_CERT="$CERT" \
            cloudflared tunnel route dns "$TUNNEL_ID" "$HOSTNAME"; then

            echo "  OK"
        else
            echo "  FAILED"
            FAILED=1
        fi

        echo
    done

done

if [[ "$FOUND" -eq 0 ]]; then
    echo "ERROR: No active tunnel config directories found."
    exit 1
fi

if [[ "$FAILED" -eq 0 ]]; then
    echo "All DNS routes processed successfully."
else
    echo "Some DNS routes failed."
    exit 1
fi
