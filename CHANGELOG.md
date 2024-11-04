# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.3] - 2024-10-18
This patch resolves a critical issue which could cause user's save data to become corrupted. It is recommended that users switch to this version immediately and avoid using version 0.5.2.
### Fixed
- Fixed a critical issue in which the Stage Editor theme value could not be parsed by older versions of the game, resulting in all save data being destroyed.
  - Added a check that prevents save data from being loaded if it is corrupted rather than overriding it.
- `optionsChartEditor.chartEditorLiveInputStyle` in the save data converted from an Enum to a String to fix save data compatibility issues.
- `optionsStageEditor.theme` in the save data converted from an Enum to a String to fix save data compatibility issues.
  - In the future, Enum values should not be used in order to prevent incompatibilities caused by introducing new types to the save data that older versions cannot parse.
- Fixed an issue where some publicly distributed release builds of the game were not updated to the latest version.


## [0.5.2] - 2024-10-11
### Added
- Added InverseDotsShader that emulates flash selections ([097dbf5](https://github.com/FunkinCrew/Funkin/commit/097dbf5bb4346d431d8ca9f0ec4bc5b5e6f4523f)) - by @ninjamuffin99
- Added a new reworked Stage Editor ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @JustKolosaki in [#3482](https://github.com/FunkinCrew/Funkin/pull/3482)
- Added the `color` attribute to stage prop JSON data to allow them to be tinted without code. ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @JustKolosaki 
- Added the `angle` attribute to stage prop JSON data to allow them to be rotated without code. ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @JustKolosaki 
- Added the `blend` attribute to the stage prop JSON data to allow blend modes to be applied without code. ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @JustKolosaki
### Changed
- (docs) Delete Modding.md since we have a separate modding documentation ([a42240e](https://github.com/FunkinCrew/Funkin/commit/a42240e6a595d33034f2c887bf38a350d1fa0f15)) - by @AbnormalPoof in [#3651](https://github.com/FunkinCrew/Funkin/pull/3651)
- (docs) Create a git cliff template for easier changelog stuff ([91b4544](https://github.com/FunkinCrew/Funkin/commit/91b4544f7ebc51485e3e28c3d716ba6ee69ad885)) - by @ninjamuffin99 in [#3652](https://github.com/FunkinCrew/Funkin/pull/3652)
- (docs) Add additional `variation` input parameter to `Save.hasBeatenSong()` to allow usage of the function by inputting a variation id ([4fa9a0d](https://github.com/FunkinCrew/Funkin/commit/4fa9a0daaa67e0977460b147bd1f74a118e3e2a5)) - by @ninjamuffin99
- (docs) Added modding docs link in readme ([4b54118](https://github.com/FunkinCrew/Funkin/commit/4b54118731e26118111e06558ae4853c577fe4bb)) - by @Cartridge-Man in [#3082](https://github.com/FunkinCrew/Funkin/pull/3082)
- (docs) Fix some misspellings and grammar in code documentation ([2175bea](https://github.com/FunkinCrew/Funkin/commit/2175beaa651e009332202985be4b7eb4ed36e5a4)) - by @Hundrec in [#3477](https://github.com/FunkinCrew/Funkin/pull/3477)
- (docs) Improvements to Github Issues templates ([399869c](https://github.com/FunkinCrew/Funkin/commit/399869cdccc9c5ac27cecfbcdc33c3d7eb4b348c)) - by @Hundrec in [#3458](https://github.com/FunkinCrew/Funkin/pull/3458)
### Fixed
- Fix the user song offsets being applied incorrectly, causing stuttering or skipping ([410cfe9](https://github.com/FunkinCrew/Funkin/commit/410cfe972d6df9de4d4d128375cf8380c4f06d92)) - by @JustKolosaki in [#3546](https://github.com/FunkinCrew/Funkin/pull/3546) in [#3506](https://github.com/FunkinCrew/Funkin/pull/3506)
- Fixed issues with variation / difficulty loading for Freeplay Menu which caused some songs to disappear ([c0314c8](https://github.com/FunkinCrew/Funkin/commit/c0314c85ecd5116641aff3de8e9153f7fe48e79c)) - by @ninjamuffin99
- Pico's songs now display properly on the Freeplay Menu ([1d2bd61](https://github.com/FunkinCrew/Funkin/commit/1d2bd61119e5f418df7f11d7ef2a0fdedee17d3d)) - by @ninjamuffin99 in [#3506](https://github.com/FunkinCrew/Funkin/pull/3506)
- Exiting the chart editor doesn't crash the game anymore ([f52472a](https://github.com/FunkinCrew/Funkin/commit/f52472a4767388b22cfbab0f5f7860f6e6762856)) - by @EliteMasterEric and @ianharrigan in [#3519](https://github.com/FunkinCrew/Funkin/pull/3519)
- Disable flickering when attempting to select FPS in the options menu ([b2647fe](https://github.com/FunkinCrew/Funkin/commit/b2647fe09f5281ce7074b26d47bc1524764168ee)) - by @lemz1 in [#3629](https://github.com/FunkinCrew/Funkin/pull/3629)
- Anti-alias / smooth the volume sound tray ([e66290c](https://github.com/FunkinCrew/Funkin/commit/e66290c55f7141402223644f06ec8a69edeee089)) - by @Kn1ghtNight in [#2853](https://github.com/FunkinCrew/Funkin/pull/2853)
- Don't restart the FreeplayState song preview when changing the difficulty within the same variation ([903b3fc](https://github.com/FunkinCrew/Funkin/commit/903b3fc59905a70802618a1cd67407722ea956ed)) - by @JustKolosaki in [#3587](https://github.com/FunkinCrew/Funkin/pull/3587)
- Character Select cursor moves properly at lower framerates ([ab5bda3](https://github.com/FunkinCrew/Funkin/commit/ab5bda3ee573a6e03595ec6941e6de38df851889)) - by @ninjamuffin99 in [#3507](https://github.com/FunkinCrew/Funkin/pull/3507)
- Stop allowing F1 to create more than one help dialog window in the Charting Editor ([777978f](https://github.com/FunkinCrew/Funkin/commit/777978f5a544e1b7c89b47dcc365f734eb6d0df1)) - by @amyspark-ng in [#3552](https://github.com/FunkinCrew/Funkin/pull/3552)
- Main menu music doesn't cut out when switching states anymore. ([711e0a6](https://github.com/FunkinCrew/Funkin/commit/711e0a6b7547eb04113e9318dab900f01ad576a5)) - by @EliteMasterEric in [#3530](https://github.com/FunkinCrew/Funkin/pull/3530)
- The dialog now shows up on the animation debugger view ([1fde59f](https://github.com/FunkinCrew/Funkin/commit/1fde59f999eac94eb10fc22094885de2f5310705)) - by @EliteMasterEric in [#3530](https://github.com/FunkinCrew/Funkin/pull/3530)
- Center preloader 'fnf' and 'dsp' text so it doesn't clip anymore ([165ad60](https://github.com/FunkinCrew/Funkin/commit/165ad6015539a295e9eefdaef291c312e9566b26)) - by @Burgerballs in [#3567](https://github.com/FunkinCrew/Funkin/pull/3567)
- `Song.getFirstValidVariation()` now properly takes into account multiple variations/difficulty input ([d2e2987](https://github.com/FunkinCrew/Funkin/commit/d2e29879fe2acc6febfe0f335f655b741d630c34)) - by @ninjamuffin99 in [#3506](https://github.com/FunkinCrew/Funkin/pull/3506)
- (debug) No more fullscreening when typing "F" in the flixel debugger console ([29b6763](https://github.com/FunkinCrew/Funkin/commit/29b6763290df05d42039806f3d142740568c80f0)) - by @ninjamuffin99 
- Fix crash in LatencyState when exiting / cleaning up state data ([39b1a42](https://github.com/FunkinCrew/Funkin/commit/39b1a42cfeafe2b7be8b66e2fe529e853d9ae197)) - by @lemz1 in [#3493](https://github.com/FunkinCrew/Funkin/pull/3493)
- Add additional classes to Polymod blacklist for security ([b0b73c8](https://github.com/FunkinCrew/Funkin/commit/b0b73c83994f33118c6a69550da9ec8ec1c07adc)) - by @EliteMasterEric in [#3558](https://github.com/FunkinCrew/Funkin/pull/3558)
- Stop allowing inputs after selecting a character ([dbf66ac](https://github.com/FunkinCrew/Funkin/commit/dbf66ac250137262866d75f7c1387645b35d88d0)) - by @ACrazyTown in [#3398](https://github.com/FunkinCrew/Funkin/pull/3398)
- Fix conflict with modded StrumlineNote sprite looping animation ([bc546e8](https://github.com/FunkinCrew/Funkin/commit/bc546e86aa77ffc795b3f079de5f590289a9c583)) - by @DaWaterMalone in [#3577](https://github.com/FunkinCrew/Funkin/pull/3577)
- Properly format the millisecond counter in the chart editor playbar ([f1b6e6c](https://github.com/FunkinCrew/Funkin/commit/f1b6e6c4e42455e0c2900d738ebc24893f2479a0)) - by @afreetoplaynoob in [#3537](https://github.com/FunkinCrew/Funkin/pull/3537)
- Fixed an issue where the player and girlfriend would disappear or overlap themselves in Character Select ([community fix by @gamerbross](https://github.com/FunkinCrew/Funkin/pull/3457))
- Fixed an issue where the game would show the wrong girlfriend in Character Select ([community fix by @gamerbross](https://github.com/FunkinCrew/Funkin/pull/3457))
- Fixed an issue where the cursor wouldn't update properly in Character Select ([community fix by @gamerbross](https://github.com/FunkinCrew/Funkin/pull/3457))
- Fixed an issue where the player would display double after entering character select or when spamming buttons ([community fix by @gamerbross](https://github.com/FunkinCrew/Funkin/pull/3457))

## New Contributors for 0.5.2
* @JustKolosaki made their first contribution in [#3482](https://github.com/FunkinCrew/Funkin/pull/3482)
* @Kn1ghtNight made their first contribution in [#2853](https://github.com/FunkinCrew/Funkin/pull/2853)
* @DaWaterMalone made their first contribution in [#3577](https://github.com/FunkinCrew/Funkin/pull/3577)
* @amyspark-ng made their first contribution in [#3552](https://github.com/FunkinCrew/Funkin/pull/3552)
* @Cartridge-Man made their first contribution in [#3082](https://github.com/FunkinCrew/Funkin/pull/3082)
* @afreetoplaynoob made their first contribution in [#3537](https://github.com/FunkinCrew/Funkin/pull/3537)


## [0.5.1] - 2024-09-30
### Added
- Readded the Merch button to the main menu.
  - Click it to check out our Makeship campaign!
- Added Discord Rich Presence support. People can now see what song you are playing from Discord!
  - We'll get mod support working for this eventually.
- Added an FPS limit option to the Preferences menu.
  - You can now change how high the game tries to push your frame rate, from as little as 30 to as high as 300.
- Added support for the Tracy instrumenation-based profiling tool in development environments. Enable it with the `-DFEATURE_DEBUG_TRACY` compilation flag.
  - For the people who aren't nerds, this is a tool for tracking down performance issues!
- Playable Character data now defines an asset location for an Animate Atlas to display Girlfriend.
  - This includes the option to display a visualizer, if configured correctly.
- Separated the Perfect and Perfect (Gold) animations in the Playable Character data.
  - Base game just uses the same animation for both, but modders can split the animations up on their custom characters now.
- Added a bunch of Flash project files from the Weekend 1 and Playable Pico updates to the `Funkin.art` repository.
- Added the `flipX` and `flipY` parameters to props in the Stage data. ([community feature by AbnormalPoof](https://github.com/FunkinCrew/Funkin/pull/3474))
### Changed
- The game's mod API version check is now more dynamic.
  - The update accepts mods with API version `0.5.0` as well as `0.5.1`.
- Pico is no longer unlocked for all players automatically.
  - You need to beat Weekend 1 in Story Mode in order to unlock him in Character Select.
- Removed some of the more spammy `trace()` calls to improve debugging a bit.
- Improved some of the compilation and modding documentation.
- The game now complains if you create a song variation with symbols in the name.
- Switched the force crash keybind from Ctrl-Shift-L to Ctrl-Alt-Shift-L.
- Added some additional functions to `funkin.Assets` after `openfl.utils.Assets` had to get blacklisted from scripts.
### Fixed
- Fixed an issue where DadBattle (Pico Mix) was not properly credited to `TeraVex (ft. Saruky)`.
- Fixed an issue where DadBattle (Pico Mix) was missing charts on the Normal and Easy difficulty.
- Fixed an issue where Spookeez (Pico Mix) was not properly credited to `Six Impala (ft. Saster)`.
- Fixed an issue where the "Shit!" judgement would display with anti-aliasing in Week 6.
- Fixed an issue where Pico Erect could be played with different instrumentals.
- Fixed an issue where Pico would not play his shooting animations in Stress.
- Fixed an issue where Freeplay would display no custom songs when switching characters.
- Fixed an issue where Freeplay would sometimes display the wrong text on the capsules.
- Fixed an issue where duplicate difficulties from custom variations wouldn't display properly in Freeplay.
- Fixed an issue where custom note styles would sometimes just use default values rather than using the fallback note style.
- Fixed an issue where custom note styles would randomly fail to fetch information about their fallback note style.
- Fixed an issue where the Screenshots and Chart Editor binds displayed in the controls menu on Web builds (where they are disabled).
- Fixed an issue where the Stage Editor bind displayed in the controls menu even when the feature was disabled.
- Fixed an issue where the Freeplay Character Select keybind displayed weird in the keybinds menu.
- Fixed an issue where setting the input offset or visual offset too high would cause the song to skip.
- Fixed an issue where video cutscenes would not scale their volume properly.
- Fixed an issue where Cocoa Erect (Erect difficulty) had a tap note stacked on top of a hold note,
- Fixed an issue where the game would stutter when playing on the Week 5 Remix stage.
- Fixed an issue where the save data version number wouldn't get written to save data properly.
- Fixed an issue where the example mod could not be loaded.
- Fixed an issue where a script error would display when entering Blazin'.
- Fixed an issue where pressing F5 to force reload a song would sometimes cause the game to crash.
- Fixed an issue where animations on Animate Atlas characters would throw a bunch of warnings in the console.
- Fixed an issue where characters with high offsets would shift over after the player dies or restarts.
- Fixed an issue where Pico wouldn't play out his full burp animation in South (Pico Mix).
- Fixed an issue where Results screen audio could continue into Freeplay or even gameplay.
- Fixed an issue where some audio tracks would get destroyed even if they were flagged as persistent.
- Fixed an issue where the audio track would stay muted if you missed a note just before Pico burps.
- Fixed an issue where the curtains in Week 1 would display in front of larger characters.
- Fixed an issue where Boyfriend wouldn't play his death animation properly on Week 2's Remix stage.
- Fixed an issue in Freeplay where the clear % would not display after switching characters.
- Fixed an issue in Freeplay where character remixes would display the base song's highscore.
- Fixed an issue where Pico would become locked every time the game starts, and you would have to watch the unlock animation each game boot.
  - The animation should now play only once per save file.
- Fixed an issue where Spirit's trail in Week 6 would not display correctly.
- Fixed an issue where the Input Offsets menu would crash when entering it before playing a song on web builds.
- Fixed an issue where the Results screen would spam the percentage tick noise instead of playing when the value changes.
- Fixed an issue where parts of the Chart Editor could not be interacted with. ([community fix by Kade-github](https://github.com/FunkinCrew/Funkin/pull/3337))
- Fixed an issue where classic FocusCamera song events could cause the camera to snap in place. ([community fix by nebulazorua](https://github.com/FunkinCrew/Funkin/pull/2331))
- Fixed an issue where achieving the same rank on a song (but a different clear %) would override your clear %, even if it was lower. ([community fix by lemz1](https://github.com/FunkinCrew/Funkin/pull/3019))
- Fixed an issue where the FPS counter would display even if Debug Display was turned off. ([community fix by Lethrial](https://github.com/FunkinCrew/Funkin/pull/3356))
- Fixed an issue where selecting the area to the left of the Chart Editor would select some of the player's notes ([community fix by NotHyper-474](https://github.com/FunkinCrew/Funkin/pull/3093))
- Fixed an issue where pixel icons in the Chart Editor would not display correctly. ([community fix by Techniktil](https://github.com/FunkinCrew/Funkin/pull/3339))
- Fixed an issue where `Stage.addCharacter` would not properly assign the `characterType`. ([community fix by Kade-github](https://github.com/FunkinCrew/Funkin/pull/3357))
- Fixed an issue where players could interact with Character Select during the unlock sequence, causing a crash. ([community fix by ActualMandM](https://github.com/FunkinCrew/Funkin/pull/3355))
- Fixed an issue where hold notes in Week 6 were not scaled/positioned correctly. ([community fix by dombomb64](https://github.com/FunkinCrew/Funkin/pull/3351))
- Fixed an issue where audio offets would not interact with the Chart Editor properly. ([community fix by Kade-github](https://github.com/FunkinCrew/Funkin/pull/3384))
- Fixed an issue where fetching Modules during the `onDestroy` event would fail at random. ([community fix by cyn0x8](https://github.com/FunkinCrew/Funkin/pull/3131))
- Fixed an issue where `onSubStateOpenEnd` and `onSubStateCloseEnd` script events would not always get called. ([community fix by lemz1](https://github.com/FunkinCrew/Funkin/pull/3138))

## New Contributors for 0.5.1
* @Lethrial made their first contribution in [#3356](https://github.com/FunkinCrew/Funkin/pull/3356)
* @dombomb64 made their first contribution in [#3351](https://github.com/FunkinCrew/Funkin/pull/3351)


## [0.5.0] - 2024-09-12
### Added
- Added a new Character Select screen to switch between playable characters in Freeplay
  - Modding isn't 100% there but we're working on it!
- Added Pico as a playable character! Unlock him by completing Weekend 1 (if you haven't already done that)
  - The songs from Weekend 1 have moved; you must now switch to Pico via Character Select screen in Freeplay to access them
- Added 11 new Pico remixes! Access them by selecting Pico from in the Character Select screen
  - Bopeebo (Pico Mix)
  - Fresh (Pico Mix)
  - DadBattle (Pico Mix)
  - Spookeez (Pico Mix)
  - South (Pico Mix)
  - Pico (Pico Mix)
  - Philly Nice (Pico Mix)
  - Blammed (Pico Mix)
  - Eggnog (Pico Mix)
  - Ugh (Pico Mix)
  - Guns (Pico Mix)
- Added 1 new Boyfriend remix! Access it by completing Weekend 1 as Pico and then selecting Boyfriend from in the Character Select screen
  - Darnell (BF Mix)
- Added 2 new Erect remixes! Access them by switching difficulty on the song
  - Cocoa Erect
  - Ugh Erect
- Implemented support for a new Instrumental Selector in Freeplay
  - Beating a Pico remix lets you use that instrumental when playing as Boyfriend
- Added the first batch of Erect Stages! These graphical overhauls of the original stages will be used when playing Erect remixes and Pico remixes
  - Week 1 Erect Stage
  - Week 2 Erect Stage
  - Week 3 Erect Stage
  - Week 4 Erect Stage
  - Week 5 Erect Stage
  - Weekend 1 Erect Stage
- Implemented alternate animations and music for Pico in the results screen.
  - These display on Pico remixes, as well as when playing Weekend 1.
- Implemented support for scripted Note Kinds. You can use HScript define a different note style to display for these notes as well as custom behavior. (community feature by lemz1)
- Implemented support for Numeric and Selector options in the Options menu. ([community feature by FlooferLand](https://github.com/FunkinCrew/Funkin/pull/2942))
- Implemented new animations for Tankman and Pico.
## Changed
- Girlfriend and Nene now perform previously unused animations when you achieve a large combo, or drop a large combo.
- The pixel character icons in the Freeplay menu now display an animation!
- Altered how Week 6 displays sprites to make things look more retro.
- Character offsets are now independent of the character's scale.
  - This should resolve issues with offsets when porting characters from older mods.
  - Pixel character offsets have been modified to compensate.
- Note style data can now specify custom combo count graphics, judgement graphics, countdown graphics, and countdown audio. ([community feature by anysad](https://github.com/FunkinCrew/Funkin/pull/3020))
  - These were previously using hardcoded values based on whether the stage was `school` or `schoolEvil`.
- The `danceEvery` property of characters and stage props can now use values with a precision of `0.25`, to play their idle animation up to four times per beat.
- Reworked the JSON merging system in Polymod; you can now include JSONPatch files under `_merge` in your mod folder to add, modify, or remove values in a JSON without replacing it entirely!
- Cutscenes now automatically pause when tabbing out ([community fix by AbnormalPoof](https://github.com/FunkinCrew/Funkin/pull/2903))
- Characters will now respect the `danceEvery` property ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2925))
- The F5 function now reloads the current song's chart data from disc ([community feature by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2990))
- Refactored the compilation guide and added common troubleshooting steps ([community fix by Hundrec](https://github.com/FunkinCrew/Funkin/pull/2813))
- Made several layout improvements and fixes to the Animation Offsets editor in the Debug menu ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2820))
- Fixed a bug where the Back sound would be not played when leaving the Story menu and Options menu ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/2986))
- Animation offsets no longer directly modify the `x` and `y` position of props, which makes props work better with tweens ([community fix by Sword352](https://github.com/FunkinCrew/Funkin/pull/2310))
- The YEAH! events in Tutorial now use chart events rather than being hard-coded ([community fix by anysad](https://github.com/FunkinCrew/Funkin/pull/3007))
- The player's Score now displays commas in it (community fix by loggo)
## Fixed
- Fixed an issue where songs with no notes would crash on the Results screen.
- Fixed an issue where the old icon easter egg would not work properly on pixel levels.
- Fixed an issue where you could play notes during the Thorns cutscene.
- Fixed an issue where the Heart icon when favoriting a song in Freeplay would be malformed.
- Fixed an issue where Pico's death animation displays a faint blue background ([community fix by doggogit](https://github.com/FunkinCrew/funkin.assets/pull/1))
- Fixed an issue where mod songs would not play a preview in the Freeplay menu ([community fix by KarimAkra](https://github.com/FunkinCrew/Funkin/pull/2724))
- Fixed an issue where the Memory Usage counter could overflow and display a negative number ([community fix by KarimAkra](https://github.com/FunkinCrew/Funkin/pull/2713))
- Fixed an issue where pressing the Chart Editor keybind while playtesting a chart would reset the chart editor ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2739))
- Fixed a crash bug when pressing F5 after seeing the sticker transition ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2863))
- Fixed an issue where the Story Mode menu couldn't be scrolled with a mouse ([community fix by JVNpixels](https://github.com/FunkinCrew/Funkin/pull/2873))
- Fixed an issue causing the song to majorly desync sometimes ([community fix by Burgerballs](https://github.com/FunkinCrew/Funkin/pull/3058))
- Fixed an issue where the Freeplay song preview would not respect the instrumental ID specified in the song metadata ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/2742))
- Fixed an issue where Tankman's icon wouldn't display in the Chart Editor ([community fix by Hundrec](https://github.com/FunkinCrew/Funkin/pull/2912))
- Fixed an issue where pausing the game during a camera zoom would zoom the pause menu. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2567))
- Fixed an issue where certain UI elements would not flash at a consistent rate ([community fix by cyn0x8](https://github.com/FunkinCrew/Funkin/pull/2494))
- Fixed an issue where the game would not use the placeholder health icon as a fallback ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/3005))
- Fixed an issue where the chart editor could get stuck creating a hold note when using Live Inputs ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2992))
- Fixed an issue where character graphics could not be placed in week folders ([community fix by 7oltan](https://github.com/FunkinCrew/Funkin/pull/3035))
- Fixed a crash issue when a Freeplay song has no `Normal` difficulty ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/3036) and [gamerbross](https://github.com/FunkinCrew/Funkin/pull/2712))
- Fixed an issue in Story Mode where a song that isn't valid for the current variation could be selected ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/3037))

## New Contributors for 0.5.0
* @Flooferland made their first contribution in [#2942](https://github.com/FunkinCrew/Funkin/pull/2942)
* @anysad made their first contribution in [#3007](https://github.com/FunkinCrew/Funkin/pull/3007)
* @Sword352 made their first contribution in [#2310](https://github.com/FunkinCrew/Funkin/pull/2310)
* @KarimAkra made their first contribution in [#2713](https://github.com/FunkinCrew/Funkin/pull/2713)
* @JVNpixels made their first contribution in [#2873](https://github.com/FunkinCrew/Funkin/pull/2873)
* @AppleHair made their first contribution in [#2742](https://github.com/FunkinCrew/Funkin/pull/2742)
* @7oltan made their first contribution in [#3035](https://github.com/FunkinCrew/Funkin/pull/3035)
* @cyn0x8 made their first contribution in [#2494](https://github.com/FunkinCrew/Funkin/pull/2494)


## [0.4.1] - 2024-06-12
### Added
- Pressing ESCAPE on the title screen on desktop now exits the game, allowing you to exit the game while in fullscreen on desktop
- Freeplay menu controls (favoriting and switching categories) are now rebindable from the Options menu, and now have default binds on controllers.
### Changed
- Highscores and ranks are now saved separately, which fixes the issue where people would overwrite their saves with higher scores,
which would remove their rank if they had a lower one.
- A-Bot speaker now reacts to the user's volume preference on desktop ([thanks to M7theguy for the issue report/suggestion](https://github.com/FunkinCrew/Funkin/issues/2744)!)
- On Freeplay, heart icons are shifted to the right when you favorite a song that has no rank on it.
- Only play `scrollMenu` sound effect when there's a real change on the freeplay menu ([thanks gamerbross for the PR!](https://github.com/FunkinCrew/Funkin/pull/2741))
- Gave antialiasing to the edge of the dad graphic on Freeplay
- Rearranged some controls in the controls menu
- Made several chart revisions
  - Re-enabled custom camera events in Roses (Erect/Nightmare)
  - Tweaked the chart for Lit Up (Hard)
  - Corrected the difficulty ratings for M.I.L.F (Easy/Normal/Hard)
### Fixed
- Fixed an issue in the controls menu where some control binds would overlap their names
- Fixed crash when attempting to exit the gameover screen when also attempting to retry the song ([thanks DMMaster636 for the PR!](https://github.com/FunkinCrew/Funkin/pull/2709))
- Fix botplay sustain release bug ([thanks Hundrec!](https://github.com/FunkinCrew/Funkin/pull/2683))
- Fix for the camera not pausing during a gameplay pause ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2684))
- Fixed issue where Pico's gameplay sprite would unintentionally appear on the gameover screen when dying on 2hot from an explosion
- Freeplay previews properly fade volume during the BF idle animation
- Fixed bug where DadBattle incorrectly appeared as DadBattle Erect when returning to freeplay on Hard
- Fixed 2hot not appearing under the "#" category in Freeplay menu
- Fixed a bug where the Chart Editor would crash when attempting to select an event with the Event toolbox open
- Improved offsets for Pico and Tankman opponents so they don't slide around as much.
- Fixed the black "temp" graphic on freeplay from being incorrectly sized / masked, now it's identical to the dad freeplay graphic

## New Contributors for 0.4.1
* @DMMaster636 made their first contribution in [#2709](https://github.com/FunkinCrew/Funkin/pull/2709)
* @Hundrec made their first contribution in [#2683](https://github.com/FunkinCrew/Funkin/pull/2683)


## [0.4.0] - 2024-06-06
### Added
- 2 new Erect remixes, Eggnog and Satin Panties. Check them out from the Freeplay menu!
- Major visual improvements to the Results screen, with additional animations and audio based on your performance.
- Major visual improvements to the Freeplay screen, with song difficulty ratings and player rank displays.
  - Freeplay now plays a preview of songs when you hover over them.
- Added a Charter field to the chart format, to allow for crediting the creator of a level's chart.
  - You can see who charted a song from the Pause menu.
- Added a new Scroll Speed chart event to change the note speed mid-song ([thanks Burgerballs!](https://github.com/FunkinCrew/Funkin/pull/2409))
### Changed
- Tweaked the charts for several songs:
  - Tutorial (increased the note speed slightly)
  - Spookeez
  - Monster
  - Winter Horrorland
  - M.I.L.F
  - Senpai (increased the note speed)
  - Roses
  - Thorns (increased the note speed slightly)
  - Ugh
  - Stress
  - Lit Up
- Favorite songs marked in Freeplay are now stored between sessions.
- The Freeplay easter eggs are now easier to see.
- In the event that the game cannot load your save data, it will now perform a backup before clearing it, so that we can try to repair it in the future.
- Custom note styles are now properly supported for songs; add new notestyles via JSON, then select it for use from the Chart Editor Metadata toolbox. ([thanks Keoiki!](https://github.com/FunkinCrew/Funkin/pull/2581))
- Health icons now support a Winning frame without requiring a spritesheet, simply include a third frame in the icon file. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2593))
  - Remember that for more complex behaviors such as animations or transitions, you should use an XML file to define each frame.
- Improved the Event Toolbox in the Chart Editor; dropdowns are now bigger, include search field, and display elements in alphabetical order rather than a random order.
### Fixed
- Fixed an issue where Nene's visualizer would not play on Desktop builds
- Fixed a bug where the game would silently fail to load saves on HTML5
- Fixed some bugs with the props on the Story Menu not bopping properly
- Additional fixes to the Loading bar on HTML5 ([thanks lemz1!](https://github.com/FunkinCrew/Funkin/pull/2553))
- Fixed several bugs with the TitleState, including missing music when returning from the Main Menu ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2539))
- Fixed a camera bug in the Main Menu ([thanks richTrash21!](https://github.com/FunkinCrew/Funkin/pull/2576))
- Fixed a bug where changing difficulties in Story mode wouldn't update the score ([thanks sector-a!](https://github.com/FunkinCrew/Funkin/pull/2585))
- Fixed a crash in Freeplay caused by a level referencing an invalid song ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2457))
- Fixed a bug where pressing the volume keys would stop the Toy commercial ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2540))
- Fixed a bug where the Chart Editor Playtest would crash when losing ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2518))
- Fixed a bug where hold notes would display improperly in the Chart Editor when downscroll was enabled for gameplay ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2565))
- Fixed a bug where hold notes would be positioned wrong on downscroll ([thanks MaybeMaru!](https://github.com/FunkinCrew/Funkin/pull/2488))
- Removed a large number of unused imports to optimize builds ([thanks Ethan-makes-music!](https://github.com/FunkinCrew/Funkin/pull/2624))
- Improved debug logging for unscripted stages ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2603))
- Fixed a crash on Linux caused by an old version of hxCodec ([thanks Noobz4Life!](https://github.com/FunkinCrew/Funkin/pull/2472))
- Optimized animation handling for characters ([thanks richTrash21!](https://github.com/FunkinCrew/Funkin/pull/2493))  
- Made improvements to compiling documentation (thanks gedehari!)
- Fixed an issue where the Chart Editor would use an incorrect instrumental on imported Legacy songs ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2604))
- Fixed a bug where opening the game from the command line would crash the preloader ([thanks NotHyper-474!](https://github.com/FunkinCrew/Funkin/pull/2629))
- Fixed a bug where characters would sometimes use the wrong scale value ([thanks PurSnake!](https://github.com/FunkinCrew/Funkin/pull/2610))
- Additional bug fixes and optimizations.

## New Contributors for 0.4.0
* @Keoiki made their first contribution in [#2581](https://github.com/FunkinCrew/Funkin/pull/2581)
* @richTrash21 made their first contribution in [#2493](https://github.com/FunkinCrew/Funkin/pull/2493)
* @sector-a made their first contribution in [#2585](https://github.com/FunkinCrew/Funkin/pull/2585)
* @MaybeMaru made their first contribution in [#2488](https://github.com/FunkinCrew/Funkin/pull/2488)
* @Ethan-makes-music made their first contribution in [#2624](https://github.com/FunkinCrew/Funkin/pull/2624)
* @Noobz4Life made their first contribution in [#2472](https://github.com/FunkinCrew/Funkin/pull/2472)
* @NotHyper-474 made their first contribution in [#2629](https://github.com/FunkinCrew/Funkin/pull/2629)
* @PurSnake made their first contribution in [#2610](https://github.com/FunkinCrew/Funkin/pull/2610)


## [0.3.3] - 2024-05-14
### Changed
- Cleaned up some code in `PlayAnimationSongEvent.hx` ([thanks Burgerballs!](https://github.com/FunkinCrew/Funkin/pull/2308))
### Fixed
- Fixes to the Loading bar on HTML5 ([thanks lemz1!](https://github.com/FunkinCrew/Funkin/pull/2499))
- Don't allow any more inputs when exiting freeplay ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2470))
- Fixed using mouse wheel to scroll on freeplay ([thanks JugieNoob!](https://github.com/FunkinCrew/Funkin/pull/2466))
- Fixed the resets of the health icons, score, and notes when re-entering gameplay from gameover ([thanks ImCodist!](https://github.com/FunkinCrew/Funkin/pull/2390))
- Fixed the chart editor character selector's hitbox width ([thanks MadBear422!](https://github.com/FunkinCrew/Funkin/pull/2370))
- Fixed camera stutter once a wipe transition to the Main Menu completes ([thanks ImCodist!](https://github.com/FunkinCrew/Funkin/pull/2315))
- Fixed an issue where hold note would be invisible for a single frame ([thanks ImCodist!](https://github.com/FunkinCrew/Funkin/pull/2309))
- Fix tween accumulation on title screen when pressing Y multiple times ([thanks TheGaloXx!](https://github.com/FunkinCrew/Funkin/pull/2300))
- Fix a crash when querying FlxG.state in the crash handler
- Fix for a game over easter egg so you don't accidentally exit it when viewing
- Fix an issue where the Freeplay menu never displays 100% clear
- Fix an issue where Weekend 1 Pico attempted to retrieve a missing asset.
- Fix an issue where duplicate keybinds would be stored, potentially causing a crash
- Chart debug key now properly returns you to the previous chart editor session if you were playtesting a chart ([thanks nebulazorua!](https://github.com/FunkinCrew/Funkin/pull/2323))
- Fix a crash on Freeplay found on AMD graphics cards

## New Contributors for 0.3.3
* @Burgerballs made their first contribution in [#2308](https://github.com/FunkinCrew/Funkin/pull/2308)
* @lemz1 made their first contribution in [#2499](https://github.com/FunkinCrew/Funkin/pull/2499)
* @gamerbross made their first contribution in [#2470](https://github.com/FunkinCrew/Funkin/pull/2470)
* @JugieNoob made their first contribution in [#2466](https://github.com/FunkinCrew/Funkin/pull/2466)
* @MadBear422 made their first contribution in [#2370](https://github.com/FunkinCrew/Funkin/pull/2370)
* @ImCodist made their first contribution in [#2309](https://github.com/FunkinCrew/Funkin/pull/2309)
* @TheGaloXx made their first contribution in [#2300](https://github.com/FunkinCrew/Funkin/pull/2300)
* @nebulazorua made their first contribution in [#2323](https://github.com/FunkinCrew/Funkin/pull/2323)


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
- Fixed crashes on Week 6 story mode dialogue if spam too fast ([Thanks to Lotusotho for the Pull Request!](https://github.com/FunkinCrew/Funkin/pull/357))
- Should show intro credits on desktop versions of the game more consistently
- Layering on Week 4 songs with GF and the LIMO LOL HOW TF I MISS THIS
- Chart's and chart editor now support changeBPM, GOD BLESS MTH FOR THIS ONE I BEEN STRUGGLIN WIT THAT SINCE OCTOBER LMAO ([GOD BLESS MTH](https://github.com/FunkinCrew/Funkin/pull/382))
- Fixed sustain note trails ALSO THANKS TO MTH U A REAL ONE ([MTH VERY POWERFUL](https://github.com/FunkinCrew/Funkin/pull/415))
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
- Idle animation bug with BF christmas and BF hair blow sprites ([Thanks to Injourn for the Pull Request!](https://github.com/FunkinCrew/Funkin/pull/237))


## [0.2.6] - 2021-01-20
### Added
- 3 NEW CHRISTMAS SONGS. 2 BY KAWAISPRITE, 1 BY BASSETFILMS!!!!! BF WITH DRIP! SANTA HANGIN OUT!
- Enemy icons change when they you are winning a lot ([Thanks to pahaze for the Pull Request!](https://github.com/FunkinCrew/Funkin/pull/138))
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
- Old Verison popup screen weirdness ([Thanks to gedehari for the Pull Request!](https://github.com/FunkinCrew/Funkin/pull/155))
- Song no longer loops when finishing the song. ([Thanks Injourn for the Pull Request!](https://github.com/FunkinCrew/Funkin/pull/132))
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
- When pausing music at the start, it doesn't continue the song anyways. ([shoutouts gedehari for the Pull Request!](https://github.com/FunkinCrew/Funkin/pull/48))
- IDK i think backing out of song menu should play main menu songs again hehe ([shoutouts gedehari for the Pull Request!](https://github.com/FunkinCrew/Funkin/pull/48))


## [0.2.4] - 2020-12-11
### Added
- 3 NEW SONGS BY KAWAISPRITE. Pico, Philly, and Blammed.
- NEW CHARACTER, PICO. Based off the classic Flash game "Pico's School" by Tom Fulp
- NEW LEVEL WOW! PHILLY BABEEEE
### Changed
- Made it less punishing to ATTEMPT to hit a note and miss, rather than let it pass you
### Fixed
- Song desync of you paused and unpaused frequently ([shoutouts SonicBlam](https://github.com/FunkinCrew/Funkin/issues/37))
- Animation offsets when GF is scared


## [0.2.3] - 2020-12-04
### Added
- More intro texts
### Fixed
- Exploit where you could potentially give yourself a high score via the debug menu
- Issue/bug where you could spam the confirm button on the story menu ([shoutouts lotusotho for the CODE contribution/pull request!](https://github.com/FunkinCrew/Funkin/pull/19))
- Glitch where if you never would lose health if you missed a note on a fast song (shoutouts [MrDulfin](https://github.com/FunkinCrew/Funkin/issues/10), [HotSauceBurritos](https://github.com/FunkinCrew/Funkin/issues/13) and [LobsterMango](https://lobstermango.newgrounds.com))
- Fixed tiny note bleed over thingies (shoutouts [lotusotho](https://github.com/FunkinCrew/Funkin/pull/24))


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
- Fixed soft lock when pausing on song finish ([shoutouts gedehari](https://github.com/FunkinCrew/Funkin/issues/15))
- Think I fixed issue that led to in-game scores being off by 2 ([shoutouts Mike](https://github.com/FunkinCrew/Funkin/issues/4))
- Should have fixed the 1 frame note appearance thing. ([shoutouts Mike](https://github.com/FunkinCrew/Funkin/issues/6))
- Cleaned up some charting on South on hard mode
- Fixed some animation timings, should feel both better to play, and watch. (shoutouts Dave/Ivan lol)
- Animation issue where GF would freak out on the title screen if you returned to it([shoutouts MultiXIII](https://github.com/FunkinCrew/Funkin/issues/12)).


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
- Balanced out Normal mode for the harder songs(DadBattle and Spookeez, not South yet). Should be much easier all around.
- Put tutorial in it's own 'week', so that if you want to play week 1, you don't have to play the tutorial.
### Fixed
- One of the charting bits on South and Spookeez during the intro.


## [0.2.0] - 2020-11-01
### Added
- Uhh Newgrounds release lolol I always lose track of shit.


## [0.1.0] - 2020-10-05
### Added
- Uh, everything. This the game's initial gamejam release. We put it out
