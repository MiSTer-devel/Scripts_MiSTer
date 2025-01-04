#!/bin/sh

set -e

SAMPLE_DIR=/media/fat/ini/sample
NEW_FILE=$SAMPLE_DIR/MiSTer.ini
OLD_FILE=$SAMPLE_DIR/MiSTer.ini.old
DIFF_FILE=$SAMPLE_DIR/$(date +%Y%m%d_%H%M%S).diff

echo "Updating: ${NEW_FILE}"

mv "${NEW_FILE}" "${OLD_FILE}"
curl --silent -k https://raw.githubusercontent.com/MiSTer-devel/Main_MiSTer/master/MiSTer.ini | sed -e 's/\r//g' > "${NEW_FILE}"

if [ -f "${NEW_FILE}" ]; then
    diff -b -B -w -d -U 0 "${OLD_FILE}" "${NEW_FILE}" | unix2dos > "${DIFF_FILE}" || true
    if [ $(stat -c %s "${DIFF_FILE}") -eq 0 ]; then
        rm -f "${DIFF_FILE}"
    else
        echo "Diff saved to ${DIFF_FILE}."
    fi
else
    mv "${OLD_FILE}" "${NEW_FILE}"
fi

rm "${OLD_FILE}"
