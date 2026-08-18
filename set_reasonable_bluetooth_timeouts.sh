#!/bin/sh

set -e

THIS_DIR="$(cd "$(dirname "$0")" && pwd -P)"

if [ "$1" == "stop" ]; then
    exit 0
fi

mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
[ "$RO_ROOT" == "true" ] && mount / -o remount,rw

echo "Setting reasonable Bluetooth timeouts."
sed -i -E 's|^(DiscoverableTimeout = ).*%|\10|g; s|^(PairableTimeout = ).*$|\10|g; s|^(AutoConnectTimeout = ).*$|\160|g; s|^(FastConnectable = ).*$|\1true|g' /etc/bluetooth/main.conf

sync
[ "$RO_ROOT" == "true" ] && mount / -o remount,ro

if [ -z "$1" ]; then
    $THIS_DIR/add_to_user_startup.sh "$0" "Set reasonable Bluetooth timeouts"
fi
