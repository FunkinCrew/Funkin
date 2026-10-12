#!/bin/bash

# Find all files in PNG format and execute oxipng to optimize file sizes
cd ../assets/ && oxipng -o 6 --strip safe --alpha {} **/*.png
