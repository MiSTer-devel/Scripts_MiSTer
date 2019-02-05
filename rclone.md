# MiSTer rclone configuration guide
These instructions will guide you through the process of creating a *rclone.conf* configuration file needed by MiSTer *rclone_config_download.sh*, *rclone_config_upload.sh*, *rclone_saves_download.sh* and *rclone_saves_upload.sh*. These scripts let you upload and download saves or config directory to the cloud storages supported by rclone:
* Amazon Drive
* Amazon S3 Compliant Storage Providers (AWS, Ceph, Dreamhost, IBM COS, Minio)
* Backblaze B2
* Box
* Dropbox
* FTP Connection
* Google Cloud Storage (this is not Google Drive)
* Google Drive
* Hubic
* JottaCloud
* Mega
* Microsoft Azure Blob Storage
* Microsoft OneDrive
* OpenDrive
* Openstack Swift (Rackspace Cloud Files, Memset Memstore, OVH)
* Pcloud
* QingCloud Object Storage
* SSH/SFTP Connection
* Webdav
* Yandex Disk
* http Connection

## Download and extract rclone
1. Download the latest rclone zip archive for your computer desktop environment from https://rclone.org/downloads/
* [Windows - AMD64 - 64 Bit](https://downloads.rclone.org/rclone-current-windows-amd64.zip)
* [Windows - 386 - 32 Bit](https://downloads.rclone.org/rclone-current-windows-386.zip)
* [OSX - AMD64 - 64 Bit](https://downloads.rclone.org/rclone-current-osx-amd64.zip)
* [OSX - 386 - 32 Bit](https://downloads.rclone.org/rclone-current-osx-386.zip)
* [Linux - AMD64 - 64 Bit](https://downloads.rclone.org/rclone-current-linux-amd64.zip)
* [Linux - 386 - 32 Bit](https://downloads.rclone.org/rclone-current-linux-386.zip)
2. Extract the rclone binary (*rclone.exe* for Windows, *rclone* for OSX and Linux) from the zip archive wherever you want.

## Launch rclone and generate rclone.conf
1. Open a command prompt window (Windows) or a terminal window (OSX and Linux) and go in the directory where you extracted the rclone binary.
2.  * for Dropbox
      * on Windows launch *type nul > ".\rclone.conf" && .\rclone config create MiSTer dropbox --config=".\rclone.conf"*
      * on OSX/Linux launch *echo -n "" > "./rclone.conf" && ./rclone config create MiSTer dropbox --config="./rclone.conf"*
    * for Google Drive
      * on Windows launch *type nul > ".\rclone.conf" && .\rclone config create MiSTer drive --config=".\rclone.conf"*
      * on OSX/Linux launch *echo -n "" > "./rclone.conf" && ./rclone config create MiSTer drive --config="./rclone.conf"*
    * for Microsoft OneDrive
      * on Windows launch *type nul > ".\rclone.conf" && .\rclone config create MiSTer onedrive --config=".\rclone.conf"*
      * on OSX/Linux launch *echo -n "" > "./rclone.conf" && ./rclone config create MiSTer onedrive --config="./rclone.conf"*
    * for other cloud storages
      * on Windows launch *type nul > ".\rclone.conf" && .\rclone config --config=".\rclone.conf"*
      * on OSX/Linux launch *echo -n "" > "./rclone.conf" && ./rclone config --config="./rclone.conf"*

     In the first three cases a browser window will appear requiring to complete the authentication process. In the last one, please follow the detailed instructions listed here https://rclone.org/docs/; please always use *MiSTer* as remote name.

## Copy rclone.conf to MiSTer
1. At this point, if the authentication process was successful, you will have a *rclone.conf* file in your current directory (the one where you extracted the rclone binary).
2. Please copy *rclone.conf* to your MiSTer in the same directory where the rclone scripts are (usually */media/fat/#Scripts*) using the method you prefer, i.e.
     * FTP
     * SCP
     * Samba share
     * Copying directly the file with a SD adapter

## Enjoy the rclone scripts
1. Use *rclone_config_download.sh*, *rclone_config_upload.sh*, *rclone_saves_download.sh* and *rclone_saves_upload.sh* either through the OSD Script menu (hit F12 while running MiSTer main menu) or manually launching them in a SSH session.
