#!/bin/sh

set -e

THIS_DIR="$(cd "$(dirname "$0")" && pwd -P)"

if [ "$1" == "stop" ]; then
    exit 0
fi

echo "Setting reasonable sshd timeouts."
sed -i -E 's|^#[[:blank:]]*ClientAliveInterval[[:blank:]]*.*$|ClientAliveInterval 60|g; s|^#[[:blank:]]*ClientAliveCountMax[[:blank:]]*.*$|ClientAliveCountMax 10|g' /etc/ssh/sshd_config

if [ -z "$1" ]; then
    $THIS_DIR/add_to_user_startup.sh "$0" "Set reasonable sshd timeouts"
fi
