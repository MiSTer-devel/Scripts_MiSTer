#!/usr/bin/python

import os
import xml.etree.ElementTree as ET
import zipfile
import argparse
import sys

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--mra-folder", default="/media/fat/_Arcade/")
parser.add_argument("-f", "--file", default="")
parser.add_argument("-ir", "--ignore-roms", action='store_true')
parser.add_argument("-ic", "--ignore-crc", action='store_true')
parser.add_argument("-im", "--ignore-mameversion", action='store_true')
parser.add_argument("-r", "--recursive", action='store_true')
args = parser.parse_args()

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

def output_line_logonly(line):
    #print(line)
    logfile_v.write(line)
    logfile_v.write('\n')

def parseMRA(mraFile):
    working = True
    tree = ET.parse(mraFile)
    root = tree.getroot()
    zipfiles = []
    info = {}
    noCRC = True
    missingCRCs = 0
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
    if not args.ignore_roms:
      somezip = False
      for zipfilename in zipfiles:
        try:
          mame_folder=find_mame_folder()
          zf = zipfile.ZipFile(mame_folder+'/'+zipfilename)
          for zi in zf.infolist():
            #output_line(zi.filename)
            #output_line('{:x}'.format(zi.CRC))
            #output_line('{0:0{1}x}'.format(zi.CRC,8))
            crclist.append('{0:0{1}x}'.format(zi.CRC,8))

          somezip = True
        except:
            #output_line('file not found: '+zipfilename)
            if ('zipfilenames' in info):
              info['zipfilenames'].append(zipfilename)
            else:
              info['zipfilenames']=[]
              info['zipfilenames'].append(zipfilename)
      if not somezip and len(zipfiles) > 0:
        working = False

    #output_line(crclist)
    for item in root.findall('rom/part'):
        #output_line(item.attrib)
        if ('name' in item.attrib and 'crc' not in item.attrib):
          missingCRCs = missingCRCs + 1
          if ('partnames' not in info):
              info['partnames'] = []
          info['partnames'].append(item.attrib['name'])

        if ('crc' in item.attrib):
          noCRC = False
          crc=item.attrib['crc']
          if (crc.lower() in crclist) or args.ignore_roms:
            a=1
            #output_line('rom found')
          else:
            #output_line('**ROM NOT FOUND**  '+crc)
            if ('partcrcs' not in info):
              info['partcrcs'] = []
            if ('partnames' not in info):
              info['partnames'] = []
            info['partcrcs'].append(crc)
            info['partnames'].append(item.attrib['name'])
            working = False

    if (noCRC or missingCRCs > 0) and len(zipfiles) and not args.ignore_crc:
      info['badcrcs']= 'NO CRC found' if noCRC else '{} Missing CRCs'.format(missingCRCs)
      output_line_logonly(mraFile+info['badcrcs'])
      working = False

    if noMameVersion and not args.ignore_mameversion:
      info['badmameversion']=':No MameVersion'
      output_line_logonly(mraFile+info['badmameversion'])
      working = False

    if not working:
      broken.append(info)


    return working

def iterateMRAFiles(directory):
    total_mras = 0
    passing_mras = 0
    for filename in os.listdir(directory):
        fullname = os.path.join(directory, filename)
        if os.path.islink(fullname):
          continue
        elif os.path.isdir(fullname) and args.recursive:
          totals = iterateMRAFiles(fullname)
          total_mras = total_mras + totals[0]
          passing_mras = passing_mras + totals[1]
        elif filename.lower().endswith(".mra"):
            #output_line(fullname)
            try:
              working=parseMRA(fullname)
              if working:
                  passing_mras = passing_mras + 1
            except Exception as e:
              info = {}
              info['brokenxml'] = str(e)
              info['mraname'] = fullname
              broken.append(info)
              
            total_mras = total_mras + 1
            #if not working:
            #    output_line('Not Working:'+fullname)

    return [total_mras, passing_mras]
            
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
logfile_v = open("Logs/mra_rom_check_mamever.log", "w")

if args.file != "":
  output_line("checking " + args.file)
  #logfile.write("checking " + args.file)
  working=parseMRA(args.file)
  if working:
      output_line("OK")
  else:
      output_line("Error")
else:
  output_line("checking " + args.mra_folder)
  #logfile.write("checking " + args.mra_folder)
  totals = iterateMRAFiles(args.mra_folder)
  print ("Total MRAs processed: " + str(totals[0]))
  print ("MRAs passing: " + str(totals[1]))

for info in broken:
    #print(info)
    missingzips=""
    wrongcrc=""
    if ('zipfilenames' in info):
      for zipname in info['zipfilenames']:
        missingzips=missingzips+zipname+", "
    if ('partnames' in info):
      for name in info['partnames']:
        wrongcrc=wrongcrc+name+", "

    errorstr = ""
    if ('brokenxml') in info:
        errorstr=errorstr+" broken XML: "+info['brokenxml']+" "
    if ('badmameversion' in info):
        errorstr=errorstr+" wrong mameversion: "+info['badmameversion']+" "
    if ('badcrcs' in info):
        errorstr=errorstr+" bad CRCs: "+info['badcrcs']+" "
    if (len(missingzips)):
        errorstr=errorstr+" missing ZIP: "+missingzips[:-2]+" "
    if (len(wrongcrc)):
        errorstr=errorstr+" missing CRC for parts: "+wrongcrc[:-2]+" "

    output_line(errorstr+" for: "+info['mraname'])

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
logfile_v.close()

if len(broken) > 0:
    exit(1)
