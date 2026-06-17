#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "$SCRIPT_DIR/cifs_common.sh"

assert_password() {
	local EXPECTED="$1"
	local VALUE="$2"
	local TMP_INI

	TMP_INI=$(mktemp)
	{
		printf 'SERVER="server"\n'
		printf 'SHARE="share"\n'
		printf 'USERNAME="user"\n'
		printf 'PASSWORD=%s\n' "$VALUE"
	} > "$TMP_INI"

	PASSWORD=""
	load_cifs_ini "$TMP_INI" SERVER SHARE USERNAME PASSWORD
	rm -f "$TMP_INI"

	if [ "$PASSWORD" != "$EXPECTED" ]
	then
		printf 'Expected password [%s], got [%s]\n' "$EXPECTED" "$PASSWORD" >&2
		exit 1
	fi
}

assert_password '$abc123' '"$abc123"'
assert_password '$abc123' '$abc123'
assert_password '$' '"$"'
assert_password '$' '$'
assert_password 'abc$123' '"abc$123"'
assert_password 'abc$123' 'abc$123'
assert_password 'pa ss' '"pa ss"'
assert_password 'pa#ss' '"pa#ss"'
assert_password 'pa&ss' '"pa&ss"'
assert_password 'p@$$word' '"p@$$word"'
assert_password 'p@$$word' 'p@$$word'
assert_password 'pa\ss' '"pa\ss"'
assert_password "pa'ss" "\"pa'ss\""
assert_password 'pa"ss' "'pa\"ss'"
assert_password '$abc123' '"$abc123" # inline comment'

TMP_INI=$(mktemp)
{
	printf 'PASSWORD\n'
	printf 'PASSWORD="$abc123"\n'
} > "$TMP_INI"
PASSWORD=""
load_cifs_ini "$TMP_INI" PASSWORD
rm -f "$TMP_INI"
[ "$PASSWORD" = '$abc123' ]

TMP_INI=$(mktemp)
{
	printf '# comment\r\n'
	printf '\r\n'
	printf ' PASSWORD = "$abc123" \r\n'
	printf 'UNKNOWN_KEY="ignored"\r\n'
	printf 'USERNAME = "user name"\r\n'
	printf 'DOMAIN = "work group"\r\n'
} > "$TMP_INI"
PASSWORD=""
USERNAME=""
DOMAIN=""
UNKNOWN_KEY="original"
load_cifs_ini "$TMP_INI" PASSWORD USERNAME DOMAIN
rm -f "$TMP_INI"
[ "$PASSWORD" = '$abc123' ]
[ "$USERNAME" = 'user name' ]
[ "$DOMAIN" = 'work group' ]
[ "$UNKNOWN_KEY" = 'original' ]

printf 'cifs_ini_parser_test: ok\n'
