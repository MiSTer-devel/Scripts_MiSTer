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

# Version 1.1.10 - 2019-06-12 - Font option value is saved without the leading slash, i.e. font=font/myfont.pf.
# Version 1.1.9 - 2019-06-10 - Testing Internet connectivity with github.com instead of google.com.
# Version 1.1.8 - 2019-05-31 - Added DIALOG_HEIGHT parameter.
# Version 1.1.7 - 2019-05-30 - The menu box uses all available space now.
# Version 1.1.6 - 2019-05-29 - Speed optimizations.
# Version 1.1.5 - 2019-05-29 - Added "Please wait..." screens; font value now is stored as font=/font/myfont.pf without the leading /media/fat.
# Version 1.1.4 - 2019-05-29 - The advanced editor starts with the Cancel button selected.
# Version 1.1.3 - 2019-05-29 - Improved textual descriptions of options.
# Version 1.1.2 - 2019-05-29 - Added support for fb_terminal, vscale_border, bootscreen, mouse_throttle, key_menu_as_rgui, keyrah_mode, rbf_hide_datecode, bootcore and bootcore_timeout.
# Version 1.1.1 - 2019-05-29 - Improved textual descriptions of options.
# Version 1.1 - 2019-05-29 - Added support for setting non existing or commented keys; the font selection page has a single row now.
# Version 1.0.10 - 2019-05-28 - Changed value selection page from a radiolist to a menu in order to improve usability; now the font value is displayed withouth path and extension.
# Version 1.0.9 - 2019-05-28 - Changed MiSTer.ini directory to /media/fat (previously it was /media/fat/config); now the script checks if ~/.dialogrc exists and creates .dialogrc in the current directory when needed (previously it used /media/fat/config/dialogrc); improved some texts.
# Version 1.0.8 - 2019-05-27 - Improved textual descriptions of options, many thanks to misteraddons.
# Version 1.0.7 - 2019-05-27 - Improved textual descriptions of options.
# Version 1.0.6 - 2019-05-27 - setupCURL (so Internet connectivity check) is called only when needed; improved textual descriptions of options.
# Version 1.0.5 - 2019-05-27 - Improved textual descriptions of options.
# Version 1.0.4 - 2019-05-27 - Improved ini value reading: only the first instance of a key is read, so specific core settings will be ignored.
# Version 1.0.4 - 2019-05-27 - Improved textual descriptions of options; removed hostname check, so users can use different hostnames than MiSTer; pressing ESC in submenus returns to the main menu instead of quitting the script.
# Version 1.0.3 - 2019-05-26 - Improved DEB packages downloading routine.
# Version 1.0.2 - 2019-05-26 - Added error checks during DEB packages downloading.
# Version 1.0.1 - 2019-05-26 - Added Windows(CrLf)<->Unix(Lf) character handling.
# Version 1.0 - 2019-05-26 - First commit



# ========= OPTIONS ==================

# ========= ADVANCED OPTIONS =========
MISTER_INI_FILE="/media/fat/MiSTer.ini"

ALLOW_INSECURE_SSL="true"

DIALOG_HEIGHT="31"

FONTS_DIRECTORY="/media/fat/font"
FONTS_EXTENSION="pf"

INI_KEYS="video_mode video_mode_ntsc video_mode_pal vsync_adjust vscale_mode vscale_border hdmi_limited dvi_mode vga_scaler forced_scandoubler ypbpr composite_sync hdmi_audio_96k video_info font volumectl mouse_throttle bootscreen key_menu_as_rgui keyrah_mode rbf_hide_datecode bootcore bootcore_timeout fb_size fb_terminal"

KEY_video_mode=(
	"Video resolution and frequency"
	"0|1280x720 60Hz"
	"1|1024x768 60Hz"
	"2|720x480 60Hz"
	"3|720x576 50Hz"
	"4|1280x1024 60Hz"
	"5|800x600 60Hz"
	"6|640x480 60Hz"
	"7|1280x720 50Hz"
	"8|1920x1080 60Hz"
	"9|1920x1080 50Hz"
	"10|1366x768 60Hz"
	"11|1024x600 60Hz"
)

KEY_video_mode_ntsc=(
	"Video resolution and frequency for NTSC cores; if you use this, please set video_mode_pal too"
	"0|1280x720 60Hz"
	"1|1024x768 60Hz"
	"2|720x480 60Hz"
	"3|720x576 50Hz"
	"4|1280x1024 60Hz"
	"5|800x600 60Hz"
	"6|640x480 60Hz"
	"7|1280x720 50Hz"
	"8|1920x1080 60Hz"
	"9|1920x1080 50Hz"
	"10|1366x768 60Hz"
	"11|1024x600 60Hz"
)

KEY_video_mode_pal=(
	"Video resolution and frequency PAL cores; if you use this, please set video_mode_ntsc too"
	"0|1280x720 60Hz"
	"1|1024x768 60Hz"
	"2|720x480 60Hz"
	"3|720x576 50Hz"
	"4|1280x1024 60Hz"
	"5|800x600 60Hz"
	"6|640x480 60Hz"
	"7|1280x720 50Hz"
	"8|1920x1080 60Hz"
	"9|1920x1080 50Hz"
	"10|1366x768 60Hz"
	"11|1024x600 60Hz"
)

KEY_vscale_mode=(
	"Video scaling mode"
	"0|Scale to fit the screen height|Some possible shimmering during vertical scrolling, not optimal for scanlines"
	"1|Use integer scale only|No shimmering during vertical scrolling, optimal for scanlines"
	"2|Use 0.5 steps of scale|Some possible shimmering during vertical scrolling, good scanlines"
	"3|Use 0.25 steps of scale|Some possible shimmering during vertical scrolling, good scanlines"
)

KEY_vsync_adjust=(
	"Video scaling sync frequency"
	"0|Match display frequency|Best display compatibility, some stuttering, 1-2 frames of lag"
	"1|Match core frequency|Some display incompatibilities, no stuttering, 1-2 frames of lag"
	"2|Low lag|Some display incompatibilities, no stuttering, virtually no lag"
)

KEY_hdmi_limited=(
	"Sets HDMI RGB output to limited (16-235, full range otherwise)"
	"0|Off|Full RGB (0-255) HDMI output"
	"1|On|Limited RGB (16-235) HDMI output"
)

KEY_dvi_mode=(
	"Sets DVI mode on HDMI output"
	"0|Off|Audio will be transmitted through HDMI"
	"1|On|Audio won't be transmitted through HDMI"
)

KEY_vga_scaler=(
	"Connects analog video output to the scaler output, changing the resolution"
	"0|Off|Analog video will output native core resolution"
	"1|On|Analog video output will output same resolution as HDMI port"
)

KEY_forced_scandoubler=(
	"Forces scandoubler (240p/15kHz to 480p/31kHz) on analog video output"
	"0|Off|15KHz analog video out for 15KHz cores, works on CRT TV sets, but may have problems with PC monitors"
	"1|On|30KHz analog video out for 15KHz cores (core dependent), good for VGA monitors not supporting 15KHz"
)

KEY_ypbpr=(
	"Enables component video (YPbPr) on analog video output"
	"0|Off|RGB analog video output; please disable Sync-on-Green (SOG) switch (position further from HDMI port)"
	"1|On|YPbPr analog video output; please enable Sync-on-Green (SOG) switch (position closest to HDMI port)"
)

KEY_composite_sync=(
	"Sets composite sync on HSync signal of analog video output; used for display compatibility"
	"0|Off|Separate sync (RGBHV); used for VGA monitors"
	"1|On|Composite sync (RGBS); used for most other displays including RGB CRTs, PVMs, BVMS, and upscaler devices"
)

KEY_hdmi_audio_96k=(
	"Sets HDMI audio to 96KHz/16bit (48KHz/16bit otherwise)"
	"0|Off|48KHz/16bit HDMI audio output; compatible with most HDMI devices"
	"1|On|96KHz/16bit HDMI audio output; better quality but not compatible with all HDMI devices"
)

KEY_fb_size=(
	"Framebuffer resolution"
	"0|Automatic"
	"1|Full size"
	"2|1/2 of resolution"
	"4|1/4 of resolution"	
)

KEY_video_info=(
	"Sets the number of seconds video info will be displayed on startup/change"
	"0|Off"
	"1|1 second"
	"2|2 seconds"
	"3|3 seconds"
	"4|4 seconds"
	"5|5 seconds"
	"6|6 seconds"
	"7|7 seconds"
	"8|8 seconds"
	"9|9 seconds"
	"10|10 seconds"
)

KEY_font=(
	"Custom font; put custom fonts in ${FONTS_DIRECTORY}"
)

KEY_volumectl=(
	"Enables audio volume control with multimedia keys"
	"0|Off"
	"1|on"
)

KEY_fb_terminal=(
	"Enables the framebuffer terminl (the one you are using now) for the Scripts menu"
	"0|Off"
	"1|on"
)

KEY_vscale_border=(
	"Adds a vertical border for TV sets cutting the upper/bottom part of the screen"
	"0|0" "1|1" "2|2" "3|3" "4|4" "5|5" "6|6" "7|7" "8|8" "9|9"
	"10|10" "11|11" "12|12" "13|13" "14|14" "15|15" "16|16" "17|17" "18|18" "19|19"
	"20|20" "21|21" "22|22" "23|23" "24|24" "25|25" "26|26" "27|27" "28|28" "29|29"
	"30|30" "31|31" "32|32" "33|33" "34|34" "35|35" "36|36" "37|37" "38|38" "39|39"
	"40|40" "41|41" "42|42" "43|43" "44|44" "45|45" "46|46" "47|47" "48|48" "49|49"
	"50|50" "51|51" "52|52" "53|53" "54|54" "55|55" "56|56" "57|57" "58|58" "59|59"
	"60|60" "61|61" "62|62" "63|63" "64|64" "65|65" "66|66" "67|67" "68|68" "69|69"
	"70|70" "71|71" "72|72" "73|73" "74|74" "75|75" "76|76" "77|77" "78|78" "79|79"
	"80|80" "81|81" "82|82" "83|83" "84|84" "85|85" "86|86" "87|87" "88|88" "89|89"
	"90|90" "91|91" "92|92" "93|93" "94|94" "95|95" "96|96" "97|97" "98|98" "99|99"
)

KEY_bootscreen=(
	"Enables boot screen of some cores like Minimig"
	"0|Off"
	"1|on"
)

KEY_mouse_throttle=(
	"1-100 mouse speed divider; useful for very sensitive mice"
	"1|1" "2|2" "3|3" "4|4" "5|5" "6|6" "7|7" "8|8" "9|9"
	"10|10" "11|11" "12|12" "13|13" "14|14" "15|15" "16|16" "17|17" "18|18" "19|19"
	"20|20" "21|21" "22|22" "23|23" "24|24" "25|25" "26|26" "27|27" "28|28" "29|29"
	"30|30" "31|31" "32|32" "33|33" "34|34" "35|35" "36|36" "37|37" "38|38" "39|39"
	"40|40" "41|41" "42|42" "43|43" "44|44" "45|45" "46|46" "47|47" "48|48" "49|49"
	"50|50" "51|51" "52|52" "53|53" "54|54" "55|55" "56|56" "57|57" "58|58" "59|59"
	"60|60" "61|61" "62|62" "63|63" "64|64" "65|65" "66|66" "67|67" "68|68" "69|69"
	"70|70" "71|71" "72|72" "73|73" "74|74" "75|75" "76|76" "77|77" "78|78" "79|79"
	"80|80" "81|81" "82|82" "83|83" "84|84" "85|85" "86|86" "87|87" "88|88" "89|89"
	"90|90" "91|91" "92|92" "93|93" "94|94" "95|95" "96|96" "97|97" "98|98" "99|99"
	"100|100"
)

KEY_key_menu_as_rgui=(
	"Enables the MENU key map to RGUI in Minimig (e.g. for Right Amiga)"
	"0|Off"
	"1|on"
)

KEY_keyrah_mode=(
	"VIDPID of Keyrah for special code translation"
	"0x18d80002|0x18d80002|Use this for original Keyrah"
	"0x23418037|0x23418037|Use this for Arduino Micro"
)

KEY_rbf_hide_datecode=(
	"Hides datecodes/timestamps for rbf file names; press F2 for quick temporary toggle"
	"0|Off|Datecodes/timestamps visible"
	"1|on|Datecodes/timestamps not visible"
)

KEY_bootcore=(
	"Enables core autobooting"
	 "|Disabled"
	 "lastcore|lastcore|Autoboot the last loaded core (corename autosaved in CONFIG/lastcore.dat) first found on the SD/USB"
	 "lastexactcore|lastexactcore|Autoboot the last loaded exact core (corename_yyyymmdd.rbf autosaved in CONFIG/lastcore.dat) first found on the SD/USB"
)

KEY_bootcore_timeout=(
	"Sets the timeout before autoboot"
	 "10|10 seconds" "11|11 seconds" "12|12 seconds" "13|13 seconds" "14|14 seconds"
	 "15|15 seconds" "16|16 seconds" "17|17 seconds" "18|18 seconds" "19|19 seconds"
	 "20|20 seconds" "21|21 seconds" "22|22 seconds" "23|23 seconds" "24|24 seconds"
	 "25|25 seconds" "26|26 seconds" "27|27 seconds" "28|28 seconds" "29|29 seconds"
	 "30|30 seconds"
)



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
}

function setupCURL
{
	[ ! -z "${CURL}" ] && return
	CURL_RETRY="--connect-timeout 15 --max-time 120 --retry 3 --retry-delay 5"
	# test network and https by pinging the most available website 
	SSL_SECURITY_OPTION=""
	curl ${CURL_RETRY} --silent https://github.com > /dev/null 2>&1
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
	
	[ -f "/media/fat/config/dialogrc" ] && rm -f "/media/fat/config/dialogrc"
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
}

function loadMiSTerINI {
	if [ ! -f "${MISTER_INI_FILE}" ]
	then
		if [ -f "/media/fat/config/MiSTer.ini" ]
		then
			mv "/media/fat/config/MiSTer.ini" "${MISTER_INI_FILE}"
		else
			setupCURL
			echo "Downloading MiSTer.ini"
			${CURL} "https://github.com/MiSTer-devel/Main_MiSTer/blob/master/MiSTer.ini?raw=true" -o "${MISTER_INI_FILE}"
		fi
		
	fi
	MISTER_INI_ORIGINAL="$(cat "${MISTER_INI_FILE}" | dos2unix)"
	MISTER_INI="${MISTER_INI_ORIGINAL}"
}

function checkKEY () {
	INI_KEY="${1}"
	echo "${MISTER_INI}" | grep -qE "^\s*${INI_KEY}\s*="
	return ${?}
}

#declare -A valueCACHE

function getVALUE () {
	INI_KEY="${1}"
	#if [ -v "valueCACHE[${INI_KEY}]" ]
	#then
	#	#echo "CACHE HIT"
	#	INI_VALUE="${valueCACHE[${INI_KEY}]}"
	#else 
	#	#echo "CACHE MISS"
		INI_VALUE=$(echo "${MISTER_INI}" | grep -oE -m 1 "^\s*${INI_KEY}\s*=\s*[a-zA-Z0-9%().,/_-]+"|sed "s/^\s*${INI_KEY}\s*=\s*//")
	#	valueCACHE["${INI_KEY}"]="${INI_VALUE}"
	#fi	
	[ ${INI_KEY} == "font" ] && INI_VALUE="${INI_VALUE/*\//}" && INI_VALUE="${INI_VALUE%.*}"
}

function setVALUE () {
	INI_KEY="${1}"
	INI_VALUE="${2}"
	[ ${INI_KEY} == "font" ] && INI_VALUE="${FONTS_DIRECTORY/\/media\/fat\//}/${INI_VALUE/[* ]/}.${FONTS_EXTENSION}"
	#valueCACHE["${INI_KEY}"]="${INI_VALUE}"
	INI_VALUE=$(echo "${INI_VALUE}" | sed 's/\//\\\//g' | sed 's/\./\\\./g')
	checkKEY ${INI_KEY} || MISTER_INI=$(echo "${MISTER_INI}" | sed "1,/^\s*;\s*$INI_KEY\s*=\s*/{s/^\s*;\s*$INI_KEY\s*=\s*/$INI_KEY=/}")
	checkKEY ${INI_KEY} || MISTER_INI=$(echo "${MISTER_INI}" | sed '/\[MiSTer\]/a\'$INI_KEY'=')
	MISTER_INI=$(echo "${MISTER_INI}" | sed "1,/^\s*$INI_KEY\s*=\s*[a-zA-Z0-9%().,/_-]*/{s/^\s*$INI_KEY\s*=\s*[a-zA-Z0-9%().,/_-]*/$INI_KEY=$INI_VALUE/}")
}

function showMainMENU_GUI {
	showPleaseWAIT
	MENU_ITEMS=""
	for INI_KEY in ${INI_KEYS}; do
		# checkKEY ${INI_KEY} || continue
		getVALUE "${INI_KEY}"
		[ "${INI_VALUE}" = "" ] && INI_VALUE="Not set or commented"
		INI_KEY_HELP=""
		INI_VALUE_DESCRIPTION=""
		for INDEX in $(eval echo \${!KEY_${INI_KEY}[@]}); do
			KEY_VALUE_CONFIG="$(eval echo \${KEY_${INI_KEY}[${INDEX}]})"
			if [ "${INDEX}" == "0" ]
			then
				INI_KEY_HELP="${KEY_VALUE_CONFIG}"
			else
				INI_VALUE_RAW="${KEY_VALUE_CONFIG%%|*}"
				if [ "${INI_VALUE_RAW}" == "${INI_VALUE}" ]
				then
					INI_VALUE_DESCRIPTION="${KEY_VALUE_CONFIG#*|}" && INI_VALUE_DESCRIPTION="${INI_VALUE_DESCRIPTION%%|*}"
					break
				fi
			fi
		done
		[ "${INI_VALUE_DESCRIPTION}" == "" ] && INI_VALUE_DESCRIPTION="${INI_VALUE}"
		MENU_ITEMS="${MENU_ITEMS} \"${INI_KEY}\" \"${INI_VALUE_DESCRIPTION}\" \"${INI_KEY_HELP}\""
	done
	
	[ "${MISTER_INI}" == "${MISTER_INI_ORIGINAL}" ] && SAVE_BUTTON="" || SAVE_BUTTON="--extra-button --extra-label \"Save\""
	
	setupDIALOGtempfile
	eval ${DIALOG} --clear --item-help --ok-label \"Select\" \
		${SAVE_BUTTON} \
		--help-button --help-label \"Advanced...\" \
		--title \"MiSTer INI Settings\" \
		--menu \"Please choose an option you want to change.$'\n'Use arrow keys, tab, space, enter and esc.\" ${DIALOG_HEIGHT} 0 999 \
		${MENU_ITEMS} \
		2> ${DIALOG_TEMPFILE}
	readDIALOGtempfile
}

function showMainMENU_EDITOR {
	EDITOR_TEMPFILE=/tmp/editor_tempfile$$
	echo "${MISTER_INI}" > "${EDITOR_TEMPFILE}"
	setupDIALOGtempfile
	eval ${DIALOG} --clear --defaultno \
		--title \"MiSTer INI Settings\" \
		--editbox "${EDITOR_TEMPFILE}" ${DIALOG_HEIGHT} 0 \
		2> ${DIALOG_TEMPFILE}
	readDIALOGtempfile
	rm -f "${EDITOR_TEMPFILE}"
	unset EDITOR_TEMPFILE
}

function showOptionMENU {
	showPleaseWAIT
	INI_KEY=${DIALOG_OUTPUT}
	MENU_ITEMS=""
	ADDITIONAL_OPTIONS=""
	getVALUE "${INI_KEY}"
	case "${INI_KEY}" in
		"font")
			[ ! -d "${FONTS_DIRECTORY}" ] && return ${DIALOG_CANCEL}
			ADDITIONAL_OPTIONS="--no-items"
			INI_KEY_HELP="$(eval echo \${KEY_${INI_KEY}[0]})"
			for FONT in "${FONTS_DIRECTORY}"/*."${FONTS_EXTENSION}"
			do
				INI_VALUE_RAW="${FONT/*\//}" && INI_VALUE_RAW="${INI_VALUE_RAW%.*}"
				# INI_VALUE_DESCRIPTION="${FONT}"
				[ "${INI_VALUE_RAW}" == "${INI_VALUE}" ] && INI_VALUE_RAW="*${INI_VALUE_RAW}" || INI_VALUE_RAW=" ${INI_VALUE_RAW}"
				INI_VALUE_HELP=""
				MENU_ITEMS="${MENU_ITEMS} \"${INI_VALUE_RAW}\" \"${INI_VALUE_HELP}\""
			done
			;;
		*)
			for INDEX in $(eval echo \${!KEY_${INI_KEY}[@]}); do
				KEY_VALUE_CONFIG="$(eval echo \${KEY_${INI_KEY}[${INDEX}]})"
				if [ "${INDEX}" == "0" ]
				then
					INI_KEY_HELP="${KEY_VALUE_CONFIG}"
				else
					INI_VALUE_RAW="${KEY_VALUE_CONFIG%%|*}"
					INI_VALUE_DESCRIPTION="${KEY_VALUE_CONFIG#*|}" && INI_VALUE_DESCRIPTION="${INI_VALUE_DESCRIPTION%%|*}"
					[ "${INI_VALUE_RAW}" == "${INI_VALUE}" ] && INI_VALUE_COLOR="\Z1\Zu" || INI_VALUE_COLOR=""
					INI_VALUE_HELP="${KEY_VALUE_CONFIG##*|}" && [ "${INI_VALUE_HELP}" == "${INI_VALUE_DESCRIPTION}" ] && INI_VALUE_HELP=""
					MENU_ITEMS="${MENU_ITEMS} \"${INI_VALUE_RAW}\" \"${INI_VALUE_COLOR}${INI_VALUE_DESCRIPTION}\" \"${INI_VALUE_HELP}\""
				fi
			done
			;;
	esac
	
	setupDIALOGtempfile
	eval ${DIALOG} --clear --colors --item-help --ok-label \"Select\" \
		--title \"MiSTer INI Settings: ${INI_KEY}\" \
		${ADDITIONAL_OPTIONS} \
		--menu \"${INI_KEY_HELP}\" ${DIALOG_HEIGHT} 0 999 \
		${MENU_ITEMS} \
		2> ${DIALOG_TEMPFILE}
	readDIALOGtempfile
}

function showPleaseWAIT {
	${DIALOG} --title "MiSTer INI Settings" \
	--infobox "Please wait..." 0 0
}



checkTERMINAL
setupScriptINI
setupDIALOG

loadMiSTerINI

SHOW_GUI="true"

while true; do
	if [ "${SHOW_GUI}" == "true" ]
	then
		showMainMENU_GUI
		case ${DIALOG_RETVAL} in
			${DIALOG_OK})
				# OK=Select INI key to change
				INI_KEY=${DIALOG_OUTPUT}
				showOptionMENU
				case ${DIALOG_RETVAL} in
					${DIALOG_OK})
						INI_VALUE="${DIALOG_OUTPUT}"
						setVALUE "${INI_KEY}" "${INI_VALUE}"
						;;
					${DIALOG_CANCEL})
						;;
					${DIALOG_ESC})
						;;
				esac
				;;
			${DIALOG_CANCEL})
				break;;
			${DIALOG_HELP})
				# Help=Advanced... manual INI editor
				SHOW_GUI="false"
				;;
			${DIALOG_EXTRA})
				# Extra=Save
				cp "${MISTER_INI_FILE}" "${MISTER_INI_FILE}.bak"
				echo "${MISTER_INI}" | unix2dos > "${MISTER_INI_FILE}"
				sync
				${DIALOG} --clear --title "MiSTer INI Settings" --defaultno --yesno "Do you want to reboot in order to apply the changes?" 0 0 && reboot now
				break;;
			${DIALOG_ESC})
				break;;
		esac
	else
		showMainMENU_EDITOR
		case ${DIALOG_RETVAL} in
			${DIALOG_OK})
				MISTER_INI="${DIALOG_OUTPUT}"
				SHOW_GUI="true"
				;;
			${DIALOG_CANCEL})
				SHOW_GUI="true"
				;;
			${DIALOG_ESC})
				SHOW_GUI="true"
				;;
		esac
	fi
done

clear

exit 0
