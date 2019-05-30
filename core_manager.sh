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

# Version 0.9 - 2019-05-30 - First commit, lacking any MiSTer Updater configuration capability.



# ========= OPTIONS ==================

# ========= ADVANCED OPTIONS =========
UPDATER_URL="https://github.com/MiSTer-devel/Updater_script_MiSTer/blob/master/mister_updater.sh"

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

function setupScriptINI {
	# get the name of the script, or of the parent script if called through a 'curl ... | bash -'
	ORIGINAL_SCRIPT_PATH="${0}"
	[[ "${ORIGINAL_SCRIPT_PATH}" == "bash" ]] && \
		ORIGINAL_SCRIPT_PATH="$(ps -o comm,pid | awk -v PPID=${PPID} '$2 == PPID {print $1}')"
	
	setupCURL
	TMP_INCLUDE_FILE=$(mktemp)
	echo "Downloading ${UPDATER_URL/*\//}"
	MISTER_UPDATER_CODE=$(${CURL} "${UPDATER_URL}?raw=true" | dos2unix)
	[ "${MISTER_UPDATER_CODE}" == "" ] && echo "Error downloading ${UPDATER_URL/*\//}" && exit 1
	echo "${MISTER_UPDATER_CODE}" | \
		sed -n '/#=========   USER OPTIONS   =========/,/#========= CODE STARTS HERE =========/p' | \
		sed 's/#========= CODE STARTS HERE =========//' | \
		sed 's/declare -A/declare -g -A/g' | \
		sed 's/DOWNLOAD_NEW_CORES="true"/DOWNLOAD_NEW_CORES="false"/g' \
		> "${TMP_INCLUDE_FILE}"
	source ${TMP_INCLUDE_FILE}
	rm -f ${TMP_INCLUDE_FILE}
	
	# ini file can contain user defined variables (as bash commands)
	# Load and execute the content of the ini file, if there is one
	INI_PATH="$(dirname ${ORIGINAL_SCRIPT_PATH})/update.ini"
	
	if [ ! -f "${INI_PATH}" ]
	then
		echo "${MISTER_UPDATER_CODE}" | \
			sed -n '/#=========   USER OPTIONS   =========/,/#========= CODE STARTS HERE =========/p' | \
			sed 's/#========= CODE STARTS HERE =========//' | \
			sed 's/DOWNLOAD_NEW_CORES="true"/DOWNLOAD_NEW_CORES="false"/g' \
			> "${INI_PATH}"
	fi
	
	echo "${MISTER_UPDATER_CODE}" | \
		sed -n '/^function checkCoreURL {/,/^}/p' \
		> "${TMP_INCLUDE_FILE}"
	source ${TMP_INCLUDE_FILE}
	rm -f ${TMP_INCLUDE_FILE}
	
	unset MISTER_UPDATER_CODE
	
	if [[ -f "${INI_PATH}" ]] ; then
		# TMP_INCLUDE_FILE=$(mktemp)
		# preventively eliminate DOS-specific format and exit command  
		dos2unix < "${INI_PATH}" 2> /dev/null | \
			grep -v "^exit" | \
			sed 's/declare -A/declare -g -A/g' \
			> ${TMP_INCLUDE_FILE}
		source ${TMP_INCLUDE_FILE}
		rm -f ${TMP_INCLUDE_FILE}
	fi
}

function setupCURL
{
	[ ! -z "${CURL}" ] && return
	CURL_RETRY="--connect-timeout 15 --max-time 120 --retry 3 --retry-delay 5"
	# test network and https by pinging the most available website 
	SSL_SECURITY_OPTION=""
	curl ${CURL_RETRY} --silent https://google.com > /dev/null 2>&1
	case $? in
		0)
			;;
		60)
			if [[ "${ALLOW_INSECURE_SSL}" == "true" ]]
			then
				SSL_SECURITY_OPTION="--insecure"
			else
				echo "CA certificates need"
				echo "to be fixed for"
				echo "using SSL certificate"
				echo "verification."
				echo "Please fix them i.e."
				echo "using security_fixes.sh"
				exit 2
			fi
			;;
		*)
			echo "No Internet connection"
			exit 1
			;;
	esac
	CURL="curl ${CURL_RETRY} ${SSL_SECURITY_OPTION} --location"
	CURL_SILENT="${CURL} --silent --fail"
}

function installDEBS () {
	DEB_REPOSITORIES=( "${@}" )
	TEMP_PATH="/tmp"
	for DEB_REPOSITORY in "${DEB_REPOSITORIES[@]}"; do
		OLD_IFS="${IFS}"
		IFS="|"
		PARAMS=(${DEB_REPOSITORY})
		DEBS_URL="${PARAMS[0]}"
		DEB_PREFIX="${PARAMS[1]}"
		ARCHIVE_FILES="${PARAMS[2]}"
		STRIP_COMPONENTS="${PARAMS[3]}"
		DEST_DIR="${PARAMS[4]}"
		IFS="${OLD_IFS}"
		if [ ! -f "${DEST_DIR}/$(echo $ARCHIVE_FILES | sed 's/*//g')" ]
		then
			DEB_NAMES=$(${CURL_SILENT} "${DEBS_URL}" | grep -oE "\"${DEB_PREFIX}[a-zA-Z0-9%./_+-]*_(armhf|all)\.deb\"" | sed 's/\"//g')
			MAX_VERSION=""
			MAX_DEB_NAME=""
			for DEB_NAME in $DEB_NAMES; do
				CURRENT_VERSION=$(echo "${DEB_NAME}" | grep -o '_[a-zA-Z0-9%.+-]*_' | sed 's/_//g')
				if [[ "${CURRENT_VERSION}" > "${MAX_VERSION}" ]]
				then
					MAX_VERSION="${CURRENT_VERSION}"
					MAX_DEB_NAME="${DEB_NAME}"
				fi
			done
			[ "${MAX_DEB_NAME}" == "" ] && echo "Error searching for ${DEB_PREFIX} in ${DEBS_URL}" && exit 1
			echo "Downloading ${MAX_DEB_NAME}"
			${CURL} "${DEBS_URL}/${MAX_DEB_NAME}" -o "${TEMP_PATH}/${MAX_DEB_NAME}"
			[ ! -f "${TEMP_PATH}/${MAX_DEB_NAME}" ] && echo "Error: no ${TEMP_PATH}/${MAX_DEB_NAME} found." && exit 1
			echo "Extracting ${ARCHIVE_FILES}"
			ORIGINAL_DIR="$(pwd)"
			cd "${TEMP_PATH}"
			rm data.tar.xz > /dev/null 2>&1
			ar -x "${TEMP_PATH}/${MAX_DEB_NAME}" data.tar.xz
			cd "${ORIGINAL_DIR}"
			rm "${TEMP_PATH}/${MAX_DEB_NAME}"
			mkdir -p "${DEST_DIR}"
			[ ! -f "${TEMP_PATH}/data.tar.xz" ] && echo "Error: no ${TEMP_PATH}/data.tar.xz found." && exit 1
			tar -xJf "${TEMP_PATH}/data.tar.xz" --wildcards --no-anchored --strip-components="${STRIP_COMPONENTS}" -C "${DEST_DIR}" "${ARCHIVE_FILES}"
			rm "${TEMP_PATH}/data.tar.xz" > /dev/null 2>&1
		fi
	done
}

function setupDIALOG {
	if which dialog > /dev/null 2>&1
	then
		DIALOG="dialog"
	else
		if [ ! -f /media/fat/linux/dialog/dialog ]
		then
			setupCURL
			installDEBS "http://http.us.debian.org/debian/pool/main/d/dialog|dialog_1.3-2016|dialog|3|/media/fat/linux/dialog" "http://http.us.debian.org/debian/pool/main/n/ncurses|libncursesw5_6.0|libncursesw.so.5*|3|/media/fat/linux/dialog" "http://http.us.debian.org/debian/pool/main/n/ncurses|libtinfo5_6.0|libtinfo.so.5*|3|/media/fat/linux/dialog"
		fi
		DIALOG="/media/fat/linux/dialog/dialog"
		export LD_LIBRARY_PATH="/media/fat/linux/dialog"
	fi
	
	rm -f "/media/fat/config/dialogrc"
	if [ ! -f "~/.dialogrc" ]
	then
		export DIALOGRC="$(dirname ${ORIGINAL_SCRIPT_PATH})/.dialogrc"
		if [ ! -f "${DIALOGRC}" ]
		then
			${DIALOG} --create-rc "${DIALOGRC}"
			sed -i "s/use_colors = OFF/use_colors = ON/g" "${DIALOGRC}"
			sed -i "s/screen_color = (CYAN,BLUE,ON)/screen_color = (CYAN,BLACK,ON)/g" "${DIALOGRC}"
			sync
		fi
	fi
	
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

function setupUPDATER {
	LOCAL_UPDATER="$(dirname $(readlink -f ${ORIGINAL_SCRIPT_PATH}))/update.sh"
	LOCAL_UPDATER_INI="${LOCAL_UPDATER%.*}.ini"
	if [ ! -f "${LOCAL_UPDATER}" ]
	then
		echo "Downloading update.sh"
		 ${CURL} "$(echo ${UPDATER_URL}?raw=true | sed 's/mister.updater.sh/update.sh/')" -o "${LOCAL_UPDATER}"
		 [ ! -f "${LOCAL_UPDATER}" ] && echo "Error downloading update.sh" && exit 1
	fi
}

function setupCoreURLs {
	declare -g -A CORE_CATEGORY_NAMES
	declare -g -A CORE_CATEGORY_REVERSE_NAMES
	declare -g -A COMPUTER_CORE_URLS
	declare -g -A CONSOLE_CORE_URLS
	declare -g -A ARCADE_CORE_URLS
	declare -g -A UTILITY_CORE_URLS
	CORE_CATEGORY_NAMES["cores"]="Computer"
	CORE_CATEGORY_NAMES["console-cores"]="Console"
	CORE_CATEGORY_NAMES["arcade-cores"]="Arcade"
	CORE_CATEGORY_NAMES["service-cores"]="Utility"
	for CORE_CATEGORY in ${!CORE_CATEGORY_NAMES[@]}; do
		CORE_CATEGORY_REVERSE_NAMES["${CORE_CATEGORY_NAMES[${CORE_CATEGORY}]^^}"]="${CORE_CATEGORY}"
	done
	
	echo "Downloading MiSTer Wiki"
	CORE_URLS=$(${CURL} "$MISTER_URL/wiki" | awk '/user-content-cores/,/user-content-development/' | grep -io '\(https://github.com/[a-zA-Z0-9./_-]*_MiSTer">[^<]*\)\|\(user-content-[a-z-]*\)')
	
	
	OLD_IFS="$IFS"
	IFS=$'\n'
	for CORE_URL in $CORE_URLS; do
		if [[ $CORE_URL == https://* ]]
		then
			CORE_NAME="${CORE_URL#*\">}" && CORE_NAME="${CORE_NAME//\'/\\\'}"
			CORE_URL="${CORE_URL%\">*}"
			[ "${CORE_URL##*\/}" == "Menu_MiSTer" ] && continue
			eval ${CORE_CATEGORY_NAMES[$CORE_CATEGORY]^^}_CORE_URLS[${CORE_NAME}]=${CORE_URL}
		else
			CORE_CATEGORY=$(echo "$CORE_URL" | sed 's/user-content-//g')
		fi
	done
	IFS="$OLD_IFS"
}

DIALOG_TITLE="MiSTer Core Manager"

function showPleaseWAIT {
	${DIALOG} --title "${DIALOG_TITLE}" \
	--infobox "Please wait..." 0 0
}

function showMainMENU {
	setupDIALOGtempfile
	${DIALOG} --clear --no-tags --item-help --ok-label "Select" \
		--title "${DIALOG_TITLE}" \
		--menu "Please choose an option.\nUse arrow keys, tab, space, enter and esc." 0 0 999 \
		"installCOMPUTER" "Install/Update Computer core" "" \
		"deleteCOMPUTER" "Delete Computer core" "" \
		"installCONSOLE" "Install/Update Console core" "" \
		"deleteCONSOLE" "Delete Console core" "" \
		"installARCADE" "Install/Update Arcade core" "" \
		"deleteARCADE" "Delete Arcade core" "" \
		"installUTILITY" "Install/Update Utility core" "" \
		"deleteUTILITY" "Delete Utility core" "" \
		"configureUPDATER" "Configure MiSTer Updater" "Configures ${LOCAL_UPDATER_INI} used both by the updater and by this script" \
		"updateMISTER" "Update MiSTer" "Launches ${LOCAL_UPDATER}" \
		"watchMOVIE" "Watch Star Wars" "Enjoy the show... Press <CTRL-C> and then <e> in order to exit the movie" \
		2> ${DIALOG_TEMPFILE}
	readDIALOGtempfile
}

function showInstallMENU {
	CORE_CATEGORY_NAME="${1}"
	MENU_ITEMS=""
	ADDITIONAL_OPTIONS="--no-tags"
	OLD_IFS="$IFS"
	IFS=$'\n'
	for CORE_NAME in $(eval echo \"\${!${CORE_CATEGORY_NAME}_CORE_URLS[*]}\"); do
		CORE_URL="$(eval echo \${${CORE_CATEGORY_NAME}_CORE_URLS[${CORE_NAME//\'/\\\'}]})"
		MENU_ITEMS="${MENU_ITEMS} \"${CORE_URL}\" \"${CORE_NAME}\""
	done
	IFS="$OLD_IFS"
	
	setupDIALOGtempfile
	eval ${DIALOG} --clear --colors --ok-label \"Install/Update\" \
		--extra-button --extra-label \"README\" \
		--title \"${DIALOG_TITLE}: Install/Update ${CORE_CATEGORY_NAME,,} core\" \
		${ADDITIONAL_OPTIONS} \
		--menu \"Please select the ${CORE_CATEGORY_NAME,,} core you wish to install or update.\" 0 0 999 \
		${MENU_ITEMS} \
		2> ${DIALOG_TEMPFILE}
	readDIALOGtempfile
}

function showDeleteMENU {
	CORE_CATEGORY_NAME="${1}"
	MENU_ITEMS=""
	ADDITIONAL_OPTIONS="--no-tags"
	for CORE_FILE in "${CORE_CATEGORY_PATHS[${CORE_CATEGORY}]}"/*.rbf; do
		MENU_ITEMS="${MENU_ITEMS} \"${CORE_FILE}\" \"${CORE_FILE}\""
	done
	
	setupDIALOGtempfile
	eval ${DIALOG} --clear --colors --ok-label \"Delete\" \
		--title \"${DIALOG_TITLE}: Delete ${CORE_CATEGORY_NAME,,} core\" \
		${ADDITIONAL_OPTIONS} \
		--menu \"Please select the ${CORE_CATEGORY_NAME,,} core you wish to delete.\" 0 0 999 \
		${MENU_ITEMS} \
		2> ${DIALOG_TEMPFILE}
	readDIALOGtempfile
}

clear
checkTERMINAL
setupScriptINI
setupUPDATER
setupDIALOG
setupCoreURLs

while true; do
	showMainMENU
	case ${DIALOG_RETVAL} in
		${DIALOG_OK})
			case "${DIALOG_OUTPUT}" in
				install*)
					CORE_CATEGORY_NAME="${DIALOG_OUTPUT/install/}"
					CORE_CATEGORY="${CORE_CATEGORY_REVERSE_NAMES[${CORE_CATEGORY_NAME}]}"
					while true; do
						showInstallMENU "${CORE_CATEGORY_NAME}"
						case ${DIALOG_RETVAL} in
							${DIALOG_OK})
								CORE_URL="${DIALOG_OUTPUT}"
								ORIGINAL_DOWNLOAD_NEW_CORES="${DOWNLOAD_NEW_CORES}"
								DOWNLOAD_NEW_CORES="true"
								ORIGINAL_SSH_CLIENT="${SSH_CLIENT}"
								SSH_CLIENT="---"
								clear
								checkCoreURL
								DOWNLOAD_NEW_CORES="${ORIGINAL_DOWNLOAD_NEW_CORES}"
								SSH_CLIENT="${ORIGINAL_SSH_CLIENT}"
								;;
							${DIALOG_EXTRA})
								showPleaseWAIT
								README_URL="https://github.com$($CURL_SILENT $DIALOG_OUTPUT | grep -oi '/MiSTer-devel/[a-zA-Z0-9./_-]*/blob/[a-zA-Z0-9./_-]*/readme[^"]*')?raw=true"
								TMP_README=/tmp/dialog_README_tempfile$$
								$CURL_SILENT "${README_URL}" | dos2unix > "${TMP_README}"
								if [ -f "${TMP_README}" ]
								then
									${DIALOG} --clear --title "${DIALOG_TITLE}" \
										--textbox "${TMP_README}" 0 0
									rm -f "${TMP_README}"
								else
									${DIALOG} --clear --title "${DIALOG_TITLE}" \
										--msgbox "Something went wrong downloading\n${README_URL}" 0 0
								fi
								;;
							*)
							break
							;;
						esac
					done
					;;
				delete*)
					CORE_CATEGORY_NAME="${DIALOG_OUTPUT/delete/}"
					CORE_CATEGORY="${CORE_CATEGORY_REVERSE_NAMES[${CORE_CATEGORY_NAME}]}"
					while true; do
						showDeleteMENU "${CORE_CATEGORY_NAME}"
						case ${DIALOG_RETVAL} in
							${DIALOG_OK})
								${DIALOG} --clear --title "${DIALOG_TITLE}" --defaultno --yesno "Are you sure you want to delete\n${DIALOG_OUTPUT}\n???" 0 0 && rm -f "${DIALOG_OUTPUT}" && sync
								;;
							*)
							break
							;;
						esac
					done
					;;
				configureUPDATER)
					${DIALOG} --title "${DIALOG_TITLE}" \
						--msgbox "Coming soon...\n\n...in the meantime you can watch Star Wars" 0 0
					;;
				updateMISTER)
					clear
					${LOCAL_UPDATER}
					;;
				watchMOVIE)
					clear
					telnet towel.blinkenlights.nl
					;;
			esac
			;;
		*)
			break;;
	esac
done

clear

exit 0
