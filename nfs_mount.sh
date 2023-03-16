#!/usr/bin/env bash

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

# Copyright 2022 Oliver "RealLarry" Jaksch

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/CIFS_MiSTer

# Version 1.1 - 2022-12-25 - Cosmetics
# Version 1.0 - 2021-12-29 - First commit



#=========   USER OPTIONS   =========
# You can edit these user options or make an ini file with the same
# name as the script, i.e. nfs_mount.ini, containing the same options.

# Your NFS Server, i.e. your NAS name or it's IP address.
SERVER=""

# The path to mount from your NFS server, for example "/storage/games"
SERVER_PATH=""

# The number of seconds to wait before considering the server unreachable
SERVER_TIMEOUT="60"

# Wake up the server from above by using WOL (Wake On LAN)
WOL="no"
MAC="FFFFFFFFFFFF"
SERVER_MAC="00:11:22:33:44:55"

# Optional additional mount options.
MOUNT_OPTIONS="noatime"

# "yes" for automounting NFS shares at boot time;
# it will create start/kill scripts in /etc/network/if-up.d and /etc/network/if-down.d.
MOUNT_AT_BOOT="yes"

#=========NO USER-SERVICEABLE PARTS BELOW THIS LINE=====

#=========FUNCTION LIBRARY==============================

# Are we running as root?

function as_root() {
  if [ "$(id -u)" != "0" ]; then
    /usr/bin/logger "This script must be run as root. Please run again with sudo or as root user. Exiting."
    exit 1
  fi
}

# Check for existing NFS mounts

function no_existing_nfs() {
  if mount | grep -q nfs; then
    /usr/bin/logger "Found mounted NFS filesystems. Aborting."
    exit 1
  fi
}

# Load script configuration from an INI file.
# ..which isn't really an INI file but just a list of Bash vars
function load_ini() {
 local SCRIPT_PATH="$(realpath "$0")"
 local INI_FILE=${SCRIPT_PATH%.*}.ini
 if [ -e "$INI_FILE" ]; then
   eval "$(cat $INI_FILE | tr -d '\r')"
 fi
}

# Check if we have an IPv4 address on any of the interfaces that is
# not a local loopback (127.0.0.0/8) or link-local (169.254.0.0/16) adddress.

function has_ip_address() {
  local start_time=$(date +%s)
  while [[ $(($(date +%s) - $start_time)) -lt 30 ]]; do
    ip addr show | grep 'inet ' | grep -vE '127.|169.254.' >/dev/null 2>&1
    if [[ $? -eq 0 ]]; then
      return 0
    fi
    sleep 1
  done
  /usr/bin/logger "Failed to obtain an IP address within the time limit. Exiting."
  exit 1
}

# Check if the script's configuration is minimally viable

function viable_config() {
  if [ -z "$SERVER" ] || [ -z "$SERVER_PATH" ]; then
    /usr/bin/logger "SERVER and SERVER_PATH must be set. Exiting."
    exit 1
  fi
}

# Wake-up the NFS server using WOL

function wake_up_nfs() {
  if [ "${WOL}" == "yes" ]; then
    for REP in {1..16}; do
      MAC+=$(echo ${SERVER_MAC})
    done
    echo -n "${MAC}" | xxd -r -u -p | socat - UDP-DATAGRAM:255.255.255.255:9,broadcast
  fi
}

# Wait for the NFS server to be up

function wait_for_nfs() {
  local PORTS=(2049 111)
  local START=$(date +%s)
  local ELAPSED=0

  while [ $ELAPSED -lt $SERVER_TIMEOUT ]; do
    for PORT in "${PORTS[@]}"; do
      if nc -z "$SERVER" "$PORT" >/dev/null 2>&1; then
        /usr/bin/logger "NFS server $SERVER is up."
        return 0
      fi
    done

  sleep 1
  ELAPSED=$(($(date +%s) - $START))
  done

  /usr/bin/logger "Timeout while waiting for NFS server $SERVER."
  exit 1
}


# Install the mount-at-boot scripts

function install_mount_at_boot() {
  # Enable strict error checking
  set -euo pipefail

  # Check if MOUNT_AT_BOOT is set to "yes"
  if [ "${MOUNT_AT_BOOT:-}" != "yes" ]; then
    return 0
  fi

  # Remount root filesystem read-write if it's currently read-only
  if mount | grep -q "on / .*[(,]ro[,$]"; then
    mount -o remount,rw /
    readonly ROOTFS_REMOUNTED="yes"
  fi

  # Set up scripts to run on network interface up/down events
  SCRIPT_PATH="$(realpath "$0")"
  SCRIPT_NAME="$(basename "${SCRIPT_PATH%.*}")"
  NET_UP_SCRIPT="/etc/network/if-up.d/${SCRIPT_NAME}"
  NET_DOWN_SCRIPT="/etc/network/if-down.d/${SCRIPT_NAME}"

  # Ensure directories for scripts exist and have appropriate permissions
  mkdir -p /etc/network/if-up.d /etc/network/if-down.d
  chmod 755 /etc/network /etc/network/if-up.d /etc/network/if-down.d

  # Create network interface up script
  cat >"${NET_UP_SCRIPT}" <<EOF
#!/bin/bash
${SCRIPT_PATH} &
EOF
  chmod 755 "${NET_UP_SCRIPT}"

  # Create network interface down script
  cat >"${NET_DOWN_SCRIPT}" <<EOF
#!/bin/bash
umount -a -t nfs4
EOF
  chmod 755 "${NET_DOWN_SCRIPT}"

  # Remount root filesystem read-only if it was remounted earlier
  if [ "${ROOTFS_REMOUNTED:-}" == "yes" ]; then
    mount -o remount,ro /
  fi

  return 0
}


# Remove the mount-at-boot script

function remove_mount_at_boot() {
  RO_ROOT="no"
  if [ "${MOUNT_AT_BOOT}" != "yes" ]; then
    local ORIGINAL_SCRIPT_PATH="$0"
    local NET_UP_SCRIPT="/etc/network/if-up.d/$(basename ${ORIGINAL_SCRIPT_PATH%.*})"
    local NET_DOWN_SCRIPT="/etc/network/if-down.d/$(basename ${ORIGINAL_SCRIPT_PATH%.*})"

    # We need to write to the root filesystem so remount it
    # read-write if it's currently read-only.
    if mount | grep -q "on / .*[(,]ro[,$]"; then
      RO_ROOT="yes"
      mount / -o remount,rw
    fi

    if [ -f "${NET_UP_SCRIPT}" ]; then
      rm "${NET_UP_SCRIPT}"
    fi

    if [ -f "${NET_DOWN_SCRIPT}" ]; then
      rm "${NET_DOWN_SCRIPT}"
    fi
    sync

    # If we remounted the rootfs because it was read-only, we now
    # undo our remount action and revert the mount to how we found it.
    if [ "${RO_ROOT}" == "yes" ]; then
      mount / -o remount,ro
    fi
    return 0
  fi
}

# Perform the actual mount operation supporting only NFSv4 for now

function mount_nfs() {
  set -e
  local ORIGINAL_SCRIPT_PATH="$0"
  local SCRIPT_NAME="${ORIGINAL_SCRIPT_PATH##*/}"
  SCRIPT_NAME="${SCRIPT_NAME%.*}"
  if ! mkdir -p "/tmp/${SCRIPT_NAME}" >/dev/null 2>&1; then
    /usr/bin/logger "Error: failed to create directory /tmp/${SCRIPT_NAME}"
    exit 1
  fi
  if ! /usr/bin/busybox mount -t nfs4 "${SERVER}:${SERVER_PATH}" "/tmp/${SCRIPT_NAME}" -o "${MOUNT_OPTIONS}"; then
    /usr/bin/logger "Error: failed to mount NFS share ${SERVER}:${SERVER_PATH} to /tmp/${SCRIPT_NAME}"
    exit 1
  fi
  find "/tmp/${SCRIPT_NAME}" -mindepth 1 -maxdepth 1 -type d | while read -r LDIR; do
    LDIR="${LDIR##*/}"
    if [ -d "/media/fat/${LDIR}" ] && ! mount | grep -q "/media/fat/${LDIR}"; then
      if ! mount -o bind "/tmp/${SCRIPT_NAME}/${LDIR}" "/media/fat/${LDIR}"; then
        /usr/bin/logger "Error: failed to mount directory /tmp/${SCRIPT_NAME}/${LDIR} to /media/fat/${LDIR}"
        exit 1
      fi
    fi
  done
}

#=========BUSINESS LOGIC================================
#
# This part just calls the functions we define above
# in a sequence. To keep things excruciatingly easy
# to follow, any and all config checks are done *inside*
# the functions themselves.
#
# Each of these steps will exit if things are not OK.
#
#=======================================================

# Ensure we are the root user
as_root

# Load configuration from the .ini file if we have one.
load_ini

# Only cause changes if the configuration is viable..
viable_config

# ..and our network seems to be working.
has_ip_address

# We wake up the NFS-server if needed
wake_up_nfs

# ..and give it time to actually get dressed.
wait_for_nfs

# Install/update the scripts to run at every reboot
install_mount_at_boot

# ..or remove them if that's what the user wants.
remove_mount_at_boot

# Only ensure we haven't already got NFS filesystems present
no_existing_nfs

# Finally, we mount the NFS filesystem and be done with it.
mount_nfs
exit 0
