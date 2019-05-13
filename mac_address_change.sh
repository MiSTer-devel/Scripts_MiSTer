#!/bin/bash

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Copyright 2019 Alessandro "Locutus73" Miele

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer

# Version 1.0 - 2019-05-13 - First commit



# ========= OPTIONS ==================
MAC_ADDRESS=""

# ========= CODE STARTS HERE =========
# get the name of the script, or of the parent script if called through a 'curl ... | bash -'
ORIGINAL_SCRIPT_PATH="${0}"
[[ "${ORIGINAL_SCRIPT_PATH}" == "bash" ]] && \
	ORIGINAL_SCRIPT_PATH="$(ps -o comm,pid | awk -v PPID=${PPID} '$2 == PPID {print $1}')"

# ini file can contain user defined variables (as bash commands)
# Load and execute the content of the ini file, if there is one
INI_PATH="${ORIGINAL_SCRIPT_PATH%.*}.ini"
if [[ -f "${INI_PATH}" ]] ; then
	TMP=$(mktemp)
	# preventively eliminate DOS-specific format and exit command  
	dos2unix < "${INI_PATH}" 2> /dev/null | grep -v "^exit" > ${TMP}
	source ${TMP}
	rm -f ${TMP}
fi

# very rarely the hexdump thing plus bitwise operations fails, so I repeat the MAC address generation to be sure
until echo "${MAC_ADDRESS}" | grep -qE "[0-9A-F]{2}(\:[0-9A-F]{2}){5}"
do
	MAC_ADDRESS="$(printf "%012X" $(( 0x$(hexdump -n6 -e '/1 "%02X"' /dev/random) & 0xFEFFFFFFFFFF | 0x020000000000 )) | sed 's/.\{2\}/&:/g' | sed s/:$//g)"
done

echo "ethaddr=${MAC_ADDRESS}" > /media/fat/linux/u-boot.txt

echo "The new MAC address is:"
echo "${MAC_ADDRESS}"
echo "it will become effective"
echo "on next reboot."

exit 0
