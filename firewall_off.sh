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

# Version 1.0 - 2019-02-02 - First commit



if [ "$(uname -n)" != "MiSTer" ]
then
	echo "This script must be run"
	echo "on a MiSTer system."
	exit 1
fi

echo "*filter"$'\n'"COMMIT" | iptables-restore
rm /etc/network/if-pre-up.d/iptables  > /dev/null 2>&1
sync

echo "Firewall is off and"
echo "inactive at startup."
echo "Done!"
exit 0