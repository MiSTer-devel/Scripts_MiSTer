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

# Version 1.1.2 - 2019-05-13 - The script doesn't reboot the system at the end of the execution anymore, it just prompts the user; changed output when video_mode_ntsc_pal=1; corrected MiSTer.ini comment char from "#" to ";".
# Version 1.1.1 - 2019-03-03 - Corrected a bug in MiSTer.ini download.
# Version 1.1 - 2019-02-09 - Support for video_mode_ntsc and video_mode_pal; the script tries to download MiSTer.ini (when needed) using SSL certificate verification; corrected a regular expression bug.
# Version 1.0 - 2019-01-14 - First commit.



# ========= ADVANCED OPTIONS =========
MISTER_INI=/media/fat/config/MiSTer.ini

# ========= CODE STARTS HERE =========
if [ ! -f "${MISTER_INI}" ]
then
	echo "Downloading MiSTer.ini"
	curl -L "https://github.com/MiSTer-devel/Main_MiSTer/blob/master/MiSTer.ini?raw=true" -o "${MISTER_INI}"
	case $? in
		0)
			;;
		60)
			if ! curl -kL "https://github.com/MiSTer-devel/Main_MiSTer/blob/master/MiSTer.ini?raw=true" -o "${MISTER_INI}"
			then
				echo "Unable to download"
				echo "MiSTer.ini"
				exit 1
			fi
			;;
		*)
			echo "Unable to download"
			echo "MiSTer.ini"
			exit 1
	esac
fi

cp ${MISTER_INI} ${MISTER_INI}.bak

if [ "$PROPERTY_NAME" == "video_mode_ntsc_pal" ]
then
	if [ "$PROPERTY_VALUE" == "1" ]
	then
		if cat ${MISTER_INI} | grep -q "video_mode_pal"
		then
			sed -i -e '/video_mode_pal/s/^;//g' ${MISTER_INI}
		else
			sed -i -e '/^\s*video_mode=[0-9,]*/{a\video_mode_pal=7\r' -e ':a;$q;n;ba;}' MiSTer.ini
		fi
		if cat ${MISTER_INI} | grep -q "video_mode_ntsc"
		then
			sed -i -e '/video_mode_ntsc/s/^;//g' ${MISTER_INI}
		else
			sed -i -e '/^\s*video_mode=[0-9,]*/{a\video_mode_ntsc=0\r' -e ':a;$q;n;ba;}' MiSTer.ini
		fi
		PROPERTY_NAME=video_mode
		PROPERTY_VALUE="$(cat ${MISTER_INI} | grep -o -m 1 "^\s*video_mode=[0-9,]*" | grep -o "[0-9,]*$")"
	else
		sed -i -e '/video_mode_ntsc/s/^;*/;/g' ${MISTER_INI}
		sed -i -e '/video_mode_pal/s/^;*/;/g' ${MISTER_INI}
		echo "video_mode_pal/ntsc disabled"
	fi
else
	sed -i "1,/^\s*$PROPERTY_NAME=[0-9,]*/{s/^\s*$PROPERTY_NAME=[0-9,]*/$PROPERTY_NAME=$PROPERTY_VALUE/}" ${MISTER_INI}
	echo "$PROPERTY_NAME=$PROPERTY_VALUE"
fi

if [ "$PROPERTY_NAME" == "video_mode" ]
then
	case $PROPERTY_VALUE in
		"0"|"7")
			sed -i "1,/^\s*video_mode_pal=[0-9,]*/{s/^\s*video_mode_pal=[0-9,]*/video_mode_pal=7/}" ${MISTER_INI}
			grep -q "^video_mode_pal=" ${MISTER_INI} && echo "video_mode_pal=7"
			sed -i "1,/^\s*video_mode_ntsc=[0-9,]*/{s/^\s*video_mode_ntsc=[0-9,]*/video_mode_ntsc=0/}" ${MISTER_INI}
			grep -q "^video_mode_ntsc=" ${MISTER_INI} && echo "video_mode_ntsc=0"
			;;
		"8"|"9")
			sed -i "1,/^\s*video_mode_pal=[0-9,]*/{s/^\s*video_mode_pal=[0-9,]*/video_mode_pal=9/}" ${MISTER_INI}
			grep -q "^video_mode_pal=" ${MISTER_INI} && echo "video_mode_pal=9"
			sed -i "1,/^\s*video_mode_ntsc=[0-9,]*/{s/^\s*video_mode_ntsc=[0-9,]*/video_mode_ntsc=8/}" ${MISTER_INI}
			grep -q "^video_mode_ntsc=" ${MISTER_INI} && echo "video_mode_ntsc=8"
			;;
		*)
			;;
	esac
fi

#reboot now
echo "Please reboot."
exit 0