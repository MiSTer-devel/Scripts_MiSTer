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

# Version 1.0.1 - 2019-02-05 - Changed the way the include file is loaded.
# Version 1.0 - 2019-02-02 - First commit



SCRIPT_PATH="$(realpath "$0")"

GDRIVE_URL="https://github.com/odeke-em/drive"
GDRIVE_COMMAND="gdrive"
GDRIVE_OPTIONS="push -exclude-ops delete -ignore-conflict -no-prompt"
BASE_PATH="/media/fat"
SYNC_PATH="$BASE_PATH/saves"

source "$(dirname "$SCRIPT_PATH")/gdrive.sh.inc"