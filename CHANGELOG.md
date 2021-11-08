# Changelog
All notable changes will be documented in this file.

## [0.3.7] - ?/?/????
### Added
- Ability to change judgement timings.
### Fixed
- Freeplay crashing when loading a bunch of songs (with space bar) and then changing speed of song, and loading one.
- Fixed some errors idk
- Fixed mania mode and death notes doing funny miss stuff? (copy, sorry Leather)
### Changed
- Update Pico offsets

## [0.3.6] - 11/6/2021
### Fixed
- Freeplay crashing when changing speed after closing song in freeplay or beating song and going back to freeplay (aka there was no bg music).

## [0.3.5] - 11/6/2021
### Added
- Hitsounds in the charter
- Rythm Input Mode (basically have to hit notes in order).
### Fixed
- Crash when ghost tapping is off (and you miss) and a modchart is active.
- Custom Difficulty Inst / Vocals not loading correctly when loading charter (because difficulty wasn't set before the audio was loaded).
- `mania` value in charts still existing after chaning things (basically it overrides `keyCount` and would glitch stuff).
- Rate / Song Speed being too fast (ie, if you were at 2x the health icon and camera zoom was higher than 2x).
- Discord RPC Song Time being glitchy.
- Freeplay Music now speeds up / slows down when changing speed.
- Vocals from other song no longer seep into other Inst in Freeplay.

## [0.3.4] - 10/30/2021
### Added
- Version display for the thing in top left.
- Different fonts for display in top left.
- Option for bigger note splashes (like in Week 7 Update and Psych Engine).
- Freeplay Colors to Debug Songs.
- Text at the bottom of the mods menu, telling you how to enable and disable mods.
- Ghost tapping option in settings.
- Options Section to the pause menu.
- Option to change fullscreen and reset keybinds in the control menu substate.
- You can select the UI Skin in the game's charter.
### Fixed
- Crashes from loading charts with Psych Engine Events in them (basically notes with weird string values and stuff).
- Info Display (text in top left) appears before settings are loaded, making it show things the player might not want to see.
- Not being able to build 32 bit.
- Health Bar randomly having white pixels on it (because it was incorrect sized compared to health bar bg).
- SHIT Rating not breaking your combo.
- Freeplay Background Color change depending on the framerate.
- Game Over Camera Movement being frame dependent.
### Changed
- Debug Songs no longer have difficulties other than NORMAL (because originally they were just one difficulty).
- SHIT Rating now gives 0.1 damage (out of 2 max) instead of 0.07 damage (miss damage amount).
### Removed
- The folder named `ui` from shared/images/ (because it was unused)

## [0.3.3] - 10/25/2021
### Fixed
- Version system.

## [0.3.2] - 10/25/2021
### Added
- Proper Freeplay Colors for default songs.
- New Logo
- Dialogue for Senpai, Roses, and Thorns
### Fixed
- A lot of bugs pretaining to dialogue (aka not all features were coded in yet.)

## [0.3.1] - 10/23/2021
### Added
- Version System (aka if newer version out, game tell u :DDDDDDDD)!
- Custom Storymode Difficulties

## [0.3] - 10/23/2021
### Added
- Revamped options menu with checkboxes and other things.
- A rank while playing.
- Character Creator.
- Custom song support.
- Custom health icon support.
- Updated hit-window.
- Decimal BPM support.
- 1 - 10 Key Support (aka POG NEW KEY SYSTEM TYPE THING).
- Custom Stage System!
- BACKEND MODDING SUPPORT WITH POLYMOD FULLY IMPLEMENTED!
- Mod Loading System (Enabling and Disabling Mods).
- Custom Healthbar Colors
- Botplay
- Strict Accuracy Mode.
- Song Speed Changes
- Thorns Trail Setting for Characters (in a cool way).
- Text for keybinds of non-4 key arrow sets.
- Cutscene JSON System (videos, dialogue, etc).
- Video Files can now be played using cutscenes!
- 11 - 18 Key Support (yo this is crazy!)
- Custom Arrow Types! (Death Notes, Caution, etc).
- Health Icons can be chosen seperately from character names now (aka by default its the char name, but a custom name can be used to prevent duplicate images in the files).
- Dialogue Cutscenes now work!
- Optimization Options! (Antialiasing, Character + Backgrounds, etc).
### Changed
- Input has been updated and is a lot better now.
- Held notes no longer count to your accuracy.
- Debug Songs are now a built-in mod instead of a setting.
### Fixed
- Bug where music wouldn't play when opening the dialogue in Senpai and Thorns.
- Bug where Roses would crash at end of dialogue (because of the fix I made for the issue above this one).
- Default Stages having weird character positions.
- Bug where strum notes would have weird offsets when hitting notes.
- 83475349875389579843589743 other random bugs that occured while developing this update.
### Removed
- Week 7 has been removed because gamebanana and stuff.

## [0.2] - 7/7/2021
### Added
- A stage editor / stage viewer.
- Note splashes when you hit a sick!
- Millisecond timer when hitting notes.
- You can now access previously unaccessible Debug Songs with the Debug Songs option in the options menu.
- A new rating system.
- Prototype health icon when pressing 8 in-game.
- Better accuracy system (instead of just going by number of notes / number of hit notes, it's slightly different).
- Song name and difficulty to the bottom of the screen while playing.
- Difficulty selector in song charter.
- Week Progression can be toggled in options menu now.
- Improved dialogue system (will still be improved).
- New Input System! (finally dude).
- Anti-Mashing is now toggleable.
- WEEK 7 IS FULLY IMPLEMENTED BESIDES THE CUTSCENES (and also besides pico-speaker's cool animations to the music).
### Changed
- Organized classes into packages.
- Health icons can now have more general types (like bf and senpai), instead of having to write down the same icon mutliple times in code.
- Alphabet now has more stuff (like bold numbers), which I took from the Agoti mod (yes ik I didn't make it myself, but I don't have adobe animate so ¯＼_(ツ)_/¯)
- Optimized the title screen by not loading unneccesary libraries on launch.
- The song charter has been revamped and now is more organized and easier to understand (generally).
### Fixed
- Song names like Philly and Dadbattle have been replaced to their actual song names (Philly Nice and Dad Battle).
- The layering of GF on the limo stage has now been fixed! (:pog:)
- In the Thorns dialogue, Senpai's dialogue portrait is now invisible, instead of behind or infront of Spirit.
### Re-Added
- When pressing 9 in-game it now will revert your health icon to bf-old (because idk why I removed it).
### Known Issues
- When hitting notes REALLY close together on the new input system, the game may sometimes allow you to hit multiple notes at once.
- Pressing "Beat Hit" in the stage editor on "Spooky" stage, may cause the game to crash.

## [0.1] - 6/18/2021
### Added
- An Options Menu.
- Custom controls option.
- Opponent side arrows glowing when hitting notes (as an option).
- Downscroll Option.
- A misses counter and an accuracy percentage to in-game score text.
- In-game score text has a small black border.
- Custom Health Icon for gf-pixel.
- Press 1, 2, or 3 to open animation debug for respective characters while in-game.
- Option to change the girlfriend for any song in the charter.
- Option to change the stage for any song in the charter.
- Better stage system for making stages.
### Changed
- You now don't miss when pressing keys with no notes.
- You can now change the character in the Animation Debugger.
- Animation Debug is accessible in non debug builds.
- Pressing the 9 key in-game does nothing now.
- You now progress through weeks instead of unlocking everything.
- Stages are in their own library / folder now.
- All characters are also in their own folder in the shared library / folder.
- When you select a song in freeplay it plays that song's instrumental again and with no lag! (This was disabled in a prior update due to some issues with the new libraries).
### Fixed
- GF's animations have been fixed (she would go up like 20 pixels when the player broke a combo before).
- Freeplay songs are now unlocked just like weeks.
### Known Issues
- I do know that GF's layering on the limo stage is broken, but I have not found a solution to fixing this yet without just seperating the limo from it's stage.

## [0.0] - 6/18/2021
### Added
- Nothing this is just 0.2.7.1 of FnF
