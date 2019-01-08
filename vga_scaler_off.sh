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

# Version 1.0 - 2019-01-08 - First commit.

if [ ! -f "/media/fat/config/MiSTer.ini" ]
then
	echo "Downloading MiSTer.ini"
	if ! curl -kL "https://github.com/MiSTer-devel/Main_MiSTer/blob/master/MiSTer.ini?raw=true" -o "/media/fat/config/MiSTer.ini"
	then
		echo "Unable to download"
		echo "MiSTer.ini"
		exit 1
	fi
fi
cp /media/fat/config/MiSTer.ini /media/fat/config/MiSTer.ini.bak
VGA_SCALER_VALUE=0
sed -i "1,/vga_scaler=[0-9]/{s/vga_scaler=[0-9]/vga_scaler=$VGA_SCALER_VALUE/}" /media/fat/config/MiSTer.ini
echo "vga_scaler=$VGA_SCALER_VALUE"
reboot now
exit 0