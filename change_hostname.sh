#!/usr/bin/env bash

ORIGINAL_SCRIPT_PATH="$0"
INI_PATH=${ORIGINAL_SCRIPT_PATH%.*}.ini

if [ -f $INI_PATH ]
then
	eval "$(cat $INI_PATH | tr -d '\r')"
fi

OLD_HOSTNAME="$( hostname )"

#echo "Original Script Path: $ORIGINAL_SCRIPT_PATH"
#echo "INI Path: $INI_PATH"
echo "New hostname: $NEW_HOSTNAME"

if [ -z "$NEW_HOSTNAME" ]; then
 echo "Error: no hostname entered. Exiting."
 exit 1
fi

echo "Changing hostname from $OLD_HOSTNAME to $NEW_HOSTNAME..."

hostname "$NEW_HOSTNAME"

if [ -n "$( grep "$OLD_HOSTNAME" /etc/hosts )" ]; then
 sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
else
 echo -e "$( hostname -I | awk '{ print $1 }' )\t$NEW_HOSTNAME" >> /etc/hosts
fi

if [ -n "$( grep "$OLD_HOSTNAME" /etc/hostname )" ]; then
 sed -i "s/$OLD_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname
else
 echo -e "$( hostname -I | awk '{ print $1 }' )\t$NEW_HOSTNAME" >> /etc/hostname
fi

echo "Done"
echo "Rebooting"
sleep 5
reboot