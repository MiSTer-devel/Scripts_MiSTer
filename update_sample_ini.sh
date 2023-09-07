#!/bin/sh

set -e

SAMPLE_FILE=/media/fat/Ini_Files/MiSTer.sample.latest.ini
DOWNLOADED_FILE=/tmp/MiSTer.sample.ini
CHANGES_FILE=/media/fat/Ini_Files/MiSTer.sample.ini.CHANGES_$(date +%Y%m%d_%H%M%S)

echo "Updating: ${SAMPLE_FILE}"

curl --silent -k https://raw.githubusercontent.com/MiSTer-devel/Main_MiSTer/master/MiSTer.ini | sed -e 's/\r//g' > ${DOWNLOADED_FILE}

if [ -f ${SAMPLE_FILE} ]; then
    diff -b -B -w -d -U 0 ${SAMPLE_FILE} ${DOWNLOADED_FILE} | unix2dos > ${CHANGES_FILE} || true
    if [ $(stat -c %s ${CHANGES_FILE}) -eq 0 ]; then
        rm -f ${CHANGES_FILE}
    else
        echo "Diff saved to ${CHANGES_FILE}."
    fi
fi

mv -f ${DOWNLOADED_FILE} ${SAMPLE_FILE}
