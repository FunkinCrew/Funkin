#!/bin/bash

# Resize each health icon to 512x512
find "./discord/" -name "icon-*.png" -exec sh -c 'ffmpeg -i {} -vf scale=512:512 "${0%.*}2.png"' {} \;
