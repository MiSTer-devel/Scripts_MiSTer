#!/usr/bin/env bash

# set -x

storage="/media/fat/linux/backup"
hwclockstatus="$(hwclock >/dev/null ; echo $?)"
ntpqstatus="$(ntpq -c rv | cut -d" " -f3 | head -n1)"
title="Backup Linux Changes"

[[ "${hwclockstatus}" == "0" ]] && gottime="yes"
[[ "${ntpqstatus}" != "leap_alarm," ]] && gottime="yes"

[[ "${HOSTNAME}" != "MiSTer" ]] && _error "This script must be run on the MiSTer device.\nPlease add the script to the Scripts folder on the SD card, and run it through MiSTer's main menu."

_preform_backup() {
	[[ -s "${storage}/files.txt" ]] || { _error "${storage}/files.txt does not exist or is empty." ; return ; }

	if [[ "${gottime}" == "yes" ]]; then
		backupserial="$(date +"%y%m%d%H%M")"
		dialog \
			--title "Got time!" \
			--msgbox "We got a valid date either from a real time clock or from the internet. We will use the current date and time as the serial number for this backup. The serial number for this backup is ${backupserial}" 22 77 3>&1 1>&2 2>&3
	elif [[ -n "$(find "${storage}" -maxdepth 1 -name 'backup_*.tar.gz' -print -quit)" ]]; then
		backupserial="$(find "${storage}" -maxdepth 1 -type f -name 'backup_*.tar.gz' | sort | tail -n1 )"
		backupserial="${backupserial##*backup_}"
		backupserial="${backupserial%%.*}"
		(( backupserial++ ))
		dialog \
			--title "No time found" \
			--msgbox "We did not get valid time either from a real time clock or from the internet. We found an older backup, and we will increment the serial number. The serial number for this backup is ${backupserial}" 22 77 3>&1 1>&2 2>&3
	else
		printf "%s\n" '#'
		backupserial="0000000000"
		dialog \
			--title "No time found" \
			--msgbox "We did not get valid time either from the real time clock or from the internet. We found no older backup. We will use ${backupserial} as the first serial number for this backup." 22 77 3>&1 1>&2 2>&3
	fi
	
	backupname="backup_${backupserial}.tar.gz"

	tar -czvf "${storage}/${backupname}" -T "${storage}/files.txt"

	printf "%s\n" "${backupname}" >> "${storage}/history"
}

_preform_restore() {
	taroutput="$(tar xzvf "${1}" -C / )"
	echo "${taroutput}" > "${storage}/.lastrestore.log"
	dialog \
		--title "Finished restoring:" \
		--msgbox "${taroutput}" 22 77 3>&1 1>&2 2>&3 

}


main() {
	menuOptions=(
		"Backup" "Backup linux image customizations"
		"Restore" "Restore a previous backup"
		"About" "Help and about this program"
	)

	selected="$(dialog \
		--cancel-label "Exit" \
		--menu "${title}" \
		22 77 16 "${menuOptions[@]}"  3>&1 1>&2 2>&3  )"

}

_Backup() {
	local contents
	contents="$(cat "${storage}/files.txt")"

	dialog \
		--title "Backup these files?" \
		--yes-label "Backup" \
		--no-label "Cancel" \
		--defaultno --yesno \
		"${contents}" 22 77 3>&1 1>&2 2>&3

	case "${?}" in
		0)
			#Backup button
			_preform_backup
			;;
	esac
}

_Restore() {
	local backups
	for f in "${storage}"/backup_*.tar.gz; do
		backups+=("$(basename "${f}")" "$(du -h "${f}" | cut -f1)" )
	done

	selected="$(dialog \
                 --cancel-label "Back" \
                 --menu "${title}" \
                 22 77 16 "${backups[@]}"  3>&1 1>&2 2>&3  )"
	[[ -z "${selected}" ]] && return

	contents="$(tar -ztf "${storage}/${selected}")"
	dialog \
		--title "${selected}" \
		--yes-label "Restore" \
		--no-label "Cancel" \
		--defaultno --yesno \
		"${contents}" 22 77 3>&1 1>&2 2>&3

	case "${?}" in
		0)
			#Restore button
			_preform_restore "${selected}"
			;;
	esac

}

_About() {
	local about
	read -rd '' about <<_EOF_
This program is intended to be used by people who have customized their Linux installation on MiSTer. When MiSTer updates Linux everything is cleared always. Because the Linux partition is a single file that is replaces during the update. MiSTer intends for all your files to be on the SD card. But this doesn't work for people want to keep their ssh public keys, ssh fingerprints, ssh settings, or your bash settings, or anything else that is whiped after an update. 

To use this software make a folder called backup in your linux folder on your sd card. And make a file that is called files.txt In this file list all the files or folders you wish to take a backup off. Example to backup your ssh settings, fingerprints and keys add:

/etc/ssh
/root/.ssh

This script is written by Ziggurat (Discord and misterfpga.org) 
https://github.com/sigboe
_EOF_

dialog --title "About" --msgbox "${about}" 22 77  3>&1 1>&2 2>&3
}

_error() {
	msg="${1}"
	dialog --title "ERROR:" --msgbox "${msg}" 22 77 3>&1 1>&2 2>&3 
}

_exit() { exit; }

while true; do
	main
	"_${selected:-exit}"
done
