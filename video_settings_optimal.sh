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
INI_PROPERTIES="hdmi_audio_96k=1 vscale_mode=0 video_mode=8 video_info=10 vsync_adjust=2 video_mode_ntsc_pal=1"
AUTHOR_NAME="Locutus73"

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

echo "These are my"
echo "(${AUTHOR_NAME}'s personal taste)"
echo "optimal video settings;"
echo "your needs may differ."
echo ""

sleep 2.5

CHANGE_PROPERTY_INCLUDE="$(dirname ${ORIGINAL_SCRIPT_PATH})/change_ini_properties.sh.inc"
TMP=$(mktemp)
# preventively eliminate DOS-specific format and reboot+exit commands
dos2unix < "${CHANGE_PROPERTY_INCLUDE}" 2> /dev/null | grep -v "^reboot" | grep -v "^exit" > ${TMP}
source "${TMP}"
rm -f "${TMP}"

sleep 2.5

echo ""
echo "I strongly recommend to set"
echo "Scale filter - Custom"
echo "Gaussian_Sharp_04.txt"
echo "or higher in each core"
echo "menu wherever possible."
echo "Please reboot."

exit 0
