# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.1] - 2024-06-12
### Added
- Pressing ESCAPE on the title screen on desktop now exits the game, allowing you to exit the game while in fullscreen on desktop
- Freeplay menu controls (favoriting and switching categories) are now rebindable from the Options menu, and now have default binds on controllers.
### Changed
- Highscores and ranks are now saved separately, which fixes the issue where people would overwrite their saves with higher scores,
which would remove their rank if they had a lower one.
- A-Bot speaker now reacts to the user's volume preference on desktop (thanks to [M7theguy for the issue report/suggestion](https://github.com/FunkinCrew/Funkin/issues/2744)!)
- On Freeplay, heart icons are shifted to the right when you favorite a song that has no rank on it.
- Only play `scrollMenu` sound effect when there's a real change on the freeplay menu ([thanks gamerbross for the PR!](https://github.com/FunkinCrew/Funkin/pull/2741))
- Gave antialiasing to the edge of the dad graphic on Freeplay
- Rearranged some controls in the controls menu
- Made several chart revisions
  - Re-enabled custom camera events in Roses (Erect/Nightmare)
  - Tweaked the chart for Lit Up (Hard)
  - Corrected the difficulty ratings for M.I.L.F. (Easy/Normal/Hard)
### Fixed
- Fixed an issue in the controls menu where some control binds would overlap their names
- Fixed crash when attempting to exit the gameover screen when also attempting to retry the song ([thanks DMMaster636 for the PR!](https://github.com/FunkinCrew/Funkin/pull/2709))
- Fix botplay sustain release bug ([thanks Hundrec!](Fix botplay sustain release bug #2683))
- Fix for the camera not pausing during a gameplay pause ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2684))
- Fixed issue where Pico's gameplay sprite would unintentionally appear on the gameover screen when dying on 2Hot from an explosion
- Freeplay previews properly fade volume during the BF idle animation
- Fixed bug where Dadbattle incorrectly appeared as Dadbattle Erect when returning to freeplay on Hard
- Fixed 2Hot not appearing under the "#" category in Freeplay menu
- Fixed a bug where the Chart Editor would crash when attempting to select an event with the Event toolbox open
- Improved offsets for Pico and Tankman opponents so they don't slide around as much.
- Fixed the black "temp" graphic on freeplay from being incorrectly sized / masked, now it's identical to the dad freeplay graphic

## [0.4.0] - 2024-06-06
### Added
- 2 new Erect remixes, Eggnog and Satin Panties. Check them out from the Freeplay menu!
- Major visual improvements to the Results screen, with additional animations and audio based on your performance.
- Major visual improvements to the Freeplay screen, with song difficulty ratings and player rank displays.
  - Freeplay now plays a preview of songs when you hover over them.
- Added a Charter field to the chart format, to allow for crediting the creator of a level's chart.
  - You can see who charted a song from the Pause menu.
- Added a new Scroll Speed chart event to change the note speed mid-song (thanks burgerballs!)
### Changed
- Tweaked the charts for several songs:
  - Tutorial (increased the note speed slightly)
  - Spookeez
  - Monster
  - Winter Horrorland
  - M.I.L.F.
  - Senpai (increased the note speed)
  - Roses
  - Thorns (increased the note speed slightly)
  - Ugh
  - Stress
  - Lit Up
- Favorite songs marked in Freeplay are now stored between sessions.
- The Freeplay easter eggs are now easier to see.
- In the event that the game cannot load your save data, it will now perform a backup before clearing it, so that we can try to repair it in the future.
- Custom note styles are now properly supported for songs; add new notestyles via JSON, then select it for use from the Chart Editor Metadata toolbox. (thanks Keoiki!)
- Health icons now support a Winning frame without requiring a spritesheet, simply include a third frame in the icon file. (thanks gamerbross!)
  - Remember that for more complex behaviors such as animations or transitions, you should use an XML file to define each frame.
- Improved the Event Toolbox in the Chart Editor; dropdowns are now bigger, include search field, and display elements in alphabetical order rather than a random order.
### Fixed
- Fixed an issue where Nene's visualizer would not play on Desktop builds
- Fixed a bug where the game would silently fail to load saves on HTML5
- Fixed some bugs with the props on the Story Menu not bopping properly
- Additional fixes to the Loading bar on HTML5 (thanks lemz1!)
- Fixed several bugs with the TitleState, including missing music when returning from the Main Menu (thanks gamerbross!)
- Fixed a camera bug in the Main Menu (thanks richTrash21!)
- Fixed a bug where changing difficulties in Story mode wouldn't update the score (thanks sectorA!)
- Fixed a crash in Freeplay caused by a level referencing an invalid song (thanks gamerbross!)
- Fixed a bug where pressing the volume keys would stop the Toy commercial (thanks gamerbross!)
- Fixed a bug where the Chart Editor Playtest would crash when losing (thanks gamerbross!)
- Fixed a bug where hold notes would display improperly in the Chart Editor when downscroll was enabled for gameplay (thanks gamerbross!)
- Fixed a bug where hold notes would be positioned wrong on downscroll (thanks MaybeMaru!)
- Removed a large number of unused imports to optimize builds (thanks Ethan-makes-music!)
- Improved debug logging for unscripted stages (thanks gamerbross!)
- Made improvements to compiling documentation (thanks gedehari!)
- Fixed a crash on Linux caused by an old version of hxCodec (thanks Noobz4Life!)
- Optimized animation handling for characters (thanks richTrash21!)
- Made improvements to compiling documentation (thanks gedehari!)
- Fixed a bug where pressing the volume keys would stop the Toy commercial (thanks gamerbross!)
- Fixed a bug where the Chart Editor Playtest would crash when losing (thanks gamerbross!)
- Removed a large number of unused imports to optimize builds (thanks Ethan-makes-music!)
- Fixed a bug where hold notes would be positioned wrong on downscroll (thanks MaybeMaru!)
- Additional fixes to the Loading bar on HTML5 (thanks lemz1!)
- Fixed a crash in Freeplay caused by a level referencing an invalid song (thanks gamerbross!)
- Improved debug logging for unscripted stages (thanks gamerbross!)
- Fixed a bug where changing difficulties in Story mode wouldn't update the score (thanks sectorA!)
- Fixed an issue where the Chart Editor would use an incorrect instrumental on imported Legacy songs (thanks gamerbross!)
- Fixed a camera bug in the Main Menu (thanks richTrash21!)
- Fixed several bugs with the TitleState, including missing music when returning from the Main Menu (thanks gamerbross!)
- Fixed a bug where opening the game from the command line would crash the preloader (thanks NotHyper474!)
- Fixed a bug where hold notes would display improperly in the Chart Editor when downscroll was enabled for gameplay (thanks gamerbross!)
- Fixed a bug where characters would sometimes use the wrong scale value (thanks PurSnake!)
- Additional bug fixes and optimizations.

## [0.3.3] - 2024-05-14
### Changed
- Cleaned up some code in `PlayAnimationSongEvent.hx` (thanks BurgerBalls!)
### Fixed
- Fixes to the Loading bar on HTML5 (thanks lemz1!)
- Don't allow any more inputs when exiting freeplay (thanks gamerbros!)
- Fixed using mouse wheel to scroll on freeplay (thanks JugieNoob!)
- Fixed the reset's of the health icons, score, and notes when re-entering gameplay from gameover (thanks ImCodist!)
- Fixed the chart editor character selector's hitbox width (thanks MadBear422!)
- Fixed camera stutter once a wipe transition to the Main Menu completes (thanks ImCodist!)
- Fixed an issue where hold note would be invisible for a single frame (thanks ImCodist!)
- Fix tween accumulation on title screen when pressing Y multiple times (thanks TheGaloXx!)
- Fix a crash when querying FlxG.state in the crash handler
- Fix for a game over easter egg so you don't accidentally exit it when viewing
- Fix an issue where the Freeplay menu never displays 100% clear
- Fix an issue where Weekend 1 Pico attempted to retrieve a missing asset.
- Fix an issue where duplicate keybinds would be stoed, potentially causing a crash
- Chart debug key now properly returns you to the previous chart editor session if you were playtesting a chart (thanks nebulazorua!)
- Fix a crash on Freeplay found on AMD graphics cards

## [0.3.2] - 2024-05-03
### Added
- Added `,` and `.` keybinds to the Chart Editor. These place Focus Camera events at the playhead, for the opponent and player respectively.
- Implemented a blacklist to prevent mods from calling system functions.
  - Added a couple utility functions to call useful stuff that got blacklisted.
- Added an `onSongLoad` script event which allows for mutation of notes and events.
- Added the current loaded modlist to crash logs.
- Added the `visible` attribute to Level JSON data.
- Enabled ZIP file system support for Polymod (make sure the metadata is in the root of the ZIP).
### Changed
- Songs in the mod folders will display in Freeplay without any extra scripting.
- Story levels in the mod folders will display in Story without any extra scripting.
- All audio should sound better in HTML5, less muddy
### Fixed
- Fixed a typo in the credits folder (`Custcene` -> `Cutscene`)
- Fixed an issue where health icon transition animations would loop and never finish properly.
- Fixed an issue where video cutscenes flagged as mid-song would crash the game when they finish.
- Fixed an issue where some substate lifecycle events were not being dispatched.
- Fixed a crash when trying to load into the Animation Offsets menu with an invalid character.
- Fixed an issue where the preloader would spam the logs when it was complete and waiting for user input.
- Should definitely have the fix for freeplay where it stops taking control of the main menu below it
- Changed the code for the story menu difficulties so that "normal" doesn't overlap the arrows after leaving Weekend 1
### Removed
- Removed some unused `.txt` files in the `assets/data` folder.

## [0.3.1] - 2024-05-01
### Changed
- Ensure the Git commit hash always displays in the log files.
- Added whether the local Git repo was modified to the log files.
- Removed "PROTOTYPE" text on release builds only (it still shows on debug builds).
- Added additional credits and special thanks.
- Updated peepo in creds to peepo173
### Fixed
- Fix a crash when retrieving system specs while handing a crash.
- Fix a crash triggered when pausing before the song started.
- Fix a crash triggered when dying before the song started.
- Fix a crash triggered when unloading certain graphics.
- Pico game over confirm plays correctly
- When exiting from a song into freeplay, main menu no longer takes inputs unintentionally (aka issues with merch links opening up when selecting songs)
- Fix for arrow keys causing web browser page scroll

## [0.3.0] - 2024-04-30
### Added
- New Story Level: Weekend 1, starting Pico, Darnell, and Nene.
  - Beat the level in Story Mode to unlock the songs for Freeplay!
- 12 new Erect remixes, featuring Kawai Sprite, Saruky, Kohta Takahashi, and Saster
  - Unlocked instantly in Freeplay
- New visually enhanced Freeplay menu.
  - Sorting, favorites, and more.
- New Results screen upon completing any song or story level.
- New refactored Chart Editor prototype (accessible via `~` in the main menu or `7` in the Play State, rebindable). (VERY EARLY PROTOTYPE. EXPECT BUGS AND CRASHES)
- Implemented a new scripting system using HScript (an interpreted language with Haxe-like syntax) for incredible flexibility.
  - All character-specific, stage-specific, or song-specific behaviors have been moved to HScript.
- New song events system allows for simple customization of camera behavior.
  - Mods can implement custom song events via HScript, and new built-in song events will come in the future.
- New credits menu to list all the dozens of people who contributed.
### Changed
- Completely refactored the game's input system for higher reliability and accuracy.
- Reworked note rendering to massively reduce lag on larger charts.
- Reworks to scoring and health gain.
- Dedicated gamepad support with the ability to rebind buttons.
- Improvements to video cutscenes and dialogue, allowing them to be easily skipped or restarted.
- Updated Polymod by several major versions, allowing for fully dynamic asset replacement and support for scripted classes.
- Completely refactored almost every part of the game's code for performance, stability, and extensibility.
  - This is not the Ludem Dare game held together with sticks and glue you played three years ago.
- Characters, stages, songs, story levels, and dialogue are now built from JSON data registries rather than being hardcoded.
  - All of these also support attaching scripts for custom behavior, more documentation on this soon.
  - You can forcibly reload the game's JSON data and scripts by pressing F5.
- Fully refactored the game's chart file format for extensibility and readability.
  - You can migrate old charts using the Import FNF Legacy option in the chart editor.
- Various visual tweaks and improvements.
### Fixed
- 17 quadrillion bugs across hundreds of PRs.

## [0.2.8] - 2021-04-18 (note, this one is iffy cuz we slacked wit it lol!)
### Added
- TANKMAN! 3 NEW SONGS BY KAWAISPRITE (UGH, GUNS, STRESS)! Charting help by MtH!
- Monster added into week 2, FINALLY (Charting help by MtH and ChaoticGamer!)
- Can now change song difficulty mid-game.
- Shows some song info on pause screen.
- Cute little icons onto freeplay menu
- Offset files for easier modification of characters
### Changed
- ASSET LOADING OVERHAUL, WAY FASTER LOAD TIMES ON WEB!!! (THANKS TO GEOKURELI WOKE KING)
- Made difficulty selector on freeplay menu more apparent
### Fixed
- That one random note on Bopeebo

## [0.2.7.1] - 2021-02-14
### Added
- Easter eggs
- readme's in desktop versions of the game
### Changed
- New icons, old one was placeholder since October woops!
- Made the transitions between the story mode levels more seamless.
- Offset of the Newgrounds logo on boot screen.
- Made the changelog txt so it can be opened easier by normal people who don't have a markdown reader (most normal people);
### Fixed
- Fixed crashes on Week 6 story mode dialogue if spam too fast ([Thanks to Lotusotho for the Pull Request!](https://github.com/ninjamuffin99/Funkin/pull/357))
- Should show intro credits on desktop versions of the game more consistently
- Layering on Week 4 songs with GF and the LIMO LOL HOW TF I MISS THIS
- Chart's and chart editor now support changeBPM, GOD BLESS MTH FOR THIS ONE I BEEN STRUGGLIN WIT THAT SINCE OCTOBER LMAO ([GOD BLESS MTH](https://github.com/ninjamuffin99/Funkin/pull/382))
- Fixed sustain note trails ALSO THANKS TO MTH U A REAL ONE ([MTH VERY POWERFUL](https://github.com/ninjamuffin99/Funkin/pull/415))
- Antialiasing on the skyscraper lights

## [0.2.7] - 2021-02-02
### Added
- PIXEL DAY UPDATE LOL 1 WEEK LATER
- 3 New songs by Kawaisprite!
- COOL CUTSCENES
- WEEK 6 YOYOYOYOY
- Swaggy pixel art by Moawling!
### Changed
- Made it so you lose sliiiightly more health when you miss a note.
- Removed the default HaxeFlixel pause screen when the game window loses focus, can get screenshots of the game easier hehehe
### Fixed
- Idle animation bug with BF christmas and BF hair blow sprites ([Thanks to Injourn for the Pull Request!](https://github.com/ninjamuffin99/Funkin/pull/237))

## [0.2.6] - 2021-01-20
### Added
- 3 NEW CHRISTMAS SONGS. 2 BY KAWAISPRITE, 1 BY BASSETFILMS!!!!! BF WITH DRIP! SANTA HANGIN OUT!
- Enemy icons change when they you are winning a lot ([Thanks to pahaze for the Pull Request!](https://github.com/ninjamuffin99/Funkin/pull/138))
- Holding CTRL in charting editor places notes on both sides
- Q and E changes sustain lengths in note editor
- Other charting editor workflow improvements
- More hair physics
- Heads appear at top of chart editor to help show which side ur charting for
### Changed
- Tweaked code relating to inputs, hopefully making notes that are close together more fair to hit
### Removed
- Removed APE
### Fixed
- Maybe fixed double notes / jump notes. Need to tweak it for balance, but should open things up for cooler charts in the future.
- Old Verison popup screen weirdness ([Thanks to gedehari for the Pull Request!](https://github.com/ninjamuffin99/Funkin/pull/155))
- Song no longer loops when finishing the song. ([Thanks Injourn for the Pull Request!](https://github.com/ninjamuffin99/Funkin/pull/132))
- Screen wipe being cut off in the limo/mom stage. Should fill the whole screen now.
- Boyfriend animations on hold notes, and pressing on repeating notes should behave differently

## [0.2.5] - 2020-12-27
### Added
- MOMMY GF, 3 NEW ASS SONGS BY KAWAISPRITE, NEW ART BY PHANTOMARCADE,WOOOOOOAH!!!!
- Different icons depending on which character you are against, art by EVILSK8R!!
- Autosave to chart editor
- Clear section button to note editor
- Swap button in note editor
- a new boot text or two
- automatic check for when you're on an old version of the game!
### Changed
- Made Spookeez on Normal easier.
- Mouse is now visible in note editor
### Fixed
- Crash when playing Week 3 and then playing a non-week 3 song
- When pausing music at the start, it doesn't continue the song anyways. ([shoutouts gedehari for the Pull Request!](https://github.com/ninjamuffin99/Funkin/pull/48))
- IDK i think backing out of song menu should play main menu songs again hehe ([shoutouts gedehari for the Pull Request!](https://github.com/ninjamuffin99/Funkin/pull/48))

## [0.2.4] - 2020-12-11
### Added
- 3 NEW SONGS BY KAWAISPRITE. Pico, Philly, and Blammed.
- NEW CHARACTER, PICO. Based off the classic Flash game "Pico's School" by Tom Fulp
- NEW LEVEL WOW! PHILLY BABEEEE
### Changed
- Made it less punishing to ATTEMPT to hit a note and miss, rather than let it pass you
### Fixed
- Song desync of you paused and unpaused frequently ([shoutouts SonicBlam](https://github.com/ninjamuffin99/Funkin/issues/37))
- Animation offsets when GF is scared

## [0.2.3] - 2020-12-04
### Added
- More intro texts
### Fixed
- Exploit where you could potentially give yourself a high score via the debug menu
- Issue/bug where you could spam the confirm button on the story menu ([shoutouts lotusotho for the CODE contribution/pull request!](https://github.com/ninjamuffin99/Funkin/pull/19))
- Glitch where if you never would lose health if you missed a note on a fast song (shoutouts [MrDulfin](https://github.com/ninjamuffin99/Funkin/issues/10), [HotSauceBurritos](https://github.com/ninjamuffin99/Funkin/issues/13) and [LobsterMango](https://lobstermango.newgrounds.com))
- Fixed tiny note bleed over thingies (shoutouts [lotusotho](https://github.com/ninjamuffin99/Funkin/pull/24))

## [0.2.2] - 2020-11-20
### Added
- Music playing on the freeplay menu.
- UI sounds on freeplay menu
- Score now shows mid-song.
- Menu on pause screen! Can resume, and restart song, or go back to main menu.
- New music made for pause menu!

### Changed
- Moved all the intro texts to its own txt file instead of being hardcoded, this allows for much easier customization. File is in the data folder, called "introText.txt", follow the format in there and you're probably good to go!
### Fixed
- Fixed soft lock when pausing on song finish ([shoutouts gedehari](https://github.com/ninjamuffin99/Funkin/issues/15))
- Think I fixed issue that led to in-game scores being off by 2 ([shoutouts Mike](https://github.com/ninjamuffin99/Funkin/issues/4))
- Should have fixed the 1 frame note appearance thing. ([shoutouts Mike](https://github.com/ninjamuffin99/Funkin/issues/6))
- Cleaned up some charting on South on hard mode
- Fixed some animation timings, should feel both better to play, and watch. (shoutouts Dave/Ivan lol)
- Animation issue where GF would freak out on the title screen if you returned to it([shoutouts MultiXIII](https://github.com/ninjamuffin99/Funkin/issues/12)).

## [0.2.1.2] - 2020-11-06
### Fixed
- Story mode scores not properly resetting, leading to VERY inflated highscores on the leaderboards. This also requires me to clear the scores that are on the leaderboard right now, sorry!
- Difficulty on storymode and in freeplay scores
- Hard mode difficulty on campaign levels have been fixed

## [0.2.1.1] - 2020-11-06
### Fixed
- Week 2 not unlocking properly

## [0.2.1] - 2020-11-06
### Added
- Scores to the freeplay menu
- A few new intro boot messages.
- Lightning effect in Spooky stages
- Campaign scores, can now compete on scoreboards for campaign!
- Can now change difficulties in Freeplay mode

### Changed
- Balanced out Normal mode for the harder songs(Dadbattle and Spookeez, not South yet). Should be much easier all around.
- Put tutorial in it's own 'week', so that if you want to play week 1, you don't have to play the tutorial.

### Fixed
- One of the charting bits on South and Spookeez during the intro.

## [0.2.0] - 2020-11-01
### Added
- Uhh Newgrounds release lolol I always lose track of shit.

## [0.1.0] - 2020-10-05
### Added
- Uh, everything. This the game's initial gamejam release. We put it out
