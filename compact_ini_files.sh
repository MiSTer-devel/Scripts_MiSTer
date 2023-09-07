#!/usr/bin/bash

while IS='' read -r -d '' _path; do
    _dir="${_path%/*}"
    _name="${_path##*/}"
    _stem="${_name%.*}"
    _ext="${_name##*.}"
    _compacted_name="$_dir/$_stem.compacted.$_ext"
    echo "Compacting: $_name >> $_compacted_name"
    sed -e 's/\r$//g; s/[\t ]*;.*$//g' $_path | grep -vx -F '' | sed -e 's/$/\r/g' > "$_compacted_name"
done < <(find /media/fat/Ini_Files/ -maxdepth 1 -type f -name "*.ini" -not -name "*.compacted.*" -not -name "*.sample.*" -print0)

