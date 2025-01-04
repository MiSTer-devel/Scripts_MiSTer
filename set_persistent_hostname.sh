#!/bin/sh

set -e

THIS_DIR="$(cd "$(dirname "$0")" && pwd -P)"

if [ "$1" == "stop" ]; then
    exit 0
fi

ORIGINAL_SCRIPT_PATH="$0"
CURRENT_HOSTNAME="$(cat /etc/hostname | tr -d '\r')"

if [ -f "$THIS_DIR/persistent_hostname" ]; then
    PERSISTENT_HOSTNAME="$(cat "$THIS_DIR/persistent_hostname" | tr -d '\r')"
    if [ -z "$PERSISTENT_HOSTNAME" ]; then
        echo "error: PERSISTENT_HOSTNAME undefined. Exiting." >&2
        exit 1
    fi
fi

if [ "$CURRENT_HOSTNAME" == "$PERSISTENT_HOSTNAME" ]; then
    echo "Hostname is already $PERSISTENT_HOSTNAME."
else
    echo "Changing hostname from $CURRENT_HOSTNAME to $PERSISTENT_HOSTNAME."

    echo -n "$PERSISTENT_HOSTNAME" > /etc/hostname
    hostname -F /etc/hostname

    sed -i -E -e "s/(\s+)$CURRENT_HOSTNAME$/\\1$PERSISTENT_HOSTNAME/g" /etc/hosts

    /etc/init.d/S40network restart
fi

if [ -z "$1" ]; then
    "$THIS_DIR/add_to_user_startup.sh" "$0" "Set persistent hostname"
fi
