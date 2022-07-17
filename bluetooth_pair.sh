#!/bin/sh

set -E -u -T

timeout_seconds=60
pipe=/tmp/btpair

function killprocs() {
    killall btpair 2>/dev/null
    killall btctl 2>/dev/null
}

function hideinput() {
    if [ -t 0 ]; then
        tput civis
        stty -echo -icanon time 0 min 0
    fi
}
trap hideinput CONT

function cleanup() {
    printf $"\b"
    trap - HUP INT TERM EXIT  # avoid re-entrancy
    if [ -t 0 ]; then
        stty sane
        tput cnorm
    fi
    [ ! -p "$pipe" ] || rm -f "$pipe"
    killprocs
    exit
}
trap cleanup HUP INT TERM EXIT

hideinput
killprocs

echo "Switch input device(s) to pairing mode."
echo ""
echo "Searching for $timeout_seconds seconds..."

function get_current_milliseconds() {
    local cur_ms="$(date +%s.%3N)"
    cur_ms=$(bc -l <<< "scale=0; $cur_ms * 1000 / 1")
    printf "$cur_ms"
}

start_ms="$(get_current_milliseconds)"
function get_elapsed_milliseconds() {
    local cur_ms="$(get_current_milliseconds)"
    printf "$(( $cur_ms - $start_ms ))"
}

paired=0
anim_frame=0

[ -p $pipe ] || mkfifo $pipe
exec 3<>$pipe
/usr/sbin/btctl pair 1<>$pipe &
elapsed_milliseconds=0
while [ $elapsed_milliseconds -lt $(( timeout_seconds * 1000 )) ]; do
    if read -t 0.1 -u 3 line; then
        echo -e "\\b$line"
        if [[ "$line" == "Done." ]]; then
            paired=1
            break
        fi
    else
        case $anim_frame in
          0) printf $"\b/";  anim_frame=1;;
          1) printf $"\b-";  anim_frame=2;;
          2) printf $"\b\\"; anim_frame=3;;
          3) printf $"\b|";  anim_frame=0;;
        esac
    fi
    elapsed_milliseconds=$(get_elapsed_milliseconds)
done

[ $anim_frame -lt 0 ] || printf $"\b"
if [ $paired -eq 0 ]; then
    echo -e "\bNo input devices found."
fi

