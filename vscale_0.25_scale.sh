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

# Version 2.0 - 2019-01-14 - Using change_ini_property.sh.inc
# Version 1.1.1 - 2019-01-09 - Fixed regular expression for not matching commented parameters.
# Version 1.1 - 2019-01-08 - MiSTer.ini downloaded from GitHub if missing.
# Version 1.0 - 2019-01-07 - First commit.

PROPERTY_NAME="vscale_mode"
PROPERTY_VALUE="3"
source "$(dirname $(readlink -f $0))/change_ini_property.sh.inc"