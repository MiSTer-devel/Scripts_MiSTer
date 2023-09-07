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

# Version 1.0.2 - 2023-08-04 - Replacing the now absent bsdtar command by unzip.
# Version 1.0.1 - 2019-06-10 - Testing Internet connectivity with github.com instead of google.com.
# Version 1.0 - 2019-02-05 - First commit



if [ ! -f /media/fat/linux/rclone ]
then
	curl -sf https://github.com &>/dev/null
	case $? in
		0)
			echo "Downloading and extracting"
			echo "rclone."
			if ! curl -sLf "$RCLONE_URL" > rclone_archive.zip; then
				echo "Error downloading rclone archive."
				exit 1
			fi

			# Extract the archive to a temporary directory
			if ! unzip -q rclone_archive.zip -d tmp_dir; then
				echo "Error extracting rclone from the archive."
				rm rclone_archive.zip
				exit 2
			fi

			# Move the contents of the extracted directory to the desired location (/media/fat/linux)
			if ! find tmp_dir -mindepth 2 -type f -exec mv -t /media/fat/linux {} +; then
				echo "Error moving extracted files to the desired location."
				rm -r tmp_dir
				rm rclone_archive.zip
				exit 3
			fi

			rm -r tmp_dir
			rm rclone_archive.zip
			echo "Rclone has been downloaded and extracted successfully."
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
