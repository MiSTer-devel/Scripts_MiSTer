#!/bin/bash

set -euo pipefail

rm /etc/init.d/S99-spinfix 2> /dev/null \
    && echo 'Spinfix is now disabled.' \
    || echo 'Spinfix was not enabled, nothing to do here.'
