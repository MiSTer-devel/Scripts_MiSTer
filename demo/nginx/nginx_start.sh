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
# https://github.com/MiSTer-devel/Scripts_MiSTer/tree/master/demo/nginx

# Version 1.0 - 2019-05-19 - First commit.



#=========   USER OPTIONS   =========
#Base directory for all script’s tasks, "/media/fat" for SD root, "/media/usb0" for USB drive root.
BASE_PATH="/media/fat"
NGINX_PATH="${BASE_PATH}/linux/nginx"
NGINX_URL="https://github.com/MiSTer-devel/Scripts_MiSTer/blob/master/demo/nginx"



#========= CODE STARTS HERE =========

ORIGINAL_SCRIPT_PATH="$0"
if [ "$ORIGINAL_SCRIPT_PATH" == "bash" ]
then
	ORIGINAL_SCRIPT_PATH=$(ps | grep "^ *$PPID " | grep -o "[^ ]*$")
fi

if [ ! -d "${NGINX_PATH}" ]
then
	echo "Downloading nginx.zip"
	curl -L "$NGINX_URL/nginx.zip?raw=true" -o "/tmp/nginx.zip"
	case $? in
		0)
			curl -L "$NGINX_URL/nginx_stop.sh?raw=true" -o "$(dirname ${ORIGINAL_SCRIPT_PATH})/nginx_stop.sh"
			;;
		60)
			if ! curl -kL "$NGINX_URL/nginx.zip?raw=true" -o "/tmp/nginx.zip"
			then
				echo "No Internet connection"
				exit 2
			else
				curl -kL "$NGINX_URL/nginx_stop.sh?raw=true" -o "$(dirname ${ORIGINAL_SCRIPT_PATH})/nginx_stop.sh"
			fi
			;;
		*)
			echo "No Internet connection"
			exit 2
			;;
	esac
	if [ -f "/tmp/nginx.zip" ]
	then
		unzip -o "/tmp/nginx.zip" -d "$(dirname ${NGINX_PATH})"
		rm "/tmp/nginx.zip" > /dev/null 2>&1
	fi
fi



iptables -I INPUT 4 -p tcp -m state --state NEW --dport 80 -j ACCEPT
export LD_LIBRARY_PATH="${NGINX_PATH}"
${NGINX_PATH}/fcgiwrap -s unix:/var/run/fcgiwrap.socket -f &
sleep 1
chmod 777 /var/run/fcgiwrap.socket
mkdir -p /tmp/nginx-logs
if ${NGINX_PATH}/nginx -c ${NGINX_PATH}/conf/nginx.conf -g "error_log /tmp/nginx-logs/error.log;" > /dev/null 2>&1
then
	echo "NGINX started"
else
	echo "NGINX not started"
	echo "please see"
	echo "/tmp/nginx-logs/error.log"
fi