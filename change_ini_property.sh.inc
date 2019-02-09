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

# Version 1.1 - 2019-02-09 - Support for video_mode_ntsc and video_mode_pal; the script tries to download MiSTer.ini (when needed) using SSL certificate verification; corrected a regular expression bug.
# Version 1.0 - 2019-01-14 - First commit.

if [ ! -f "/media/fat/config/MiSTer.ini" ]
then
	echo "Downloading MiSTer.ini"
	curl -k "https://github.com/MiSTer-devel/Main_MiSTer/blob/master/MiSTer.ini?raw=true" -o "/media/fat/config/MiSTer.ini"
	case $? in
		0)
			;;
		60)
			if ! curl -kL "https://github.com/MiSTer-devel/Main_MiSTer/blob/master/MiSTer.ini?raw=true" -o "/media/fat/config/MiSTer.ini"
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

cp /media/fat/config/MiSTer.ini /media/fat/config/MiSTer.ini.bak

sed -i "1,/^\s*$PROPERTY_NAME=[0-9,]*/{s/^\s*$PROPERTY_NAME=[0-9,]*/$PROPERTY_NAME=$PROPERTY_VALUE/}" /media/fat/config/MiSTer.ini
echo "$PROPERTY_NAME=$PROPERTY_VALUE"

if [ "$PROPERTY_NAME" == "video_mode_ntsc_pal" ]
then
	if [ "$PROPERTY_VALUE" == "1" ]
	then
		if cat /media/fat/config/MiSTer.ini | grep -q "video_mode_pal"
		then
			sed -i -e '/video_mode_pal/s/^#//g' /media/fat/config/MiSTer.ini
		else
			sed -i -e '/^\s*video_mode=[0-9,]*/{a\video_mode_pal=7\r' -e ':a;$q;n;ba;}' MiSTer.ini
		fi
		if cat /media/fat/config/MiSTer.ini | grep -q "video_mode_ntsc"
		then
			sed -i -e '/video_mode_ntsc/s/^#//g' /media/fat/config/MiSTer.ini
		else
			sed -i -e '/^\s*video_mode=[0-9,]*/{a\video_mode_ntsc=0\r' -e ':a;$q;n;ba;}' MiSTer.ini
		fi
		PROPERTY_NAME=video_mode
		PROPERTY_VALUE="$(cat /media/fat/config/MiSTer.ini | grep -o -m 1 "^\s*video_mode=[0-9,]*" | grep -o "[0-9,]*$")"
	else
		sed -i -e '/video_mode_ntsc/s/^#*/#/g' /media/fat/config/MiSTer.ini
		sed -i -e '/video_mode_pal/s/^#*/#/g' /media/fat/config/MiSTer.ini
	fi
fi

if [ "$PROPERTY_NAME" == "video_mode" ]
then
	case $PROPERTY_VALUE in
		"0"|"7")
			sed -i "1,/^\s*video_mode_pal=[0-9,]*/{s/^\s*video_mode_pal=[0-9,]*/video_mode_pal=7/}" /media/fat/config/MiSTer.ini
			sed -i "1,/^\s*video_mode_ntsc=[0-9,]*/{s/^\s*video_mode_ntsc=[0-9,]*/video_mode_ntsc=0/}" /media/fat/config/MiSTer.ini
			;;
		"8"|"9")
			sed -i "1,/^\s*video_mode_pal=[0-9,]*/{s/^\s*video_mode_pal=[0-9,]*/video_mode_pal=9/}" /media/fat/config/MiSTer.ini
			sed -i "1,/^\s*video_mode_ntsc=[0-9,]*/{s/^\s*video_mode_ntsc=[0-9,]*/video_mode_ntsc=8/}" /media/fat/config/MiSTer.ini
			;;
		*)
			;;
	esac
fi

reboot now
exit 0