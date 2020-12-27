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
    #print(zipfiles)
    crclist = []
    for zipfilename in zipfiles:
      try:
        mame_folder=find_mame_folder()
        zf = zipfile.ZipFile(mame_folder+'/'+zipfilename)
        for zi in zf.infolist():
          #print(zi.filename)
          #print('{:x}'.format(zi.CRC))
          #print('{0:0{1}x}'.format(zi.CRC,8))
          crclist.append('{0:0{1}x}'.format(zi.CRC,8))
      except:
          #print('file not found: '+zipfilename)
          if ('filename' in info):
            info['filename'].append(zipfilename)
          else:
            info['filename']=[]
            info['filename'].append(zipfilename)

    #print(crclist)
    for item in root.findall('rom/part'):
        #print(item.attrib)
        if ('crc' in item.attrib):
          noCRC = False
          crc=item.attrib['crc']
          if (crc.lower() in crclist):
            a=1
            #print('rom found')
          else:
            #print('**ROM NOT FOUND**  '+crc)
            if (crc in info):
              info['crc'].append(crc)
              info['name'].append(item.attrib['name'])
            else:
              info['crc']=[]
              info['name']=[]
              info['crc'].append(crc)
              info['name'].append(item.attrib['name'])
            working = False
    if not working:
      broken.append(info)
    if noCRC and len(zipfiles):
      print(mraFile+':NO CRC, Could not validate')
    if noMameVersion:
      print(mraFile+':No MameVersion ')

    return working

def iterateMRAFiles(directory):
    for filename in os.listdir(directory):
        if filename.endswith(".mra"):
            fullname=os.path.join(directory,filename)
            #print(fullname)
            try:
              working=parseMRA(fullname)
            except:
              print('Broken XML:'+fullname)
            #if not working:
            #    print('Not Working:'+fullname)
            
print("checking /media/fat/_Arcade/")
iterateMRAFiles('/media/fat/_Arcade/')

for info in broken:
    #print(info)
    missingzips=""
    wrongcrc=""
    if ('filename' in info):
      for fname in info['filename']:
        missingzips=missingzips+fname+","
    if ('name' in info):
      for name in info['name']:
        wrongcrc=wrongcrc+name+","
    errorstr = ""
    if (len(missingzips)):
        errorstr=errorstr+" missing zip: "+missingzips+" "
    if (len(wrongcrc)):
        errorstr=errorstr+" wrong crc for: "+wrongcrc+" "

    print(errorstr+" for: "+info['mraname'])

#working=parseMRA('Xevious.mra')
#working=parseMRA('Tapper.mra')
#print('Working:'+str(working))
#working=parseMRA('Asteroids.mra')
#print('Working:'+str(working))
#working=parseMRA('Alien Arena.mra')
#print('Working:'+str(working))
#working=parseMRA('Xevious.mra')
#print('Working:'+str(working))

