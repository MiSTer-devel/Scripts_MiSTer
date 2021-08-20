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

# Version 1.0.3 - 2019-05-02 - Code review by by frederic-mahe, now the script performs more compact tests and operations, thank you very much.
# Version 1.0.2 - 2019-02-03 - Remounting / as RW only when needed; downgraded version from 1.1 to 1.0.2.
# Version 1.0.1 - 2019-02-02 - Remounting / as RW before altering /etc/init.d/ so the script actually works from OSD.
# Version 1.0 - 2019-02-02 - First commit



if [ -f "/media/fat/MiSTer" ]; 
then
	mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
	[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
	mv /etc/init.d/_S50sshd /etc/init.d/S50sshd > /dev/null 2>&1
	sync
	[ "$RO_ROOT" == "true" ] && mount / -o remount,ro

	# start listening port 22 (SSH)
	IP_FILTERING="/media/fat/linux/iptables.up.rules"
	[[ -f "${IP_FILTERING}" ]] && sed -i '/--dport 22 / s/^#//' "${IP_FILTERING}"
	sync

	if [ -f /etc/network/if-pre-up.d/iptables ]
	then
		/etc/network/if-pre-up.d/iptables
	fi
	/etc/init.d/S50sshd start

	echo "SSH is on and"
	echo "active at startup."
	echo "Done!"
	exit 0
else
	echo "This script should be run"
	echo "on a MiSTer system."
	#exit 1
fi


