#!/bin/bash

eval "$(cat Copy-Mame-Roms.ini | tr -d '\r')"

if [[ -z $HBMAME_PATH && -z $MAME_PATH || -z $MISTER_MAME_PATH || -z $MISTER_HBMAME_PATH ]];
then
    echo "Set the paths to your mame roms and MiSTer directories in Copy-Mame-Roms.ini"
    exit 1
else
    if [[ -n $MAME_PATH && -n $MISTER_MAME_PATH ]];
    then
        for file in `cat mame-filelist.txt`; do
            cp ${MAME_PATH}/${file} ${MISTER_MAME_PATH}
        done
    fi
    if [[ -n $HBMAME_PATH && -n $MISTER_HBMAME_PATH ]];
    then
        for file in `cat hbmame-filelist.txt`; do
            cp ${HBMAME_PATH}/${file} ${MISTER_HBMAME_PATH}
        done
    fi
fi
