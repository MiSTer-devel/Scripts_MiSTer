#!/bin/bash

set -e

LOG_FILE="$1"
if [ "$LOG_FILE" == "" ]; then
    LOG_FILE=/dev/null
fi

    SCRIPT=/media/fat/MiSTer
OLD_SCRIPT=/media/fat/.MiSTer
   BIN_DIR=/media/fat/main
   SYMLINK=/media/fat/main/MiSTer
STABLE_DIR=/media/fat/main/stable
            SYMLINK_TARGET=stable/MiSTer
    BINARY=/media/fat/main/stable/MiSTer
OLD_BINARY=/media/fat/main/stable/.MiSTer

if [ ! -d $BIN_DIR ]; then
    mkdir -p $BIN_DIR
fi

if [ ! -d $STABLE_DIR ]; then
    mkdir -p $STABLE_DIR
fi

if file -b --mime-type $OLD_SCRIPT | grep -qF "x-executable"; then
    mv -f $OLD_SCRIPT $OLD_BINARY
fi

if file -b --mime-type $SCRIPT | grep -qF "x-executable"; then
    mv -f $SCRIPT $BINARY
elif [ -f $SCRIPT ]; then
    mv -f $SCRIPT $OLD_SCRIPT
fi

if [ ! -L $SYMLINK ]; then
    ln -f -s $SYMLINK_TARGET $SYMLINK
fi

echo '#!/bin/bash'                             > $SCRIPT
echo "$SYMLINK >"$LOG_FILE" 2>&1 &" >> $SCRIPT
chmod +x $SCRIPT

