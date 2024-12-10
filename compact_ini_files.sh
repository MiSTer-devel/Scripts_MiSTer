#!/usr/bin/bash

INPUT_DIR=/media/fat/ini/source
OUTPUT_DIR=/media/fat/ini/compacted

if [ -d "$OUTPUT_DIR" ]; then rm "$OUTPUT_DIR"/*; else mkdir "$OUTPUT_DIR"; fi

while IFS='' read -r -d '' INI_FILE_NAME; do
    echo "Compacting: $INI_FILE_NAME"
    sed -e 's/\r$//g; s/[\t ]*;.*$//g' "$INPUT_DIR/$INI_FILE_NAME" | grep -vx -F '' | sed -e 's/$/\r/g' > "$OUTPUT_DIR/$INI_FILE_NAME"
done < <(cd $INPUT_DIR; find * -maxdepth 1 -type f -name "*.ini" -print0)
