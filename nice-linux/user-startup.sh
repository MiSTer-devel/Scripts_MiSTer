#!/bin/sh

MAKE_LINUX_NICE_SCRIPT=/media/fat/Scripts/make_linux_nice.sh

echo "***" $1 "***"

case "$1" in
	start)
		[ ! -f "${MAKE_LINUX_NICE_SCRIPT}" ] || "${MAKE_LINUX_NICE_SCRIPT}" ;;
	*)
		exit 0
esac
 
