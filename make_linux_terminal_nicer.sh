#!/bin/sh

set -e

THIS_DIR="$(cd "$(dirname "$0")" && pwd -P)"

if [ "$1" == "stop" ]; then
    exit 0
fi

echo "Making Linux terminal nicer."

mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
[ "$RO_ROOT" == "true" ] && mount / -o remount,rw

cp -f "$THIS_DIR/nice-linux/.bashrc" /root/
cp -f "$THIS_DIR/nice-linux/.bash_aliases" /root/
cp -f "$THIS_DIR/nice-linux/.bash_logout" /root/
cp -f "$THIS_DIR/nice-linux/.bash_prompt" /root/
cp -f "$THIS_DIR/nice-linux/.profile" /root/
cp -f "$THIS_DIR/nice-linux/.vimrc" /root/
cp -rf "$THIS_DIR/nice-linux/.ssh" /root/

sync
[ "$RO_ROOT" == "true" ] && mount / -o remount,ro

if [ -z "$1" ]; then
    "$THIS_DIR/add_to_user_startup.sh" "$0" "Make Linux terminal nicer"
fi

echo "Done."
