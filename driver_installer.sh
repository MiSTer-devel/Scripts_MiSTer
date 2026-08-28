#!/usr/bin/env bash

# set -x
shopt -s nocasematch

installpath="/media/fat/linux/modules"
lsmod="$(lsmod)"
title="Driver Installer"

[[ "${HOSTNAME}" != "MiSTer" ]] && _error "This script must be run on the MiSTer device.\nPlease add the script to the Scripts folder on the SD card, and run it through MiSTer's main menu."


main() {
	menuOptions=(
		"Install" "Install a driver into the Linux image"
		"Uninstall" "Unload previously installed driver"
		"About" "Help and about this program"
	)

	selected="$(dialog \
		--cancel-label "Exit" \
		--menu "${title}" \
		22 77 16 "${menuOptions[@]}"  3>&1 1>&2 2>&3  )"

}

_Uninstall() {

	while IFS= read -r line; do
		[[ "${line}" == "Module"* ]] && continue
		modname="$(awk '{print $1}' <<< "${line}")"
		installed+=( "${modname}" "$(modinfo -F description "${modname}")" )
	done <<< "${lsmod}"

	selected="$(dialog \
                 --cancel-label "Back" \
                 --menu "Uninstall driver" \
                 22 77 16 "${installed[@]}"  3>&1 1>&2 2>&3  )"

	[[ -z "${selected}" ]] && return
	contents="$(modinfo "${selected}")"
	dialog \
		--title "${selected}" \
		--yes-label "Unload" \
		--no-label "Cancel" \
		--defaultno --yesno \
		"${contents}" 22 77 3>&1 1>&2 2>&3

	case "${?}" in
		0)
			#Unload button
			_preform_unload "${selected}"
			;;
	esac

}

_preform_unload() {
	local selected="${1}"

	modprobe -r "${selected}"
	rm "$(modinfo -n "${selected}")" 
}

_Install() {
	local modules moddesc selected modinfo
	[[ ! -d "${installpath}" ]] && { _error "${installpath} does not exist."; return; }

	for f in "${installpath}"/*.ko; do
		#get module information and skip if not a module
		moddesc="$(modinfo -F description "${f}")" || continue
		#add module to install menu
		modules+=("$(basename "${f}")" "${moddesc}" )
	done

	selected="$(dialog \
                 --cancel-label "Back" \
                 --menu "Install driver" \
                 22 77 16 "${modules[@]}"  3>&1 1>&2 2>&3  )"

	[[ -z "${selected}" ]] && return

	modinfo="$(modinfo "${installpath}/${selected}")"
	dialog \
		--title "${selected}" \
		--yes-label "Symlink" \
		--no-label "Cancel" \
		--defaultno --yesno \
		"${modinfo}" 22 77 3>&1 1>&2 2>&3

	case "${?}" in
		0)
			#Symlink button
			_preform_install "${selected}" "${modinfo}"
			;;
	esac

}

_preform_install() {
	local selected modinfo
	selected="${1}"
	modinfo="${2}"
	
	#check if not for this kernel
	[[ "${modinfo}" == *"$(uname -r)"* ]] || { _error "Module is not for this kernel"; return; }	
	#check if not for ARM
	[[ "${modinfo}" == *"ARM"* ]] || { _error "Module is not for this architecture"; return; }
	
	#check if module already loaded
	grep -q "$(modinfo -F name "${i}")" <<< "${lsmod}" && { _error "Module is already installed"; return; }

	#Check for unwritable filesystem
	mount | grep -q "on / .*[(,]ro[,$]" && RO_ROOT="true"
	[[ "${RO_ROOT}" == "true" ]] && mount / -o remount,rw
	
	##copy to modules folder
	#cp "${i}" "/lib/modules/$(uname -r)/"
	#make a symlink for the driver
	ln -sf "${selected}" "/lib/modules/$(uname -r)/" 
	#build dependency map
	depmod -a
	#install and load module
	modprobe "$(modinfo -F name "${selected}")"
}

_About() {
	local about
	read -rd '' about <<_EOF_
This program can install drivers into the Linux image on the MiSTer platform. When MiSTer updates Linux everything is cleared always. Because the Linux partition is a single file that is replaced during the update. This program makes it easy to install your driver again after an update.

This script is written by Ziggurat (Discord and misterfpga.org) 
https://github.com/sigboe
_EOF_

dialog --title "About" --msgbox "${about}" 22 77  3>&1 1>&2 2>&3
}

_error() {
	msg="${1}"
	dialog --title "ERROR:" --msgbox "${msg}" 22 77 3>&1 1>&2 2>&3 
}

_exit() { 
	sync
	[[ "${RO_ROOT}" == "true" ]] && mount / -o remount,ro
	dialog \
		--title "Exiting:" \
		--msgbox "Please reboot for any changes to take into effect." 22 77 3>&1 1>&2 2>&3 
	exit
}

while true; do
	main
	"_${selected:-exit}"
done
