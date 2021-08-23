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

# Version 1.0.4 - 2021-08-23 - New method for checking if the script is run on a real MiSTer system (thanks to MiSTer Addons).
# Version 1.0.3 - 2019-02-05 - Cosmetic changes.
# Version 1.0.2 - 2019-02-03 - Remounting / as RW only when needed; downgraded version from 1.1 to 1.0.2.
# Version 1.0.1 - 2019-02-02 - Remounting / as RW before altering /etc/init.d/ so the script actually works from OSD.
# Version 1.0 - 2019-02-02 - First commit



if [ ! -f "/media/fat/MiSTer" ]; 
then
	echo "This script must be run"
	echo "on a MiSTer system."
	exit 1
else
	if ! iptables -L > /dev/null 2>&1
	then
		echo "The current Kernel doesn't support iptables/firewalling."
		echo "Please fix that before running this script,"
		echo "i.e. updating your MiSTer Linux and/or running security_fixes.sh."
		exit 1
	fi

	if [ ! -f /media/fat/linux/iptables.up.rules ]
	then
		IPTABLES_UP_RULES="*filter"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -i lo -j ACCEPT"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Accepts all established inbound connections"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows all outbound traffic"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# You could modify this to only allow certain traffic"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A OUTPUT -j ACCEPT"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows SSH connections"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# The --dport number is the same as in /etc/ssh/sshd_config"
		if [ -f /etc/init.d/S50sshd ]
		then
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT"
		else
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT"
		fi
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Now you should read up on iptables rules and consider whether ssh access"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# for everyone is really desired. Most likely you will only allow access from certain IPs."
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows FTP connections"
		if [ -f /etc/init.d/S50proftpd ]
		then
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 21 -j ACCEPT"
		else
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 21 -j ACCEPT"
		fi
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allows Samba connections"
		if [ -f /etc/init.d/S91smb ]
		then
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p udp -m state --state NEW --dport 137 -j ACCEPT"
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p udp -m state --state NEW --dport 138 -j ACCEPT"
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 139 -j ACCEPT"
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p tcp -m state --state NEW --dport 445 -j ACCEPT"
		else
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p udp -m state --state NEW --dport 137 -j ACCEPT"
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p udp -m state --state NEW --dport 138 -j ACCEPT"
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 139 -j ACCEPT"
			IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#-A INPUT -p tcp -m state --state NEW --dport 445 -j ACCEPT"
		fi
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Allow ping"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#  note that blocking other types of icmp packets is considered a bad idea by some"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#  remove -m icmp --icmp-type 8 from this line to allow all kinds of icmp:"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"#  https://security.stackexchange.com/questions/22711"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# log iptables denied calls (access via 'dmesg' command)"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -m limit --limit 5/min -j LOG --log-prefix \"iptables denied: \" --log-level 7"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"# Reject all other inbound - default deny unless explicitly allowed policy:"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A INPUT -j REJECT"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"-A FORWARD -j REJECT"
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'""
		IPTABLES_UP_RULES=$IPTABLES_UP_RULES$'\n'"COMMIT"
		echo "$IPTABLES_UP_RULES" > /media/fat/linux/iptables.up.rules
	fi
	mount | grep "on / .*[(,]ro[,$]" -q && RO_ROOT="true"
	[ "$RO_ROOT" == "true" ] && mount / -o remount,rw
	echo "#!/bin/bash"$'\n'"iptables-restore < /media/fat/linux/iptables.up.rules" > /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
	sync
	[ "$RO_ROOT" == "true" ] && mount / -o remount,ro
	/etc/network/if-pre-up.d/iptables

	echo "Firewall is on and"
	echo "active at startup."
	echo "Done!"
	exit 0
fi
