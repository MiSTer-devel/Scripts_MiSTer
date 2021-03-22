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

# Version 1.1 - 2021-01-24 - Added options for polling rate
# Version 1.0 - 2020-01-22 - first version

import os
import select
import sys
import time
import tty
import re
from os import path

def has_input(timeout=0):
    return select.select([sys.stdin], [], [], timeout)[0]

def get_ans(options=None, timeout=20):
    try:
        # flush per-character
        fd = sys.stdin.fileno()
        old_fd = tty.tcgetattr(fd)
        tty.setcbreak(fd)

        # countdown while waiting for input
        i = timeout
        max_num_length = len(str(timeout))
        while i:
            print("\r{:{}}... ".format(i, max_num_length), end="", flush=True)
            i -= 1
            if has_input(1):
                c = sys.stdin.read(1)
                if options is not None:
                    if c in options:
                        return c
                else:
                    return c
        return None
    finally:
        # restore attr
        tty.tcsetattr(fd, tty.TCSAFLUSH, old_fd) 

UBOOT_PATH = "/media/fat/linux/u-boot.txt"

if os.uname()[1] != "MiSTer":
    print ("This script must be run on a MiSTer system.")
    sys.exit(1)

print ("""
Fast USB polling

Press 1     for 1000hz (1ms) [default]
Press 2     for  500hz (2ms)
Press 3     for  250hz (4ms)
Press 4     for  125hz (8ms)
Press Enter for default
""")

poll_input = get_ans(["1", "2", "3", "4", "\n"])

if poll_input == "1":
    print ("Selected 1000hz (1ms)")
    poll_value = 1
elif poll_input == "2":
    print ("Selected 500hz (2ms)")
    poll_value = 2
elif poll_input == "3":
    print ("Selected 250hz (4ms)")
    poll_value = 4
elif poll_input == "4":
    print ("Selected 125hz (8ms)")
    poll_value = 8
else:
    print ("Using default")
    poll_value = 1

# give time to see selection on screen
time.sleep(2)

if path.exists(UBOOT_PATH):

    poll_prefixes = ("v=loglevel=","usbhid.jspoll=","xpad.cpoll=")

    #reads lines, removing old polling choices and stripping whitespace
    with open("/media/fat/linux/u-boot.txt","r") as file:
        lines_out = []
        for l in file.readlines():
            stripped_line = re.sub("(%s|%s|%s)\d+\s*" % poll_prefixes,"",l).strip()
            if len(stripped_line) > 0:
                lines_out.append(stripped_line)

    #rewrites cleaned output with selected polling turned on
    with open("/media/fat/linux/u-boot.txt","w") as file:
        for l in lines_out:
            file.write(l + "\n")
        file.write("v=loglevel=4 usbhid.jspoll=%s xpad.cpoll=%s\n" % (poll_value, poll_value))

else:
    with open("/media/fat/linux/u-boot.txt","w") as file:
        file.write("v=loglevel=4 usbhid.jspoll=%s xpad.cpoll=%s\n" % (poll_value, poll_value))

os.system("clear")

print ("""
Fast USB polling is ON and will be active after reboot.

This will force selected polling on all gamepads and joysticks!
If you have any input issues, please run fast_USB_polling_off.sh

Rebooting in:
""")

time.sleep(2)

t = 5
while t > 0:
    print ("...%x" % t)
    t -= 1
    time.sleep(1)

print ("...NOW!")
os.system("reboot")

time.sleep(10) # Reboot without showing "Press any key..."
