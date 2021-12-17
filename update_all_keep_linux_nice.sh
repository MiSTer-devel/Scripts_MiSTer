#!/bin/sh
this_dir="$(cd "$(dirname "$0")" && pwd -P)"
"$this_dir/update_all.sh"
/bin/mount -o remount,rw /
"$this_dir/make_linux_nice.sh"
/bin/mount -o remount,ro /
