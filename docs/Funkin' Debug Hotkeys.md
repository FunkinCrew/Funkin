# Funkin' Debug Hotkeys

Most of this functionality is only available on debug builds of the game!

## Any State
- `F2`: ***OVERLAY***: Enables the Flixel debug overlay, which has partial support for scripting.
- `F3`: ***SCREENSHOT***: Takes a screenshot of the game and saves it to the local `screenshots` directory. Works outside of debug builds too!
- `F4`: ***EJECT***: Forcibly switch state to the Main Menu (with no extra transition). Useful if you're stuck in a level and you need to get out!
- `F5`: ***HOT RELOAD***: Forcibly reload the game's scripts and data files, then restart the current state. If any files in the `assets` folder have been modified, the game should process the changes for you! NOTE: Known bug, this does not reset song charts or song scripts, but it should reset everything else (such as stage layout data and character animation data).
- `CTRL-SHIFT-L`: ***FORCE CRASH***: Immediately crash the game with a detailed crash log and a stack trace.

## **Play State**
- `H`: ***HIDE UI***: Makes the user interface invisible. Works in Pause Menu, great for screenshots.
- `1`: ***END SONG***: Immediately ends the song and moves to Results Screen on Freeplay, or next song on Story Mode.
- `2`: ***GAIN HEALTH***: Debug function, add 10% to the player's health.
- `3`: ***LOSE HEALTH***: Debug function, subtract 5% to the player's health.
- `9`: NEATO!
- `PAGEUP` (MacOS: `Fn-Up`): ***FORWARDS TIME TRAVEL***: Move forward by 2 sections. Hold SHIFT to move forward by 20 sections instead.
- `PAGEDOWN` (MacOS: `Fn-Down`): ***BACKWARDS TIME TRAVEL***: Move backward by 2 sections. Hold SHIFT to move backward by 20 sections instead.

## **Freeplay State**
- `F` (Freeplay Menu) - Move to Favorites
- `Q` (Freeplay Menu) - Back one category
- `E` (Freeplay Menu) - Forward one category

## **Title State**
- `Y` - WOAH

## **Main Menu**
- `~`: ***DEBUG***: Opens a menu to access the Chart Editor and other work-in-progress editors. Rebindable in the options menu.
- `CTRL-ALT-SHIFT-W`: ***ALL ACCESS***: Unlocks all songs in Freeplay. Only available on debug builds.
