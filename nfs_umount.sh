#!/usr/bin/env bash

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

# Copyright 2022 Oliver "RealLarry" Jaksch

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/CIFS_MiSTer

# Version 1.0 - 2023-03-10 - First commit

#=========NO USER-SERVICEABLE PARTS BELOW THIS LINE=====

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root. Please run again with sudo or as root user. Exiting."
  exit 1
else
  umount -a -t nfs4
fi
