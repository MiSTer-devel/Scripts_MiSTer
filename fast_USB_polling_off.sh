#!/usr/bin/env python

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

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer

# Version 1.0 - 2019-12-26 - first version

import os
import sys
import time

if os.uname()[1] != "MiSTer":
    print "This script must be run on a MiSTer system."
    sys.exit(1)

with open("/media/fat/linux/u-boot.txt","w") as file:
    file.write("v=loglevel=4 usbhid.jspoll=0 xpad.cpoll=0\n")

os.system("clear")

print """
Fast USB polling is OFF and
will be inactive after reboot.

Rebooting in:
""",

time.sleep(1)

t = 3
while t > 0:
    print "...%x" % t
    t -= 1
    time.sleep(1)

print "...NOW!"
os.system("reboot")

time.sleep(10) # Reboot without showing "Press any key..."

