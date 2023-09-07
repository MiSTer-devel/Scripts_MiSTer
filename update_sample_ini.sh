#!/bin/sh

set -e

echo "Updating MiSTer_sample.ini..."
pushd /media/fat/ > /dev/null

curl -k -o ./MiSTer_sample.ini.NEW https://raw.githubusercontent.com/MiSTer-devel/Main_MiSTer/master/MiSTer.ini

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
CHANGES_FILE=./MiSTer_sample.ini.CHANGES_$TIMESTAMP

if [ -f ./MiSTer_sample.ini ]; then
    diff -b -B -w -d -U 0 ./MiSTer_sample.ini ./MiSTer_sample.ini.NEW >> $CHANGES_FILE
    if [ $(stat -c %s $CHANGES_FILE) -eq 0 ]; then
        rm -f $CHANGES_FILE
    fi
fi

mv -f ./MiSTer_sample.ini.NEW ./MiSTer_sample.ini

popd > /dev/null
echo "Done."
