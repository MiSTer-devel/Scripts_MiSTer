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

# Version 1.0 - 2019-05-13 - First commit.

# get the name of the script, or of the parent script if called through a 'curl ... | bash -'
ORIGINAL_SCRIPT_PATH="${0}"
[[ "${ORIGINAL_SCRIPT_PATH}" == "bash" ]] && \
	ORIGINAL_SCRIPT_PATH="$(ps -o comm,pid | awk -v PPID=${PPID} '$2 == PPID {print $1}')"

CHANGE_PROPERTY_INCLUDE="$(dirname ${ORIGINAL_SCRIPT_PATH})/change_ini_property.sh.inc"
TMP=$(mktemp)
# preventively eliminate DOS-specific format and reboot+exit commands
dos2unix < "${CHANGE_PROPERTY_INCLUDE}" 2> /dev/null | grep -vi "^echo \"Please reboot" | grep -v "^reboot" | grep -v "^exit" > ${TMP}
FIRST_ITERATION="true"
for INI_PROPERTIY in ${INI_PROPERTIES}
do
	PROPERTY_NAME=$(echo "${INI_PROPERTIY}" | grep -o "^[^=]*")
	PROPERTY_VALUE=$(echo "${INI_PROPERTIY}" | grep -o "[^=]*$")
	source "${TMP}"
	if [ "${FIRST_ITERATION}" == "true" ]
	then
		# removing the ini backup command too, since we did that on the first iteration
		rm -f "${TMP}"
		dos2unix < "${CHANGE_PROPERTY_INCLUDE}" 2> /dev/null | grep -v "^cp /media/fat/config/MiSTer.ini" | grep -vi "^echo \"Please reboot" | grep -v "^reboot" | grep -v "^exit" > ${TMP}
		FIRST_ITERATION="false"
	fi
done
rm -f "${TMP}"