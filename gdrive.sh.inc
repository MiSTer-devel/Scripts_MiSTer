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

# Version 1.0 - 2019-02-02 - First commit



if [ ! -f /media/fat/linux/$GDRIVE_COMMAND ]
then
	echo "Downloading $GDRIVE_COMMAND"
	RELEASES_PAGE="$(curl -sLf $GDRIVE_URL/releases)"
	case $? in
		0)
			RELEASE_URLS=$(echo "$RELEASES_PAGE" | grep -o "href=[\"\'][^\"\']*drive_armv7[\"\']" | sed "s/href=//g" | sed "s/[\"\']//g")
			MAX_VERSION=""
			MAX_RELEASE_URL=""
			for RELEASE_URL in $RELEASE_URLS
			do
				CURRENT_VERSION=$(echo "$RELEASE_URL" | grep -o '/v[0-9]*\.[0-9]*\.[0-9]*/')
				if [[ "$CURRENT_VERSION" > "$MAX_VERSION" ]]
				then
					MAX_VERSION=$CURRENT_VERSION
					MAX_RELEASE_URL=$RELEASE_URL
				fi
			done
			curl -L "https://github.com$MAX_RELEASE_URL" -o "/media/fat/linux/$GDRIVE_COMMAND"
			;;
		60)
			echo "CA certificates need"
			echo "to be fixed for"
			echo "using $GDRIVE_COMMAND."
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

if [ ! -f "$BASE_PATH/.gd/credentials.json" ]
then
	if [ "$SSH_CLIENT" == "" ]
	then
		echo "This script must be run"
		echo "from a SSH terminal"
		echo "once for performing"
		echo "Google Drive"
		echo "authentication."
		exit 3
	fi
	if ! /media/fat/linux/$GDRIVE_COMMAND init "$BASE_PATH"
	then
		echo "Google Drive authentication failed."
		curl -q https://google.com &>/dev/null
		case $? in
			0)
				exit 3
				;;
			60)
				echo "CA certificates need"
				echo "to be fixed for"
				echo "using $GDRIVE_COMMAND."
				echo "Please fix them i.e."
				echo "using security_fixes.sh"
				exit 2
				;;
			*)
				echo "No Internet connection"
				exit 1
				;;
		esac
	fi
fi

/media/fat/linux/$GDRIVE_COMMAND $GDRIVE_OPTIONS "$SYNC_PATH"

echo "Done!"
exit 0