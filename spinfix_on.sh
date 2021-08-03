#!/bin/bash

:<<LICENSE
Spinfix, disk polling process.

Copyright (C) 2021  Felipe A Hernandez

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
LICENSE

#
# CONFIG
# 

:<<COMMENT
SPINFIX_INTERVAL
================
Pause for NUMBER seconds.  SUFFIX may be 's' for seconds (the default),
'm' for minutes, 'h' for hours or 'd' for days.  NUMBER need not be an
integer.  Given two or more arguments, pause for the amount of time
specified by the sum of their values.
COMMENT
SPINFIX_INTERVAL="60s"

#
# SCRIPT
#

set -euo pipefail

cat <<EOF
Spinfix is a background process meant to keep spinning drives awake.

Many laptop and external hard drives include an aggressive power management
configuration causing issues on cores relying on intermitent access such
as CD seeking operations.

In order to configure the disk polling interval (currently set to ${SPINFIX_INTERVAL}),
edit this script to update the SPINFIX_INTERVAL value and then rerun it for
that change to be applied.

Credits to jca from misterfpga forums for the solution.

EOF

if [ -f /bin/spinfix ]; then
    echo -n 'Reinstalling... '
else
    echo -n 'Installing... '
fi

cat <<'EOF' \
    | sed "s/\${SPINFIX_INTERVAL}/${SPINFIX_INTERVAL}/" \
    > /bin/spinfix
#!/bin/bash

:<<LICENSE
Spinfix, disk polling process.

Copyright (C) 2021  Felipe A Hernandez

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
LICENSE

set -euo pipefail

IFS=$'\n'
while true; do
    pos=$RANDOM
    devices=$(lsblk -prsno rota,name,mountpoint | grep -E '^1\s[^ ]+\s/media/.*$' | cut -d ' ' -f 2)
    for dev in $devices; do
        dd \
            if=$dev \
            iflag=direct \
            of=/dev/null \
            count=1 \
            status=none \
            skip=$pos \
            > /dev/null 2>&1 \
            && echo "$(date --iso-8601=seconds) DEBUG: ${dev}:${pos} read"  \
            || echo "$(date --iso-8601=seconds) ERROR: ${dev}:${pos} read error"
    done
    sleep ${SPINFIX_INTERVAL}
done
EOF

cat <<'EOF' \
    > /etc/init.d/S99-spinfix
#!/bin/bash
(nohup spinfix > /dev/null) 2> /dev/null &
EOF
echo 'OK'

chmod +x /bin/spinfix /etc/init.d/S99-spinfix
killall spinfix 2> /dev/null \
    && echo -n 'Restarting... ' \
    || echo -n 'Starting... '
(nohup spinfix > /dev/null) 2> /dev/null &
echo 'OK'

devices=$(lsblk -prsno rota,mountpoint | grep -E '^1\s/media/.*$' | cut -d ' ' -f 2)
if [ -z "$devices" ]; then
    echo -e '\nNo rotational hard drives detected.'
else
    echo -e '\nDetected rotational hard drives:'
    IFS=$'\n'
    for device in $devices; do
        echo "  ${device}"
    done
fi

cat <<EOF

Spinfix is now set to run every ${SPINFIX_INTERVAL}.

These changes will be persisted across reboots
(until the base MiSTer linux image receives an update).

EOF
