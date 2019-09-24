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

# Copyright 2019 "self_slaughter"

# Version 1.0 - 2019-09-24 - First commit

# Note: Some code taken from Locutus73's updater scripts found here:
# https://github.com/MiSTer-devel/Updater_script_MiSTer



# Change MAME_DIR to point to where you have your mame roms mounted
MAME_DIR="/media/fat/Mame/MAME 0.213 ROMs (non-merged)"

WORK_DIR="/media/fat/Scripts/other_authors/.mame"
OUTPUT_DIR="/media/fat/bootrom"
CURL_RETRY="--insecure --connect-timeout 15 --max-time 120 --retry 3 --retry-delay 5"
MISTER_URL="https://github.com/MiSTer-devel/Main_MiSTer"

setup_workspace() {
    mkdir "$WORK_DIR" &>/dev/null
    mkdir "$OUTPUT_DIR" &>/dev/null
    cp /media/fat/Scripts/other_authors/flips /bin &>/dev/null
}

cleanup() {
    rm -rf "$WORK_DIR" &>/dev/null
}

find_urls() {
    echo "Searching for cores"
    CORE_URL=($(curl --insecure $CURL_RETRY -sLf "$MISTER_URL/wiki"| awk '/(user-content-cores)|(user-content-computer-cores)/,/user-content-development/' | grep -io '\(https://github.com/[a-zA-Z0-9./_-]*_MiSTer\)' | grep 'Arcade.*'))
    echo "${#CORE_URL[@]} cores found!"
}

find_core_names() {
    for url in ${CORE_URL[@]}; do
    CORE_NAME+=($(echo "$url" | sed -e 's/https:\/\/github.com\/MiSTer-devel\/Arcade-//gI' -e 's/_MiSTer//gI'))
    done
}

grab_scripts()
{
    count=$(($1 + 1))
    echo -e "\n${CORE_NAME[$1]} ($count/$totalCount)"
    mkdir "$WORK_DIR/${CORE_NAME[$1]}" &>/dev/null
    echo "- Downloading Scripts"

    SCRIPT_URLS=$(curl $CURL_RETRY -sLf "${CORE_URL[$1]}/raw/master/releases/" | grep -io '\"\/MiSTer\-devel\/[a-zA-Z0-9].*\?\(\.ini\|\.sh\|\.bin\|\.1\|\.2\|\.3\|\.ips\)\"')
    for buildFiles in $SCRIPT_URLS; do
        buildFile=$(echo "$buildFiles" | sed -e 's/^"//' -e 's/"$//' | grep -io 'releases/.*' | grep -io '/.*' | sed -e 's/\///')
        curl $CURL_RETRY -sLf "${CORE_URL[$1]}/raw/master/releases/$buildFile" -o "$WORK_DIR/${CORE_NAME[$1]}/$buildFile"
    done
}

grab_zips()
{
    zip=""
    zips=""
    cd "$WORK_DIR/${CORE_NAME[$1]}"
    for iniFile in *.ini; do
        if [ ! -f "$iniFile" ]; then
            echo "- Nothing to build"
            skipped+=("${CORE_NAME[$1]}")
            return 1
        fi
        source "$WORK_DIR/${CORE_NAME[$1]}/$iniFile"
        if [ -f "$OUTPUT_DIR/${ofile}" ]; then
            echo "- ROM Already Exists"
            skipped+=("${CORE_NAME[$1]}")
            return 1
        fi
        echo "- Copying ZIPs"
        for zipFile in "${zip:-${zips[@]:-default}}"; do
            if [ ! -f "$MAME_DIR/$zipFile" ]; then
                echo "- Can't find $zipFile"
                failed+=("${CORE_NAME[$1]}")
                return 1
            else
                cp "$MAME_DIR/$zipFile" "$WORK_DIR/${CORE_NAME[$1]}/"
            fi
        done
    done
}

build_roms()
{
    cd "$WORK_DIR/${CORE_NAME[$1]}"
    for buildScript in *.sh; do
        source "$WORK_DIR/${CORE_NAME[$1]}/${buildScript%.*}.ini"
        echo "- Building ROM"
        chmod +x "$WORK_DIR/${CORE_NAME[$1]}/${buildScript}" &>/dev/null
        bash "$WORK_DIR/${CORE_NAME[$1]}/${buildScript}" &>/dev/null
        if [ $? -eq 0 ]; then
            echo "- Success"
            verified+=("${CORE_NAME[$1]}")
        else 
            if [ -f "$WORK_DIR/${CORE_NAME[$1]}/${ofile}" ]; then
                echo "- Success (MD5 Fail)"
                unverified+=("${CORE_NAME[$1]}")
            else
                echo "- Build Failed"
                failed+=("${CORE_NAME[$1]}")
                return 1
            fi
        fi
        if [ "${ofile}" == "a.JT1943.rom" ] && [ ! -f "$OUTPUT_DIR/a.1943.rom" ]; then
            cp "$WORK_DIR/${CORE_NAME[$1]}/${ofile}" "$OUTPUT_DIR/a.1943.rom"
        fi
        cp "$WORK_DIR/${CORE_NAME[$1]}/${ofile}" "$OUTPUT_DIR/${ofile}"
    done
}

show_stats()
{
    echo -e "\n*** FINISHED ***\n"
    echo "Verified:    ${#verified[@]}"
    echo "Unverified:  ${#unverified[@]}"
    echo "Failed:      ${#failed[@]}"
    echo "Skipped:     ${#skipped[@]}"
}

find_urls
find_core_names
cleanup
setup_workspace

totalCount=${#CORE_URL[@]}
for (( i=0; i<$totalCount; i++ ));
do
    grab_scripts "$i"
    grab_zips "$i"
    if [ $? == 0 ]; then
        build_roms "$i"
    fi
done

show_stats
cleanup
