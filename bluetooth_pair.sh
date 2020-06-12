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

# Original script by Alexey "Sorgelig" Melnikov https://github.com/MiSTer-devel/Main_MiSTer/wiki
# Copyright 2019 Alessandro "Locutus73" Miele

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer



# Version 1.0 - 2019-10-26 - First commit.



# ========= OPTIONS ==================

# ========= ADVANCED OPTIONS =========

DIALOG_HEIGHT="31"

# ========= CODE STARTS HERE =========

function checkTERMINAL {
#	if [ "$(uname -n)" != "MiSTer" ]
#	then
#		echo "This script must be run"
#		echo "on a MiSTer system."
#		exit 1
#	fi
	if [[ ! (-t 0 && -t 1 && -t 2) ]]
	then
		echo "This script must be run"
		echo "from an interactive terminal."
		echo "Please press F9 (F12 to exit)"
		echo "or use SSH."
		exit 2
	fi
}

function setupDIALOG {
	DIALOG="dialog"

	
	export NCURSES_NO_UTF8_ACS=1
	
	: ${DIALOG_OK=0}
	: ${DIALOG_CANCEL=1}
	: ${DIALOG_HELP=2}
	: ${DIALOG_EXTRA=3}
	: ${DIALOG_ITEM_HELP=4}
	: ${DIALOG_ESC=255}

	: ${SIG_NONE=0}
	: ${SIG_HUP=1}
	: ${SIG_INT=2}
	: ${SIG_QUIT=3}
	: ${SIG_KILL=9}
	: ${SIG_TERM=15}
}

function setupDIALOGtempfile {
	DIALOG_TEMPFILE=`(DIALOG_TEMPFILE) 2>/dev/null` || DIALOG_TEMPFILE=/tmp/dialog_tempfile$$
	trap "rm -f $DIALOG_TEMPFILE" 0 $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM
}

function readDIALOGtempfile {
	DIALOG_RETVAL=$?
	DIALOG_OUTPUT="$(cat ${DIALOG_TEMPFILE})"
	#rm -f ${DIALOG_TEMPFILE}
	#unset DIALOG_TEMPFILE
}


checkTERMINAL

RESCAN=true

while $RESCAN; do
	RESCAN=false

	clear
	echo Switch input devices
	echo to pairing mode.
	echo Searching...
	echo

	OLD_IFS="$IFS"
	IFS=$'\n'
	MAC_NAMES=( $( btscan ) )
	IFS="$OLD_IFS"

	unset MENU_ITEMS
	if [ ! -z "${MAC_NAMES[*]}" ]; then
		for MAC_NAME in "${MAC_NAMES[@]}"; do
			MAC=$(echo "${MAC_NAME}" | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}')
			NAME=$(echo "${MAC_NAME}" | sed 's/[^ 	]*[ 	]*//')
			MENU_ITEMS="${MENU_ITEMS} \"${MAC}\" \"${NAME}\""
		done

		setupDIALOG
		setupDIALOGtempfile
		eval ${DIALOG} --clear --colors --ok-label \"Pair\" \
			--title \"Bluetooth pair\" \
			--extra-button --extra-label \"Rescan\"\
			--menu \"Please select the Controller/Keyboard/Mouse you want to pair.\" ${DIALOG_HEIGHT} 0 999 \
			${MENU_ITEMS} \
			2> ${DIALOG_TEMPFILE}
		readDIALOGtempfile

		case ${DIALOG_RETVAL} in
			${DIALOG_OK})
				clear
				MAC="${DIALOG_OUTPUT}"
				;;
			${DIALOG_EXTRA})
				RESCAN=true
				;;
			${DIALOG_CANCEL})
				clear
				exit 0
				;;
			*)
				exit 1
				;;
		esac
	fi
done

if [ ! -z "${MAC}" ]; then
	pair-agent hci0 $MAC
else
	echo nothing found.
fi
