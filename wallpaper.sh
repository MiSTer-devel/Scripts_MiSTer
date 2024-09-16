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

# Copyright 2020 Pavel "Pasha-From-Russia" Borovskikh
# based on work of 
#   Alessandro "Locutus73" Miele
#   Alexey "Sorgelig" Melnikov 

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer

# Version 1.0 - 2020-11-23 - First commit



# ========= OPTIONS ==================

DIALOG_TITLE="MiSTer Wallpaper Manager"
WALLPAPER_DIR=/media/fat/Backgrounds

# ========= ADVANCED OPTIONS =========

DIALOG_HEIGHT="31"

# ========= CODE STARTS HERE =========

function checkTERMINAL()
{
	if [[ ! (-t 0 && -t 1 && -t 2) ]]; then
		echo "This script must be run"
		echo "from an interactive terminal."
		echo "Please press F9 (F12 to exit)"
		echo "or use SSH."
		exit 2
	fi
}

function setupDIALOG()
{
	local ORIGINAL_SCRIPT_PATH="${0}"
	if which dialog > /dev/null 2>&1
	then
		DIALOG="dialog"
	else
		DIALOG="/media/fat/linux/dialog/dialog"
		if [ ! -f ${DIALOG} ]; then
			set -e
			exit 0
		fi
		
		export LD_LIBRARY_PATH="/media/fat/linux/dialog"
	fi
	
	rm -f "/media/fat/config/dialogrc"
	if [ ! -f "~/.dialogrc" ]; then
		export DIALOGRC="$(dirname ${ORIGINAL_SCRIPT_PATH})/.dialogrc"
		if [ ! -f "${DIALOGRC}" ]; then
			${DIALOG} --create-rc "${DIALOGRC}"
			sed -i "s/use_colors = OFF/use_colors = ON/g" "${DIALOGRC}"
			sed -i "s/screen_color = (CYAN,BLUE,ON)/screen_color = (CYAN,BLACK,ON)/g" "${DIALOGRC}"
			sync
		fi
	fi
	
	export NCURSES_NO_UTF8_ACS=1
	
	: ${DIALOG_OK=0}
	: ${DIALOG_CANCEL=1}
	: ${DIALOG_ESC=255}

	: ${SIG_NONE=0}
	: ${SIG_HUP=1}
	: ${SIG_INT=2}
	: ${SIG_QUIT=3}
	: ${SIG_KILL=9}
	: ${SIG_TERM=15}
}

function setupDIALOGtempfile()
{
	DIALOG_TEMPFILE=`(DIALOG_TEMPFILE) 2>/dev/null` || DIALOG_TEMPFILE=/tmp/dialog_tempfile$$
	trap "rm -f $DIALOG_TEMPFILE 2>/dev/null" 0 $SIG_NONE $SIG_HUP $SIG_INT $SIG_QUIT $SIG_TERM $SIG_KILL
}

function readDIALOGtempfile()
{
	DIALOG_RETVAL=$?
	DIALOG_OUTPUT="$(cat ${DIALOG_TEMPFILE})"
}

function showInfoMsg()
{
	[ "$1" == "" ] && return
	${DIALOG} --title "${DIALOG_TITLE}" --infobox "$1" 0 0
	local WAIT="$2"
	[ "$WAIT" == "" ] && return
	WAIT=$((WAIT))
	sleep $WAIT
}

function forceExit()
{
	showInfoMsg "$1" 5
	clear
	set -e
	exit 1
}

function showMainMENU()
{
	OIFS="$IFS"
	IFS=$'\n'
	local WALLPAPERS=`ls $WALLPAPER_DIR 2>/dev/null`
	if [ "$WALLPAPERS" == "" ]; then
		IFS="$OIFS"
		forceExit "No wallpapers found in $WALLPAPER_DIR"
	fi
	local INDEX=0
	local MENU_ITEMS=""
	for FILE in `ls $WALLPAPER_DIR 2>/dev/null`; do
		INDEX=$((INDEX + 1))
		[[ "$FILE" == *" "* ]] && continue
		MENU_ITEMS="${MENU_ITEMS} ${FILE} ${FILE} "
	done
	IFS="$OIFS"
	setupDIALOGtempfile
	${DIALOG} --clear --no-tags --ok-label "Select" \
		--title "${DIALOG_TITLE}" \
		--menu "Please choose an option.\nUse arrow keys, tab, space, enter and esc.\nPut wallpapers to $WALLPAPER_DIR.\nNo spaces allowed in filenames." ${DIALOG_HEIGHT} 0 999 \
		${MENU_ITEMS} \
		2> ${DIALOG_TEMPFILE}
	readDIALOGtempfile
}

function process()
{
	[ "$1" == "" ] && return
	local FILE=$WALLPAPER_DIR/"$1"
	if [ ! -f "$FILE" ]; then
		showInfoMsg "File not found!" 2
		return
	fi
	local EXT=${1#*.}
	local DEST=/media/fat/menu.$EXT
	showInfoMsg "Copying $1... to $DEST" 1
	rm -f /media/fat/menu.jpg
	rm -f /media/fat/menu.png
	cp -f "${FILE}" ${DEST} || showInfoMsg "File copy error!" 2
	sync
}

clear
checkTERMINAL
setupDIALOG

[ ! -d $WALLPAPER_DIR ] && forceExit "$WALLPAPER_DIR not found!"

while true; do
	showMainMENU
	case ${DIALOG_RETVAL} in
		${DIALOG_OK})
			process "${DIALOG_OUTPUT}"
			;;
		*)
			break
			;;
	esac
done

clear
reboot now
forceExit "Rebooting ..." 5