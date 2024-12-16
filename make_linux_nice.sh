#!/bin/sh

set -e

THIS_DIR="$(cd "$(dirname "$0")" && pwd -P)"

if [ "$1" == "stop" ]; then
    exit 0
fi

echo "Modifying root user settings."
cp -f "$THIS_DIR/nice-linux/.bashrc" /root/
cp -f "$THIS_DIR/nice-linux/.bash_aliases" /root/
cp -f "$THIS_DIR/nice-linux/.bash_functions" /root/
cp -f "$THIS_DIR/nice-linux/.bash_logout" /root/
cp -f "$THIS_DIR/nice-linux/.bash_prompt" /root/
cp -f "$THIS_DIR/nice-linux/.profile" /root/
cp -f "$THIS_DIR/nice-linux/.vimrc" /root/
cp -rf "$THIS_DIR/nice-linux/.ssh" /root/

echo "Configuring ssh KeepAlive settings."
sed -i -E 's|^#[[:blank:]]*ClientAliveInterval[[:blank:]]*.*$|ClientAliveInterval 60|g; s|^#[[:blank:]]*ClientAliveCountMax[[:blank:]]*.*$|ClientAliveCountMax 10|g' /etc/ssh/sshd_config

if [ -z "$1" ]; then
    /media/fat/Scripts/add_to_user_startup.sh "$0" "Make Linux nice"
fi
