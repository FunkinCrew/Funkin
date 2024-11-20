#!/bin/bash

# Find all files in OGG format and execute ffmpeg to convert them to MP3
# Skips files that are already in MP3 format
find "../assets/" -name "*.ogg" -exec sh -c 'ffmpeg -n -i {} "${0%.*}.mp3"' {} \;
