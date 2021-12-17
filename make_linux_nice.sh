#!/bin/sh

set -e

echo "Making Linux nice..."

this_dir="$(cd "$(dirname "$0")" && pwd -P)"

echo " - Modifying root user settings..."
cp -f "$this_dir/nice-linux/.bashrc" /root/
cp -f "$this_dir/nice-linux/.bash_aliases" /root/
cp -f "$this_dir/nice-linux/.bash_logout" /root/
cp -f "$this_dir/nice-linux/.bash_prompt" /root/
cp -f "$this_dir/nice-linux/.profile" /root/
cp -f "$this_dir/nice-linux/.vimrc" /root/
cp -rf "$this_dir/nice-linux/.ssh" /root/

echo " - Configuring ssh KeepAlive settings..."
sed -i -E 's|^#[[:blank:]]*ClientAliveInterval[[:blank:]]*.*$|ClientAliveInterval 60|g; s|^#[[:blank:]]*ClientAliveCountMax[[:blank:]]*.*$|ClientAliveCountMax 10|g' /etc/ssh/sshd_config

echo " - Configuring Bluetooth timeouts..."
sed -i -E 's|^(DiscoverableTimeout = ).*%|\10|g; s|^(PairableTimeout = ).*$|\10|g; s|^(AutoConnectTimeout = ).*$|\160|g; s|^(FastConnectable = ).*$|\1true|g' /etc/bluetooth/main.conf

echo "Done."
