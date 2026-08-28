#!/usr/bin/python

import os
import xml.etree.ElementTree as ET
import zipfile
import argparse
import gzip
import json
import re
from collections import defaultdict
from difflib import SequenceMatcher

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--mra-folder", default="/media/fat/_Arcade/")
parser.add_argument("-f", "--file", default="")
parser.add_argument("-ir", "--ignore-roms", action='store_true')
parser.add_argument("-ic", "--ignore-crc", action='store_true')
parser.add_argument("-im", "--ignore-mameversion", action='store_true')
parser.add_argument("-r", "--recursive", action='store_true')
parser.add_argument("--layout-check", action='store_true', help="check top-level/alternative placement using a MAME parent map")
parser.add_argument("--layout-only", action='store_true', help="run only XML and MRA placement checks")
parser.add_argument("--parent-map", default="", help="mame-parent-map.json or .json.gz from mister-mra-auditor")
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
    with open(mraFile, 'rb') as f:
        text = f.read()
    # XML is case-sensitive. Lowercasing the whole document hid malformed
    # pairs such as <rom>...</ROM>.
    return ET.fromstring(text)

def tag_name(element):
    return element.tag.rsplit('}', 1)[-1].lower()

def children_named(element, name):
    return [child for child in element if tag_name(child) == name.lower()]

def child_text(element, name):
    children = children_named(element, name)
    return (children[0].text or '').strip() if children else ''

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
    for item in children_named(root, 'mameversion'):
        noMameVersion = False
    for item in children_named(root, 'rom'):
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
    for rom_el in children_named(root, 'rom'):
        for rom_child in rom_el:
            if tag_name(rom_child) == 'part':
                parts.append(rom_child)
            elif tag_name(rom_child) == 'interleave':
                for interlieve_child in rom_child:
                    if tag_name(interlieve_child) == 'part':
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

def load_parent_map(path):
    if not path:
        raise ValueError('--parent-map is required with --layout-check or --layout-only')
    opener = gzip.open if path.lower().endswith('.gz') else open
    with opener(path, 'rt', encoding='utf-8') as handle:
        data = json.load(handle)
    return data.get('descriptions', {}), data.get('parents', {})

def mra_metadata(path, location):
    root = et_parse(path)
    return {
        'path': path,
        'location': location,
        'name': child_text(root, 'name') or os.path.splitext(os.path.basename(path))[0],
        'setname': child_text(root, 'setname'),
        'rbf': child_text(root, 'rbf'),
        'bootleg': child_text(root, 'bootleg').lower(),
    }

def family_of(setname, parents):
    current = setname
    seen = set()
    while current in parents and current not in seen:
        seen.add(current)
        current = parents[current]
    return current

def is_bootleg(metadata, descriptions):
    text = '{} {} {}'.format(metadata['name'], descriptions.get(metadata['setname'], ''), metadata['bootleg']).lower()
    return metadata['bootleg'] == 'yes' or 'bootleg' in text or '[bl]' in text

def normalized_title(value):
    value = re.sub(r'\([^)]*\)|\[[^]]*\]', ' ', value.lower()).replace('&', 'and')
    return re.sub(r'[^a-z0-9]+', '', value)

def titles_match(left, right):
    left = normalized_title(left)
    right = normalized_title(right)
    if not left or not right:
        return False
    return left == right or left.startswith(right) or right.startswith(left) or SequenceMatcher(None, left, right).ratio() >= 0.84

def check_mra_layout(directory, parent_map):
    descriptions, parents = load_parent_map(parent_map)
    roots = []
    alternatives = []
    violations = []

    for filename in sorted(os.listdir(directory)):
        path = os.path.join(directory, filename)
        if os.path.isfile(path) and filename.lower().endswith('.mra'):
            try:
                roots.append(mra_metadata(path, 'root'))
            except Exception as error:
                violations.append('well_formed_xml | {} | {}'.format(path, error))

    alternatives_root = os.path.join(directory, '_alternatives')
    if os.path.isdir(alternatives_root):
        for current, _, filenames in os.walk(alternatives_root):
            for filename in sorted(filenames):
                if not filename.lower().endswith('.mra'):
                    continue
                path = os.path.join(current, filename)
                try:
                    alternatives.append(mra_metadata(path, 'alternative'))
                except Exception as error:
                    violations.append('well_formed_xml | {} | {}'.format(path, error))

    by_family = defaultdict(list)
    for item in roots:
        item['family'] = family_of(item['setname'], parents) if item['setname'] else ''
        if item['family']:
            by_family[item['family']].append(item)
    for item in alternatives:
        item['family'] = family_of(item['setname'], parents) if item['setname'] else ''

    separate_game_families = {'qix', 'sprint1'}
    for family, items in sorted(by_family.items()):
        if len(items) > 1 and family not in separate_game_families:
            evidence = ', '.join('{} ({})'.format(os.path.basename(x['path']), x['setname']) for x in items)
            violations.append('one_top_level_mra_per_game | parent={} | {}'.format(family, evidence))

        bootlegs = [x for x in items if x['setname'] != family and is_bootleg(x, descriptions)]
        parent_available = [x for x in roots + alternatives if x.get('setname') == family]
        if bootlegs and parent_available:
            evidence = ', '.join('{} ({})'.format(os.path.basename(x['path']), x['setname']) for x in parent_available + bootlegs)
            violations.append('parent_over_bootleg | parent={} | {}'.format(family, evidence))

    root_titles = []
    for item in roots:
        root_titles.extend([item['name'], os.path.splitext(os.path.basename(item['path']))[0]])
    if os.path.isdir(alternatives_root):
        for bucket in sorted(os.listdir(alternatives_root)):
            bucket_path = os.path.join(alternatives_root, bucket)
            if not os.path.isdir(bucket_path):
                continue
            game = bucket.lstrip('_')
            if not any(titles_match(game, title) for title in root_titles):
                violations.append('game_must_have_top_level_mra | alternative bucket={} has no matching top-level MRA'.format(bucket))

    return violations
            
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

layout_violations = []
if args.layout_only:
    args.layout_check = True

if args.layout_only:
    output_line("checking MRA XML and layout " + args.mra_folder)
elif args.file != "":
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

if args.layout_check:
    try:
        layout_violations = check_mra_layout(args.mra_folder, args.parent_map)
    except Exception as error:
        layout_violations = ['layout_check_failed | {}'.format(error)]

    for violation in layout_violations:
        output_line('MRA LAYOUT: ' + violation)

    print("MRA layout violations: " + str(len(layout_violations)))

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

if len(broken) > 0 or len(layout_violations) > 0:
    exit(1)


