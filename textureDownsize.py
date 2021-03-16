import argparse
import pathlib
import math
from PIL import Image
import xml.etree.ElementTree as ET

# run 'python -m pip install Pillow' to install PIL
# usage: python textureDownsize.py 'downsizing factor/divisor' 'path to xml file' 'path to image file'
# Note that both the width and height are downsized (downsize = 2 returns an image 1/4 of the original size)

parser = argparse.ArgumentParser()
parser.add_argument('downsize', help='Image downsizing factor.')
parser.add_argument('xml', help='The path of the XML file.')
parser.add_argument('img', help='The path of the image file.')
args = parser.parse_args()
downsize = int(args.downsize)

if (downsize % 2 != 0 or downsize == 0):
    raise ValueError("Downsizing factor should be a multiple of 2 for Integer Scaling.")

xmlPath = pathlib.Path() / args.xml
imgPath = pathlib.Path() / args.img
tree = ET.parse(xmlPath)
root = tree.getroot()

newImage = Image.open(imgPath)
width, height = newImage.size

# resample=0 for nearest neighbour, 1 for lanczos, 2 bilinear, 3 cubic, 4 box, 5 hamming
# default uses bilinear cause anything more for sprites is wasted space
newImage = newImage.resize((int(width/downsize), int(height/downsize)), resample=2)
newImage.save(imgPath)

def scale(value):
    return str(math.floor(int(value)/downsize))

for subtext in root.findall('SubTexture'):
    subtext.set('x', scale(subtext.get('x')))
    subtext.set('y', scale(subtext.get('y')))
    subtext.set('width', scale(subtext.get('width')))
    subtext.set('height', scale(subtext.get('height')))

    if (subtext.get('frameWidth') is not None):
        subtext.set('frameWidth', scale(subtext.get('frameWidth')))

    if (subtext.get('frameHeight') is not None):
        subtext.set('frameHeight', scale(subtext.get('frameHeight')))

tree.write(xmlPath, encoding='utf-8', xml_declaration=True) 


