#!/bin/bash

set -e
set -o pipefail
set -u

if [ "$1" == "" ]; then
    echo "usage: $0 <A_MISTER_LOG_FILE>" >&2
    exit 1
fi

CONTROL_CODES_REGEX='[[:cntrl:]]\[([0-9]{1,3};)*[0-9]{1,3}m'

cat "$1" | sed -Ee "s/$CONTROL_CODES_REGEX//g" | grep -Ee "video mode"
