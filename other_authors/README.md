# other_authors
Miscellaneous Bash scripts for MiSTer from other authors


###### fast_USB_polling_on/off by tofukazoo

Toggles 1000hz USB polling for joysticks and gamepads on or off by editing /linux/u-boot.txt:
   
   ON:  v=loglevel=4 usbhid.jspoll=1 xpad.cpoll=1
   OFF: v=loglevel=4 usbhid.jspoll=0 xpad.cpoll=0

Should not overwrite other u-boot.txt settings.

###### mra_rom_check.sh by alanswx

This will validate the standard MRAs and report which ones are missing mame zip files

###### wifi.sh by MiSTerAddons

Script adapted from RetroPie for use with MiSTer FPGA project by MiSterAddons

###### change_hostname.sh by MiSTerAddons

Script used to change network hostname so MiSTer devices can be addressed by network name. 
By default, they are all set to "MiSTer". Security scripts also updated to check for MiSTer
main binary instead of checking hostname. To use, edit change_hostname.ini by replacing 
"New_MiSTer_Hostname" with the desired hostname. For example:
   NEW_HOSTNAME="OOGABOOGA"

