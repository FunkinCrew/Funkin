#!/bin/sh
lime build mac -64 -release
cd export/release
rm -rf macosUniversal
mkdir macosUniversal
cp -r macos/bin/Funkin.app macosUniversal
cd ../..
lime build mac -arm64 -release
cd export/release
cp -r macos/bin/Funkin.app/Contents/MacOS/Funkin macosUniversal/Funkin.app/Contents/MacOS/FunkinArm
cp -r macos/bin/Funkin.app/Contents/MacOS/lime.ndll macosUniversal/Funkin.app/Contents/MacOS/limeArm.ndll
cd macosUniversal/Funkin.app/Contents/MacOS
mv Funkin Funkin64
mv lime.ndll lime64.ndll
lipo -create -output lime.ndll lime64.ndll limeArm.ndll
lipo -create -output Funkin Funkin64 FunkinArm
rm FunkinArm Funkin64 lime64.ndll limeArm.ndll
