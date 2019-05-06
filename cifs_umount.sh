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
# https://github.com/MiSTer-devel/CIFS_MiSTer

# Version 2.0 - 2019-02-05 - Renamed from mount_cifs.sh and umount_cifs.sh to cifs_mount.sh and cifs_umount.sh for having them sequentially listed in alphabetical order.
# Version 1.0 - 2019.01.05 - First commit



umount -a -t cifs
echo "Done!"
exit 0