#!/bin/sh

set -e

SCRIPT="$1"
DESCRIPTION="$2"

if [ -z "$SCRIPT" ] || [ -z "$DESCRIPTION" ]; then
	echo -e "  usage: $0 <script_to_add> <description>" >&2
    echo -e "example: $0 /my/cool/script.sh \"My cool script\"" >&2
    exit 1
fi

HEADER_COMMENT="# $DESCRIPTION"
USER_STARTUP=/media/fat/linux/user-startup.sh

if grep -q -F "esac" "$USER_STARTUP"; then
	mv -f "$USER_STARTUP" "$USER_STARTUP.bak" > /dev/null 2>&1
fi

if ! [ -f "$USER_STARTUP" ]; then
	touch $USER_STARTUP
	echo -E '#!/bin/sh'           >> $USER_STARTUP
	echo -E ''                    >> $USER_STARTUP
	echo -E 'echo "***" $1 "***"' >> $USER_STARTUP
fi

if ! grep -q -F "$HEADER_COMMENT" "$USER_STARTUP"; then
	echo "Adding to $USER_STARTUP"
	echo -E ''                                       >> $USER_STARTUP
	echo -E "$HEADER_COMMENT"                        >> $USER_STARTUP
	echo -e "[ -x \"$SCRIPT\" ] && \"$SCRIPT\" "'$1' >> $USER_STARTUP
fi
