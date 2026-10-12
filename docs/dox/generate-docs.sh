#!/bin/bash
cd ../..

# ask for version
read -p "Enter version (Will display on the website): " version

# regenerate XML files?
read -p "Regenerate XML files? (y/n): " regenerateXml

if [ "$regenerateXml" == "y" ]; then
    echo "Regenerating XML files..."

    echo "Generating docs for version $version..."

    lime build windows -xml -cpp --no-output -Ddoc-gen
    lime build linux -xml -cpp --no-output -Ddoc-gen

    cp export/release/linux/types.xml docs/dox/Linux.xml
    cp export/release/windows/types.xml docs/dox/Windows.xml
else
    echo "Skipping XML regeneration..."
fi

# Then run dox
haxelib run dox \
  -i ./docs/dox/ \
  -o docs/dox/output \
  -theme "docs/dox/funkin-theme" \
  --title "Funkin'" \
  -D version "$version" \
  -D source-path "https://github.com/FunkinCrew/Funkin/tree/main/source" \
  -D website "https://funkin.me/" \
  -D description "Friday Night Funkin' API Reference" \
  -in "funkin" \
  -in "openfl" \
  -in "lime" \
  -in "flixel" \
  -ex "funkin.ui.debug.*" \
  -ex "funkin.macro.*" \
  -ex "funkin.save.*" \
  -ex "funkin.api.*" \
  -ex "funkin.vis.*"

cd docs/dox
