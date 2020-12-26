#!/bin/python
import os
import xml.etree.ElementTree as ET
import zipfile

mame_paths = [
		"/usb0/mame",
		"/usb1/mame",
		"/usb2/mame",
		"/usb3/mame",
		"/usb4/mame",
		"/usb5/mame",
		"/usb0/games/mame",
		"/usb1/games/mame",
		"/usb2/games/mame",
		"/usb3/games/mame",
		"/usb4/games/mame",
		"/usb5/games/mame",
		"/media/fat/cifs/mame",
		"/media/fat/cifs/games/mame",
		"/media/fat/games/mame",
		"/media/fat/mame",
		"/media/fat/_Arcade/mame"
	]

def find_mame_folder():
	for x in mame_paths:
		if os.path.isdir(x):
			return x 

	return nil

broken = []

def output_line(line):
    print(line)
    logfile.write(line)
    logfile.write('\n')

def parseMRA(mraFile):
    working = True
    tree = ET.parse(mraFile)
    root = tree.getroot()
    zipfiles = []
    info = {}
    noCRC = True
    noMameVersion= True
    info['mraname']=mraFile
    for item in root.findall('mameversion'):
	    noMameVersion = False
    for item in root.findall('rom'):
        if ('zip' in item.attrib):
           zip=item.attrib['zip']
           zipfiles = zipfiles+ zip.split('|')
        for child in item:
            if ('zip' in child.attrib):
              zip=child.attrib['zip']
              zipfiles = zipfiles+ zip.split('|')
    #output_line(zipfiles)
    crclist = []
    for zipfilename in zipfiles:
      try:
        mame_folder=find_mame_folder()
        zf = zipfile.ZipFile(mame_folder+'/'+zipfilename)
        for zi in zf.infolist():
          #output_line(zi.filename)
          #output_line('{:x}'.format(zi.CRC))
          #output_line('{0:0{1}x}'.format(zi.CRC,8))
          crclist.append('{0:0{1}x}'.format(zi.CRC,8))
      except:
          #output_line('file not found: '+zipfilename)
          if ('filename' in info):
            info['filename'].append(zipfilename)
          else:
            info['filename']=[]
            info['filename'].append(zipfilename)

    #output_line(crclist)
    for item in root.findall('rom/part'):
        #output_line(item.attrib)
        if ('crc' in item.attrib):
          noCRC = False
          crc=item.attrib['crc']
          if (crc.lower() in crclist):
            a=1
            #output_line('rom found')
          else:
            #output_line('**ROM NOT FOUND**  '+crc)
            if (crc in info):
              info['crc'].append(crc)
            else:
              info['crc']=[]
              info['crc'].append(crc)
            working = False
    if not working:
      broken.append(info)
    if noCRC and len(zipfiles):
      output_line(mraFile+':NO CRC, Could not validate')
    if noMameVersion:
      output_line(mraFile+':No MameVersion ')

    return working

def iterateMRAFiles(directory):
    for filename in os.listdir(directory):
        if filename.endswith(".mra"):
            fullname=os.path.join(directory,filename)
            #output_line(fullname)
            try:
              working=parseMRA(fullname)
            except:
              output_line('Broken XML:'+fullname)
            #if not working:
            #    output_line('Not Working:'+fullname)
            
#########################################
# Create Logs subdirectory for log output
#########################################
path = os.getcwd()
print ("The current working directory is %s" % path)
path = "Logs"

try:
    os.mkdir(path)
except OSError:
    print ("Directory %s already exists" % path)
else:
    print ("Successfully created the directory %s " % path)

#########################################
# Create Logs subdirectory for log output
#########################################

logfile = open("Logs/mra_rom_check.log", "w")

output_line("checking /media/fat/_Arcade/")
#logfile.write("checking /media/fat/_Arcade/")
iterateMRAFiles('/media/fat/_Arcade/')

for info in broken:
    missingzips=""
    if ('filename' in info):
      for fname in info['filename']:
        missingzips=missingzips+fname+","
    output_line("missing: "+missingzips+" for: "+info['mraname'])

#working=parseMRA('Xevious.mra')
#working=parseMRA('Tapper.mra')
#output_line('Working:'+str(working))
#working=parseMRA('Asteroids.mra')
#output_line('Working:'+str(working))
#working=parseMRA('Alien Arena.mra')
#output_line('Working:'+str(working))
#working=parseMRA('Xevious.mra')
#output_line('Working:'+str(working))

logfile.close()

