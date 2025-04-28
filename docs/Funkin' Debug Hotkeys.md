# Funkin' Debug Hotkeys

Most of this functionality is only available on debug builds of the game!

## Any State
- `INSERT`: ***MEMORY GARBAGE COLLECTION***: Immediately perform memory garbage collection.
- `F2`: ***OVERLAY***: Enables the Flixel debug overlay, which has partial support for scripting.
- `F3`: ***SCREENSHOT***: Takes a screenshot of the game and saves it to the local `screenshots` directory. Works outside of debug builds too!
- `F4`: ***EJECT***: Forcibly switch state to the Main Menu (with no extra transition). Useful if you're stuck in a level and you need to get out!
- `F5`: ***HOT RELOAD***: Forcibly reload the game's scripts and data files, then restart the current state. If any files in the `assets` folder have been modified, the game should process the changes for you! NOTE: Known bug, this does not reset song charts or song scripts, but it should reset everything else (such as stage layout data and character animation data).
- `CTRL-ALT-SHIFT-L`: ***FORCE CRASH***: Immediately crash the game with a detailed crash log and a stack trace. (Only works in the Main Menu on debug builds).

- `CTRL-SHIFT-L`: ***FORCE CRASH***: Immediately crash the game with a detailed crash log and a stack trace.

## **Play State**
- `H`: ***HIDE UI***: Makes the user interface invisible. Works in Pause Menu, great for screenshots.
- `1`: ***END SONG***: Immediately ends the song and moves to Results Screen on Freeplay, or next song on Story Mode.
- `2`: ***GAIN HEALTH***: Debug function, add 10% to the player's health.
- `3`: ***LOSE HEALTH***: Debug function, subtract 5% to the player's health.
- `9`: NEATO!
- `PAGEUP` (MacOS: `Fn-Up`): ***FORWARDS TIME TRAVEL***: Move forward by 2 sections. Hold SHIFT to move forward by 20 sections instead.
- `PAGEDOWN` (MacOS: `Fn-Down`): ***BACKWARDS TIME TRAVEL***: Move backward by 2 sections. Hold SHIFT to move backward by 20 sections instead.
- `CHART Hotkey`: ***OPEN CHART EDITOR***: Open the Chart Editor with the current song loaded.
- `STAGE Hotkey`: ***OPEN STAGE EDITOR***: Open the old Stage Editor overlay.

## **Freeplay State**
- `P`: ***SWITCH TO PICO/BF***: Switch to Pico or BF (reopens Freeplay as the other character).
- `T`: ***TEST RANK ANIMATION***: Play the Gold Perfect rank animation on the currently selected song.
- `SHIFT-ACCEPT`: ***BOTPLAY MODE***: Start a song with Botplay mode enabled.
- `CTRL-Switch Song`: Play the first unlocked alternate instrumental as the song preview.

## **Title State**
- `ESCAPE`: ***QUIT***: Quit the game.
- `D`: COOL
- `UI LEFT`/`UI RIGHT Hotkey`: 2COOL
- `Y`: WOAH

## **Main Menu**
- `~`: ***DEBUG***: Opens a menu to access the Chart Editor and other work-in-progress editors. Rebindable in the options menu.
- `SHIFT-ACCEPT`: ***OPEN FREEPLAY AS PICO***: When selecting Freeplay, open the Freeplay menu with the playable character set to Pico.
- `CTRL-ALT-SHIFT-W`: ***ALL ACCESS***: Unlocks all songs in Freeplay. Only available on debug builds.
- `CTRL-ALT-SHIFT-M`: ***NO MORE ACCESS***: Re-locks all songs in Freeplay except those unlocked by default. Only available on debug builds.
- `CTRL-ALT-SHIFT-R`: ***GREAT SCORE?***: Give the user a hypothetical overridden score, and see if we can maintain that golden P rank. Only available on debug builds.
- `CTRL-ALT-SHIFT-P`: ***CHARACTER UNLOCK SCREEN***: Forces the Character Select screen to play Pico's unlocking animation. Only available on debug builds.
- `CTRL-ALT-SHIFT-N`: ***CHARACTER NOT SEEN***: Marks all characters as not seen and enables BF's new character unlocked animation in Freeplay. Only available on debug builds.
- `CTRL-ALT-SHIFT-E`: ***DUMP SAVE DATA***: Prompts the user to save their save data as a JSON file, so its contents can be viewed. Only available on debug builds.
