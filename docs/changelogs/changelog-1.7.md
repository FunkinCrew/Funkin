# Latest (master) changelog/Changelog

Changes marked with 💖 will be listed in the short version of the changelog in `version.downloadMe`.

### Additions
- 💖 A speed modifier (To use, press shift-left/right in freeplay or the charter. Does not work on modcharts.)

### Changes
- Relocated all of the stage code into it's own file
- 💖 Completely redid all of modcharting (docs can be found [here](https://github.com/KadeDev/Kade-Engine/wiki))
- Removed replay functionality due to it being a peice of shit and never working and causing issues and problems all the time.
- 💖 Optimized a lot of code to run better
- 💖 Allowed numpad to be binded as a key
- Optimized rating code to be faster
- Removed debug code from release builds for faster execution
- Binding a key to an already binded key no longer sets the other as null
- When beat quant colors are enabled, your key presses are highlighted in the color you hit instead of the original color.
- Removed beat base idle animations for characters
- Changed beat quant colors to. 4th = red, 8th = blue, green = 12th, purple = 16th+
- 💖 Changed the editor to work entirely on beats
- Changed the BPM change code to work on beats instead of timestamps
- Removed a lot of unnecessary code.
- Changed **scroll speed** change events to be **based on multipliers instead of constant values** (aka 2 scroll speed would be scrollSpeed * 2 instead of setting it to 2)

### Bugfixes
- 💖 Fix multiplie crashes with story mode and other weeks in story mode
- 💖 Fix desyncs with bpm changes and section notes in the charter
- Fix snap working in the charter (it's way more accurate now)
- Fixed crashing on a song that has a modchart at the end.
