#!/bin/bash

trim_ini_field() {
	local FIELD="$1"
	FIELD="${FIELD#"${FIELD%%[!$' \t']*}"}"
	FIELD="${FIELD%"${FIELD##*[!$' \t']}"}"
	printf '%s' "$FIELD"
}

load_cifs_ini() {
	local INI_FILE="$1"
	local LINE KEY VALUE ALLOWED_KEY KEY_ALLOWED
	shift

	while IFS= read -r LINE || [ "$LINE" != "" ]
	do
		LINE=${LINE%$'\r'}
		case "$LINE" in
			*=*) ;;
			*) continue ;;
		esac
		KEY=$(trim_ini_field "${LINE%%=*}")
		case "$KEY" in
			''|\#*) continue ;;
		esac

		KEY_ALLOWED="false"
		for ALLOWED_KEY in "$@"
		do
			if [ "$KEY" == "$ALLOWED_KEY" ]
			then
				KEY_ALLOWED="true"
				break
			fi
		done
		[ "$KEY_ALLOWED" == "true" ] || continue

		VALUE=$(trim_ini_field "${LINE#*=}")
		case "$VALUE" in
			\"*) VALUE=${VALUE#\"}; VALUE=${VALUE%%\"*} ;;
			\'*) VALUE=${VALUE#\'}; VALUE=${VALUE%%\'*} ;;
		esac
		printf -v "$KEY" '%s' "$VALUE"
	done < "$INI_FILE"
}
