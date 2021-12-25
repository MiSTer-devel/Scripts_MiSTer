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
# https://github.com/MiSTer-devel/CIFS_MiSTer

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
#name as the script, i.e. mount_cifs.ini, containing the same options.

#Your CIFS Server, i.e. your NAS name or its IP address.
SERVER=""

#The share name on the Server.
SHARE="MiSTer"

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
#it will create start/kill scripts in /etc/network/if-up.d and /etc/network/if-down.d.
MOUNT_AT_BOOT="false"



#========= ADVANCED OPTIONS =========
BASE_PATH="/media/fat"
#MISTER_CIFS_URL="https://github.com/MiSTer-devel/CIFS_MiSTer"
KERNEL_MODULES="md4.ko|md5.ko|des_generic.ko|fscache.ko|cifs.ko"
IFS="|"
SINGLE_CIFS_CONNECTION="true"
#Pipe "|" separated list of directories which will never be mounted when LOCAL_DIR="*"
SPECIAL_DIRECTORIES="config|linux|System Volume Information"



#=========CODE STARTS HERE=========

ORIGINAL_SCRIPT_PATH="$0"
if [ "$ORIGINAL_SCRIPT_PATH" == "bash" ]
then
	ORIGINAL_SCRIPT_PATH=$(ps | grep "^ *$PPID " | grep -o "[^ ]*$")
fi
INI_PATH=${ORIGINAL_SCRIPT_PATH%.*}.ini
if [ -f $INI_PATH ]
then
	eval "$(cat $INI_PATH | tr -d '\r')"
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

if [ "$(basename "ORIGINAL_SCRIPT_PATH")" != "mount_cifs.sh" ]
then
	if [ -f "/etc/network/if-up.d/mount_cifs" ] || [ -f "/etc/network/if-down.d/mount_cifs" ]
	then
		mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
		[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
		rm "/etc/network/if-up.d/mount_cifs" > /dev/null 2>&1
		rm "/etc/network/if-down.d/mount_cifs" > /dev/null 2>&1
		sync
		[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
	fi
fi
NET_UP_SCRIPT="/etc/network/if-up.d/$(basename ${ORIGINAL_SCRIPT_PATH%.*})"
NET_DOWN_SCRIPT="/etc/network/if-down.d/$(basename ${ORIGINAL_SCRIPT_PATH%.*})"
if [ "$MOUNT_AT_BOOT" ==  "true" ]
then
	WAIT_FOR_SERVER="true"
	if [ ! -f "$NET_UP_SCRIPT" ] || [ ! -f "$NET_DOWN_SCRIPT" ]
	then
		mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
		[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
		echo "#!/bin/bash"$'\n'"$(realpath "$ORIGINAL_SCRIPT_PATH") &" > "$NET_UP_SCRIPT"
		chmod +x "$NET_UP_SCRIPT"
		echo "#!/bin/bash"$'\n'"umount -a -t cifs" > "$NET_DOWN_SCRIPT"
		chmod +x "$NET_DOWN_SCRIPT"
		sync
		[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
	fi
else
	if [ -f "$NET_UP_SCRIPT" ] || [ -f "$NET_DOWN_SCRIPT" ]
	then
		mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
		[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
		rm "$NET_UP_SCRIPT" > /dev/null 2>&1
		rm "$NET_DOWN_SCRIPT" > /dev/null 2>&1
		sync
		[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
	fi
fi

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

if ! echo "$SERVER" | grep -q "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$"
then
	if iptables -L > /dev/null 2>&1; then IPTABLES_SUPPORT="true"; else IPTABLES_SUPPORT="false"; fi
	[ "$IPTABLES_SUPPORT" == "true" ] && if iptables -C INPUT -p udp --sport 137 -j ACCEPT > /dev/null 2>&1; then PRE_EXISTING_FIREWALL_RULE="true"; else PRE_EXISTING_FIREWALL_RULE="false"; fi
	[ "$IPTABLES_SUPPORT" == "true" ] && [ "$PRE_EXISTING_FIREWALL_RULE" == "false" ] && iptables -I INPUT -p udp --sport 137 -j ACCEPT > /dev/null 2>&1
	if [ "$WAIT_FOR_SERVER" == "true" ]
	then
		echo "Waiting for $SERVER"
		until nmblookup $SERVER &>/dev/null
		do
			[ "$IPTABLES_SUPPORT" == "true" ] && [ "$PRE_EXISTING_FIREWALL_RULE" == "false" ] && iptables -D INPUT -p udp --sport 137 -j ACCEPT > /dev/null 2>&1
			sleep 1
			[ "$IPTABLES_SUPPORT" == "true" ] && if iptables -C INPUT -p udp --sport 137 -j ACCEPT > /dev/null 2>&1; then PRE_EXISTING_FIREWALL_RULE="true"; else PRE_EXISTING_FIREWALL_RULE="false"; fi
			[ "$IPTABLES_SUPPORT" == "true" ] && [ "$PRE_EXISTING_FIREWALL_RULE" == "false" ] && iptables -I INPUT -p udp --sport 137 -j ACCEPT > /dev/null 2>&1
		done
	fi
	SERVER=$(nmblookup $SERVER|awk 'END{print $1}')
	[ "$IPTABLES_SUPPORT" == "true" ] && [ "$PRE_EXISTING_FIREWALL_RULE" == "false" ] && iptables -D INPUT -p udp --sport 137 -j ACCEPT > /dev/null 2>&1
else
	if [ "$WAIT_FOR_SERVER" == "true" ]
	then
		echo "Waiting for $SERVER"
		until ping -q -w1 -c1 $SERVER &>/dev/null
		do
			sleep 1
		done
	fi
fi

if [ "$LOCAL_DIR" == "*" ] || { echo "$LOCAL_DIR" | grep -q "|"; }
then
	if [ "$SINGLE_CIFS_CONNECTION" == "true" ]
	then
		SCRIPT_NAME=${ORIGINAL_SCRIPT_PATH##*/}
		SCRIPT_NAME=${SCRIPT_NAME%.*}
		mkdir -p "/tmp/$SCRIPT_NAME" > /dev/null 2>&1
		if mount -t cifs "//$SERVER/$SHARE" "/tmp/$SCRIPT_NAME" -o "$MOUNT_OPTIONS"
		then
			echo "//$SERVER/$SHARE mounted"
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
				mkdir -p "$BASE_PATH/$DIRECTORY" > /dev/null 2>&1
				if mount --bind "/tmp/$SCRIPT_NAME/$DIRECTORY" "$BASE_PATH/$DIRECTORY"
				then
					echo "$DIRECTORY mounted"
				else
					echo "$DIRECTORY not mounted"
				fi
			done
		else
			echo "//$SERVER/$SHARE not mounted"
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
			mkdir -p "$BASE_PATH/$DIRECTORY" > /dev/null 2>&1
			if mount -t cifs "//$SERVER/$SHARE/$DIRECTORY" "$BASE_PATH/$DIRECTORY" -o "$MOUNT_OPTIONS"
			then
				echo "$DIRECTORY mounted"
			else
				echo "$DIRECTORY not mounted"
			fi
		done
	fi
else
	mkdir -p "$BASE_PATH/$LOCAL_DIR" > /dev/null 2>&1
	if mount -t cifs "//$SERVER/$SHARE" "$BASE_PATH/$LOCAL_DIR" -o "$MOUNT_OPTIONS"
	then
			echo "$LOCAL_DIR mounted"
	else
			echo "$LOCAL_DIR mounted"
	fi
fi

echo "Done!"
exit 0
