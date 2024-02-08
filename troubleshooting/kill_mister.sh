#!/bin/bash

set -e
set -o pipefail
set -u

IFS= read -r -a PS_LINES < <(ps -o pid,comm,args | grep -F MiSTer | grep -vF grep || true)
for PS_LINE in "${PS_LINES[@]}"; do
    pid="$(echo "$PS_LINE" | sed -E -e 's/^\s*([[:digit:]]+).*$/\1/g')"
    kill -s SIGTERM $pid
done
