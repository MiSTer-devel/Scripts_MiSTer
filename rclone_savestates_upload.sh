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

# Copyright 2021 Andrew Kendall (andrewkendall.com) based on a script by Alessandro "Locutus73" Miel

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer

# Version 1.0 - 2021-01-13 - First commit



SCRIPT_PATH="$(realpath "$0")"

RCLONE_URL="https://downloads.rclone.org/rclone-current-linux-arm.zip"
RCLONE_CONFIG="$(dirname "$SCRIPT_PATH")/rclone.conf"
RCLONE_OPTIONS="--verbose"
RCLONE_COMMAND="copy"
RCLONE_SD_DIR="savestates"
RCLONE_SOURCE="/media/fat/$RCLONE_SD_DIR"
RCLONE_DEST="MiSTer:MiSTer/$RCLONE_SD_DIR"

source "$(dirname "$SCRIPT_PATH")/rclone.sh.inc"
