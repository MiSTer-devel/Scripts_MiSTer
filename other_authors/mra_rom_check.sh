#!/usr/bin/python

import os
import xml.etree.ElementTree as ET
import zipfile
import argparse

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

    raise Exception("No MAME folder found in known paths: " + str(mame_paths))

broken = []

def output_line(line):
    print(output_line_logonly(line))

def output_line_logonly(line):
    if isinstance(line, list):
        line = [ET.tostring(item, encoding='unicode').strip() if isinstance(item, ET.Element) else item for item in line]
        line = str(line)

    if isinstance(line, ET.Element):
        line = ET.tostring(line, encoding='unicode')

    #print(line)
    logfile_v.write(line)
    logfile_v.write('\n')
    return line

def et_parse(mraFile):
    with open(mraFile, 'r') as f:
        text = f.read()
    return ET.fromstring(text.lower())

def make_info():
    return {'zipfilenames': [], 'partcrcs': [], 'partnames': [], 'mraname': '', 'badcrcs': '', 'badmameversion': '', 'brokenxml': ''}

def parseMRA(mraFile):
    working = True
    root = et_parse(mraFile)
    zipfiles = []
    info = make_info()
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
                info['zipfilenames'].append(zipfilename)
        if not somezip and len(zipfiles) > 0:
            working = False

    #output_line(crclist)
    parts = []
    for rom_el in root.findall('rom'):
        for rom_child in rom_el:
            if rom_child.tag == 'part':
                parts.append(rom_child)
            elif rom_child.tag == 'interleave':
                for interlieve_child in rom_child:
                    if interlieve_child.tag == 'part':
                        parts.append(interlieve_child)
    #output_line(parts)

    for part_el in parts:
        if 'name' in part_el.attrib and 'crc' not in part_el.attrib and 'ignore_crc' not in part_el.attrib:
            missingCRCs = missingCRCs + 1
            info['partnames'].append(part_el.attrib['name'])

        elif ('crc' in part_el.attrib):
            noCRC = False
            crc=part_el.attrib['crc']
            if (crc.lower() in crclist) or args.ignore_roms:
                pass
                #output_line('rom found')
            else:
                #output_line('**ROM NOT FOUND**  '+crc)
                info['partcrcs'].append(crc)
                info['partnames'].append(part_el.attrib['name'])
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
                info = make_info()
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
    if len(info['zipfilenames']):
        for zipname in info['zipfilenames']:
            missingzips=missingzips+zipname+", "
    if len(info['partnames']):
        for name in info['partnames']:
            wrongcrc=wrongcrc+name+", "

    errorstr = ""
    if len(info['brokenxml']):
        errorstr=errorstr+" broken XML: "+info['brokenxml']+" "
    if len(info['badmameversion']):
        errorstr=errorstr+" wrong mameversion: "+info['badmameversion']+" "
    if len(info['badcrcs']):
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


