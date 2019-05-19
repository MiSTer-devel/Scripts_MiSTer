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



#========= CODE STARTS HERE =========

iptables -D INPUT -p tcp -m state --state NEW --dport 80 -j ACCEPT > /dev/null 2>&1
killall nginx > /dev/null 2>&1
killall fcgiwrap > /dev/null 2>&1
rm /var/run/fcgiwrap.socket > /dev/null 2>&1
echo "NGINX stopped"