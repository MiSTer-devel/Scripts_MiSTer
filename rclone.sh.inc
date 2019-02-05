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

# Version 1.0 - 2019-02-05 - First commit



if [ ! -f /media/fat/linux/rclone ]
then
	curl -sf https://google.com &>/dev/null
	case $? in
		0)
			echo "Downloading and extracting"
			echo "rclone."
			if ! curl -sLf "$RCLONE_URL" | bsdtar -xf - --strip-components=1 --no-same-owner -C "/media/fat/linux" "*/rclone"
			then
				echo "Error downloading"
				echo "or extracting rclone."
				rm /media/fat/linux/rclone > /dev/null 2>&1
				exit 3
			fi
			;;
		60)
			echo "CA certificates need"
			echo "to be fixed for"
			echo "using rclone."
			echo "Please fix them i.e."
			echo "using security_fixes.sh"
			exit 2
			;;
		*)
			echo "No Internet connection."
			exit 1
			;;
	esac
fi

if [ ! -f "$RCLONE_CONFIG" ]
then
	echo "rclone must be configured"
	echo "before first use."
	echo "Please visit"
	echo "https://goo.gl/JcqhgS"
	echo "for the instructions."
	exit 4
fi

CLOUD_NAME="$(cat "$RCLONE_CONFIG" | grep "^ *type *=" | sed 's/^ *type *= *//g'  | sed 's/\r//g')"
if echo "$RCLONE_DEST" | grep -q "^MiSTer:"
then
	echo "Uploading $RCLONE_SD_DIR"
	echo "to $CLOUD_NAME"
else
	echo "Downloading $RCLONE_SD_DIR"
	echo "from $CLOUD_NAME"
fi

echo ""

/media/fat/linux/rclone --config="$RCLONE_CONFIG" $RCLONE_OPTIONS $RCLONE_COMMAND "$RCLONE_SOURCE" "$RCLONE_DEST" 2>&1 |
	while IFS= read -r line
	do
		if [ "$SSH_CLIENT" == "" ]
		then
			echo ""
			echo "$line" | sed 's/[ 	]\{1,\}/ /g' | fold -w 29 -s
		else
			echo "$line"
		fi
	done

echo "Done!"
exit 0