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

## Loading State
- `SPACE`: Trace callbacks.

## **Play State**
- `H`: ***HIDE UI***: Makes the user interface invisible. Works in Pause Menu, great for screenshots.
- `1`: ***END SONG***: Immediately ends the song and moves to Results Screen on Freeplay, or next song on Story Mode.
- `2`: ***GAIN HEALTH***: Debug function, add 10% to the player's health.
- `3`: ***LOSE HEALTH***: Debug function, subtract 5% to the player's health.
- `9`: NEATO!
- `PAGEUP` (MacOS: `Fn-Up`): ***FORWARDS TIME TRAVEL***: Move forward by 2 sections. Hold SHIFT to move forward by 20 sections instead.
- `PAGEDOWN` (MacOS: `Fn-Down`): ***BACKWARDS TIME TRAVEL***: Move backward by 2 sections. Hold SHIFT to move backward by 20 sections instead.
- `CHART Hotkey`: ***OPEN CHART EDITOR ON SONG***: Redirect to the chart editor playing the current song.
- `STAGE Hotkey`: ***OPEN STAGE EDITOR ON STAGE***: Open the stage editor overlaying the current state.

## **Freeplay State**
- `CTRL-HOLD`: When a song preview is played it will instead play the preview for the first variation available for that song.
- `SHIFT-HOLD`: ***BOTPLAY***: Will enable botplay when a song is started.
- `P`: ***SWITCH TO PICO/BF***: Switch to Pico or BF (reopens Freeplay as the other character).
- `T`: ***TEST RANK***: Test rank the tutorial (/random if the character has no variation for it) with Perfect Gold.
- `CTRL+LEFT`/`RIGHT`/`UP`/`DOWN+SHIFT/ALT`: ***OFFSET BF DJ IN CARTOON STATE***: Offset the BF DJ in the cartoon state by 1 pixel in that direction. `SHIFT` to move 10 pixels, `ALT` to move 0.1 pixels.
- `CTRL+C`: ***SET/UNSET DJ CARTOON***: Set the Freeplay DJ's state to cartoon, or change it back to idle.

## **Title State**
- `ESCAPE`: ***QUIT***: Quit the game.
- `D`: COOL
- `UI LEFT`/`UI RIGHT Hotkey`: 2COOL
- `Y`: WOAH

## **Main Menu**
- `SHIFT-HOLD`: ***OPEN FREEPLAY WITH PICO***: Entering freeplay will set the target character to Pico.
- `~`: ***DEBUG***: Opens a menu to access the Chart Editor and other work-in-progress editors. Rebindable in the options menu.
- `CTRL-ALT-SHIFT-W`: ***ALL ACCESS***: Unlocks all songs in Freeplay. Only available on debug builds.
- `CTRL-ALT-SHIFT-M`: ***NO MORE ACCESS***: Re-locks all songs in Freeplay except those unlocked by default. Only available on debug builds.
- `CTRL-ALT-SHIFT-R`: ***GREAT SCORE?***: Give the user a hypothetical overridden score, and see if we can maintain that golden P rank. Only available on debug builds.
- `CTRL-ALT-SHIFT-P`: ***CHARACTER UNLOCK SCREEN***: Forces the Character Select screen to play Pico's unlocking animation. Only available on debug builds.
- `CTRL-ALT-SHIFT-N`: ***CHARACTER NOT SEEN***: Marks all characters as not seen and enables BF's new character unlocked animation in Freeplay. Only available on debug builds.
- `CTRL-ALT-SHIFT-E`: ***DUMP SAVE DATA***: Prompts the user to save their save data as a JSON file, so its contents can be viewed. Only available on debug builds.
