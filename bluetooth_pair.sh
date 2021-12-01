#!/bin/sh

timeout=60
pipe=/tmp/btpair
trap "rm -f $pipe" EXIT
[ -p $pipe ] || mkfifo $pipe

echo "Switch input device(s) to pairing mode."
echo ""
echo "Searching for $timeout seconds..."

/usr/sbin/btctl pair 1<>$pipe &
SECONDS=0
paired=0
while [ $SECONDS -lt $timeout ]; do
    if read -t 1 line <$pipe; then
        echo $line
        if [[ $line == "Done." ]]; then
            paired=1
            break
        fi
    fi
done

killall btctl 2>/dev/null
if [ $paired -eq 0 ]; then
    echo "No input devices found."
fi

