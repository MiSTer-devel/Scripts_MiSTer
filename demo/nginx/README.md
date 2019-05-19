# NGINX + CGI + MiSTer Web Control demo
This is a proof of concept demonstrating the use of NGINX Web server with CGI support on the MiSTer FPGA system through a simple MiSTer Web Control demo page.<br>
Simply put [nginx_start.sh](https://github.com/MiSTer-devel/Scripts_MiSTer/blob/master/demo/nginx/nginx_start.sh?raw=true) in your SD and launch it through MiSTer main menu OSD (press F12 and then Scripts). Please right click on the links in this README or on the RAW button in GitHub script pages in order to actually download the raw Bash script, otherwise you could download an HTML page which isn’t a script and won’t be executed by MiSTer (you will see no output, but just an OK button in MiSTer Script menu interface).<br>
This demo uses the following open source projects (visit their Web sites for the source code and the license files)
- NGINX Open Source https://nginx.org
- fcgiwrap https://github.com/gnosek/fcgiwrap
- Screenshot_MiSTer by alanswx https://github.com/alanswx/Screenshot_MiSTer
- my personal fork vodik's uinput-injector of https://github.com/Locutus73/uinput-injector
I take no responsibility for any data loss or anything, if your DE10-Nano catches fire it’s up to you: **use the script at your own risk**.
