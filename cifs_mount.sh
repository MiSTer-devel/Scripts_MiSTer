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

# Changelog:
# Version 2.2.1 - 2026-04-30 - Skips already-mounted targets, tries DNS before NetBIOS, logs boot starts,
#                              and recovers stale /tmp/cifs_mount mounts before remounting.
#                            - Waits for a default route at boot, settles dual-interface routing,
#                              and can restart NTP after successful boot mounts.
# Version 2.2.0 - 2026-04-19 - MiSTer-safe boot automount: MOUNT_AT_BOOT now uses /media/fat/linux/user-startup.sh when available,
#                              with a late /etc/init.d fallback, instead of /etc/network/if-up.d hooks.
#                            - Removes legacy CIFS network hooks before config validation so old hooks do not keep breaking WiFi.
#                            - Waits for IPv4 before boot mounting, adds bounded network/server waits, and fails cleanly on lookup timeout.
#                            - Preserves SHARE_DIRECTORY support and fixes failed single-directory mounts reporting success.
# Version 2.1.1 - 2023-11-16 - Updated Github link, fixed unary operator error if "SHARE_DIRECTORY" not specified.
# Version 2.1.0 - 2022-04-16 - Introduced "SHARE_DIRECTORY" option; useful if you don't have a dedicated MiSTer-share on the remote server, but only a specific folder which should be mounted here.
# Version 2.0.1 - 2019-05-06 - Removed kernel modules downloading, now the script asks to update the MiSTer Linux system when necessary.
# Version 2.0 - 2019-02-05 - Renamed from mount_cifs.sh and umount_cifs.sh to cifs_mount.sh and cifs_umount.sh for having them sequentially listed in alphabetical order.
# Version 1.8 - 2019-02-03 - Added MOUNT_AT_BOOT option: "true" for automounting CIFS shares at boot time; it will create start/kill scripts in /etc/network/if-up.d and /etc/network/if-down.d.
# Version 1.7 - 2019-02-02 - The script temporarily modifies the firewalling rules for querying the CIFS Server name with NetBIOS when needed.
# Version 1.6 - 2019-02-02 - The script tries to download kernel modules (when needed) using SSL certificate verification.
# Version 1.5.1 - 2019-01-19 - Now the script checks if kernel modules are built in, so it's compatible with latest MiSTer Linux distros.
# Version 1.5 - 2019-01-15 - Added WAIT_FOR_SERVER option; set it to "true" in order to wait for the CIFS server to be reachable; useful when using this script at boot time.
# Version 1.4 - 2019-01-07 - Added support for an ini configuration file with the same name as the original script, i.e. mount_cifs.ini; changed LOCAL_DIR="*" behaviour so that, when SINGLE_CIFS_CONNECTION="true", all remote directories are listed and mounted locally; kernel modules moved to /media/fat/linux.
# Version 1.3 - 2019-01-05 - Added an advanced SINGLE_CIFS_CONNECTION option for making a single CIFS connection to the CIFS server, you can leave it set to "true"; implemented LOCAL_DIR="*" for mounting all local directories on the SD root.
# Version 1.2 - 2019-01-04 - Changed the internal field separator from space " " to pipe "|" in order to allow directory names with spaces; made the script verbose with some output.
# Version 1.1.1 - 2019-01-03 - Improved server name resolution speed for multiple mount points; now you can directly use an IP address; added des_generic.ko fscache.ko kernel modules.
# Version 1.1 - 2019-01-03 - Implemented multiple mount points, improved descriptions for user options.
# Version 1.0.1 - 2018-12-22 - Changed some option descriptions, thanks NML32
# Version 1.0 - 2018-12-20 - First commit



#=========   USER OPTIONS   =========
#You can edit these user options or make an ini file with the same
#name as the script, i.e. cifs_mount.ini, containing the same options.

#Your CIFS Server, i.e. your NAS name or its IP address.
SERVER=""

#The share name on the Server.
SHARE="MiSTer"

#Use this if only a specific directory from the share's root should be mounted.
SHARE_DIRECTORY=""

#The user name, leave blank for guest access.
USERNAME=""

#The user password, irrelevant (leave blank) for guest access.
PASSWORD=""

#Optional user domain, when in doubt leave blank.
DOMAIN=""

#Local directory/directories where the share will be mounted.
#- It can ba a single directory, i.e. "cifs", so the remote share, i.e. \\NAS\MiSTer
#  will be directly mounted on /media/fat/cifs (/media/fat is the root of the SD card).
#  NOTE: /media/fat/cifs is a special location that the mister binary will try before looking in
# the standard games location of /media/fat/games, so "cifs" is the suggested setting.
#- It can be a pipe "|" separated list of directories, i.e. "Amiga|C64|NES|SNES",
#  so the share subdirectiories with those names,
#  i.e. \\NAS\MiSTer\Amiga, \\NAS\MiSTer\C64, \\NAS\MiSTer\NES and \\NAS\MiSTer\SNES
#  will be mounted on local /media/fat/Amiga, /media/fat/C64, /media/fat/NES and /media/fat/SNES.
#- It can be an asterisk "*": when SINGLE_CIFS_CONNECTION="true",
#  all the directories in the remote share will be listed and mounted locally,
#  except the special ones (i.e. linux and config);
#  when SINGLE_CIFS_CONNECTION="false" all the directories in the SD root,
#  except the special ones (i.e. linux and config), will be mounted when one
#  with a matching name is found on the remote share.
LOCAL_DIR="cifs"

#Optional additional mount options, when in doubt leave blank.
#If you have problems not related to username/password, you can try "vers=2.0" or "vers=3.0".
ADDITIONAL_MOUNT_OPTIONS=""

#"true" in order to wait for the CIFS server to be reachable;
#useful when using this script at boot time.
WAIT_FOR_SERVER="false"

#"true" for automounting CIFS shares at boot time;
#this MiSTer-safe copy uses /media/fat/linux/user-startup.sh when available,
#and falls back to a late /etc/init.d startup entry instead of network if-up.d hooks.
MOUNT_AT_BOOT="false"



#========= ADVANCED OPTIONS =========
BASE_PATH="/media/fat"
#MISTER_CIFS_URL="https://github.com/MiSTer-devel/CIFS_MiSTer"
KERNEL_MODULES="md4.ko|md5.ko|des_generic.ko|fscache.ko|cifs.ko"
IFS="|"
SINGLE_CIFS_CONNECTION="true"
#Pipe "|" separated list of directories which will never be mounted when LOCAL_DIR="*"
SPECIAL_DIRECTORIES="config|linux|System Volume Information"
BOOT_START_DELAY_SECONDS="8"
NETWORK_READY_TIMEOUT_SECONDS="45"
DEFAULT_ROUTE_READY_TIMEOUT_SECONDS="30"
DUAL_INTERFACE_SETTLE_SECONDS="5"
SERVER_WAIT_TIMEOUT_SECONDS="60"
BOOT_LOG_PATH="/tmp/cifs_mount.log"
RESTART_NTP_AFTER_BOOT_MOUNT="auto"
NTP_INIT_SCRIPT="/etc/init.d/S49ntp"



#=========CODE STARTS HERE=========

BOOT_ARG="--boot-start"
USER_STARTUP="/media/fat/linux/user-startup.sh"
USER_STARTUP_TEMPLATE="/media/fat/linux/_user-startup.sh"

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
SCRIPT_NAME=${ORIGINAL_SCRIPT_PATH##*/}
SCRIPT_NAME=${SCRIPT_NAME%.*}
SCRIPT_REALPATH=$(resolve_path "$ORIGINAL_SCRIPT_PATH")
INI_PATH=${ORIGINAL_SCRIPT_PATH%.*}.ini
FALLBACK_INI="/media/fat/Scripts/cifs_mount.ini"
STARTUP_LEGACY_MARKER="# Startup ${SCRIPT_NAME}"
STARTUP_BEGIN_MARKER="# ${SCRIPT_NAME}: BEGIN managed boot mount"
STARTUP_END_MARKER="# ${SCRIPT_NAME}: END managed boot mount"
STARTUP_MATCH="${SCRIPT_NAME}.sh ${BOOT_ARG}"
STARTUP_COMMAND="[ -e \"${SCRIPT_REALPATH}\" ] && \"${SCRIPT_REALPATH}\" ${BOOT_ARG} &"
INIT_SERVICE_PATH="/etc/init.d/S99${SCRIPT_NAME}"
BOOT_CONFIG_CHANGED="false"
ROOT_WAS_RO="false"
ROOT_EDIT_ACTIVE="false"
IPTABLES_SUPPORT="false"
FIREWALL_RULE_ADDED="false"
MOUNT_FAILURES=0
MULTI_INTERFACE_BOOT="false"

BOOT_START="false"
if [ "${1:-}" == "$BOOT_ARG" ]
then
	BOOT_START="true"
	shift
fi

if [ -f "$INI_PATH" ]
then
	eval "$(tr -d '\r' < "$INI_PATH")"
elif [ "$INI_PATH" != "$FALLBACK_INI" ] && [ -f "$FALLBACK_INI" ]
then
	eval "$(tr -d '\r' < "$FALLBACK_INI")"
fi

start_boot_log() {
	[ "$BOOT_START" == "true" ] || return 0
	: >> "$BOOT_LOG_PATH" 2>/dev/null || return 0
	echo "==== $(date '+%Y-%m-%d %H:%M:%S') ${SCRIPT_NAME} boot start ====" >> "$BOOT_LOG_PATH"
	exec >> "$BOOT_LOG_PATH" 2>&1
}

start_boot_log

begin_root_edit() {
	ROOT_WAS_RO="false"
	ROOT_EDIT_ACTIVE="true"
	if mount | grep "on / .*[(,]ro[,$]" -q
	then
		ROOT_WAS_RO="true"
		mount / -o remount,rw || return 1
	fi
}

end_root_edit() {
	[ "$ROOT_EDIT_ACTIVE" == "true" ] || return 0
	sync
	[ "${ROOT_WAS_RO:-false}" == "true" ] && mount / -o remount,ro
	ROOT_WAS_RO="false"
	ROOT_EDIT_ACTIVE="false"
}

open_netbios_lookup() {
	IPTABLES_SUPPORT="false"
	FIREWALL_RULE_ADDED="false"

	iptables -L >/dev/null 2>&1 || return 0
	IPTABLES_SUPPORT="true"
	iptables -C INPUT -p udp --sport 137 -j ACCEPT >/dev/null 2>&1 && return 0
	iptables -I INPUT -p udp --sport 137 -j ACCEPT >/dev/null 2>&1 && FIREWALL_RULE_ADDED="true"
}

close_netbios_lookup() {
	if [ "$IPTABLES_SUPPORT" == "true" ] && [ "$FIREWALL_RULE_ADDED" == "true" ]
	then
		iptables -D INPUT -p udp --sport 137 -j ACCEPT >/dev/null 2>&1 || true
	fi
	FIREWALL_RULE_ADDED="false"
}

is_ipv4_literal() {
	echo "$1" | grep -q "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$"
}

resolve_dns_server() {
	local LOOKUP_SERVER="$1"
	local RESOLVED_SERVER

	if command -v getent >/dev/null 2>&1
	then
		RESOLVED_SERVER=$(getent ahostsv4 "$LOOKUP_SERVER" 2>/dev/null | awk '/^[0-9]+\./ { print $1; exit }')
		[ "$RESOLVED_SERVER" != "" ] && echo "$RESOLVED_SERVER" && return 0
		RESOLVED_SERVER=$(getent hosts "$LOOKUP_SERVER" 2>/dev/null | awk '/^[0-9]+\./ { print $1; exit }')
		[ "$RESOLVED_SERVER" != "" ] && echo "$RESOLVED_SERVER" && return 0
	fi

	if command -v nslookup >/dev/null 2>&1
	then
		RESOLVED_SERVER=$(nslookup "$LOOKUP_SERVER" 2>/dev/null | awk '
			/^Name:/ || /Non-authoritative answer:/ { found = 1; next }
			found {
				for (i = 1; i <= NF; i++) {
					if ($i ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
						print $i
						exit
					}
				}
			}
		')
		[ "$RESOLVED_SERVER" != "" ] && echo "$RESOLVED_SERVER" && return 0
	fi

	return 1
}

resolve_netbios_server() {
	local LOOKUP_SERVER="$1"
	local RESOLVED_SERVER

	command -v nmblookup >/dev/null 2>&1 || return 1
	open_netbios_lookup
	RESOLVED_SERVER=$(nmblookup "$LOOKUP_SERVER" 2>/dev/null | awk '/^[0-9]+\./ { print $1; exit }')
	close_netbios_lookup
	[ "$RESOLVED_SERVER" != "" ] && echo "$RESOLVED_SERVER" && return 0
	return 1
}

resolve_named_server() {
	resolve_dns_server "$1" && return 0
	resolve_netbios_server "$1"
}

cleanup_on_exit() {
	close_netbios_lookup
	end_root_edit
}

trap cleanup_on_exit EXIT
trap 'cleanup_on_exit; exit 1' HUP TERM
trap 'cleanup_on_exit; exit 130' INT

record_mount_failure() {
	MOUNT_FAILURES=$((MOUNT_FAILURES + 1))
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

target_is_mounted() {
	get_mount_info "$1"
}

mount_cifs_target() {
	local SOURCE="$1"
	local TARGET="$2"
	local LABEL="$3"

	mkdir -p "$TARGET" > /dev/null 2>&1
	if target_is_mounted "$TARGET"
	then
		echo "$LABEL already mounted"
		return 0
	fi

	if mount -t cifs "$SOURCE" "$TARGET" -o "$MOUNT_OPTIONS"
	then
		echo "$LABEL mounted"
		return 0
	fi

	echo "$LABEL not mounted"
	record_mount_failure
	return 1
}

mount_bind_target() {
	local SOURCE="$1"
	local TARGET="$2"
	local LABEL="$3"

	mkdir -p "$TARGET" > /dev/null 2>&1
	if target_is_mounted "$TARGET"
	then
		echo "$LABEL already mounted"
		return 0
	fi

	if mount --bind "$SOURCE" "$TARGET"
	then
		echo "$LABEL mounted"
		return 0
	fi

	echo "$LABEL not mounted"
	record_mount_failure
	return 1
}

unmount_temp_bind_mounts() {
	local TEMP_MOUNT="$1"
	local LINE
	local SOURCE
	local REST
	local TARGET

	while IFS= read -r LINE
	do
		SOURCE=${LINE%% on *}
		case "$SOURCE" in
			"$TEMP_MOUNT"/*) ;;
			*) continue ;;
		esac
		REST=${LINE#* on }
		[ "$REST" != "$LINE" ] || continue
		TARGET=${REST%% type *}
		echo "Recovering stale ${TARGET##*/} bind mount"
		umount "$TARGET" >/dev/null 2>&1 || true
	done <<EOF
$(mount)
EOF
}

prepare_temp_mount() {
	local TEMP_MOUNT="/tmp/$SCRIPT_NAME"

	mkdir -p "$TEMP_MOUNT" > /dev/null 2>&1
	if target_is_mounted "$TEMP_MOUNT"
	then
		if [ "$MOUNT_TYPE_FOR_TARGET" == "cifs" ] && [ "$MOUNT_SOURCE_FOR_TARGET" == "$MOUNT_SOURCE" ]
		then
			echo "$MOUNT_SOURCE already mounted"
			return 0
		fi

		echo "Recovering stale ${TEMP_MOUNT} mount"
		unmount_temp_bind_mounts "$TEMP_MOUNT"
		if ! umount "$TEMP_MOUNT"
		then
			echo "$MOUNT_SOURCE not mounted"
			record_mount_failure
			return 1
		fi
	fi

	mount_cifs_target "$MOUNT_SOURCE" "$TEMP_MOUNT" "$MOUNT_SOURCE"
}

remove_legacy_network_hooks() {
	local HOOK_PATHS
	local HOOK_PATH
	local TOUCHED="false"

	HOOK_PATHS="/etc/network/if-up.d/mount_cifs|/etc/network/if-down.d/mount_cifs|/etc/network/if-up.d/cifs_mount|/etc/network/if-down.d/cifs_mount|/etc/network/if-up.d/${SCRIPT_NAME}|/etc/network/if-down.d/${SCRIPT_NAME}"
	local OLD_IFS="$IFS"
	IFS="|"
	for HOOK_PATH in $HOOK_PATHS
	do
		[ -e "$HOOK_PATH" ] || continue
		if [ "$TOUCHED" == "false" ]
		then
			begin_root_edit || return 1
			TOUCHED="true"
		fi
		rm "$HOOK_PATH" >/dev/null 2>&1 || true
	done
	IFS="$OLD_IFS"

	[ "$TOUCHED" == "true" ] && end_root_edit
}

ensure_user_startup() {
	[ -e /etc/init.d/S99user ] || return 1
	if [ ! -e "$USER_STARTUP" ]
	then
		if [ -e "$USER_STARTUP_TEMPLATE" ]
		then
			cp "$USER_STARTUP_TEMPLATE" "$USER_STARTUP"
		else
			printf '#!/bin/sh\n\n' > "$USER_STARTUP"
		fi
	fi
	chmod +x "$USER_STARTUP" >/dev/null 2>&1 || true
	return 0
}

remove_user_startup_entry() {
	local TMP_STARTUP

	[ -e "$USER_STARTUP" ] || return 0
	TMP_STARTUP="/tmp/${SCRIPT_NAME}_startup.$$"

	awk -v begin_marker="$STARTUP_BEGIN_MARKER" -v end_marker="$STARTUP_END_MARKER" -v legacy_marker="$STARTUP_LEGACY_MARKER" -v startup_match="$STARTUP_MATCH" '
		$0 == begin_marker { skip = 1; next }
		$0 == end_marker { skip = 0; next }
		skip { next }
		index($0, legacy_marker) { next }
		index($0, startup_match) { next }
		{ print }
	' "$USER_STARTUP" > "$TMP_STARTUP" || { rm -f "$TMP_STARTUP"; return 1; }

	if cmp -s "$TMP_STARTUP" "$USER_STARTUP"
	then
		rm -f "$TMP_STARTUP"
		return 0
	fi

	cat "$TMP_STARTUP" > "$USER_STARTUP"
	rm -f "$TMP_STARTUP"
	BOOT_CONFIG_CHANGED="true"
	chmod +x "$USER_STARTUP" >/dev/null 2>&1 || true
	return 0
}

install_user_startup_entry() {
	local TMP_STARTUP

	ensure_user_startup || return 1
	TMP_STARTUP="/tmp/${SCRIPT_NAME}_startup.$$"

	awk -v begin_marker="$STARTUP_BEGIN_MARKER" -v end_marker="$STARTUP_END_MARKER" -v legacy_marker="$STARTUP_LEGACY_MARKER" -v startup_match="$STARTUP_MATCH" '
		$0 == begin_marker { skip = 1; next }
		$0 == end_marker { skip = 0; next }
		skip { next }
		index($0, legacy_marker) { next }
		index($0, startup_match) { next }
		{ print }
	' "$USER_STARTUP" > "$TMP_STARTUP" || { rm -f "$TMP_STARTUP"; return 1; }
	printf '\n%s\n%s\n%s\n' "$STARTUP_BEGIN_MARKER" "$STARTUP_COMMAND" "$STARTUP_END_MARKER" >> "$TMP_STARTUP"

	if cmp -s "$TMP_STARTUP" "$USER_STARTUP"
	then
		rm -f "$TMP_STARTUP"
		return 0
	fi

	cat "$TMP_STARTUP" > "$USER_STARTUP" || { rm -f "$TMP_STARTUP"; return 1; }
	rm -f "$TMP_STARTUP"
	BOOT_CONFIG_CHANGED="true"
	chmod +x "$USER_STARTUP" >/dev/null 2>&1 || true
	return 0
}

remove_init_service() {
	if [ -e "$INIT_SERVICE_PATH" ]
	then
		begin_root_edit || return 1
		rm "$INIT_SERVICE_PATH" >/dev/null 2>&1 || true
		BOOT_CONFIG_CHANGED="true"
		end_root_edit
	fi
}

install_init_service() {
	local TMP_SERVICE

	TMP_SERVICE="/tmp/${SCRIPT_NAME}_init.$$"
	cat > "$TMP_SERVICE" <<EOF
#!/bin/sh
[ -e "$SCRIPT_REALPATH" ] && "$SCRIPT_REALPATH" $BOOT_ARG &
EOF
	if [ -e "$INIT_SERVICE_PATH" ] && cmp -s "$TMP_SERVICE" "$INIT_SERVICE_PATH"
	then
		rm -f "$TMP_SERVICE"
		return 0
	fi

	begin_root_edit || { rm -f "$TMP_SERVICE"; return 1; }
	cat "$TMP_SERVICE" > "$INIT_SERVICE_PATH" || { rm -f "$TMP_SERVICE"; end_root_edit; return 1; }
	rm -f "$TMP_SERVICE"
	chmod +x "$INIT_SERVICE_PATH"
	BOOT_CONFIG_CHANGED="true"
	end_root_edit
}

configure_boot_mount() {
	local BOOT_TARGET

	BOOT_CONFIG_CHANGED="false"
	if [ "$MOUNT_AT_BOOT" == "true" ]
	then
		WAIT_FOR_SERVER="true"
		if install_user_startup_entry
		then
			BOOT_TARGET="$USER_STARTUP"
			remove_init_service
		else
			install_init_service || return 1
			BOOT_TARGET="$INIT_SERVICE_PATH"
		fi
		[ "$BOOT_CONFIG_CHANGED" == "true" ] && echo "Boot automount enabled via ${BOOT_TARGET}."
	else
		remove_user_startup_entry || true
		remove_init_service
		[ "$BOOT_CONFIG_CHANGED" == "true" ] && echo "Boot automount disabled."
	fi
}

wait_for_network_ready() {
	local TIMEOUT
	local WAITED

	if [ "${BOOT_START_DELAY_SECONDS:-0}" -gt 0 ] 2>/dev/null
	then
		sleep "$BOOT_START_DELAY_SECONDS"
	fi

	if ! command -v ip >/dev/null 2>&1
	then
		return 0
	fi

	TIMEOUT="${NETWORK_READY_TIMEOUT_SECONDS:-45}"
	case "$TIMEOUT" in
		''|*[!0-9]*) TIMEOUT="45" ;;
	esac
	WAITED=0

	echo "Waiting for network"
	until ip -o -4 addr show up scope global 2>/dev/null | grep -q .
	do
		if [ "$TIMEOUT" -gt 0 ] && [ "$WAITED" -ge "$TIMEOUT" ]
		then
			echo "Network not ready after ${TIMEOUT} seconds."
			return 1
		fi
		sleep 1
		WAITED=$((WAITED + 1))
	done
}

default_route_exists() {
	if command -v ip >/dev/null 2>&1
	then
		ip route show default 2>/dev/null | grep -q . && return 0
	fi
	if command -v route >/dev/null 2>&1
	then
		route -n 2>/dev/null | grep -q '^0\.0\.0\.0' && return 0
	fi
	return 1
}

global_ipv4_interface_count() {
	local COUNT

	if ! command -v ip >/dev/null 2>&1
	then
		echo "0"
		return 0
	fi

	COUNT=$(ip -o -4 addr show up scope global 2>/dev/null | cut -d' ' -f2 | sort -u | wc -l | tr -d ' ')
	case "$COUNT" in
		''|*[!0-9]*) COUNT="0" ;;
	esac
	echo "$COUNT"
}

wait_for_default_route() {
	local TIMEOUT
	local WAITED
	local INTERFACE_COUNT
	local SETTLE_SECONDS

	if ! command -v ip >/dev/null 2>&1 && ! command -v route >/dev/null 2>&1
	then
		return 0
	fi

	TIMEOUT="${DEFAULT_ROUTE_READY_TIMEOUT_SECONDS:-30}"
	case "$TIMEOUT" in
		''|*[!0-9]*) TIMEOUT="30" ;;
	esac
	WAITED=0

	echo "Waiting for default route"
	until default_route_exists
	do
		if [ "$TIMEOUT" -gt 0 ] && [ "$WAITED" -ge "$TIMEOUT" ]
		then
			echo "Default route not ready after ${TIMEOUT} seconds."
			return 1
		fi
		sleep 1
		WAITED=$((WAITED + 1))
	done

	INTERFACE_COUNT=$(global_ipv4_interface_count)
	if [ "$INTERFACE_COUNT" -gt 1 ] 2>/dev/null
	then
		MULTI_INTERFACE_BOOT="true"
		SETTLE_SECONDS="${DUAL_INTERFACE_SETTLE_SECONDS:-5}"
		case "$SETTLE_SECONDS" in
			''|*[!0-9]*) SETTLE_SECONDS="5" ;;
		esac
		if [ "$SETTLE_SECONDS" -gt 0 ]
		then
			echo "Settling dual-interface routing for ${SETTLE_SECONDS} seconds"
			sleep "$SETTLE_SECONDS"
		fi
	fi
}

restart_ntp_after_boot_mount() {
	[ "$BOOT_START" == "true" ] || return 0

	case "$RESTART_NTP_AFTER_BOOT_MOUNT" in
		true) ;;
		auto)
			[ "$MULTI_INTERFACE_BOOT" == "true" ] || return 0
			;;
		*)
			return 0
			;;
	esac

	[ -x "$NTP_INIT_SCRIPT" ] || return 0
	echo "Restarting NTP"
	if ! "$NTP_INIT_SCRIPT" restart >/dev/null 2>&1
	then
		echo "NTP restart failed"
	fi
}

remove_legacy_network_hooks || true

if [ "$BOOT_START" == "true" ] && [ "$MOUNT_AT_BOOT" != "true" ]
then
	exit 0
fi

if [ "$BOOT_START" != "true" ] && [ "$MOUNT_AT_BOOT" != "true" ]
then
	configure_boot_mount || true
fi

if [ "$SERVER" == "" ]
then
	echo "Please configure"
	echo "this script"
	echo "either editing"
	echo "${ORIGINAL_SCRIPT_PATH##*/}"
	echo "or making a new"
	echo "${INI_PATH##*/}"
	exit 1
fi

if [ "$BOOT_START" != "true" ] && [ "$MOUNT_AT_BOOT" == "true" ]
then
	configure_boot_mount || exit 1
elif [ "$BOOT_START" == "true" ]
then
	WAIT_FOR_SERVER="true"
	wait_for_network_ready || exit 1
	wait_for_default_route || exit 1
fi

for KERNEL_MODULE in $KERNEL_MODULES; do
	if ! cat /lib/modules/$(uname -r)/modules.builtin | grep -q "$(echo "$KERNEL_MODULE" | sed 's/\./\\\./g')"
	then
		if ! lsmod | grep -q "${KERNEL_MODULE%.*}"
		then
			echo "The current Kernel doesn't"
			echo "support CIFS (SAMBA)."
			echo "Please update your"
			echo "MiSTer Linux system."
			exit 1
#			if ! insmod "/media/fat/linux/$KERNEL_MODULE" > /dev/null 2>&1
#			then
#				echo "Downloading $KERNEL_MODULE"
#				curl -L "$MISTER_CIFS_URL/blob/master/$KERNEL_MODULE?raw=true" -o "/media/fat/linux/$KERNEL_MODULE"
#				case $? in
#					0)
#						;;
#					60)
#						if ! curl -kL "$MISTER_CIFS_URL/blob/master/$KERNEL_MODULE?raw=true" -o "/media/fat/linux/$KERNEL_MODULE"
#						then
#							echo "No Internet connection"
#							exit 2
#						fi
#						;;
#					*)
#						echo "No Internet connection"
#						exit 2
#						;;
#				esac
#				if ! insmod "/media/fat/linux/$KERNEL_MODULE" > /dev/null 2>&1
#				then
#					echo "Unable to load $KERNEL_MODULE"
#					exit 1
#				fi
#			fi
		fi
	fi
done

if [ "$USERNAME" == "" ]
then
	MOUNT_OPTIONS="sec=none"
else
	MOUNT_OPTIONS="username=$USERNAME,password=$PASSWORD"
	if [ "$DOMAIN" != "" ]
	then
		MOUNT_OPTIONS="$MOUNT_OPTIONS,domain=$DOMAIN"
	fi
fi
if [ "$ADDITIONAL_MOUNT_OPTIONS" != "" ]
then
	MOUNT_OPTIONS="$MOUNT_OPTIONS,$ADDITIONAL_MOUNT_OPTIONS"
fi

if ! is_ipv4_literal "$SERVER"
then
	SERVER_WAIT_TIMEOUT="${SERVER_WAIT_TIMEOUT_SECONDS:-60}"
	case "$SERVER_WAIT_TIMEOUT" in
		''|*[!0-9]*) SERVER_WAIT_TIMEOUT="60" ;;
	esac
	if [ "$WAIT_FOR_SERVER" == "true" ]
	then
		SERVER_WAITED=0
		echo "Waiting for $SERVER"
		until RESOLVED_SERVER=$(resolve_named_server "$SERVER")
		do
			if [ "$SERVER_WAIT_TIMEOUT" -gt 0 ] && [ "$SERVER_WAITED" -ge "$SERVER_WAIT_TIMEOUT" ]
			then
				echo "$SERVER not found after ${SERVER_WAIT_TIMEOUT} seconds."
				exit 1
			fi
			sleep 1
			SERVER_WAITED=$((SERVER_WAITED + 1))
		done
	else
		RESOLVED_SERVER=$(resolve_named_server "$SERVER")
	fi
	if [ "$RESOLVED_SERVER" == "" ]
	then
		echo "$SERVER not found."
		exit 1
	fi
	SERVER="$RESOLVED_SERVER"
else
	if [ "$WAIT_FOR_SERVER" == "true" ]
	then
		SERVER_WAIT_TIMEOUT="${SERVER_WAIT_TIMEOUT_SECONDS:-60}"
		case "$SERVER_WAIT_TIMEOUT" in
			''|*[!0-9]*) SERVER_WAIT_TIMEOUT="60" ;;
		esac
		SERVER_WAITED=0
		echo "Waiting for $SERVER"
		until ping -q -w1 -c1 "$SERVER" &>/dev/null
		do
			if [ "$SERVER_WAIT_TIMEOUT" -gt 0 ] && [ "$SERVER_WAITED" -ge "$SERVER_WAIT_TIMEOUT" ]
			then
				echo "$SERVER not reachable after ${SERVER_WAIT_TIMEOUT} seconds."
				exit 1
			fi
			sleep 1
			SERVER_WAITED=$((SERVER_WAITED + 1))
		done
	fi
fi

MOUNT_SOURCE="//$SERVER/$SHARE"

if [ -n "$SHARE_DIRECTORY" ] && [ -n "$MOUNT_SOURCE" ]
then
	MOUNT_SOURCE="$MOUNT_SOURCE/$SHARE_DIRECTORY"
fi

if [ "$LOCAL_DIR" == "*" ] || { echo "$LOCAL_DIR" | grep -q "|"; }
then
	if [ "$SINGLE_CIFS_CONNECTION" == "true" ]
	then
		if prepare_temp_mount
		then
			if [ "$LOCAL_DIR" == "*" ]
			then
				LOCAL_DIR=""
				for DIRECTORY in "/tmp/$SCRIPT_NAME"/*
				do
					if [ -d "$DIRECTORY" ]
					then
						DIRECTORY=$(basename "$DIRECTORY")
						for SPECIAL_DIRECTORY in $SPECIAL_DIRECTORIES
						do
							if [ "$DIRECTORY" == "$SPECIAL_DIRECTORY" ]
							then
								DIRECTORY=""
								break
							fi
						done
						if [ "$DIRECTORY" != "" ]
						then
							if [ "$LOCAL_DIR" != "" ]
							then
								LOCAL_DIR="$LOCAL_DIR|"
							fi
							LOCAL_DIR="$LOCAL_DIR$DIRECTORY"
						fi
					fi
				done
			fi
			for DIRECTORY in $LOCAL_DIR
			do
				mount_bind_target "/tmp/$SCRIPT_NAME/$DIRECTORY" "$BASE_PATH/$DIRECTORY" "$DIRECTORY"
			done
		fi
	else
		if [ "$LOCAL_DIR" == "*" ]
		then
			LOCAL_DIR=""
			for DIRECTORY in "$BASE_PATH"/*
			do
				if [ -d "$DIRECTORY" ]
				then
					DIRECTORY=$(basename "$DIRECTORY")
					for SPECIAL_DIRECTORY in $SPECIAL_DIRECTORIES
					do
						if [ "$DIRECTORY" == "$SPECIAL_DIRECTORY" ]
						then
							DIRECTORY=""
							break
						fi
					done
					if [ "$DIRECTORY" != "" ]
					then
						if [ "$LOCAL_DIR" != "" ]
						then
							LOCAL_DIR="$LOCAL_DIR|"
						fi
						LOCAL_DIR="$LOCAL_DIR$DIRECTORY"
					fi
				fi
			done
		fi
		for DIRECTORY in $LOCAL_DIR
		do
			mount_cifs_target "$MOUNT_SOURCE/$DIRECTORY" "$BASE_PATH/$DIRECTORY" "$DIRECTORY"
		done
	fi
else
	mount_cifs_target "$MOUNT_SOURCE" "$BASE_PATH/$LOCAL_DIR" "$LOCAL_DIR"
fi

if [ "$MOUNT_FAILURES" -gt 0 ]
then
	echo "Done with ${MOUNT_FAILURES} failure(s)."
	exit 1
fi

restart_ntp_after_boot_mount

echo "Done!"
exit 0
