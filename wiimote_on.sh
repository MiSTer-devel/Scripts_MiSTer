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

# Copyright 2018-2019 Alessandro "Locutus73" Miele

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer

# Version 1.0 - 2019-04-27 - First commit



#=========   USER OPTIONS   =========
#You can edit these user options or make an ini file with the same
#name as the script, i.e. mount_cifs.ini, containing the same options.

#"true" for starting wiimote support at boot time;
#it will create start script in /etc/init.d.
START_AT_BOOT="false"



#========= ADVANCED OPTIONS =========
BASE_PATH="/media/fat"
CWIID_PATH="${BASE_PATH}/linux/cwiid"
MAPS_PATH="${BASE_PATH}/config"
MISTER_CWIID_URL="https://github.com/MiSTer-devel/Scripts_MiSTer/blob/master/cwiid"
KERNEL_MODULES="uinput.ko"
CWIID_FILES="AUTHORS|COPYING|MiSTer.config|README|acc.so|cwiid.so|ir_fps.so|ir_ptr.so|led.so|libcwiid.so.1|nunchuk_acc.so|nunchuk_kb.so|nunchuk_stick2btn.so|wminput"
MAP_FILES="NES_input_0001_0001_v2.map|NES_input_0079_1803_v2.map|input_0001_0001_v2.map|input_0079_1802_v2.map|input_0079_1803_v2.map"
CWIID_CONFIG="MiSTer.config"
IFS="|"



#=========CODE STARTS HERE=========

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

for KERNEL_MODULE in ${KERNEL_MODULES}; do
	if ! cat /lib/modules/$(uname -r)/modules.builtin | grep -q "$(echo "${KERNEL_MODULE}" | sed 's/\./\\\./g')"
	then
		if ! lsmod | grep -q "${KERNEL_MODULE%.*}"
		then
			if ! insmod "${CWIID_PATH}/${KERNEL_MODULE}" > /dev/null 2>&1
			then
				echo "Downloading $KERNEL_MODULE"
				mkdir -p "${CWIID_PATH}"
				curl -L "${MISTER_CWIID_URL}/${KERNEL_MODULE}?raw=true" -o "${CWIID_PATH}/${KERNEL_MODULE}"
				case $? in
					0)
						;;
					60)
						if ! curl -kL "${MISTER_CWIID_URL}/${KERNEL_MODULE}?raw=true" -o "${CWIID_PATH}/${KERNEL_MODULE}"
						then
							echo "No Internet connection"
							exit 2
						fi
						;;
					*)
						echo "No Internet connection"
						exit 2
						;;
				esac
				if ! insmod "${CWIID_PATH}/${KERNEL_MODULE}" > /dev/null 2>&1
				then
					echo "Unable to load ${KERNEL_MODULE}"
					exit 1
				fi
			fi
		fi
	fi
done

for CWIID_FILE in ${CWIID_FILES}; do
	if [ ! -f "${CWIID_PATH}/${CWIID_FILE}" ]
	then
		echo "Downloading $CWIID_FILE"
		mkdir -p "${CWIID_PATH}"
		curl -L "${MISTER_CWIID_URL}/${CWIID_FILE}?raw=true" -o "${CWIID_PATH}/${CWIID_FILE}"
		case $? in
			0)
				;;
			60)
				if ! curl -kL "${MISTER_CWIID_URL}/${CWIID_FILE}?raw=true" -o "${CWIID_PATH}/${CWIID_FILE}"
				then
					echo "No Internet connection"
					exit 2
				fi
				;;
			*)
				echo "No Internet connection"
				exit 2
				;;
		esac
	fi
done

for MAP_FILE in ${MAP_FILES}; do
	if [ ! -f "${MAPS_PATH}/${MAP_FILE}" ]
	then
		echo "Downloading $MAP_FILE"
		mkdir -p "${MAPS_PATH}"
		curl -L "${MISTER_CWIID_URL}/${MAP_FILE}?raw=true" -o "${MAPS_PATH}/${MAP_FILE}"
		case $? in
			0)
				;;
			60)
				if ! curl -kL "${MISTER_CWIID_URL}/${MAP_FILE}?raw=true" -o "${MAPS_PATH}/${MAP_FILE}"
				then
					echo "No Internet connection"
					exit 2
				fi
				;;
			*)
				echo "No Internet connection"
				exit 2
				;;
		esac
	fi
done

STARTUP_SCRIPT="/etc/init.d/S99_$(basename ${ORIGINAL_SCRIPT_PATH%.*})"
if [ "$START_AT_BOOT" == "true" ]
then
	if [ ! -f "${STARTUP_SCRIPT}" ]
	then
		mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
		[ "${RO_ROOT}" == "true" ] && mount / -o remount,rw
		echo "#!/bin/bash"$'\n'"$(realpath "${ORIGINAL_SCRIPT_PATH}") &" > "${STARTUP_SCRIPT}"
		chmod +x "${STARTUP_SCRIPT}"
		sync
		[ "${RO_ROOT}" == "true" ] && mount / -o remount,ro
	fi
else
	if [ -f "${STARTUP_SCRIPT}" ]
	then
		mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
		[ "${RO_ROOT}" == "true" ] && mount / -o remount,rw
		rm "${STARTUP_SCRIPT}" > /dev/null 2>&1
		sync
		[ "${RO_ROOT}" == "true" ] && mount / -o remount,ro
	fi
fi

if ! ps | grep "[w]minput"
then
	export LD_LIBRARY_PATH="${CWIID_PATH}"
	export PYTHONPATH="${CWIID_PATH}"
	"${CWIID_PATH}/wminput" --daemon --config "${CWIID_PATH}/${CWIID_CONFIG}" &
	echo "cwiid's wminput started"
else
	echo "cwiid's wminput"
	echo "already running"
fi
echo "put Wiimote in discoverable"
echo "mode now (press 1+2) and"
echo "wait for solid led 1..."

exit 0