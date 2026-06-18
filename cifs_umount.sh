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
# https://github.com/MiSTer-devel/CIFS_MiSTer

# Version 2.2.0 - 2026-04-19 - Default unmount now targets cifs_mount.sh managed mounts only.
#                            - Added --all to preserve the old global "umount -a -t cifs" behavior.
#                            - Falls back to lazy unmount for busy targets.
#                            - Warns when the caller's current directory was unmounted.
# Version 2.0 - 2019-02-05 - Renamed from mount_cifs.sh and umount_cifs.sh to cifs_mount.sh and cifs_umount.sh for having them sequentially listed in alphabetical order.
# Version 1.0 - 2019.01.05 - First commit



BASE_PATH="/media/fat"
LOCAL_DIR="cifs"
IFS="|"
SINGLE_CIFS_CONNECTION="true"
SPECIAL_DIRECTORIES="config|linux|System Volume Information"
LAZY_UNMOUNT_ON_BUSY="true"



resolve_path() {
	if command -v realpath >/dev/null 2>&1
	then
		realpath "$1" 2>/dev/null && return 0
	fi
	if command -v readlink >/dev/null 2>&1
	then
		readlink -f "$1" 2>/dev/null && return 0
	fi
	echo "$1"
}

ORIGINAL_SCRIPT_PATH="$0"
if [ "$ORIGINAL_SCRIPT_PATH" == "bash" ]
then
	ORIGINAL_SCRIPT_PATH=$(ps | grep "^ *$PPID " | grep -o "[^ ]*$")
fi
SCRIPT_REALPATH=$(resolve_path "$ORIGINAL_SCRIPT_PATH")
case "$SCRIPT_REALPATH" in
	*/*) SCRIPT_DIR=${SCRIPT_REALPATH%/*} ;;
	*) SCRIPT_DIR="." ;;
esac
. "$SCRIPT_DIR/cifs_common.sh"
CIFS_UMOUNT_INI_KEYS=(
	BASE_PATH
	LOCAL_DIR
	SINGLE_CIFS_CONNECTION
	SPECIAL_DIRECTORIES
	LAZY_UNMOUNT_ON_BUSY
)

MOUNT_INI_PATH="${SCRIPT_DIR}/cifs_mount.ini"
FALLBACK_INI="/media/fat/Scripts/cifs_mount.ini"
MOUNT_SCRIPT_NAME="cifs_mount"
TEMP_MOUNT="/tmp/${MOUNT_SCRIPT_NAME}"

if [ "${1:-}" == "--all" ]
then
	if umount -a -t cifs
	then
		echo "Done!"
		exit 0
	fi
	echo "CIFS shares not unmounted."
	exit 1
elif [ "${1:-}" != "" ]
then
	echo "Usage: ${ORIGINAL_SCRIPT_PATH##*/} [--all]"
	exit 2
fi

if [ -f "$MOUNT_INI_PATH" ]
then
	load_cifs_ini "$MOUNT_INI_PATH" "${CIFS_UMOUNT_INI_KEYS[@]}"
elif [ "$MOUNT_INI_PATH" != "$FALLBACK_INI" ] && [ -f "$FALLBACK_INI" ]
then
	load_cifs_ini "$FALLBACK_INI" "${CIFS_UMOUNT_INI_KEYS[@]}"
fi

IFS="|"
UNMOUNT_TARGETS=()
UNMOUNT_FAILURES=0
INITIAL_PWD=$(pwd -P 2>/dev/null || pwd 2>/dev/null)
CURRENT_DIRECTORY_UNMOUNTED="false"

add_target() {
	local TARGET="$1"
	local EXISTING

	[ "$TARGET" != "" ] || return 0
	for EXISTING in "${UNMOUNT_TARGETS[@]}"
	do
		[ "$EXISTING" == "$TARGET" ] && return 0
	done
	UNMOUNT_TARGETS+=("$TARGET")
}

target_contains_initial_pwd() {
	local TARGET="$1"

	[ "$INITIAL_PWD" != "" ] || return 1
	case "$INITIAL_PWD" in
		"$TARGET"|"$TARGET"/*) return 0 ;;
	esac
	return 1
}

is_special_directory() {
	local DIRECTORY="$1"
	local SPECIAL_DIRECTORY
	local OLD_IFS="$IFS"

	IFS="|"
	for SPECIAL_DIRECTORY in $SPECIAL_DIRECTORIES
	do
		if [ "$DIRECTORY" == "$SPECIAL_DIRECTORY" ]
		then
			IFS="$OLD_IFS"
			return 0
		fi
	done
	IFS="$OLD_IFS"
	return 1
}

get_mount_info() {
	local PATH_TO_CHECK="$1"
	local LINE
	local SOURCE
	local REST
	local TARGET
	local TYPE_REST

	MOUNT_SOURCE_FOR_TARGET=""
	MOUNT_TYPE_FOR_TARGET=""

	while IFS= read -r LINE
	do
		SOURCE=${LINE%% on *}
		REST=${LINE#* on }
		[ "$REST" != "$LINE" ] || continue
		TARGET=${REST%% type *}
		[ "$TARGET" == "$PATH_TO_CHECK" ] || continue
		TYPE_REST=${REST#* type }
		[ "$TYPE_REST" != "$REST" ] || return 1
		MOUNT_SOURCE_FOR_TARGET="$SOURCE"
		MOUNT_TYPE_FOR_TARGET=${TYPE_REST%% *}
		return 0
	done <<EOF
$(mount)
EOF
	return 1
}

target_is_script_managed() {
	local TARGET="$1"

	get_mount_info "$TARGET" || return 1
	[ "$MOUNT_TYPE_FOR_TARGET" == "cifs" ] && return 0
	case "$MOUNT_SOURCE_FOR_TARGET" in
		"$TEMP_MOUNT"/*) return 0 ;;
	esac
	return 1
}

add_configured_targets() {
	local DIRECTORY
	local OLD_IFS="$IFS"

	IFS="|"
	for DIRECTORY in $LOCAL_DIR
	do
		[ "$DIRECTORY" != "" ] || continue
		add_target "$BASE_PATH/$DIRECTORY"
	done
	IFS="$OLD_IFS"
}

add_wildcard_targets_from_mounts() {
	local LINE
	local SOURCE
	local REST
	local TARGET
	local TYPE_REST
	local TYPE
	local DIRECTORY

	while IFS= read -r LINE
	do
		SOURCE=${LINE%% on *}
		REST=${LINE#* on }
		[ "$REST" != "$LINE" ] || continue
		TARGET=${REST%% type *}
		TYPE_REST=${REST#* type }
		[ "$TYPE_REST" != "$REST" ] || continue
		TYPE=${TYPE_REST%% *}

		case "$TARGET" in
			"$BASE_PATH"/*) ;;
			*) continue ;;
		esac

		DIRECTORY=${TARGET##*/}
		is_special_directory "$DIRECTORY" && continue

		if [ "$TYPE" == "cifs" ]
		then
			add_target "$TARGET"
		elif [ "$SINGLE_CIFS_CONNECTION" == "true" ]
		then
			case "$SOURCE" in
				"$TEMP_MOUNT"/*) add_target "$TARGET" ;;
			esac
		fi
	done <<EOF
$(mount)
EOF
}

unmount_temp_mounts() {
	local LINE
	local REST
	local TARGET
	local TYPE_REST
	local TYPE

	while IFS= read -r LINE
	do
		REST=${LINE#* on }
		[ "$REST" != "$LINE" ] || continue
		TARGET=${REST%% type *}
		TYPE_REST=${REST#* type }
		[ "$TYPE_REST" != "$REST" ] || continue
		TYPE=${TYPE_REST%% *}
		[ "$TYPE" == "cifs" ] || continue

		case "$TARGET" in
			/tmp/cifs_mount*) unmount_path "$TARGET" ;;
		esac
	done <<EOF
$(mount)
EOF
}

unmount_path() {
	local TARGET="$1"
	local UNMOUNTED="false"

	while target_is_script_managed "$TARGET"
	do
		if umount "$TARGET" >/dev/null 2>&1
		then
			UNMOUNTED="true"
		elif [ "$LAZY_UNMOUNT_ON_BUSY" == "true" ] && umount -l "$TARGET" >/dev/null 2>&1
		then
			UNMOUNTED="true"
		else
			echo "${TARGET##*/} not unmounted"
			UNMOUNT_FAILURES=$((UNMOUNT_FAILURES + 1))
			return 1
		fi
	done

	if [ "$UNMOUNTED" == "true" ]
	then
		echo "${TARGET##*/} unmounted"
		target_contains_initial_pwd "$TARGET" && CURRENT_DIRECTORY_UNMOUNTED="true"
	fi
	return 0
}

if [ "$LOCAL_DIR" == "*" ]
then
	add_wildcard_targets_from_mounts
else
	add_configured_targets
fi

for ((INDEX=${#UNMOUNT_TARGETS[@]} - 1; INDEX >= 0; INDEX--))
do
	unmount_path "${UNMOUNT_TARGETS[$INDEX]}"
done
unmount_temp_mounts

if [ "$UNMOUNT_FAILURES" -gt 0 ]
then
	echo "Done with ${UNMOUNT_FAILURES} failure(s)."
	exit 1
fi

echo "Done!"
[ "$CURRENT_DIRECTORY_UNMOUNTED" == "true" ] && echo "Current shell directory was unmounted; run: cd /media/fat/Scripts"
exit 0
