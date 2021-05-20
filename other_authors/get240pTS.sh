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

# Copyright 2021 donluca <donluca@theclassicgamer.net>

# You can download the latest version of this script from:
# https://github.com/MiSTer-devel/Scripts_MiSTer

# Version 1.0 - 2021-04-26 - First commit

# ========= OPTIONS ==================
CURL_OPTIONS="-L --connect-timeout 15 --max-time 120 --retry 3 --retry-delay 5 --show-error"

# ========= ADVANCED OPTIONS =========
# ALLOW_INSECURE_SSL="true" will check if SSL certificate verification (see https://curl.haxx.se/docs/sslcerts.html )
# is working (CA certificates installed) and when it's working it will use this feature for safe curl HTTPS downloads,
# otherwise it will use --insecure option for disabling SSL certificate verification.
# If CA certificates aren't installed it's advised to install them (i.e. using security_fixes.sh).
# ALLOW_INSECURE_SSL="false" will never use --insecure option and if CA certificates aren't installed
# any download will fail.
ALLOW_INSECURE_SSL="true"

# ========= CODE STARTS HERE =========

# Function to show this script's syntax
function showUsage () {
    echo "Usage: ./get240pTS.sh <Platform> (z)"
    echo " "
    echo "Platforms supported:"
    echo " "
    # echo "DC (SEGA Dreamcast)"
    echo "GB (Nintendo Game Boy)"
    # echo "GC (Nintendo GameCube)"
    echo "GBA (Nintendo GameBoy Advance)"
    echo "MCD (SEGA Mega Drive/Genesis + Mega CD/SEGA CD)"
    echo "MD (SEGA Mega Drive/Genesis)"
    echo "NES (Nintendo Entertainment System/Famicom)"
    echo "PCE (NEC PC Engine/TurboGrafx-16)"
    echo "PCECD (NEC PC Engine/TurboGrafx-16 + TurboGrax-CD/CD-ROM)"
    echo "PCESCD (NEC PC Engine/TurboGrafx-16 + Super CD-ROM)"
    # echo "PS1 (Sony Playstation)"
    echo "SMS (Sega Master System/Mark III)"
    echo "SNES (Nintendo Super NES/Super Famicom)"
    # echo "WII (Nintendo Wii)"
    echo "ALL (Download all of the above)"
    echo " "
    echo "If the file is zipped, you can unzip it by adding z to the command"
    echo " "
    echo "Example: ./get240pTS.sh MD z"
    echo "This will download the Mega Drive 240p Test Suite and unzip it"
}

# Function to download the 240p Test Suites for all platforms
function getAll()
{
    # ./get240pTS.sh DC z
    ./get240pTS.sh GB
    ./get240pTS.sh GBA
    # ./get240pTS.sh GC z
    ./get240pTS.sh MCD z
    ./get240pTS.sh MD z
    ./get240pTS.sh NES
    ./get240pTS.sh PCE z
    ./get240pTS.sh PCECD z
    ./get240pTS.sh PCESCD z
    # ./get240pTS.sh PS1 z
    ./get240pTS.sh SMS z
    ./get240pTS.sh SNES z
    # ./get240pTS.sh WII z
}

# Set the cache file path
CACHEFILE="/media/fat/Scripts/.cache/get240pTS"

# The variable responsible for showing the usage following an invalid input
invalidInput=0;

# Links to the various 240p Test Suite latest version
LINKS=()
LINKS+=("http://junkerhq.net/240pTestSuite/Dreamcast/240pTestSuite-Dreamcast-latest.zip") #Dreamcast
LINKS+=("http://junkerhq.net/240pTestSuite/PinoBatch/144pTestSuite.gb") #Game Boy
LINKS+=("http://junkerhq.net/240pTestSuite/PinoBatch/160pTestSuite.gba") #Game Boy Advanced
LINKS+=("http://junkerhq.net/240pTestSuite/GameCube/240pTestSuite-GameCube-latest.zip") #GameCube
LINKS+=("http://junkerhq.net/240pTestSuite/SegaCD/240pTestSuite-Sega_Mega_CD-latest.zip") #MegaCD
LINKS+=("http://junkerhq.net/240pTestSuite/MegaDrive/240pTestSuite-MD_Genesis-latest.zip") #Mega Drive
LINKS+=("http://junkerhq.net/240pTestSuite/PinoBatch/240pTestSuite.nes") #NES
LINKS+=("http://junkerhq.net/240pTestSuite/PCE/240pTestSuite-PCE_TG16-HuCard-latest.zip") #PCEngine
LINKS+=("http://junkerhq.net/240pTestSuite/PCE/240pTestSuite-PCE_TG16-CDROM-latest.zip") #PCEngine CD
LINKS+=("http://junkerhq.net/240pTestSuite/PCE/240pTestSuite-PCE_TG16-SuperCDROM-latest.zip") #PCEngine SuperCD
LINKS+=("https://github.com/filipalac/240pTestSuite-PS1/releases/download/19122020/240pTestSuitePS1-EMU.zip") #Playstation
LINKS+=("https://github.com/sverx/SMSTestSuite/releases/download/v0.32/SMSTestSuite.sms") #Master System
LINKS+=("http://junkerhq.net/240pTestSuite/SNES/240pTestSuite-SNES-latest.zip") #SNES
LINKS+=("http://junkerhq.net/240pTestSuite/Wii/240pTestSuite-Wii-latest.zip") #Wii

# Look for the folder used to store ROMs and ISOs
ACTIVEMOUNTS=`mount | awk '{ print $3 }'`

TEMP_TDIR=()
TEMP_TDIR+=(`echo "${ACTIVEMOUNTS}" | grep /media/usb | sed -n 1p`)
TEMP_TDIR+=(`echo "${ACTIVEMOUNTS}" | grep /media/cifs | sed -n 1p`)
TEMP_TDIR+=(`echo "${ACTIVEMOUNTS}" | grep /media/fat | sed -n 1p`)
TDIR="${TEMP_TDIR[0]}/"

if [[ -d "${TDIR}games" ]]; then TDIR+="games/"; fi

# Create the cache file if it doesn't exist and load it
if [[ ! -f "${CACHEFILE}" ]]
then
    > "${CACHEFILE}"
    for (( c=1; c<=${#LINKS[@]}; c++ )); do echo 0 >> "${CACHEFILE}"; done
fi
CACHE=(`cat "${CACHEFILE}"`)

# Set platform and target directories
case $1 in
    # DC)
    #    INDEX=0
    #    TDIR=""
    #    ;;
    GB)
        INDEX=1
        TDIR+="GAMEBOY/"
        ;;
    GBA)
        INDEX=2
        TDIR+="GBA/"
        ;;
    # GC)
    #    INDEX=3
    #    TDIR=""
    #    ;;
    MCD)
        INDEX=4
        TDIR+="MegaCD/"
        ;;
    MD)
        INDEX=5
        TDIR+="Genesis/"
        ;;
    NES)
        INDEX=6
        TDIR+="NES/"
        ;;
    PCE)
        INDEX=7
        TDIR+="TGFX16/"
        ;;
    PCECD)
        INDEX=8
        TDIR+="TGFX16-CD/CD-"
        ;;
    PCESCD)
        INDEX=9
        TDIR+="TGFX16-CD/SCD-"
        ;;
    # PS1)
    #    INDEX=10
    #    TDIR+="Playstation/"
    #    ;;
    SMS)
        INDEX=11
        TDIR+="SMS/"
        ;;
    SNES)
        INDEX=12
        TDIR+="SNES/"
        ;;
    # WII)
    #    INDEX=13
    #    TDIR=""
    #    ;;
    *)
        invalidInput=1;
esac
LINK="${LINKS[$INDEX]}"
TDIR+="240pTestSuite/"

# Check first if the input is valid. If it isn't show usage.
# Although, if this was run from the OSD, then just download everything
if [[ "${invalidInput}" == 1 ]]
then
    if [[ `echo "${PATH}" | grep /media/fat/Scripts/` == "" || "${1}" == "ALL" ]]
    then 
        getAll
    else
        showUsage
    fi
else
    # Test network and https by pinging the target website 
    curl ${CURL_OPTIONS} -s -I -X POST "https://github.com" > /dev/null 2>&1
    case $? in
        0)
            ;;
        60)
            if [[ "${ALLOW_INSECURE_SSL}" == "true" ]]
            then
                CURL_OPTIONS+=" --insecure"
            else
                echo "CA certificates need"
                echo "to be fixed for"
                echo "using SSL certificate"
                echo "verification."
                echo "Please fix them i.e."
                echo "using security_fixes.sh"
                exit 2
            fi
            ;;
        *)
            echo "No Internet connection"
            exit 1
            ;;
    esac

    # Grab the file name from the link, it will be needed to know if the file is zipped
    FILENAME=`basename "${LINK}"`

    # Create target directory (if necessary)
    if [[ ! -d "${TDIR}" ]]; then mkdir -p "${TDIR}"; fi
    
    # Check the cache file and target directory to see if the 240p Test Suite is already downloaed and updated
    UPDATE=`curl ${CURL_OPTIONS} -s -I ${LINK} | grep -i etag | awk '{ print $2 }'`
    if [[ "${UPDATE}" != "${CACHE[$INDEX]}" || `ls "${TDIR}"` == "" ]]
    then
        # Check if an older 240p Test suite is present. If it is, delete it
        find "${TDIR}" -type f -exec rm -rf {} \;

        # Download the 240p Test Suite for requested platform
        echo "Downloading ${FILENAME} for platform ${1}..."
        cd "${TDIR}" && { curl -O ${CURL_OPTIONS} "${LINK}" ; RES=$? ; cd - > /dev/null ; }
        if [[ "${2}" == "z" && `echo "${FILENAME}" | sed 's/^.*\.//'` == "zip" ]]
        then
            cd "${TDIR}" && { unzip -qq -o "${FILENAME}" && rm -rf "${FILENAME}"; cd - > /dev/null ; }
        fi
        
        # Show a message to inform the user if the 240p Test Suite has been downloaded correctly and update the cachefile (if needed)
        if [[ "${RES}" == 0 ]]
        then 
            echo "${FILENAME} for platform ${1} downloaded correctly"
            CACHE[$INDEX]="${UPDATE}"
            printf '%s\n' "${CACHE[@]}" > "${CACHEFILE}"
        else
            echo "There has been an error when downloading ${FILENAME} for the platform ${1}"
        fi
    else
        echo "240p Test Suite for platform ${1} is already downloaded and updated"
    fi
fi
echo " "
