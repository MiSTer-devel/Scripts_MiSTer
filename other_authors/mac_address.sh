#!/usr/bin/env bash

# Hardcoded for MiSTer
iface="eth0"
file="/media/fat/linux/u-boot.txt"

update_uboot() {
	if [ -n "$1" ]; then
		if [ ! -e "$file" ]; then
			echo "ethaddr=${1^^}" > "$file"
		elif grep -q 'ethaddr=' "$file"; then
			sed -i "s/\(ethaddr=\)[0-9A-Fa-f:]\+/\1${1^^}/" "$file"
		else
			echo "ethaddr=${1^^}" >> "$file"
		fi
	fi
}

valid() {
	# Convert to a locally administistored unicast MAC address
	local byte=$(( 16#${1:0:2} ))
	byte=$(( (byte & ~1) | 2 ))
	byte=$(printf "%02x" $byte)

	local mac="${byte}${1:2}"
	echo "${mac^^}"

	if [[ "${1^^}" != "${mac^^}" ]]; then
		return 0 # Input was not valid
	fi

	return 1 # Input was already valid
}

finished() {
	if dialog --yesno "The MAC address has been changed to '$1'.\nYou will need to do a cold reboot for this to take effect.\n\nWould you like to cold reboot now?" 10 38 1>&2; then
		dialog --infobox "Rebooting please wait..."  3 28 1>&2
		reboot
	else
		dialog --clear
	fi
	exit 0
}

auto() {
	local mac
	mac=$(tr -dc '0-9a-f' </dev/urandom | head -c 12 | sed 's/../&:/g; s/:$//')
	mac=$(valid "$mac")
	update_uboot "$mac"
	finished "$mac"
}

manual() {
	local current input
	current=$(cat "/sys/class/net/$iface/address")
	current="${current^^}"
	input=$current

	while true; do
		if ! input=$(dialog --inputbox "The MAC address for $iface is currently '$current'\n\nPlease enter a new MAC address..." 11 42 "$input" 3>&1 1>&2 2>&3); then
			return
		fi

		# Format MAC address
		input=${input^^}
		input=${input//-/:}

		# Validate user input is a MAC address
		if [[ ! "$input" =~ ^([0-9A-F]{2}([-:])){5}([0-9A-Fa-f]{2})$ ]]; then
			dialog --msgbox "Not a valid MAC address." 5 52 1>&2
			continue
		fi

		local mac sta
		mac=$(valid "$input")
		sta=$?

		if [ $sta -eq 0 ]; then
			if dialog --yesno "'${input^^}' is not a suitable MAC address.\n\nWould you like to use '$mac' instead?" 7 64 1>&2; then
				input="$mac"
				break
			fi
		else
			if [ "$input" = "$current" ]; then
				dialog --msgbox "'$input' is the current MAC address." 5 52 1>&2
				continue
			fi
			break
		fi
	done

	update_uboot "$mac"
	finished "$mac"
}

while true; do
	local addr
	local choice
	addr=$(cat "/sys/class/net/$iface/address")
	choice=$(dialog --menu "The current MAC address for $iface is '${addr^^}'.\n\nWhat do you want to do?" 12 44 3 \
		A "Automatically generate MAC address" M "Manually set MAC address..." 3>&1 1>&2 2>&3)

	case $choice in
		A)
			auto
		;;
		M)
			manual
		;;
		*)
			exit 0
		;;
	esac
done
