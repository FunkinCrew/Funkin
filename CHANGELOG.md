# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.8.3] - 2026-02-23

### Fixed

- [HTML5] Hitting a can in 2hot no longer creates a script error. (Thanks NotHyper-474!)
- The game no longer consistently lag spikes during gameplay. ([823120c](https://github.com/FunkinCrew/Funkin/commit/823120cdef7bfbb2d3ec37c7085878fcbeebcb30)) - by @ACrazyTown in [#6970](https://github.com/FunkinCrew/Funkin/pull/6970)



## [0.8.2] - 2026-02-23

### Added

- Added 14 new blend modes, allowing the engine to render better visual effects.
- Added a PlayState parameter that mirrors notes during a song.
- Added preview graphs for Chart Editor event easing types. ([eea1265](https://github.com/FunkinCrew/Funkin/commit/eea12657b1d8131014a3fdc270c3f351fae6e851)) - by @PurSnake in [#6374](https://github.com/FunkinCrew/Funkin/pull/6374)
- Added the ability to mirror notes on the X and Y axes in the Chart Editor. ([fd0c2df](https://github.com/FunkinCrew/Funkin/commit/fd0c2df35ee8cda3f1566a297c4faec984d809bb)) - by @Lasercar in [#4372](https://github.com/FunkinCrew/Funkin/pull/4372)
- Added a deselect button and shortcut to the Stage Editor. ([a9f1d41](https://github.com/FunkinCrew/Funkin/commit/a9f1d41771f0c97fdd70d4d6c54087ac0e64ff38)) - by @Lasercar in [#5281](https://github.com/FunkinCrew/Funkin/pull/5281)

### Changed

- Made some improvements to Polymod:
  - Added string interpolation support. (Thanks NotHyper-474!)
  - Scripted classes can now extend nothing. (Thanks NotHyper-474!)
  - Scripted classes can now extend other scripted classes. (Thanks KoloInDaCrib!)
  - Tweaked some error messages to be more verbose.
  - Added `scriptHas` and `staticScriptHas` functions to check if a script has a specific variable/function.
  - The `is` operator is now more accurate to regular Haxe. (Thanks Starexify!)
  - Static functions can now use static extensions (`using`s). (Thanks NotHyper-474!)
  - `interface`s can now be properly parsed. (Thanks Starexify!)
  - Optional fields and extensions can now be used in `typedef`s. (Thanks Starexify!)
  - Added stricter checking for default/optional arguments in functions. (Thanks Starexify!)
    - May be a breaking change for some scripts, so please update your scripts to account for this!
  - Enums now have multiple arguments. (Thanks Starexify!)
  - Basic types (e.g `String`, `Int`, `Bool`, etc.) can now be used with the `is` operator without having to import the type first.
- Tweaked charts for the following songs:
  - Bopeebo (Pico Mix) [Normal/Hard] -  Adjusted note timings and added a “hey” animation event in Sections 18, 26, and 27.
  - Fresh Erect [Nightmare] - Added 2 notes where Boyfriend’s vocals echo.
  - DadBattle Erect [Nightmare] - Added a missing jack note in Section 38, added holds to two notes in Section 63.
  - DadBattle (Pico Mix) [all difficulties] - Adjusted timings for various notes in Sections 37-40 and 60.
  - Spookeez Erect [Erect/Nightmare] - Adjusted many hold note lengths to better match vocals.
  - Spookeez (Pico Mix) - Added one missing note to Section 14.
  - South Erect [Erect/Nightmare] - Adjusted many hold note lengths to better match vocals.
  - Pico [Easy] - Adjusted timings for one note each in Sections 36 and 38.
  - Pico [Normal/Hard] - Adjusted timings for Boyfriend’s right notes to be a bit earlier in Sections 31-42.
  - Pico [all difficulties] - Added a Focus Camera event on Girlfriend during the duet.
  - Satin Panties Erect [Erect/Nightmare] - Split a hold note into two for Mom in Sections 14 and 18.
  - High Erect [Erect/Nightmare] - Adjusted timing for one note each in Sections 25 and 41.
  - M.I.L.F [Easy] - Adjusted timings for two notes in Section 73.
  - M.I.L.F [Hard] - Changed one down note into an up note in Section 15 for consistency.
  - Cocoa Erect [Nightmare] - Fixed one note not being a Mom notekind in Section 24, added holds to 2 notes in Section 67.
  - Cocoa (Pico Mix) [all difficulties] - Adjusted timings for two notes in Section 15.
  - Eggnog Erect [Erect/Nightmare] - Adjusted how a grace note is charted in Section 52, added 2 missing notes for Mom in Section 72, adjusted Camera Bop event in Section 63.
  - Senpai (Pico Mix) [all difficulties] - Adjusted timing for one note in Section 10.
  - Roses [Normal] - Adjusted timings for four notes in Sections 30, 32, 41, and 43.
  - Thorns Erect [Erect] - Adjusted timings for two notes in Section 36, removed some double notes to differentiate the chart from Nightmare.
  - Ugh Erect [Erect/Nightmare] - Adjusted some Zoom Camera events around Section 24.
  - Guns (Pico Mix) [all difficulties] - Fixed many timing issues throughout the whole song.
  - SPAGHETTI [Normal/Hard] - Added one note to match Boyfriend’s rapping.
  - Darnell (BF Mix) [all difficulties] - Removed extra notes from Sections 49 and 50, adjusted various note timings throughout the song.
  - Lit Up [Normal] - Added one missing note each in Sections 40 and 60.
  - Lit Up (BF Mix) [Normal/Hard] - Adjusted timings for various grace notes in Sections 1, 52, 55, and 56.
  - 2hot [Easy/Normal] - Recharted many sections to be more predictable.
- [macOS] Disabled high DPI to significantly improve performance on some displays.
- Improved the Lag Adjustment menu to better handle very large offsets.
- Chart Editor exporting now omits default values and orders values more consistently.
- Chart Editor playtests now processes all events before the starting position.
- Optimized the Week 2 Spooky Mansion stage background by using a texture atlas. ([2bdd5a7](https://github.com/FunkinCrew/funkin.assets/commit/2bdd5a713f0b5c7e945c457e2a4a92bdb367cc02)) - by @MaybeMaru and @Trayfellow in [funkin.assets#348](https://github.com/FunkinCrew/funkin.assets/pull/348)
- Added more default imports for mods. ([1620cf3](https://github.com/FunkinCrew/Funkin/commit/1620cf388973eab5d83e151eec28b2c8abc84eb1)) - by @Starexify in [#6706](https://github.com/FunkinCrew/Funkin/pull/6706)
- The Set Camera Bop event now supports decimal values for rate and offset at 0.25 precision. ([ffaba34](https://github.com/FunkinCrew/Funkin/commit/ffaba343258c4a0e5ee7e1bd7fa0e8138ae60bc1)) - by @KoloInDaCrib in [#6741](https://github.com/FunkinCrew/Funkin/pull/6741)

### Fixed

- Fixed some issues with Polymod:
  - The super constructor for scripted classes can now accept more than 4 arguments. (Thanks NotHyper-474!)
  - Functions can now accept more than 8 arguments. (Thanks NotHyper-474!)
  - Script variables are no longer dropped early when passing them to a callback (ex. `FlxTimer`). (Thanks NotHyper-474!)
  - Fix a memory leak that could happen if a script tried to reference an anonymous object with a lot of `StringMap`s. (Thanks NotHyper-474!)
  - Properties (`get_`/`set_` functions) are now much more accurate to regular Haxe. (Thanks NotHyper-474!)
- Re-exported some assets to fix some issues:
  - Re-exported all variations of Pico as texture atlases to optimize memory usage.
  - Freeplay DJ Pico’s table sparks no longer persist when his gun is lifted.
  - Pico (Blazin’)’s game over retry animation now properly displays its blend modes.
  - Pico (Christmas) no longer shows several stray marks around his sprites.
  - Nene (Christmas) no longer becomes slightly offset when her knife is raised.
  - The running tankmen in Stress (Pico Mix) no longer tank the game’s performance.
  - Daddy Dearest now properly holds his up pose.
  - Monster (Christmas)’s hat no longer moves while he holds a pose.
  - Darnell’s can in 2hot now shows a sparkling effect.
- [DESKTOP] Modded atlas characters with both .png and .astc spritesheets no longer crash the game.
- [DESKTOP] The game display no longer sometimes becomes offset from the window.
- [MOBILE] Selecting a song using touch controls when a keyboard is connected no longer disables the keyboard strumline layout.
- [ANDROID] Improved Freeplay scrolling behavior on high framerate displays.
- [WINDOWS] Chart Editor save dialog windows no longer freeze the game.
- The Chart Editor Results Screen playtest option now consistently shows the Results Screen after each playtest.
- Scrolling really quickly in Freeplay no longer crashes the game. ([76699b2](https://github.com/FunkinCrew/Funkin/commit/76699b235cd5b359bc34e6950cd05bbbb13918f8)) - by @ComedyLost in [#6962](https://github.com/FunkinCrew/Funkin/pull/6962)
- Fixed a memory leak in the Freeplay menu. ([910ba65](https://github.com/FunkinCrew/Funkin/commit/910ba650b0c1011802b151b85f4a9d8177ae95c7)) - by @KoloInDaCrib in [#6615](https://github.com/FunkinCrew/Funkin/pull/6615)
- Modded difficulty dots and graphics now render correctly in Freeplay. ([90b856d](https://github.com/FunkinCrew/Funkin/commit/90b856d88635ac4e5517e934298e3820b2e5f45c)) - by @ComedyLost in [#6205](https://github.com/FunkinCrew/Funkin/pull/6205)
- Freeplay capsules with long song names no longer display too far to the left during the new rank animation. ([17a914c](https://github.com/FunkinCrew/Funkin/commit/17a914c933592cb3ba79881ca6a8d900b8513cbc)) - by @VirtuGuy in [#6690](https://github.com/FunkinCrew/Funkin/pull/6690)
- Freeplay capsule BPM values ending in 1 now display with proper spacing. ([e5b4351](https://github.com/FunkinCrew/Funkin/commit/e5b43510dd810a74a7d06f7f02c52892d11d6f8b)) - by @VirtuGuy in [#6696](https://github.com/FunkinCrew/Funkin/pull/6696)
- The Freeplay pixel icon now properly plays its confirm animation when mashing the capsule. ([a56bc44](https://github.com/FunkinCrew/Funkin/commit/a56bc4462d1c49e8ec71462b9bd7ff338b743c93)) - by @VirtuGuy in [#6723](https://github.com/FunkinCrew/Funkin/pull/6723)
- [HTML5] Scrolling with the mouse now works properly in Story Mode and Freeplay. ([506d80b](https://github.com/FunkinCrew/Funkin/commit/506d80b287b969121dc3601714c2459cc71f7e55)) - by @VirtuGuy in [#6621](https://github.com/FunkinCrew/Funkin/pull/6621)
- Optimized rendering in the Character Select menu. ([2ecebf7](https://github.com/FunkinCrew/Funkin/commit/2ecebf79205a66b64148d64bbb3162c9fc073d85)) - by @MaybeMaru in [#6789](https://github.com/FunkinCrew/Funkin/pull/6789)
- [MOBILE] Tapping on a lock in Character Select now plays its reject animation. ([05148f0](https://github.com/FunkinCrew/Funkin/commit/05148f0e5dad4d60089e6074e616b583ba29a5e6)) - by @VirtuGuy in [#6779](https://github.com/FunkinCrew/Funkin/pull/6779)
- Hold note covers now follow when the strumline position is modified. ([77c6651](https://github.com/FunkinCrew/Funkin/commit/77c6651e245ea276b1bdf33e5d6732073dcb6037)) - by @MightyTheArmiddilo in [#6746](https://github.com/FunkinCrew/Funkin/pull/6746)
- The pause and game over screens no longer sometimes play the wrong character's themes. ([878644a](https://github.com/FunkinCrew/Funkin/commit/878644aee7ba425e482707b94b9f887ec23f6306)) - by @KoloInDaCrib in [#6812](https://github.com/FunkinCrew/Funkin/pull/6812)
- The game over camera focus point is now consistent, regardless of which animation was previously playing. ([18cceb4](https://github.com/FunkinCrew/Funkin/commit/18cceb4946a51fda0009d77baae1115437694415)) - by @KoloInDaCrib in [#6705](https://github.com/FunkinCrew/Funkin/pull/6705)
- Pico (Pixel) and other pixel characters now use RetroCameraFade as Boyfriend (Pixel) does. ([d1382aa](https://github.com/FunkinCrew/Funkin/commit/d1382aa985f97e3b40b0b629cb3d04301ebfb55e)) - by @afreetoplaynoob in [#6526](https://github.com/FunkinCrew/Funkin/pull/6526)
- [MOBILE] The back button can no longer exit during the Boyfriend fakeout death animation. ([9d06018](https://github.com/FunkinCrew/Funkin/commit/9d0601813e912de9e25a851ad9204a654316625a)) - by @ActualMandM in [#6917](https://github.com/FunkinCrew/Funkin/pull/6917)
- The song name text is now properly hidden at the beginning of the Results Screen animation. ([a5b15b9](https://github.com/FunkinCrew/Funkin/commit/a5b15b9424f16d8eadc7a92f1c355da647990c3a)) - by @NotHyper-474 and @Trayfellow in [#6931](https://github.com/FunkinCrew/Funkin/pull/6931)
- The sticker transition no longer covers the volume soundtray. ([616546d](https://github.com/FunkinCrew/Funkin/commit/616546d298a06c4135a32ffad41483be208552f1)) - by @VirtuGuy in [#6727](https://github.com/FunkinCrew/Funkin/pull/6727)
- Lightning now appears more regularly during South Erect and South (Pico Mix). ([9ca2092](https://github.com/FunkinCrew/funkin.assets/commit/9ca20929bc3dde6b07d74100c45fb45e48769c35)) - by @JackXson-Real in [funkin.assets#345](https://github.com/FunkinCrew/funkin.assets/pull/345)
- [HTML5] The city lights in the Week 3 stages now show up. ([603684f](https://github.com/FunkinCrew/funkin.assets/commit/603684ffb327f03d8216aaeaba143ca5f9cd77f0)) - by @VirtuGuy in [funkin.assets#342](https://github.com/FunkinCrew/funkin.assets/pull/342)
- The Week 3 Pico doppelganger cutscene background music no longer cuts off at the end. ([8ef58aa](https://github.com/FunkinCrew/funkin.assets/commit/8ef58aabdba8287d4c88808e2f0ecc0ac385b383)) - by @Trayfellow in [funkin.assets#349](https://github.com/FunkinCrew/funkin.assets/pull/349)
- The Story Mode cutscene before Stress now properly plays when viewed more than once. ([6ec45ec](https://github.com/FunkinCrew/funkin.assets/commit/6ec45ec82ca77188b1b2b9c58ada172f5c357103)) - by @NotHyper-474 in [funkin.assets#341](https://github.com/FunkinCrew/funkin.assets/pull/341)
- Darnell's can sound effects in 2hot no longer play twice with high offsets or when lagging. ([6315e25](https://github.com/FunkinCrew/funkin.assets/commit/6315e25eaaa8be4ca85e9b607f547595c699997a)) - by @JackXson-Real in [funkin.assets#354](https://github.com/FunkinCrew/funkin.assets/pull/354)
- [MOBILE] The cutscene after 2hot now properly accounts for different resolutions. ([dd3371a](https://github.com/FunkinCrew/Funkin/commit/dd3371a549f4e10f68f1a458f40ec1a342f07876)) - by @ActualMandM in [#6937](https://github.com/FunkinCrew/Funkin/pull/6937)
- Made the AttractState video skipping pie smoother. ([5a161b1](https://github.com/FunkinCrew/Funkin/commit/5a161b1d7342d7931950edf37554ce3a338736f9)) - by @PurSnake in [#6728](https://github.com/FunkinCrew/Funkin/pull/6728)
- The screenshot preview no longer breaks when changing states. ([dc78db8](https://github.com/FunkinCrew/Funkin/commit/dc78db8808a7ea205fe75eba006e4ec1c57a8190)) - by @Lasercar in [#6792](https://github.com/FunkinCrew/Funkin/pull/6792)
- Holding Ctrl and clicking on a hold note trail no longer crashes the Chart Editor (again). ([86ac336](https://github.com/FunkinCrew/Funkin/commit/86ac336d62a65fb420cdd6b1be739c3262d21159)) - by @Lasercar in [#6912](https://github.com/FunkinCrew/Funkin/pull/6912)
- Chart Editor tooltips no longer appear when hovering over a deleted note or event. ([091c18b](https://github.com/FunkinCrew/Funkin/commit/091c18bccd95b588ba0d4577a94d83acf5942417)) - by @KoloInDaCrib in [#6929](https://github.com/FunkinCrew/Funkin/pull/6929)
- Chart Editor vocal waveforms now render more accurately after BPM changes in the song. ([4e8f48d](https://github.com/FunkinCrew/Funkin/commit/4e8f48d5f0f1be4438c4ef9571137eaa35935f67)) - by @gamerbross in [#6833](https://github.com/FunkinCrew/Funkin/pull/6833)
- The Chart Editor vocal waveforms now display in the proper position regardless of the game's aspect ratio. ([1fb9040](https://github.com/FunkinCrew/Funkin/commit/1fb9040470432528a0441d7938d217e424ce27fd)) - by @Starexify in [#6193](https://github.com/FunkinCrew/Funkin/pull/6193)
- The second section number and divider now renders consistently in the Chart Editor. ([ac539bd](https://github.com/FunkinCrew/Funkin/commit/ac539bdf26ee7b5ecdcc52665c7c95287ef491c0)) - by @NotHyper-474 in [#6765](https://github.com/FunkinCrew/Funkin/pull/6765)
- The Chart Editor now saves the Show Results Screen setting. ([c893a73](https://github.com/FunkinCrew/Funkin/commit/c893a7320d72abd3743bc5c1ddeaecf073035eb1)) - by @MightyTheArmiddilo in [#6854](https://github.com/FunkinCrew/Funkin/pull/6854)
- Closing the game while in the Stage Editor no longer crashes the game. ([99cd4e2](https://github.com/FunkinCrew/Funkin/commit/99cd4e2cbd7fba87249b02b072a1e60f07c2c907)) - by @VirtuGuy in [#6775](https://github.com/FunkinCrew/Funkin/pull/6775)
- The onion skin now properly renders as transparent after changing characters in the Animation Editor. ([5c444f1](https://github.com/FunkinCrew/Funkin/commit/5c444f1109e5af04735a4383e577c69682b3713f)) - by @VirtuGuy in [#6545](https://github.com/FunkinCrew/Funkin/pull/6545)
- Blacklisted a class for security. ([3a113c2](https://github.com/FunkinCrew/Funkin/commit/3a113c270f92a6b14dfcda221124742437e1670a)) - by @charlesisfeline in [#6573](https://github.com/FunkinCrew/Funkin/pull/6573)
- Even more tiny fixes!



## [0.8.1] - 2026-01-04

### Added

- Added a new "Non-scoreable" notekind to the Chart Editor that doesn't affect scores and ranks, or play miss animations.

### Changed

- Changed the order in which events are dispatched in PlayState. ([16f3e03](https://github.com/FunkinCrew/Funkin/commit/16f3e038d80c37d016c9d2b6cdd1012c94ef88b9)) - by @ComedyLost in [#6606](https://github.com/FunkinCrew/Funkin/pull/6606)

### Fixed

- The last note of SPAGHETTI no longer counts toward scoring, allowing players to earn Perfect ranks.



## [0.8.0] - 2026-01-03

The LE SSERAFIM collab update!

### Added

- Added a new playable song: SPAGHETTI (feat. j-hope of BTS) (Clean ver.) by LE SSERAFIM (feat. j-hope)!
  - Try it out from either Story Mode or the Freeplay Menu!
- Added subtitles for various cutscenes and songs throughout the game.
  - This can be toggled in the Preferences menu.
- [MOBILE] Added support for Newgrounds logins and saving/loading from the cloud.
- [MOBILE] Added support for opening FNFC chart files through the filesystem.
- [MOBILE] Added haptics for tapping to begin on the Title Screen.
- [MOBILE] Added the back button to the Character Select menu.
- Added new function callbacks for Module scripts in Freeplay and Character Select.
- Added `getOtherNotes()` function for counting notes that are not of a certain notekind.
- Implemented stacked patches to JSON merging.
  - This allows mods to add new variations to existing songs without any extra fuss. See the [Code Cookbook](https://thekade.net/funkin-cookbook/) for more information.
- Added the ability to import Osu!Mania and StepMania charts in the Chart Editor.
- Added Move Difficulty and Clone Difficulty buttons to the Chart Editor Difficulty window.
- Added a checkbox to hide vocal waveforms in the Chart Editor.
- Added support for SRT subtitles that can display in game. ([a7fc70a](https://github.com/FunkinCrew/Funkin/commit/a7fc70a5c9cbd811b48cf2eb2f6c221814c2a3cd)) - by @PurSnake in [#6206](https://github.com/FunkinCrew/Funkin/pull/6206)
- Added support for various render types and scripting for the Freeplay DJ. ([8b38bcf](https://github.com/FunkinCrew/Funkin/commit/8b38bcfbdd9ef1b135046022b1b93eec5dedbd28)) - by @PurSnake and @AbnormalPoof in [#5698](https://github.com/FunkinCrew/Funkin/pull/5698)
- Level props can now have a flipX field. ([4961d4e](https://github.com/FunkinCrew/Funkin/commit/4961d4ee992445a487587dd3a7f3ab965eb4f5cf)) - by @Starexify in [#6218](https://github.com/FunkinCrew/Funkin/pull/6218)
- [LINUX] Added support for Feral Gamemode. ([555ec09](https://github.com/FunkinCrew/Funkin/commit/555ec09ef5be3c1d1966eeaa0275835e59aa5709)) - by @Noobz4Life in [#2473](https://github.com/FunkinCrew/Funkin/pull/2473)
- Added support for importing charts from Osu!Mania. ([0be42bf](https://github.com/FunkinCrew/Funkin/commit/0be42bf0475975d3195d4da85e653899df72a28c)) - by @FuroYT in [#6155](https://github.com/FunkinCrew/Funkin/pull/6155)
- Added a "No Animation" notekind to the Chart Editor. ([618e093](https://github.com/FunkinCrew/Funkin/commit/618e093e1ce2d4f45fa4da5d34ed84e58394126e)) - by @Eviethecoder in [#4036](https://github.com/FunkinCrew/Funkin/pull/4036)
- Added a way to adjust time signature/BPM changes through the Metadata window in the Chart Editor. ([b05a5c7](https://github.com/FunkinCrew/Funkin/commit/b05a5c7f54f9b41d63081837dd2c7392203b4530)) - by @Keoiki and @Lasercar in [#4770](https://github.com/FunkinCrew/Funkin/pull/4770)
- Added character preview windows for the player and opponent in the Chart Editor. ([9f59231](https://github.com/FunkinCrew/Funkin/commit/9f59231d58a889e2c9a0f8e7e30b2e1c370e0d9a)) - by @PurSnake and @ComedyLost in [#6221](https://github.com/FunkinCrew/Funkin/pull/6221)
- Added the option to view the Results Screen after Chart Editor playtests. ([eeba677](https://github.com/FunkinCrew/Funkin/commit/eeba677da9fac75cd34481ead01dc05dfa074bce)) - by @Lasercar in [#4087](https://github.com/FunkinCrew/Funkin/pull/4087)
- Added the option to carry over Chart Editor volume levels into a playtest. ([4dd87e7](https://github.com/FunkinCrew/Funkin/commit/4dd87e7308789bae9a9e903bb15737e8149012f7)) - by @KoloInDaCrib in [#6302](https://github.com/FunkinCrew/Funkin/pull/6302)
- Added the ability to time-travel during a Chart Editor playtest in release builds with PgUp and PgDown. ([4a00429](https://github.com/FunkinCrew/Funkin/commit/4a00429a57f03f60159a4e2e4f531bd6fa118658)) - by @AbnormalPoof in [#4209](https://github.com/FunkinCrew/Funkin/pull/4209)
- Added the Rift of the Necrodancer collab trailer to the pool of videos in Attract Mode.

### Changed

- The mod API version is now 0.8.0. Please update your mods to ensure they work.
- Made some improvements to Polymod:
  - Scripts can no longer accidentally redefine variables defined in their super class.
  - `Math` and `Std` can now properly be used in static functions. (Thanks NotHyper-474!)
  - Significantly improved the speed of retrieving modded assets, improving the performance of the game with a lot of mods installed. (Thanks PurSnake!)
- Replaced `FlxAnimate` with `flixel-animate` to overhaul texture atlas handling:
  - Significantly improved performance in the Character Select Menu.
  - Pico (holding Nene)’s game over confirm animation now plays properly.
  - The camera now properly focuses on atlas characters after restarting the song.
  - Atlas characters now properly display the rimlight shader.
  - Implemented multiple new settings for atlas sprites.
  - Fixed a ton of bugs across various menus.
- Re-exported many assets to improve memory usage and performance throughout the game.
- [MOBILE] Music from external sources now pauses when opening the game.
- [MOBILE] The game is now named “FNF” on the Home Screen.
- [DESKTOP] Reworked window resizing behavior to behave more consistently.
- Made it easier to implement custom Pause Menu substates.
- Pressing F6 (rebindable) now cycles through debug display modes.
- Boyfriend and Girlfriend’s scared animations in Week 2 now last longer.
- Added “Change difficulty” to the list of undo-able actions in the Chart Editor.
- Changed the default easing type for the Chart Editor Focus Camera event from Linear to Classic.
- The game now displays a user-friendly crash message when attempting to play without a graphics card. ([5270353](https://github.com/FunkinCrew/Funkin/commit/52703536a62fc004fb7be0457da89705f812364f)) - by @ACrazyTown in [#6160](https://github.com/FunkinCrew/Funkin/pull/6160)
- Adjusted strumline confirm animations when hitting notes to feel more responsive. ([62a3f73](https://github.com/FunkinCrew/Funkin/commit/62a3f73de9d653d4ca5a7d7f4c895fc9fd1a4be7)) - by @gamerbross in [#6261](https://github.com/FunkinCrew/Funkin/pull/6261)
- The Lag Adjustment menu now displays a note splash when hitting perfectly. ([342c3cd](https://github.com/FunkinCrew/Funkin/commit/342c3cd7d6f33b3babb70f3d1fb604b0bdb90464)) - by @ExtraCode75 in [#6602](https://github.com/FunkinCrew/Funkin/pull/6602)
- Freeplay song previews now fade out before restarting. ([aaf5084](https://github.com/FunkinCrew/Funkin/commit/aaf5084fd9e9c2d3b7e823767a93db82ce908d86)) - by @JVNpixels in [#6094](https://github.com/FunkinCrew/Funkin/pull/6094)
- The game's volume is now reduced when unfocused without pausing. ([3040692](https://github.com/FunkinCrew/Funkin/commit/30406928522f88762eab4bbf571fedf1424f7569)) - by @PurSnake in [#6250](https://github.com/FunkinCrew/Funkin/pull/6250)
- Optimized the way the windows in Week 3 are handled. ([70d433d](https://github.com/FunkinCrew/funkin.assets/commit/70d433de3027badb39027d295d1b18d20a130741)) - by @CrusherNotDrip in [funkin.assets#291](https://github.com/FunkinCrew/funkin.assets/pull/291)
- Script create events now also run after hot-reloading with F5, rather than only during initialization. ([2f865a5](https://github.com/FunkinCrew/Funkin/commit/2f865a5c7f4d8712f1b1e0bc70cb910f4fed08dc)) - by @VirtuGuy in [#6084](https://github.com/FunkinCrew/Funkin/pull/6084)
- Hot-reloading with F5 during a Chart Editor playtest no longer returns to the Chart Editor. ([c1988f1](https://github.com/FunkinCrew/Funkin/commit/c1988f1858344a78a82bf335774d986703cac942)) - by @KoloInDaCrib in [#6275](https://github.com/FunkinCrew/Funkin/pull/6275)
- Opening the Chart Editor during a song now places the playhead at the current song position. ([71b4a58](https://github.com/FunkinCrew/Funkin/commit/71b4a58cab821c3b5a530e3a2be6d73966faa2a6)) - by @KoloInDaCrib in [#6210](https://github.com/FunkinCrew/Funkin/pull/6210)
- The Easing property for Chart Editor events is now split into two separate dropdowns: type and direction. ([d1d77dd](https://github.com/FunkinCrew/Funkin/commit/d1d77dd85c3daed22ee954353fa41e81279ced3c)) - by @PurSnake in [#5612](https://github.com/FunkinCrew/Funkin/pull/5612)
- The Chart Editor Events window now supports collapsible groups. ([9f6879e](https://github.com/FunkinCrew/Funkin/commit/9f6879ecc98e725afa3de8f9b02755047b353cd7)) - by @KoloInDaCrib in [#6554](https://github.com/FunkinCrew/Funkin/pull/6554)
- Chart Editor BPM fields now support up to 3 decimal places. ([c863ef3](https://github.com/FunkinCrew/funkin.assets/commit/c863ef378569ce0d6b0804029e5d395b1c321cbd)) - by @roma-perec-bp in [funkin.assets#273](https://github.com/FunkinCrew/funkin.assets/pull/273)
- Long difficulty and variation names are now shortened in the Chart Editor playbar. ([2c4167b](https://github.com/FunkinCrew/Funkin/commit/2c4167bc11aec92693494816735063c381279b3e)) - by @Lasercar in [#6150](https://github.com/FunkinCrew/Funkin/pull/6150)
- The remaining time in the playbar now also shows a millisecond value in the Chart Editor. ([2d5ef19](https://github.com/FunkinCrew/Funkin/commit/2d5ef19b3b3c55db1eb70506b00d4f820e7ccb20)) - by @JVNpixels in [#6089](https://github.com/FunkinCrew/Funkin/pull/6089)
- Added more hotkeys to the Chart Editor user guide. ([7d0d9eb](https://github.com/FunkinCrew/funkin.assets/commit/7d0d9ebf7ea60e04d09c9b140772c36493dc6291)) - by @afreetoplaynoob in [funkin.assets#294](https://github.com/FunkinCrew/funkin.assets/pull/294)
- The Stage Editor can now be opened from Freeplay to the selected capsule's stage. ([1ff6a16](https://github.com/FunkinCrew/Funkin/commit/1ff6a1656cebdfe415768ffe38bd43b37c663eda)) - by @Lasercar in [#5264](https://github.com/FunkinCrew/Funkin/pull/5264)
- The Stage Editor now saves backups upon quitting or crashing. ([5326c40](https://github.com/FunkinCrew/Funkin/commit/5326c40347b1548a682ef1f79eeb4a70618256ff)) - by @Lasercar in [#6190](https://github.com/FunkinCrew/Funkin/pull/6190)
- Stage Editor backups are now saved in the same folder as Chart Editor backups. ([4f8da59](https://github.com/FunkinCrew/Funkin/commit/4f8da595777c4b7fe6ddf6536ffa29a50c23dcb3)) - by @CrusherNotDrip in [#6297](https://github.com/FunkinCrew/Funkin/pull/6297)

### Fixed

- Fixed some issues with Polymod:
  - Modded assets now properly go in their respective asset libraries. (Thanks NotHyper-474!)
  - Static functions and fields from imported scripted classes can now be used.
  - Properties can now be used in a static context.
  - Local variables in a function no longer get dropped if said function calls its own `scriptCall` function. (Thanks KoloInDaCrib!)
    - Local functions now properly report the class name.
- [DESKTOP] Switching audio devices no longer breaks audio processing.
- [HTML5] The Character Select Menu no longer crashes on Firefox.
- Pressing Escape and an arrow key with the Freeplay alternate instrumental selector open no longer crashes the game.
- Hot reloading with F5 on the Game Over screen no longer crashes the game.
- [HTML5] Restarting a video cutscene now properly plays the video again.
- [iOS] The navigation bar is no longer unlocked after watching an ad.
- [iOS] The “larger text” accessibility setting no longer causes the game to not fill the whole screen.
- [iOS] The game now displays error popups.
- [ANDROID] Taking a screenshot no longer pauses the game for a moment.
- The Title Screen no longer switches to Attract Mode while the Girlfriend’s Ringtone easter egg is playing.
- Holding Escape in the Main Menu no longer quickly closes the game.
- [MOBILE] Scrolling to another Week is no longer possible after entering a Story Week.
- [MOBILE] Long Freeplay capsule song names now properly scroll sideways.
- Exiting Character Select no longer allows mashing inputs in Freeplay.
- Controller inputs now register in the Character Select Menu.
- The player character in Character Select no longer slides in upon entering.
- The Character Select cursor no longer flies in from the top left corner.
- The Character Select cursor no longer continues to move without input after unfocusing the game.
- Video cutscenes no longer start at maximum volume for a split second.
- The input system now properly handles alternating between two keybinds bound to the same note.
- The camera now bops independently from the framerate during songs.
- The Pause Menu music now properly pauses when unfocusing with Pause on Unfocus enabled.
- Changing to the same difficulty as the current one during a Story Week no longer resets the Week score.
- More characters including parentheses now display properly in the Results Screen.
- [MOBILE] The rimlight for Girlfriend (Tankman Stickup) now renders properly.
- Character sprites with high global offsets no longer disappear near the edge of the screen.
- Fixed positions for Pico (Pixel) and Nene (Pixel), and removed the School (Pico) stage.
- Tweaked a few charts.
- [macOS] Fixed a crash related to notifications in the Chart Editor.
- [Windows] Opening the File Explorer no longer sometimes hangs in the Chart Editor.
- Pressing F4 to exit a debug editor before a tooltip appears no longer crashes the game.
- Changing the theme in the Chart Editor more than once no longer crashes the game.
- Unplugging a controller no longer crashes the Chart Editor.
- The Chart Editor measure ticks no longer cause a memory leak.
- Selecting multiple events by Ctrl-clicking in the Chart Editor no longer converts one into the other.
- Event tooltips now display all values including default ones.
- Pause on Unfocus now properly applies to Chart Editor playtests.
- Unfocusing while the Chart Editor is playing audio now pauses the playback.
- Fixed a memory leak with the Freeplay backing card scrolling text. ([67846d6](https://github.com/FunkinCrew/Funkin/commit/67846d6c4bfd2f42e002fa129a51772f0717329d)) - by @FuroYT in [#5963](https://github.com/FunkinCrew/Funkin/pull/5963)
- Using a static pixel icon in Character Select no longer crashes the game. ([96f8ee8](https://github.com/FunkinCrew/Funkin/commit/96f8ee85e0c2281834b7334b87d1862003e5fa05)) - by @VirtuGuy in [#6171](https://github.com/FunkinCrew/Funkin/pull/6171)
- A-Bot's visualizer no longer causes a memory leak during gameplay or in Character Select. ([6607645](https://github.com/FunkinCrew/Funkin/commit/6607645786ed8611436fa5f92a35027c2a64f1d0)) - by @FuroYT in [#5908](https://github.com/FunkinCrew/Funkin/pull/5908)
- The Credits menu no longer crashes when not using hardcoded credits. ([4366fbe](https://github.com/FunkinCrew/Funkin/commit/4366fbe51274438ad2bc190afcca42e37987386d)) - by @sphis-sinco in [#5982](https://github.com/FunkinCrew/Funkin/pull/5982)
- The game no longer lag spikes when Darnell throws his can in 2hot. ([a0bc6d6](https://github.com/FunkinCrew/funkin.assets/commit/a0bc6d61fde5799a7fc619b7fdea691b0d8bae05)) - by @KoloInDaCrib in [funkin.assets#313](https://github.com/FunkinCrew/funkin.assets/pull/313)
- Hold note covers no longer get permanently stuck playing after a lag spike. ([66882d9](https://github.com/FunkinCrew/Funkin/commit/66882d9677268396320ee003478a3e2627655755)) - by @KoloInDaCrib in [#6066](https://github.com/FunkinCrew/Funkin/pull/6066)
- Scrolling through Freeplay songs for the first time no longer stutters. ([cc486ad](https://github.com/FunkinCrew/Funkin/commit/cc486ad94b5e9806d18fb65165663fea0ce0d7b4)) - by @mikolka9144 in [#4851](https://github.com/FunkinCrew/Funkin/pull/4851)
- Re-implemented an error that appears when a video file does not exist. ([2ad5933](https://github.com/FunkinCrew/Funkin/commit/2ad593341f8bea8384646f4803dc8795a9efe32a)) - by @TechnikTil in [#6253](https://github.com/FunkinCrew/Funkin/pull/6253)
- [ANDROID] Keyboard detection and strumline positioning now work properly. ([5763ae5](https://github.com/FunkinCrew/Funkin/commit/5763ae5b728359c5639bbc578f15b65a16fa57b1)) - by @NotHyper-474 in [#6328](https://github.com/FunkinCrew/Funkin/pull/6328)
- The game now properly parses .json files beginning with a bracket. ([c7367ae](https://github.com/FunkinCrew/Funkin/commit/c7367ae33d7e11f57b821f7d5fbff39a3edc1604)) - by @NotHyper-474 in [#6164](https://github.com/FunkinCrew/Funkin/pull/6164)
- The Newgrounds logo no longer covers the intro text. ([28883fb](https://github.com/FunkinCrew/Funkin/commit/28883fb9ed025abf9f9aee2621f365cd6f4d8b6c)) - by @hucks5 in [#6196](https://github.com/FunkinCrew/Funkin/pull/6196)
- Exiting from the Save Data Options menu no longer exits the Options Menu as well. ([26b253d](https://github.com/FunkinCrew/Funkin/commit/26b253d8cac97f0dcd09a5ef233f7058cd26008e)) - by @VirtuGuy in [#6036](https://github.com/FunkinCrew/Funkin/pull/6036)
- Numeric values in the Options Menu are now rounded to prevent near-zero precision errors. ([934bce7](https://github.com/FunkinCrew/Funkin/commit/934bce7bdc5780e09623d845eda97a27c0ad0ecf)) - by @Starexify in [#6225](https://github.com/FunkinCrew/Funkin/pull/6225)
- The Test/Offset Calibration menu no longer starts playing after exiting the Lag Adjustment menu. ([23a38f7](https://github.com/FunkinCrew/Funkin/commit/23a38f76f9c79c5fab5b9af5e2d98e51597e05a8)) - by @VioletSnowLeopard in [#6088](https://github.com/FunkinCrew/Funkin/pull/6088)
- [MOBILE] The Back button now fades out when entering a Week in Story Mode. ([1ebce74](https://github.com/FunkinCrew/Funkin/commit/1ebce748d4e3306b4464a7bf82fab56bcb427a62)) - by @VirtuGuy in [#6255](https://github.com/FunkinCrew/Funkin/pull/6255)
- The Freeplay difficulty can now only be changed in one direction at a time. ([95af46c](https://github.com/FunkinCrew/Funkin/commit/95af46cbf72291d9d3226df91ed17f1aa3d3839f)) - by @Starexify in [#6262](https://github.com/FunkinCrew/Funkin/pull/6262)
- Pico's backing card now renders properly in widescreen aspect ratios. ([aa29b3d](https://github.com/FunkinCrew/funkin.assets/commit/aa29b3dcc1ee2f8e89d2622c480b2e997410d57d)) - by @VirtuGuy in [funkin.assets#297](https://github.com/FunkinCrew/funkin.assets/pull/297)
- The album titles in Freeplay are now positioned consistently. ([ed8cca4](https://github.com/FunkinCrew/funkin.assets/commit/ed8cca4694a098ae6aa56c4d2a231587edb9688c)) - by @Donothan73 in [funkin.assets#257](https://github.com/FunkinCrew/funkin.assets/pull/257)
- Health icons now bop independently from the framerate. ([8e6fa51](https://github.com/FunkinCrew/Funkin/commit/8e6fa51c27ceaa830efec06bb8a52e281a008255)) - by @PurSnake in [#6035](https://github.com/FunkinCrew/Funkin/pull/6035)
- The note resetting animation on song restart is now consistent between Downscroll and Upscroll. ([7b8d657](https://github.com/FunkinCrew/Funkin/commit/7b8d6577eddba568f20c3d23663dded054699090)) - by @FuroYT in [#6220](https://github.com/FunkinCrew/Funkin/pull/6220)
- Offsets are now properly applied to stage props. ([33a020a](https://github.com/FunkinCrew/Funkin/commit/33a020a34bb220f56c0ff9fbad8688e10ca5b44f)) - by @Starexify in [#6224](https://github.com/FunkinCrew/Funkin/pull/6224)
- Notestyles now accept offset values. ([193c443](https://github.com/FunkinCrew/Funkin/commit/193c443bc47c1a7d1481d280a1d0674b920a323c)) - by @NebulaStellaNova in [#6326](https://github.com/FunkinCrew/Funkin/pull/6326)
- The path for a notestyle's countdown sound is now properly loaded as a sound instead of an image. ([dd5ea77](https://github.com/FunkinCrew/Funkin/commit/dd5ea7748b3b1878139998c209aa06db0fa05e0b)) - by @gamerbross in [#6232](https://github.com/FunkinCrew/Funkin/pull/6232)
- The Pause Menu theme no longer plays at maximum volume for a split second when pausing. ([6ba44d6](https://github.com/FunkinCrew/Funkin/commit/6ba44d6cb0c71deb29eb23b82b61f58b2e95193e)) - by @ComedyLost in [#6334](https://github.com/FunkinCrew/Funkin/pull/6334)
- The scrolling text in the Results Screen is now positioned consistently. ([200f798](https://github.com/FunkinCrew/Funkin/commit/200f7984379cb1bd911e49de92be312750893420)) - by @NotHyper-474 in [#6595](https://github.com/FunkinCrew/Funkin/pull/6595)
- The scrolling text in the Results Screen is now FPS-independent. ([8c43f6f](https://github.com/FunkinCrew/Funkin/commit/8c43f6f67a362bde4de4ad8dbd72966d7c4a9f60)) - by @VirtuGuy in [#6476](https://github.com/FunkinCrew/Funkin/pull/6476)
- The Results Screen theme now loops more smoothly. ([592bf1a](https://github.com/FunkinCrew/Funkin/commit/592bf1a9221d4dcef53ae421571eddf78ed631e4)) - by @FuroYT in [#6477](https://github.com/FunkinCrew/Funkin/pull/6477)
- Transition stickers now render properly with the window resized to any aspect ratio. ([4215b1c](https://github.com/FunkinCrew/Funkin/commit/4215b1c72e4391b2176014825885799b81dde2ba)) - by @PurSnake in [#6156](https://github.com/FunkinCrew/Funkin/pull/6156)
- Boyfriend now stands in the same position in the Week 3 and Week 3 Erect stages. ([d2d15f1](https://github.com/FunkinCrew/funkin.assets/commit/d2d15f114256125d53c6331b46415701ae291c1f)) - by @CEliuxJV in [funkin.assets#261](https://github.com/FunkinCrew/funkin.assets/pull/261)
- Pico's game over music now properly loops after his explosion death in 2hot. ([f1a1db0](https://github.com/FunkinCrew/Funkin/commit/f1a1db08347c3f9248fd16909cff06027297ad13)) - by @KoloInDaCrib in [#6216](https://github.com/FunkinCrew/Funkin/pull/6216)
- 2hot now smoothly transitions into the cutscene. ([462b1b6](https://github.com/FunkinCrew/funkin.assets/commit/462b1b6e6e9b622ad8fd15f15a1f39c7dffa4764)) - by @hucks5 in [funkin.assets#286](https://github.com/FunkinCrew/funkin.assets/pull/286)
- Nene now swings her legs during in-game cutscenes. ([6a5d9b2](https://github.com/FunkinCrew/funkin.assets/commit/6a5d9b265732d60da28083fb1c3d7b7b854edf63)) - by @hucks5 in [funkin.assets#289](https://github.com/FunkinCrew/funkin.assets/pull/289)
- Nene's 50 combo animation now renders its heart properly. ([bcd96ee](https://github.com/FunkinCrew/funkin.assets/commit/bcd96eeb78b9b03cf7b24dc956ac3bc36438193e)) - by @VirtuGuy in [funkin.assets#296](https://github.com/FunkinCrew/funkin.assets/pull/296)
- A-Bot (Christmas) now properly looks at the opponent. ([f81cc16](https://github.com/FunkinCrew/funkin.assets/commit/f81cc16c8f99655f76b7e27ce221819798c9c94e)) - by @ComedyLost in [funkin.assets#279](https://github.com/FunkinCrew/funkin.assets/pull/279)
- Nene (Pixel) now raises and lowers her knife properly. ([1d9f50d](https://github.com/FunkinCrew/funkin.assets/commit/1d9f50d405f202e07efd883aeef5d6c1e9eaaa90)) - by @VirtuGuy in [funkin.assets#274](https://github.com/FunkinCrew/funkin.assets/pull/274)
- Pico (Pixel)'s game over theme now plays at the right time. ([e8a4d24](https://github.com/FunkinCrew/funkin.assets/commit/e8a4d2472ca2dc28b03be05953dff3d7b5ec7433)) - by @JackXson-Real and @ComedyLost in [funkin.assets#288](https://github.com/FunkinCrew/funkin.assets/pull/288)
- Pico holding Nene's idle animation no longer lasts too long. ([3483345](https://github.com/FunkinCrew/funkin.assets/commit/348334583746ec45f1c6ab2c5e1715a67038cc5c)) - by @JackXson-Real in [funkin.assets#271](https://github.com/FunkinCrew/funkin.assets/pull/271)
- The tankmen in Stress no longer briefly appear behind the speakers when restarting. ([7f79ad8](https://github.com/FunkinCrew/funkin.assets/commit/7f79ad8c08d66fb909a9382de2c09f0430b756f1)) - by @VirtuGuy in [funkin.assets#298](https://github.com/FunkinCrew/funkin.assets/pull/298)
- Encountering a Set Health Icon event during Minimal playtesting no longer crashes the Chart Editor. ([9f0a498](https://github.com/FunkinCrew/Funkin/commit/9f0a4988a3cc47581916a9750731bb7e63f168f3)) - by @charlesisfeline in [#6481](https://github.com/FunkinCrew/Funkin/pull/6481)
- Typing in Chart Editor text fields no longer triggers bound key functions. ([3b5e589](https://github.com/FunkinCrew/Funkin/commit/3b5e5893c01c2b56036e53626eaea8d41e70f640)) - by @MightyTheArmiddilo in [#6601](https://github.com/FunkinCrew/Funkin/pull/6601)
- Clicking between Chart Editor events no longer converts the second event's dropdown values into those of the first. ([c170c25](https://github.com/FunkinCrew/Funkin/commit/c170c256934ae316a735d38620ad5e24c2f15f4d)) - by @NotHyper-474 in [#6211](https://github.com/FunkinCrew/Funkin/pull/6211)
- Chart Editor note kinds no longer lose their data when selecting multiple notes with different data. ([5a2c364](https://github.com/FunkinCrew/Funkin/commit/5a2c364c507fb4b86a740c3b2476c336496cd729)) - by @Lasercar in [#4248](https://github.com/FunkinCrew/Funkin/pull/4248)
- Placing a note and removing it no longer breaks the cursor in the Chart Editor. ([8cb5ed9](https://github.com/FunkinCrew/Funkin/commit/8cb5ed91baf50b6f78eefc2e50612a01195a2742)) - by @Lasercar in [#4237](https://github.com/FunkinCrew/Funkin/pull/4237)
- Playtesting in the Chart Editor now properly loads song variation scripts. ([055f620](https://github.com/FunkinCrew/Funkin/commit/055f62026ef44a928876d9065cc388da0905e9f1)) - by @PurSnake in [#6405](https://github.com/FunkinCrew/Funkin/pull/6405)
- Playtesting in the Chart Editor no longer sometimes moves on to another song like Story Mode. ([9497378](https://github.com/FunkinCrew/Funkin/commit/9497378600bad44639ff8b3fc92cb329052fd08a)) - by @KoloInDaCrib in [#6192](https://github.com/FunkinCrew/Funkin/pull/6192)
- The cursor is now hidden when playtesting through the Chart Editor. ([0471872](https://github.com/FunkinCrew/Funkin/commit/047187257b6712e61bf05fdebab33c7b3e9ac0f6)) - by @VirtuGuy in [#6137](https://github.com/FunkinCrew/Funkin/pull/6137)
- The Chart Editor note moving sound no longer plays when dragging outside the grid. ([593456e](https://github.com/FunkinCrew/Funkin/commit/593456e53e02c53e71189fdb154e4a3e4f2b3092)) - by @amyspark-ng in [#4157](https://github.com/FunkinCrew/Funkin/pull/4157)
- The Chart Editor music now fades in after a period of silence when enabled. ([960d2f3](https://github.com/FunkinCrew/Funkin/commit/960d2f3cf166400c6fecee212b87961f3df10c2e)) - by @Lasercar in [#4148](https://github.com/FunkinCrew/Funkin/pull/4148)
- The Chart Editor Difficulty toolbox no longer displays the incorrect song name. ([dff2a1e](https://github.com/FunkinCrew/Funkin/commit/dff2a1e487dc20f86ef4f526a259083a7726ea6a)) - by @VirtuGuy in [#6547](https://github.com/FunkinCrew/Funkin/pull/6547)
- Chart Editor notifications now display a bit higher. ([9e645db](https://github.com/FunkinCrew/Funkin/commit/9e645db0074424ffb2de42b27afb3adaff55de62)) - by @MightyTheArmiddilo in [#6445](https://github.com/FunkinCrew/Funkin/pull/6445)
- The Yes and No text in the Chart Editor exit confirmation prompt buttons now always render properly. ([4c0d925](https://github.com/FunkinCrew/Funkin/commit/4c0d92507ae0b81a744d223e5292bf8d27013abd)) - by @NotHyper-474 in [#6173](https://github.com/FunkinCrew/Funkin/pull/6173)
- Exiting the Chart Editor now consistently saves your audio preferences. ([2f77ccf](https://github.com/FunkinCrew/Funkin/commit/2f77ccfc6e93fabef27d3e06447f9f6edd8e840d)) - by @VioletSnowLeopard in [#6127](https://github.com/FunkinCrew/Funkin/pull/6127)
- The Chart Editor and Stage Editor backup window now properly retrieves the most recently edited backup. ([a8dec0c](https://github.com/FunkinCrew/Funkin/commit/a8dec0cd7053f88865757f30a7d9f0ca5eb0fb02)) - by @Lasercar in [#6119](https://github.com/FunkinCrew/Funkin/pull/6119)
- The Chart Editor backup dialog no longer appears if the latest backup is deleted. ([bc1d36d](https://github.com/FunkinCrew/Funkin/commit/bc1d36ddeab81a790e3604598248a9b2fe869cac)) - by @KoloInDaCrib in [#6027](https://github.com/FunkinCrew/Funkin/pull/6027)
- Switching between Animation and Spritesheet mode no longer crashes the Animation Editor. ([a61016d](https://github.com/FunkinCrew/Funkin/commit/a61016d2dfc2ac6a50aae230969c036f0753cfaa)) - by @VirtuGuy in [#6114](https://github.com/FunkinCrew/Funkin/pull/6114)
- The Animation Editor no longer displays a missing object icon next to the dropdown menus. ([b30ea36](https://github.com/FunkinCrew/Funkin/commit/b30ea36fcc982ce4ac0be9143fd4701e180fc684)) - by @KoloInDaCrib in [#6177](https://github.com/FunkinCrew/Funkin/pull/6177)
- The Animation Editor onion skin now properly accounts for character scale and offsets. ([a76a868](https://github.com/FunkinCrew/Funkin/commit/a76a868cb6a27c1c76d09177b90cf6df3df29d17)) - by @VirtuGuy in [#6123](https://github.com/FunkinCrew/Funkin/pull/6123)
- The debug cursor is now properly hidden when exiting the Animation Editor. ([f2f6b4c](https://github.com/FunkinCrew/Funkin/commit/f2f6b4c8591e1ab4a8c6f0ed998d6d25d7cc9f43)) - by @VirtuGuy in [#6112](https://github.com/FunkinCrew/Funkin/pull/6112)
- Plenty more tiny fixes.

## New Contributors for 0.8.0

* @Eviethecoder made their first contribution in [#4036](https://github.com/FunkinCrew/Funkin/pull/4036)
* @FuroYT made their first contribution in [#5908](https://github.com/FunkinCrew/Funkin/pull/5908)
* @HeroEyad made their first contribution in [#6049](https://github.com/FunkinCrew/Funkin/pull/6049)
* @hucks5 made their first contribution in [#6196](https://github.com/FunkinCrew/Funkin/pull/6196)
* @Starexify made their first contribution in [#6225](https://github.com/FunkinCrew/Funkin/pull/6225)
* @NebulaStellaNova made their first contribution in [#6326](https://github.com/FunkinCrew/Funkin/pull/6326)
* @MightyTheArmiddilo made their first contribution in [#6445](https://github.com/FunkinCrew/Funkin/pull/6445)
* @Donothan73 made their first contribution in [funkin.assets#257](https://github.com/FunkinCrew/funkin.assets/pull/257)
* @CEliuxJV made their first contribution in [funkin.assets#261](https://github.com/FunkinCrew/funkin.assets/pull/261)
* @roma-perec-bp made their first contribution in [funkin.assets#273](https://github.com/FunkinCrew/funkin.assets/pull/273)
* @ComedyLost made their first contribution in [funkin.assets#279](https://github.com/FunkinCrew/funkin.assets/pull/279)



## [0.7.5] - 2025-09-19

### Added

- Added an `onStateCreate` event to the Module class.

### Changed

- Gave the debug display a huge upgrade!
  - Choose from three settings in the Preferences Menu: Off/Simple/Advanced
  - New “Task memory” counter shows how much RAM the game is using on your computer.
  - Advanced mode displays graphs for FPS and RAM usage.
- Hot reloading now works in scripted states.
- Made a few more classes scriptable.
  - FunkinVideoSprite
  - FlxStrip
  - FlxTypedGroup
  - Strumline
  - StageProp​​
- The Random capsule now brings up the option to select a random instrumental. ([0d5c6ac](https://github.com/FunkinCrew/Funkin/commit/0d5c6ac9632ee3bf3977b9bd369daab9f2d95fea)) - by @VioletSnowLeopard in [#5891](https://github.com/FunkinCrew/Funkin/pull/5891)
- The Character Select menu now returns to Freeplay after pressing a back button. ([250d218](https://github.com/FunkinCrew/Funkin/commit/250d2188b9cb2c92d283d8b12ed7de0286324592)) - by @MrMadera in [#5887](https://github.com/FunkinCrew/Funkin/pull/5887)
- Pressing the Shift key in the Credits menu now pauses scrolling. ([479036a](https://github.com/FunkinCrew/Funkin/commit/479036a4008fe1c54adc970c0a476fae6b1b3e94)) - by @JVNpixels in [#2924](https://github.com/FunkinCrew/Funkin/pull/2924)
- Chart Editor and Stage Editor backup files are now given relevant filenames. ([b31be10](https://github.com/FunkinCrew/Funkin/commit/b31be1043ccd1e906a656913b947bae160b451fe)) - by @Lasercar in [#4118](https://github.com/FunkinCrew/Funkin/pull/4118)
- The Animation Editor's onion skin now properly accounts for offsets and displays the idle animation. ([0fd6f5b](https://github.com/FunkinCrew/Funkin/commit/0fd6f5b3b7bd115a3b6821096daa929c220bd235)) - by @KoloInDaCrib in [#5810](https://github.com/FunkinCrew/Funkin/pull/5810)

### Fixed

- The Freeplay new rank animation now shows the new rank slamming onto the old one.
- Freeplay capsules with a Gold Perfect rank no longer become randomly offset when scrolling.
- The Pico Freeplay DJ’s new rank animation now properly renders its lighting.
- Freeplay song previews no longer play replaced or deleted audio files.
- The strumline no longer disappears after re-entering Lag Adjustment.
- Fixed various issues with Week 6 dialogue boxes, portraits, and audio.
- [MOBILE] The strumlines are no longer offset to the left in Blazin’.
- The preloader no longer disables fullscreen mode after completion.
- Attempting to log in to Newgrounds during an ongoing login attempt no longer crashes the game. ([4e572b1](https://github.com/FunkinCrew/Funkin/commit/4e572b171fe901a84f12b4566963fd3c1f4ae6fb)) - by @KoloInDaCrib in [#5922](https://github.com/FunkinCrew/Funkin/pull/5922)
- Added null-safety to Leaderboards and Medals to prevent a rare crash. ([88fc5f9](https://github.com/FunkinCrew/Funkin/commit/88fc5f9ed684e287d7411a59fb4fdf170acfed5a)) - by @NotHyper-474 in [#5926](https://github.com/FunkinCrew/Funkin/pull/5926)
- Freeplay ranks no longer pop out when scrolling through song capsules. ([747446e](https://github.com/FunkinCrew/Funkin/commit/747446e2e420449f422fbc69aafda6128ac8d16e)) - by @VioletSnowLeopard in [#5822](https://github.com/FunkinCrew/Funkin/pull/5822)
- The Freeplay intro no longer plays when returning from a sticker transition. ([63ec749](https://github.com/FunkinCrew/Funkin/commit/63ec749c7a3c90d529e9e8f2f3ed1c8913e8f9a1)) - by @PurSnake in [#5942](https://github.com/FunkinCrew/Funkin/pull/5942)
- Hot-reloading with F5 after earning a rank no longer crashes Freeplay. ([79e8b5d](https://github.com/FunkinCrew/Funkin/commit/79e8b5d71e052953b77b81b66e0a83a7bbeeeeed)) - by @KoloInDaCrib in [#5971](https://github.com/FunkinCrew/Funkin/pull/5971)
- The Main Menu music now fades in consistently when exiting from Freeplay to the Title Screen. ([a10bbf6](https://github.com/FunkinCrew/Funkin/commit/a10bbf60acbbeadfb5a91930745ef4fd338b1a24)) - by @VirtuGuy in [#5855](https://github.com/FunkinCrew/Funkin/pull/5855)
- The game now falls back to default audio files when files specified by the metadata don't exist. ([b5357ac](https://github.com/FunkinCrew/Funkin/commit/b5357acf98bde81a4121a3723061f7c559a0640f)) - by @VioletSnowLeopard in [#5954](https://github.com/FunkinCrew/Funkin/pull/5954)
- The cutscene pause menu no longer persists across songs after exiting a video cutscene. ([c2305f3](https://github.com/FunkinCrew/Funkin/commit/c2305f32f0147f6326e8665d21a6b8a793f45033)) - by @KoloInDaCrib in [#5880](https://github.com/FunkinCrew/Funkin/pull/5880)
- Mashing to skip the Eggnog Erect cutscene no longer crashes the game. ([5ca3c6a](https://github.com/FunkinCrew/funkin.assets/commit/5ca3c6a5745b61a457db149c289784c08e560ee9)) - by @VioletSnowLeopard in [funkin.assets#258](https://github.com/FunkinCrew/funkin.assets/pull/258)
- Stress (Pico Mix) no longer lag spikes when loading in the background tankmen. ([6701405](https://github.com/FunkinCrew/funkin.assets/commit/670140571239ca08c1ae1c5286773d99c2875c2d)) - by @NotHyper-474 and @KoloInDaCrib in [funkin.assets#242](https://github.com/FunkinCrew/funkin.assets/pull/242)
- Stress (Pico Mix) no longer lag spikes when Tankman changes sprites. ([aa5956a](https://github.com/FunkinCrew/Funkin/commit/aa5956a30bdc47d53ebebb4b61a7ebb3f04c7dc6)) - by @NotHyper-474 in [#5939](https://github.com/FunkinCrew/Funkin/pull/5939)
- The bricks in Stress (Pico Mix) no longer move after restarting the song. ([9cfee03](https://github.com/FunkinCrew/Funkin/commit/9cfee0398a057567f80ad68ff6052964da63af09)) - by @VirtuGuy in [#5875](https://github.com/FunkinCrew/Funkin/pull/5875)
- Pico now properly shoots after restarting Stress. ([b0ef0d3](https://github.com/FunkinCrew/funkin.assets/commit/b0ef0d352c199e93903652a95ffdf16a3dc2d569)) - by @7oltan in [funkin.assets#254](https://github.com/FunkinCrew/funkin.assets/pull/254)
- A-Bot's visualizer now zeroes out when restarting the song. ([ba3a8b0](https://github.com/FunkinCrew/funkin.assets/commit/ba3a8b0cbbf785a0729dcf85e25b6e59c0c12657)) - by @KoloInDaCrib in [funkin.assets#246](https://github.com/FunkinCrew/funkin.assets/pull/246)
- Notekinds now properly receive dispatched events last in PlayState. ([89b2b7f](https://github.com/FunkinCrew/Funkin/commit/89b2b7fcc3130db0af1f782594af72ae1f4ce320)) - by @Az989YT in [#5936](https://github.com/FunkinCrew/Funkin/pull/5936)
- Text from .json files is now properly sanitized before it is parsed. ([80d7ace](https://github.com/FunkinCrew/Funkin/commit/80d7ace714efb729cb8f1b23b61fdab4ac655275)) - by @KoloInDaCrib in [#5108](https://github.com/FunkinCrew/Funkin/pull/5108)
- Fixed a crash when exiting the Chart Editor after interacting with a text field. ([f85f2f0](https://github.com/FunkinCrew/Funkin/commit/f85f2f03d97fc1332275f088ddce2b4056f0ded2)) - by @NotHyper-474 in [#5992](https://github.com/FunkinCrew/Funkin/pull/5992)
- Fixed some issues with variation handling in the Chart Editor. ([970ccf2](https://github.com/FunkinCrew/Funkin/commit/970ccf2f4a9b5802b70d0b3c269c8b9e541d53f2)) - by @NotHyper-474 in [#4396](https://github.com/FunkinCrew/Funkin/pull/4396)
- Audio no longer plays when dragging a playhead in the Chart Editor. ([2d95754](https://github.com/FunkinCrew/Funkin/commit/2d95754d492da06920d56de2b2bcbb9b81182af0)) - by @Lasercar in [#4140](https://github.com/FunkinCrew/Funkin/pull/4140)
- The Chart Editor Offsets window song preview no longer continues playing during playtesting. ([11eb406](https://github.com/FunkinCrew/Funkin/commit/11eb4060d03b18a2f3604297eb9a24e54077fe3c)) - by @PurSnake and @Lasercar in [#5973](https://github.com/FunkinCrew/Funkin/pull/5973)
- The fullscreen keybind no longer triggers when typing in a field. ([4ebd00b](https://github.com/FunkinCrew/Funkin/commit/4ebd00bc06a5c94e935f557ba14ba9729faec104)) - by @lemz1 in [#4131](https://github.com/FunkinCrew/Funkin/pull/4131)
- The Stage Editor new stage menu can no longer be opened multiple times at once. ([47b1cee](https://github.com/FunkinCrew/Funkin/commit/47b1cee6d5ee37cd18146ca8098da85610c6b544)) - by @VioletSnowLeopard in [#5873](https://github.com/FunkinCrew/Funkin/pull/5873)
- Adjusted the save hotkeys in the Animation Editor to be usable on Windows. ([8ead5ee](https://github.com/FunkinCrew/Funkin/commit/8ead5eeb0840756a843fdcf0f3f347b087e7182d)) - by @VioletSnowLeopard in [#5974](https://github.com/FunkinCrew/Funkin/pull/5974)
- A few more tiny fixes.

## New Contributors for 0.7.5

* @Az989YT made their first contribution in [#5936](https://github.com/FunkinCrew/Funkin/pull/5936)



## [0.7.4] - 2025-09-01

### Added

- [MOBILE] Added haptics to the can explosion in 2hot.
- Added the `scorable` property to notekinds, which excludes them from tallies.
- Added saving and loading save data using Newgrounds! Check out the new "Save Data Options" button in the Options menu after logging in. ([832f013](https://github.com/FunkinCrew/Funkin/commit/832f01345f441631a5372dbc3382dc8a13c150d6)) - by @TechnikTil in [#4900](https://github.com/FunkinCrew/Funkin/pull/4900)
- Added variation-specific song scripts, improving compatibility between mods. ([c94d6bb](https://github.com/FunkinCrew/Funkin/commit/c94d6bbb6640f7a9fbce8a202fbecf19d36da2f7)) - by @AbnormalPoof in [#5165](https://github.com/FunkinCrew/Funkin/pull/5165)
- Added scoped modules, which only run in a specified state. ([842ec2c](https://github.com/FunkinCrew/Funkin/commit/842ec2c1cd0243741170c431e4095bad2a4842e0)) - by @AbnormalPoof in [#5138](https://github.com/FunkinCrew/Funkin/pull/5138)
- Added ModStore, a helper class that stores data across hot reloads until the game is closed. ([3170346](https://github.com/FunkinCrew/Funkin/commit/3170346b83e5f73a88b3e7135e75ec1be2384929)) - by @cyn0x8 in [#4230](https://github.com/FunkinCrew/Funkin/pull/4230)
- Added hotkeys to toggle individual audio tracks in the Chart Editor. ([1e1b564](https://github.com/FunkinCrew/Funkin/commit/1e1b5643a8536a3061a237e058c45223b66039da)) - by @Lasercar in [#4247](https://github.com/FunkinCrew/Funkin/pull/4247)
- Added visual indicators and tooltips for notekinds. ([32c775e](https://github.com/FunkinCrew/Funkin/commit/32c775ef3f131accd69a04591608420919a607a1)) - by @KoloInDaCrib in [#5284](https://github.com/FunkinCrew/Funkin/pull/5284)
- Added a Charter field to the New Chart dialog in the Chart Editor. ([23b163c](https://github.com/FunkinCrew/Funkin/commit/23b163cb69ffbb8d2ae1c12d965a6ed3a26020e0)) - by @NotHyper-474 in [#5657](https://github.com/FunkinCrew/Funkin/pull/5657)
- Added a Song ID field to the Chart Editor metadata toolbox. ([55f9d24](https://github.com/FunkinCrew/funkin.assets/commit/55f9d24e9dc475b981e4cc087101425e85d3c1e2)) - by @cyn0x8 in [funkin.assets#229](https://github.com/FunkinCrew/funkin.assets/pull/229)
- Added a confirmation prompt when exiting the Chart Editor with an unsaved chart. ([e6d7371](https://github.com/FunkinCrew/Funkin/commit/e6d737125e0031d1efabc73266dfbde6d6c758de)) - by @anysad in [#5091](https://github.com/FunkinCrew/Funkin/pull/5091)
- [ANDROID] Added support for monochrome icons on Android 12 and above. ([5de4e76](https://github.com/FunkinCrew/Funkin/commit/5de4e766b7317c50d3ae40b9525b7c391984d52c)) - by @ThatOneCalculator in [#5507](https://github.com/FunkinCrew/Funkin/pull/5507)

### Changed

- Reworked the Conductor to make note scrolling smoother.
- Reworked Attract Mode.
  - The Title Screen fades out and plays a video after a certain amount of time.
  - The video alternates between the Mobile Trailer and the BOYFRIEND EVERYWHERE music video, replacing the previous toy commercial.
- The “Input Offsets” menu is now named “Lag Adjustment”.
- Freeplay difficulty dots are now displayed as rows of eight when modded difficulties are present.
- Optimized the way the game searches for Freeplay pixel icons.
- Results Screen and game over haptics are now softcoded.
- [WINDOWS] The window title bar now matches the system theme, light or dark.
- [LINUX] The game now displays with an icon.
- [iOS] The edges of the app icon are now properly filled in.
- Made several improvements and fixes to Polymod and HScript:
  - Significantly optimized mod loading, especially with many installed at once. (Thanks KoloInDaCrib!)
  - Fixed several cases where script variables would be lost. (Thanks NotHyper-474!)
  - Zip mod loading on Linux is now case-insensitive. (Thanks NotHyper-474!)
  - Added the ability to import scripted classes. (Thanks lemz1!)
    - NOTE: You currently can’t use them in a static context.
  - Added the ability to use the `??=` operator. (Thanks lemz1!)
  - Added the ability to use the `using` keyword. (Thanks KoloInDaCrib!)
  - `final` variables created inside of scripts are now treated as actual `final`s. (Thanks KoloInDaCrib!)
  - Added null-safe field assign. (ex. `someVar?.someVar2 = new Class();`) (Thanks NotHyper-474!)
  - Improved properties support, behaving more like regular Haxe. (Thanks NotHyper-474!)
  - Fixed a null object reference when evaluating static variables with no explicit values. (Thanks NotHyper-474!)
  - Fixed a null object reference when iterating over a null variable. (Thanks NotHyper-474!)
  - Scripts are now automatically cleared when Polymod is initialized. (Thanks KoloInDaCrib!)
- Polished every chart in the game!
  - The lengths of hold notes have been adjusted to match the vocals as closely as possible, across all variations and difficulties.
  - Easy and Normal charts from Week 1 to Week 3 have been adjusted for more consistency between the player and opponent.
  - Many charting errors have been corrected.
- Accept keybinds and gamepad south buttons now work on the Title Screen. ([e281bdd](https://github.com/FunkinCrew/Funkin/commit/e281bdddca5f31982bdc620e8ea92b080dcd416a)) - by @MrMadera in [#5650](https://github.com/FunkinCrew/Funkin/pull/5650)
- [ANDROID] Pressing the Back button in the Title Screen now closes the game. ([e6fd5d9](https://github.com/FunkinCrew/Funkin/commit/e6fd5d9b129f74703d6bd96744f63cb201afc941)) - by @NotHyper-474 in [#5527](https://github.com/FunkinCrew/Funkin/pull/5527)
- The HOME and END keys now jump to the top and bottom of the Story Mode menu, respectively. ([d1a96f7](https://github.com/FunkinCrew/Funkin/commit/d1a96f791f2ed35accc1c1e9ff548a75b2b9d7ef)) - by @JVNpixels in [#4591](https://github.com/FunkinCrew/Funkin/pull/4591)
- Freeplay favorite songs are now separated by variation. ([b4b2e8d](https://github.com/FunkinCrew/Funkin/commit/b4b2e8da9dde41d730556a41e6bb18b0f3d8d7db)) - by @KoloInDaCrib in [#5154](https://github.com/FunkinCrew/Funkin/pull/5154)
- Freeplay preview volumes now play at 70% volume, up from 40%. ([4ecef6d](https://github.com/FunkinCrew/Funkin/commit/4ecef6db744bab7e3fe5de0d680d813cc3bd1ea7)) - by @JackXson-Real in [#5645](https://github.com/FunkinCrew/Funkin/pull/5645)
- Selecting a song in the Freeplay menu now plays a fade-out transition. ([705e6b3](https://github.com/FunkinCrew/Funkin/commit/705e6b330806c3157bca7301b1e43cd78acdb23a)) - by @VirtuGuy in [#5626](https://github.com/FunkinCrew/Funkin/pull/5626)
- Implemented null safety to PlayState and LoadingState. ([34ce13c](https://github.com/FunkinCrew/Funkin/commit/34ce13c5dfd52760675a1d09efa489bcb108e607)) - by @NotHyper-474 in [#4789](https://github.com/FunkinCrew/Funkin/pull/4789)
- Health icons now have an offset variable. ([8bab619](https://github.com/FunkinCrew/Funkin/commit/8bab6196e50420c6586441f2d321bd1c139567c3)) - by @PurSnake in [#5760](https://github.com/FunkinCrew/Funkin/pull/5760)
- The "hey" notekind now plays the animation for BF (Christmas). ([91d5970](https://github.com/FunkinCrew/funkin.assets/commit/91d5970e0274aa0a31fc6f2b05c114730256408f)) - by @JackXson-Real in [funkin.assets#225](https://github.com/FunkinCrew/funkin.assets/pull/225)
- Added an "offset" property to the Set Camera Bop event, enabling more flexible camera bops. ([3f5ef4a](https://github.com/FunkinCrew/Funkin/commit/3f5ef4abe09bbd222bb9e5e212d63973b1b87175)) - by @Burgerballs in [#3575](https://github.com/FunkinCrew/Funkin/pull/3575)
- Added caching to multi-sparrow characters and fixed textures not being properly cached. ([feb55b2](https://github.com/FunkinCrew/Funkin/commit/feb55b26258e1dd0c4d209e2fa8af1dfb32ea684)) - by @PurSnake in [#5684](https://github.com/FunkinCrew/Funkin/pull/5684)
- Optimized the way Freeplay backing card text is rendered. ([f6de4c5](https://github.com/FunkinCrew/Funkin/commit/f6de4c54d37d3febc01db20d84885ccd3e21e833)) - by @MaybeMaru in [#5730](https://github.com/FunkinCrew/Funkin/pull/5730)
- Optimized the rendering of many visual elements in Freeplay. ([6f193c4](https://github.com/FunkinCrew/Funkin/commit/6f193c4bd88675f46d9455a5310129f1517c8e18)) - by @MaybeMaru in [#5773](https://github.com/FunkinCrew/Funkin/pull/5773)
- Optimized the way notes are rendered, especially when many are visible at once. ([a2b347e](https://github.com/FunkinCrew/Funkin/commit/a2b347e31e7a539f12131980ffeaf980e3e677af)) - by @MaybeMaru in [#5752](https://github.com/FunkinCrew/Funkin/pull/5752)
- Image assets for gradients are now smaller and stretched in-game for better optimization. ([fab646c](https://github.com/FunkinCrew/funkin.assets/commit/fab646ce4a3045dcd6aa2ab86c403a40ee89bfa3)) - by @MaybeMaru in [funkin.assets#227](https://github.com/FunkinCrew/funkin.assets/pull/227)

### Fixed

- The song no longer restarts from an earlier point in the song instead of ending.
- Perfect ranks no longer occasionally disappear after the rank slam animation.
- Later notes are no longer hit before earlier notes on songs with high scroll speeds.
- [MOBILE] Clearing save data no longer crashes the game.
- [MOBILE] Cutscenes no longer continue playing behind the Pause Menu after losing focus.
- [MOBILE] Freeplay capsules now properly shift away from under the letter sort bar.
- [MOBILE] The Options button now animates properly after the first interaction.
- [HTML5] The “Touch here to play” button is no longer too large.
- Shaders now apply to A-Bot.
- Adjusted offsets for some of Pico’s special animations.
- Trimmed the extra silence at the beginning of Stress.
- Trimmed the extra silence at the end of Senpai.
- Monster and Winter Horrorland now display the correct album.
- The “Haptics intensity” preference no longer displays inconsistent values.
- The Lag Adjustment menu no longer permanently stops sending notes.
- The Results Screen clear percentage now disappears behind the sound system.
- The Debug Menu background now accounts for wider aspect ratios.
- The Legacy Chart Importer now imports charts properly.
- Fixed the “Starting BPM” text in the Chart Editor being tiny.
- Chromebooks no longer use touch controls.
- Enabled note recycling, resulting in a significant performance boost during songs. ([57a276d](https://github.com/FunkinCrew/Funkin/commit/57a276d17c293f40d6b27a89816b1659fc8b078f)) - by @KoloInDaCrib and @NotHyper-474 in [#5732](https://github.com/FunkinCrew/Funkin/pull/5732)
- Misses are now properly processed for recycled notes. ([e7f7f47](https://github.com/FunkinCrew/Funkin/commit/e7f7f4794f410b74eab79941531f19c68737f94e)) - by @NotHyper-474 in [#5751](https://github.com/FunkinCrew/Funkin/pull/5751)
- Bad save data no longer causes the game to immediately crash. ([84f1190](https://github.com/FunkinCrew/Funkin/commit/84f119036b44881488e47136f23f960855d47897)) - by @mikolka9144 in [#5703](https://github.com/FunkinCrew/Funkin/pull/5703)
- Spamming the Reset and Accept buttons no longer softlocks the game over screen. ([01a2458](https://github.com/FunkinCrew/Funkin/commit/01a2458c1281440947f1aab586752e7ff490fe37)) - by @KoloInDaCrib in [#5714](https://github.com/FunkinCrew/Funkin/pull/5714)
- Pressing F4 while calibrating or testing offsets no longer results in a softlock. ([7f82b48](https://github.com/FunkinCrew/Funkin/commit/7f82b48e3face75791955d28e807b7919d668be6)) - by @KoloInDaCrib in [#5716](https://github.com/FunkinCrew/Funkin/pull/5716)
- Spamming through the Freeplay letter sort lists no longer crashes the game. ([0d6bc2b](https://github.com/FunkinCrew/Funkin/commit/0d6bc2bedd4494838db288247c4b13ec4031f0a8)) - by @JVNpixels in [#5578](https://github.com/FunkinCrew/Funkin/pull/5578)
- Main menu items can no longer be scrolled and selected again after selecting an item. ([1fc611d](https://github.com/FunkinCrew/Funkin/commit/1fc611d1308e26f50cc01658b0ab7b848f05debe)) - by @JackXson-Real in [#5680](https://github.com/FunkinCrew/Funkin/pull/5680)
- Fixed a crash caused by parsing CRLF line endings incorrectly. ([65349f4](https://github.com/FunkinCrew/Funkin/commit/65349f47145f44c94dae8a7a39004968da48cf0d)) - by @NotHyper-474 in [#5656](https://github.com/FunkinCrew/Funkin/pull/5656)
- Fixed a script error when playing a Week 3 Erect song after a Week 3 (Pico Mix) song. ([6ecada8](https://github.com/FunkinCrew/funkin.assets/commit/6ecada82ac0072826132cad8f9e11f07006f9977)) - by @ThatRozebudDude in [funkin.assets#131](https://github.com/FunkinCrew/funkin.assets/pull/131)
- Boyfriend's vocals no longer double up after restarting in Week 3. ([743e8b1](https://github.com/FunkinCrew/Funkin/commit/743e8b13c28d9f0471b392edc3127973f6fef329)) - by @NotHyper-474 in [#5408](https://github.com/FunkinCrew/Funkin/pull/5408)
- Songs with BPM changes now restart at the correct BPM. ([51eec45](https://github.com/FunkinCrew/Funkin/commit/51eec4522e49ed7ed2c9457b5224c3b06e758958)) - by @VioletSnowLeopard in [#4721](https://github.com/FunkinCrew/Funkin/pull/4721)
- Dropped hold notes are now properly handled. ([1df0cb9](https://github.com/FunkinCrew/Funkin/commit/1df0cb95f6a86d41dc5ef2d19a28c4c09952a69a)) - by @Lasercar in [#5172](https://github.com/FunkinCrew/Funkin/pull/5172)
- Fullscreen keybinds now work properly on Web builds. ([1fbb760](https://github.com/FunkinCrew/Funkin/commit/1fbb7604ddf4fb8d311b9b414cbcfa0fd9bab255)) - by @NotHyper-474 in [#5664](https://github.com/FunkinCrew/Funkin/pull/5664)
- Corrected the heights of characters in the intro text font. ([90242e2](https://github.com/FunkinCrew/funkin.assets/commit/90242e2e200fca38f5f535986db49b7a53282d1f)) - by @SpritersBlock in [funkin.assets#190](https://github.com/FunkinCrew/funkin.assets/pull/190)
- PureColor shaders now properly apply anti-aliasing. ([8d1bfa1](https://github.com/FunkinCrew/Funkin/commit/8d1bfa105c89f68ab1f14a197f8c0a5e4fe7fb14)) - by @MaybeMaru in [#5781](https://github.com/FunkinCrew/Funkin/pull/5781)
- The Preferences menu camera now remembers its position when exiting and re-entering. ([3d88fbb](https://github.com/FunkinCrew/Funkin/commit/3d88fbb11fea2b52d399f37cb8154795329c31c2)) - by @VirtuGuy in [#5608](https://github.com/FunkinCrew/Funkin/pull/5608)
- The Freeplay DJ no longer flickers between animations. ([1b91f3b](https://github.com/FunkinCrew/Funkin/commit/1b91f3b57cda3310db2f5196650b89c8d88e69be)) - by @VirtuGuy in [#5598](https://github.com/FunkinCrew/Funkin/pull/5598)
- The Freeplay DJ's turntable lights now glow properly. ([0c5a965](https://github.com/FunkinCrew/funkin.assets/commit/0c5a965400937cbdac55ed9317a2a00a9d4343ae)) - by @Johferson in [funkin.assets#211](https://github.com/FunkinCrew/funkin.assets/pull/211)
- The Random capsule now opens the selected song with the correct variation. ([1605514](https://github.com/FunkinCrew/Funkin/commit/160551442453fccc0961c570701bdba7bee95ef0)) - by @PurSnake in [#5611](https://github.com/FunkinCrew/Funkin/pull/5611)
- Newly earned Freeplay ranks no longer appear larger than others. ([47813ea](https://github.com/FunkinCrew/Funkin/commit/47813eac3157927f851713cc4c41c5eb5fac2e19)) - by @anysad in [#5768](https://github.com/FunkinCrew/Funkin/pull/5768)
- Freeplay now displays the correct number of difficulty stars after returning from a song. ([30721c3](https://github.com/FunkinCrew/Funkin/commit/30721c3a30f7e980557d055daa30e7e5501b83e3)) - by @KoloInDaCrib in [#5560](https://github.com/FunkinCrew/Funkin/pull/5560)
- Removed stray pixels around pixel icons in Freeplay and Character Select. ([b1d770b](https://github.com/FunkinCrew/funkin.assets/commit/b1d770b7f69cb73bd35a279ba5b26908e0cd94be)) - by @Hundrec in [funkin.assets#69](https://github.com/FunkinCrew/funkin.assets/pull/69)
- The nametag in the Character Select screen now fades and moves as other elements do. ([2b1f346](https://github.com/FunkinCrew/Funkin/commit/2b1f346097efadcad19058c4ed9cefe4f84c8b64)) - by @JackXson-Real in [#5583](https://github.com/FunkinCrew/Funkin/pull/5583)
- [MOBILE] The touch pointer now displays during songs. ([9d2cfa9](https://github.com/FunkinCrew/Funkin/commit/9d2cfa9686880170c5c398786c72d878974eaf93)) - by @SrtHero278 in [#5565](https://github.com/FunkinCrew/Funkin/pull/5565)
- Note splashes are now more centered on the strumline. ([cfa6016](https://github.com/FunkinCrew/funkin.assets/commit/cfa6016eeacb745cb2787c99f8d1f156ab4d16e8)) - by @JVNpixels in [funkin.assets#234](https://github.com/FunkinCrew/funkin.assets/pull/234)
- Removed stray pixels from BF's old icon and aligned its losing icon. ([e57dc54](https://github.com/FunkinCrew/funkin.assets/commit/e57dc54fe333f8fa3f3933164b423128c74f4c38)) - by @Hundrec in [funkin.assets#93](https://github.com/FunkinCrew/funkin.assets/pull/93)
- Daddy Dearest's idle animation now plays on beat. ([b4c1aa9](https://github.com/FunkinCrew/funkin.assets/commit/b4c1aa95aad45c42256432ec81cce8bf35107fa7)) - by @qt2k4 in [funkin.assets#148](https://github.com/FunkinCrew/funkin.assets/pull/148)
- Boyfriend (Dark)'s idle animation now properly syncs with his regular idle. ([d1610f1](https://github.com/FunkinCrew/funkin.assets/commit/d1610f1e6f0d5b0db0af34e3d00e7a1fc1d4a4b5)) - by @TechnikTil in [funkin.assets#203](https://github.com/FunkinCrew/funkin.assets/pull/203)
- Spooky Kids (Dark)'s idle animation now properly syncs with their regular idle. ([aa28bd7](https://github.com/FunkinCrew/funkin.assets/commit/aa28bd74a33ab0026649d19e642c41b4f1c5cd06)) - by @Honton129 in [funkin.assets#213](https://github.com/FunkinCrew/funkin.assets/pull/213)
- Lightning now appears more regularly during South and Monster in Story Mode. ([c5f4a8e](https://github.com/FunkinCrew/funkin.assets/commit/c5f4a8e55f18cbc2e57a72743320da79358b1816)) - by @JackXson-Real in [funkin.assets#222](https://github.com/FunkinCrew/funkin.assets/pull/222)
- The Picos no longer gasp twice in the Week 3 doppelganger cutscene. ([7b30a14](https://github.com/FunkinCrew/funkin.assets/commit/7b30a1418ef4597e567a22a2ea1bc1d9e4b061da)) - by @Lasercar in [funkin.assets#231](https://github.com/FunkinCrew/funkin.assets/pull/231)
- The Week 3 train now consistently plays its sound. ([469ce39](https://github.com/FunkinCrew/funkin.assets/commit/469ce397b8eef3be47f8fadaa61a500e1a87ca3a)) - by @Lasercar in [funkin.assets#212](https://github.com/FunkinCrew/funkin.assets/pull/212)
- Nene no longer freezes after playing two animations at once. ([d346ebd](https://github.com/FunkinCrew/funkin.assets/commit/d346ebdbf4781b49a081e0719221cf584fc3fe55)) - by @NotHyper-474 in [funkin.assets#228](https://github.com/FunkinCrew/funkin.assets/pull/228)
- The Week 4 car now properly pauses with the game. ([26d1cff](https://github.com/FunkinCrew/funkin.assets/commit/26d1cffe19793c67a89f299b7a60be95c5656282)) - by @NotHyper-474 in [funkin.assets#114](https://github.com/FunkinCrew/funkin.assets/pull/114)
- Pressing Reset and Pause at the same time no longer breaks the game over animation in Blazin'. ([8cd3785](https://github.com/FunkinCrew/Funkin/commit/8cd3785e3c3e913ed791204814eba86eb7142a5d)) - by @VirtuGuy in [#5639](https://github.com/FunkinCrew/Funkin/pull/5639)
- Pico's Blazin' death animation no longer lags and offsets improperly. ([2cb42fe](https://github.com/FunkinCrew/funkin.assets/commit/2cb42fec422313db4e8000c963be0539221c9e21)) - by @KoloInDaCrib in [funkin.assets#217](https://github.com/FunkinCrew/funkin.assets/pull/217)
- Pico and Darnell now properly punch with their other arms in Blazin'. ([4fb015f](https://github.com/FunkinCrew/funkin.assets/commit/4fb015f20261995ce41370910989094f4f2f26bb)) - by @Honton129 in [funkin.assets#221](https://github.com/FunkinCrew/funkin.assets/pull/221)
- Pico's Perfect Results Screen animation now syncs with the music. ([0531e27](https://github.com/FunkinCrew/funkin.assets/commit/0531e27feed83dcc9a1703b3df654fd3bba1bd8a)) - by @JackXson-Real in [funkin.assets#201](https://github.com/FunkinCrew/funkin.assets/pull/201)
- Filled in invisible pixels in the Story Mode button. ([c83ea78](https://github.com/FunkinCrew/funkin.assets/commit/c83ea788485693e22d429d81db8eb4da202e0140)) - by @D4rkJony in [funkin.assets#214](https://github.com/FunkinCrew/funkin.assets/pull/214)
- Filled in invisible pixels in Tankman's icons. ([cb46973](https://github.com/FunkinCrew/funkin.assets/commit/cb46973bf8d9f48cd4738d483957c1edb501b386)) - by @JackXson-Real in [funkin.assets#224](https://github.com/FunkinCrew/funkin.assets/pull/224)
- Scripted classes are no longer registered twice after hot-reloading. ([f870ed2](https://github.com/FunkinCrew/Funkin/commit/f870ed2858507273c4dbbca3e4b8b97d80a8d2ec)) - by @KoloInDaCrib in [#5743](https://github.com/FunkinCrew/Funkin/pull/5743)
- The Chart Editor now properly uses the song ID from the manifest. ([df67b64](https://github.com/FunkinCrew/Funkin/commit/df67b642a8d7f7460e36a42c570a1ff2303751fd)) - by @cyn0x8 in [#4168](https://github.com/FunkinCrew/Funkin/pull/4168)
- Dragging and dropping a Chart Editor selection in the same place no longer breaks the selection. ([4b65587](https://github.com/FunkinCrew/Funkin/commit/4b655879f763f6dbe34c89fc4a781cae9ff4abd8)) - by @Lasercar in [#4185](https://github.com/FunkinCrew/Funkin/pull/4185)
- Clicking between hold note trails no longer causes visual errors in the Chart Editor. ([0e52744](https://github.com/FunkinCrew/Funkin/commit/0e527447188dbd3d850154a73f61467c1b8e585a)) - by @KoloInDaCrib in [#5683](https://github.com/FunkinCrew/Funkin/pull/5683)
- Holding Shift and Right Click over a note no longer produces a solitaire effect in the Chart Editor. ([172041d](https://github.com/FunkinCrew/Funkin/commit/172041d4f779271533e0d1c529297540bfec337a)) - by @Lasercar in [#4139](https://github.com/FunkinCrew/Funkin/pull/4139)
- Chart Editor event properties now have minimum values. ([9b81ebc](https://github.com/FunkinCrew/Funkin/commit/9b81ebc4f2c1c70b33d7351210c40c9a0e48ecc8)) - by @Lasercar in [#4110](https://github.com/FunkinCrew/Funkin/pull/4110)
- Added missing notekinds to the Chart Editor Notes window. ([b7a5761](https://github.com/FunkinCrew/Funkin/commit/b7a5761730d43f27891dfec1c23fcb5e66daccf1)) - by @Lasercar in [#4286](https://github.com/FunkinCrew/Funkin/pull/4286)
- Playback speed is now preserved when a new song or variation is loaded in the Chart Editor. ([3f82f37](https://github.com/FunkinCrew/Funkin/commit/3f82f3792b056a03724a0d1a320b7549a7b59844)) - by @Lasercar in [#4212](https://github.com/FunkinCrew/Funkin/pull/4212)
- The Legacy Chart Importer now properly imports scroll speeds. ([2645d56](https://github.com/FunkinCrew/Funkin/commit/2645d56514dd1a27a050ff432c3cd4122f958e10)) - by @VirtuGuy in [#5655](https://github.com/FunkinCrew/Funkin/pull/5655)
- Opponent characters now play singing animations when selected as the player character. ([8ee24c8](https://github.com/FunkinCrew/funkin.assets/commit/8ee24c84de6aa6e6313699198f35f61991612d04)) - by @Lasercar in [funkin.assets#141](https://github.com/FunkinCrew/funkin.assets/pull/141)
- The Chart Editor character selector window no longer opens when clicking while playtesting. ([223e837](https://github.com/FunkinCrew/Funkin/commit/223e837fe8d9ce227e289a38bdfc095e4d81c48a)) - by @Lasercar in [#4350](https://github.com/FunkinCrew/Funkin/pull/4350)
- Renamed Nene's pixel variant to Nene (Pixel) in the Chart Editor. ([69a7898](https://github.com/FunkinCrew/funkin.assets/commit/69a78988e3d6042d2e4779c9a4055c5de73ee775)) - by @JVNpixels in [funkin.assets#208](https://github.com/FunkinCrew/funkin.assets/pull/208)
- Renamed Tankman's variants in the Chart Editor. ([70c43b7](https://github.com/FunkinCrew/funkin.assets/commit/70c43b792078d913c4c4d9fc019e378249d08b78)) - by @ExtraCode75 in [funkin.assets#209](https://github.com/FunkinCrew/funkin.assets/pull/209)
- Pressing F4 in the Chart Editor now properly resets the window title. ([86e69cf](https://github.com/FunkinCrew/Funkin/commit/86e69cfbd1b1bd3daa49181b827fa813cb716703)) - by @VirtuGuy in [#5651](https://github.com/FunkinCrew/Funkin/pull/5651)
- Saving a character in the Animation Editor no longer crashes the game. ([da5f691](https://github.com/FunkinCrew/Funkin/commit/da5f6918656d4a1ad3e83233b358034db92ca675)) - by @anysad in [#5519](https://github.com/FunkinCrew/Funkin/pull/5519)
- The Stage Editor can now properly load modded stages. ([50c601a](https://github.com/FunkinCrew/Funkin/commit/50c601a7f0f27fc0f155e2bfbcb8ef54631aeac7)) - by @KoloInDaCrib in [#5744](https://github.com/FunkinCrew/Funkin/pull/5744)
- XML files exported from the Stage Editor now account for rotated frames. ([661ddb1](https://github.com/FunkinCrew/Funkin/commit/661ddb15f72c2dae22f41a922a521740ab3617f0)) - by @KoloInDaCrib in [#5303](https://github.com/FunkinCrew/Funkin/pull/5303)
- A few more adjustments for good measure.

## New Contributors for 0.7.4

* @ThatOneCalculator made their first contribution in [#5507](https://github.com/FunkinCrew/Funkin/pull/5507)
* @SrtHero278 made their first contribution in [#5565](https://github.com/FunkinCrew/Funkin/pull/5565)
* @VirtuGuy made their first contribution in [#5598](https://github.com/FunkinCrew/Funkin/pull/5598)
* @SpritersBlock made their first contribution in [funkin.assets#190](https://github.com/FunkinCrew/funkin.assets/pull/190)
* @Johferson made their first contribution in [funkin.assets#211](https://github.com/FunkinCrew/funkin.assets/pull/211)
* @Honton129 made their first contribution in [funkin.assets#213](https://github.com/FunkinCrew/funkin.assets/pull/213)
* @D4rkJony made their first contribution in [funkin.assets#214](https://github.com/FunkinCrew/funkin.assets/pull/214)



## [0.7.3] - 2025-07-21

### Fixed

- Fixed stuttering throughout the game caused by the Polymod upgrade. (Thanks NotHyper-474!)
- [MOBILE] Fixed buttons in the Main Menu not working.
- [iOS] The Upgrade button no longer appears if you have already purchased it (actually this time).
- Fixed the countdown overlapping itself when restarting the song. (Thanks NotHyper-474!)
- Optimized the Week 6 Erect stage.
- Fixed an oversight when clearing the cache. (Thanks cherrythecool!)
- The Input Offset Test menu text now displays in the correct position.
- Fixed script errors appearing in the Week 3 Erect stage.
- Fixed adding variations in the Chart Editor erasing difficulties. (Thanks NotHyper-474!)

## New Contributors for 0.7.3

* @cherrythecool made their first contribution in [#5458](https://github.com/FunkinCrew/Funkin/pull/5458)



## [0.7.2] - 2025-07-18

### Added

- [ANDROID] Added a button in the Options menu to access the mods folder.
- [MOBILE] Added a preference to adjust the intensity of haptic feedback, ranging from 0.1 to 5.
- [MOBILE] Added an easter egg when tapping the player's healthbar icon.

### Changed

- Changed default OpenAL configuration settings to improve audio quality. (Thanks Smokey555, cyn0x8, and CCobaltDev!)
  - The difference may be more or less noticeable on different devices and hardware.
  - Applies to Desktop and Android, but not iOS yet.
- Made several improvements to Polymod and HScript. These changes might break some mods, so please update them accordingly!
  - Fixed an issue where scripted classes can define two or more fields with the same name.
  - Fixed an issue causing some syntax errors (such as missing commas) to be ignored by the parser.
  - Scripted classes can now create static fields and functions.
  - Scripted classes can now create variables with the `final` keyword.
  - Scripted classes can now access variables from another scripted class with `class.someVariable`, instead of `class.scriptGet("someVariable")`
    - This applies to functions too: `class.someFunction()`
  - Scripted classes that don't extend another class can now be created!
    - This only works if you access the class in a static context. Creating an instance of said class doesn't work just yet!
  - Added support for properties (`get_` and `set_` functions) (Thanks KoloInDaCrib!)
  - Added support for abstracts in a static context. (Thanks lemz1!)
    - You can now use classes like `FlxColor` properly!
  - Added support for creating and using enums. (Thanks lemz1!)
    - You can import them in another script as usual.
  - Added support for renaming imported classes using the `as` keyword. (Thanks KoloInDaCrib!)
  - Fixed `try`/`catch` blocks not working properly. (Thanks NotHyper-474!)
  - Fixed null-safe field access not working properly for functions (ex. `class?.someFunction()`). (Thanks KoloInDaCrib!)
  - Fixed Linux being case-sensitive with filenames. (Thanks mikolka9144!)

### Fixed

- [MOBILE] Weekend 1 Story Mode no longer crashes before loading into Blazin'.
- [MOBILE] Beating 2hot from Freeplay no longer crashes in the Results screen.
- [MOBILE] Retrying and pressing the Back button at the same time no longer crashes the game.
- [MOBILE] Pressing the Options and Back buttons at the same time no longer softlocks the game.
- [HTML5] Pausing while the train passes by on the Week 3 Erect stage no longer crashes.
- [DESKTOP] Getting a Bad/Shit rating on Blazin' no longer breaks animations.
- The scroll sound no longer plays once after entering Freeplay.
- The Freeplay song preview and album cover now update properly when switching variations.
- The Freeplay clear percent counter now consistently displays the correct value on unranked songs.
- The Freeplay difficulty star flames no longer become offset from the stars.
- The Freeplay difficulty star flames no longer appear during a new rank animation.
- The Freeplay menu now correctly assigns the `currentCharacterId`. (Thanks TechnikTil!)
- Boyfriend's Perfect (Gold) Results animation now loops properly.
- [DESKTOP] The Input Offsets menu no longer activates the debug cursor.
- The Input Offsets Test menu no longer generates stacked notes.
- The Input Offsets Test menu drums no longer desync from the rest of the track.
- The Input Offsets Test menu no longer breaks when a keyboard or controller is connected.
- [MOBILE] Sustain trails now display properly with upscroll enabled.
- [MOBILE] Added a Back button to the keyboard/gamepad Controls menu.
- [iOS] Fixed app name spacing on the Home Screen.
- [iOS] Adjusted the preloader to accommodate for different screen sizes.
- [iOS] The Upgrade button no longer appears if you have already purchased it.
- [ANDROID] Fixed some issues with scrolling.
- [ANDROID] Toasts with blank messages no longer appear.
- Fixed a critical security vulnerability that could be exploited in mods.
- A few more bugfixes and optimizations here and there.

## New Contributors for 0.7.2

* @Smokey555 made their first contribution in [#3318](https://github.com/FunkinCrew/Funkin/pull/3318)
* @CCobaltDev made their first contribution in [#3318](https://github.com/FunkinCrew/Funkin/pull/3318)
* @mikolka9144 made their first contribution in [polymod#212](https://github.com/larsiusprime/polymod/pull/212)



## [0.7.1] - 2025-07-15

### Fixed
- Properly implemented ad playback on iOS devices.



## [0.7.0] - 2025-07-15

### Added

- Friday Night Funkin' now has OFFICIAL mobile versions for Android and iOS, available on the Google Play Store and Apple App Store!
  - This version contains 100% of the songs from the desktop version of the game.
- [MOBILE] New touch input compatibility for all menus.
- [MOBILE] Added banner and interstitial advertisements to the game. You can upgrade to the full version through an in-app purchase to permanently disable advertisements.
- [MOBILE] Graphics are compressed using the ASTC algorithm, decreasing memory usage in exchange for a slightly larger file size.
- [MOBILE] Added haptic feedback to several areas of the game.
- Added a visual indicator that shows available difficulties for the currently selected song in Freeplay.
- Overhauled the input offsets system, including:
  - One unified "offset" value.
  - An "Offset Calibration" screen where the game determines your ideal offset.
  - A "Test" screen where you can play a short note pattern to try out your offset.
  - A brand new offset testing theme: Syncobation by Kawai Sprite!
  - The ability to change your offsets in the Pause Menu, mid-song!
  - The Input Offsets menu isn't yet available on HTML5, but offsets are still configurable through the Pause Menu.
- Added null-safety to a bunch of classes in the source code.
- Added the Changelog back to the game files, written by Hundrec and AbnormalPoof!
- Added a few sandboxed classes to give mods limited access to the Discord and Newgrounds APIs. ([50d9584](https://github.com/FunkinCrew/Funkin/commit/50d9584a388bd891aa2f8b68a5cde894a6e1ede6)) - by @KoloInDaCrib in [#5040](https://github.com/FunkinCrew/Funkin/pull/5040)
- Added script support for Freeplay Backing Cards. ([0001017](https://github.com/FunkinCrew/Funkin/commit/0001017c003be653236c6cc56487c7d0ee33633e)) - by @KoloInDaCrib in [#5233](https://github.com/FunkinCrew/Funkin/pull/5233)
- Sparrow results screen animations can now be scriptable. ([7bb2336](https://github.com/FunkinCrew/Funkin/commit/7bb23369727ca4955aa1fbe25e5798809e8169bd)) - by @KoloInDaCrib in [#5168](https://github.com/FunkinCrew/Funkin/pull/5168)
- Added a blank `Object` class for scripts to extend, and made `FlxObject` and `FlxBasic` scriptable. ([eb6becc](https://github.com/FunkinCrew/Funkin/commit/eb6becc03fff76117ee3fcbeb32fe254236ca232)) - by @cyn0x8 in [#3119](https://github.com/FunkinCrew/Funkin/pull/3119)
- Added default gamepad controls for two recently added Freeplay controls. ([a0d3f8e](https://github.com/FunkinCrew/Funkin/commit/a0d3f8ec553e06b625b463c7989658edbebbbdf5)) - by @MrMadera in [#4559](https://github.com/FunkinCrew/Funkin/pull/4559)
- Added the ability to press the Chart Editor keybind in Freeplay with a song capsule selected. ([2221594](https://github.com/FunkinCrew/Funkin/commit/2221594883afa7cd0e518fca7ea975d05626692a)) - by @Lasercar in [#4114](https://github.com/FunkinCrew/Funkin/pull/4114)
- The Chart Editor now highlights and deletes stacked notes using a customizable threshold. ([8cae34e](https://github.com/FunkinCrew/Funkin/commit/8cae34eed711bff70e5348ffc6178a0fd69b5846)) - by @NotHyper-474 in [#3574](https://github.com/FunkinCrew/Funkin/pull/3574)
- Added a variation indicator next to the Chart Editor playbar difficulty. ([ccd0148](https://github.com/FunkinCrew/Funkin/commit/ccd0148e9b46d512a22b4958d3f289cfc7854965)) - by @KoloInDaCrib in [#5236](https://github.com/FunkinCrew/Funkin/pull/5236)
- Added more tween types to certain Chart Editor events. ([5177e12](https://github.com/FunkinCrew/Funkin/commit/5177e1275eb2fb2b016224c139e84debb421b895)) - by @Lasercar in [#4249](https://github.com/FunkinCrew/Funkin/pull/4249)
- Pressing Ctrl + N now creates a new stage in the Stage Editor. ([576f8e5](https://github.com/FunkinCrew/Funkin/commit/576f8e54ff8ca8e205241fafa33d0256b62d11d5)) - by @Lasercar in [#5175](https://github.com/FunkinCrew/Funkin/pull/5175)
- Added "Flip character horizontally" to the list of shortcuts in the Animation Editor. ([c464cae](https://github.com/FunkinCrew/funkin.assets/commit/c464caec921dcefef7b0b74b2abf95e76ce64491)) - by @AbnormalPoof in [funkin.assets#60](https://github.com/FunkinCrew/funkin.assets/pull/60)
- Added Perfect (Gold) to the list of available ranks in Results Debug menu. ([c5308cc](https://github.com/FunkinCrew/Funkin/commit/c5308ccbb9d2b98c62fa4974b8ad7ac1e1ec7d19)) - by @AbnormalPoof in [#4642](https://github.com/FunkinCrew/Funkin/pull/4642)
- [MOBILE] Implemented Kevin and Michael.

### Changed

- The mod API version now supports v0.7.0, along with v0.6.3. Be sure to check that your mods still work!
- Updated the app icon for Desktop platforms.
- [MOBILE] Modified several parts of the game to look better on phone screens with wider aspect ratios, up to 20:9.
- [DESKTOP] The game now tries to match the window's aspect ratio when changing states, extending as wide as 20:9.
- [DESKTOP] Included Mobile stage expansions on Desktop as well. Now you'll have more room for camera events!
- Playable Pico and Weekend 1 songs are now always unlocked in Freeplay, even on new saves.
- The Freeplay difficulty graphic now scrolls smoothly when changing difficulties.
- The "Pause on Unfocus" preference now opens the Pause Menu when unfocusing during a song.
- Scripts can now make hold note trails semi-transparent.
- Completely reformatted every script file within the game's assets for better readability.
- Completely reformatted and optimized every single chart file in the game.
- Recharted pico-speaker's chart in Stress
- Tweaked charts for the following songs:
  - Bopeebo [all difficulties] - Removed an extra hey animation event
  - Bopeebo (Pico Mix) [Hard] - Added a missing note in Section 24
  - Fresh Erect [Nightmare] - Added a missing grace note for BF in Section 24
  - South Erect [Nightmare] - Added missing grace notes for BF in Sections 13, 17, and 53
  - Philly Nice [Hard] - Added missing grace notes for Pico in Sections 30 and 62
  - Philly Nice [all difficulties] - Added hey animations throughout the song
  - Philly Nice Erect [Erect] - Added a grace note for BF in Section 33, removed a stacked note for opponent in Section 12
  - Philly Nice (Pico Mix) [Normal] - Adjusted a left note by 1/96 in Section 60
  - Blammed (Pico Mix) [Hard] - Added a missing jack in Section 46
  - Satin Panties [Hard] - Added grace notes in Sections 7-10
  - Satin Panties [Normal/Hard] - Made Mom sing a sustain rather than two notes in Section 30
  - High Erect [Erect/Nightmare] - Added a missing note in Section 16
  - Cocoa [Easy] - Added some notes to reduce sparseness, fixed Mom singing Dad's notes
  - Cocoa Erect [Erect/Nightmare] - Reimplemented BF's censored notes for Nightmare, adjusted one note by 1/48 in Section 63
  - Eggnog Erect [Erect/Nightmare] Added two grace notes in Sections 10 and 14 and a missing note for Dad in Section 44
  - Eggnog (Pico Mix) [Hard] - Added a missing grace note for Pico that was present on Normal in Section 20
  - Roses [Normal/Hard] - Made Senpai sing a sustain rather than two notes (sneaky)
  - Roses Erect [Erect/Nightmare] - Mirrored the changes from normal Roses
  - Guns [all difficulties] - Added a missing note in Sections 28 and 32 and adjusted a hold note's length in Section 73
  - Stress [Hard] - Split whole notes in halves in Sections 57-60
  - Darnell [Hard] - Added one missing note for Pico in Section 35
  - Darnell [all difficulties] - Adjusted camera event timings for consistency
  - Darnell (BF Mix) [all difficulties] - Removed 3 extra notes and fixed Darnell's pattern being offset
  - Lit Up [all difficulties] - Added 4 sustains for Darnell throughout the song
  - Lit Up (BF Mix) [all difficulties] - Added 4 sustains for Darnell throughout the song
  - 2hot [Easy/Hard] - Fixed remaining offset rhythms (for real this time)
- Notes now scroll more smoothly by rendering based on delta timing. ([6ad9ffc](https://github.com/FunkinCrew/Funkin/commit/6ad9ffc7f9d66bbaf6ba343663de4c7268f4be3b)) - by @KutikiPlayz in [#3544](https://github.com/FunkinCrew/Funkin/pull/3544)
- The Freeplay character select hint now always displays if you have more than one character unlocked. ([7ccf75c](https://github.com/FunkinCrew/Funkin/commit/7ccf75cd869ba4b6f18a5adc01e65e52ae7bb809)) - by @Hundrec in [#5023](https://github.com/FunkinCrew/Funkin/pull/5023)
- Favorite songs in Freeplay are now sorted by Week order instead of alphabetically. ([da0964a](https://github.com/FunkinCrew/Funkin/commit/da0964a7b7bbe4ece1bdbd19233eb6dba0de3ac5)) - by @Hundrec in [#3609](https://github.com/FunkinCrew/Funkin/pull/3609)
- Shifted Mommy Mearest's pixel icon to the left in Freeplay. ([d861eba](https://github.com/FunkinCrew/funkin.assets/commit/d861ebac027dd07d0254c79d7c89b59ee04b38f1)) - by @KoloInDaCrib in [funkin.assets#197](https://github.com/FunkinCrew/funkin.assets/pull/197)
- The Character Select screen now opens on the currently selected character. ([4819a74](https://github.com/FunkinCrew/Funkin/commit/4819a74c2959cc9b32dfe2cb76c3a4c00e7c7f9a)) - by @Lasercar in [#4072](https://github.com/FunkinCrew/Funkin/pull/4072)
- Visualizers now zero out when the game audio is muted. ([6dcec59](https://github.com/FunkinCrew/Funkin/commit/6dcec592f467a0daeb8ff1e0ce122916e36ca869)) - by @Lasercar in [#5266](https://github.com/FunkinCrew/Funkin/pull/5266)
- The Options Menu can now scroll to display more menu items. ([70f0a54](https://github.com/FunkinCrew/Funkin/commit/70f0a54191597bd72a6d30d4d12ef5ece6ba078c)) - by @AbnormalPoof in [#4706](https://github.com/FunkinCrew/Funkin/pull/4706)
- Raised the FPS cap preference from 300 to 500. ([be73134](https://github.com/FunkinCrew/Funkin/commit/be7313453f70983fff55e69a8b52d741f0cc53b4)) - by @Hundrec in [#5044](https://github.com/FunkinCrew/Funkin/pull/5044)
- The Credits menu now uses less memory, especially with many entries. ([1b68c3a](https://github.com/FunkinCrew/Funkin/commit/1b68c3a8d6f66905a9a508a1cb692fe3beb7b4a2)) - by @lemz1 in [#2655](https://github.com/FunkinCrew/Funkin/pull/2655)
- Added a timer sequence class to queue up multiple timers in scripts with ease. ([9e182f7](https://github.com/FunkinCrew/Funkin/commit/9e182f70d2bcc92eb68d730d74af143c45f7dcf8)) - by @cyn0x8 in [#2391](https://github.com/FunkinCrew/Funkin/pull/2391)
- Replaced smoothLerp and coolLerp with smoothLerpPrecision to fix a few lerp-related bugs. ([94eae11](https://github.com/FunkinCrew/Funkin/commit/94eae116c7a5e6039683d6391208b169378b5ff1)) - by @cyn0x8 in [#3617](https://github.com/FunkinCrew/Funkin/pull/3617)
- Fixed empty text strings softlocking the dialogue box. ([88d0e8c](https://github.com/FunkinCrew/Funkin/commit/88d0e8c3b0529654fb7eee8aebb099f7fb346f66)) - by @xenkap in [#4671](https://github.com/FunkinCrew/Funkin/pull/4671)
- Adjusted the size of the Beat/Step display in the Chart Editor. ([905181c](https://github.com/FunkinCrew/Funkin/commit/905181c9af29bb11280bda33ef9343069678a762)) - by @NotHyper-474 in [#4994](https://github.com/FunkinCrew/Funkin/pull/4994)
- The Chart Editor will now only fall back to the first available difficulty if the selected difficulty cannot be found. ([1c25713](https://github.com/FunkinCrew/Funkin/commit/1c257134648ebd89acf6c9d07f5a0c088fb915c6)) - by @Lasercar in [#4949](https://github.com/FunkinCrew/Funkin/pull/4949)
- The undo/redo history is now cleared when loading another song in the Chart Editor. ([426a9c0](https://github.com/FunkinCrew/Funkin/commit/426a9c0c108ac65a042295194679d46444ec1ea5)) - by @Lasercar in [#4308](https://github.com/FunkinCrew/Funkin/pull/4308)
- Blacklisted more classes for security reasons. ([cadfa3b](https://github.com/FunkinCrew/Funkin/commit/cadfa3b7ceae2ecabe2d544ddc4c9f453b0dfd56)) - by @NotHyper-474 in [#5185](https://github.com/FunkinCrew/Funkin/pull/5185)

### Fixed

- Fixed a ton of performance issues to help the game run better on mobile devices.
  - Exiting the Freeplay Menu no longer freezes the game for a really long time (thanks NotHyper-474!)
  - Notestyle graphics are now preloaded before the song starts, fixing the stutter at the beginning of the song.
  - Hitting many hold note trails in one song no longer leads to a lag spike.
  - The first lightning strike in Week 2 Erect no longer creates a lag spike.
- [DESKTOP] The conductor and music no longer gradually drift out of sync to eventually trigger a resync.
- Pixel notestyle strumlines are now properly positioned when Downscroll is enabled.
- Added the missing graffiti to the wall in the Weekend 1 Blazin' stage.
- Accept keybinds now properly scroll faster through the Credits.
- Typing in most text fields in debug editors no longer triggers keyboard shortcuts.
- The Chart Editor playback speed feature now works properly.
- The Chart Editor metronome and hitsounds now play at exactly the right time.
- The Chart Editor notification box no longer covers playbar info.
- Selecting a Recent File too quickly in the Stage Editor no longer crashes the game.
- Blacklisted a few classes for security.
- Opening the logs or backups folder before it's created no longer crashes the game. ([d3490f8](https://github.com/FunkinCrew/Funkin/commit/d3490f8c9929eefb9879ad65ce43038c193642d6)) - by @NotHyper-474 in [#4940](https://github.com/FunkinCrew/Funkin/pull/4940)
- Fixed a crash when mashing D or I during startup. ([b52c73f](https://github.com/FunkinCrew/Funkin/commit/b52c73f2b0fa32fbc349804621cf947dff2d364e)) - by @CrusherNotDrip in [#5160](https://github.com/FunkinCrew/Funkin/pull/5160)
- Hot-reloading with F5 during gameplay no longer crashes the game. ([d2acb5d](https://github.com/FunkinCrew/Funkin/commit/d2acb5d167afd42299d7200ab8c67972044a09c6)) - by @AbnormalPoof in [#5065](https://github.com/FunkinCrew/Funkin/pull/5065)
- Hot-reloading with F5 in the Input Offsets menu no longer crashes the game. ([58257f6](https://github.com/FunkinCrew/Funkin/commit/58257f6ac187925f3b23d3f1eef2c812ae569a6b)) - by @NotHyper-474 in [#5085](https://github.com/FunkinCrew/Funkin/pull/5085)
- Songs no longer skip forward at the beginning with high offsets. ([1f75a64](https://github.com/FunkinCrew/Funkin/commit/1f75a641e0c80d15f1af10bae7ee71a6ffecf219)) - by @xenkap in [#3732](https://github.com/FunkinCrew/Funkin/pull/3732)
- The song countdown no longer stacks when restarting or continues behind the Pause Menu.
([63eca96](https://github.com/FunkinCrew/Funkin/commit/63eca96c98a87e7155df8b2a1735f269ea83e1b5)) - by @KoloInDaCrib and @NotHyper-474 in [#4875](https://github.com/FunkinCrew/Funkin/pull/4875)
- Fixed incorrect highlighting and squashed text on Freeplay song capsules. ([0c62428](https://github.com/FunkinCrew/Funkin/commit/0c62428fc883c0fa6d09cd403efb287ff3af8c53)) - by @VioletSnowLeopard in [#5036](https://github.com/FunkinCrew/Funkin/pull/5036)
- The Freeplay song preview no longer plays twice after returning from Character
Select. ([3d3e2bd](https://github.com/FunkinCrew/Funkin/commit/3d3e2bd3786b858143d214caf55be2ee3e9483fc)) - by @Lasercar in [#5248](https://github.com/FunkinCrew/Funkin/pull/5248)
- Freeplay song ranks no longer disappear after changing variations. ([7cc9464](https://github.com/FunkinCrew/Funkin/commit/7cc9464573d07996e4bd0d557f82847809d3a786)) - by @VioletSnowLeopard in [#4583](https://github.com/FunkinCrew/Funkin/pull/4583)
- Freeplay song capsules now cycle through long names consistently. ([e193f73](https://github.com/FunkinCrew/Funkin/commit/e193f7392a83a04e4aac85fba4f441a78f7b6668)) - by @VioletSnowLeopard in [#4677](https://github.com/FunkinCrew/Funkin/pull/4677)
- Fixed a few visual issues with Freeplay's rank slam animation. ([ab817bb](https://github.com/FunkinCrew/Funkin/commit/ab817bb1eab74ae71c1b1fd74d7512a11e6d4339)) - by @Lasercar in [#4986](https://github.com/FunkinCrew/Funkin/pull/4986)
- Fixed visual errors in Freeplay after exiting Character Select. ([56a18e1](https://github.com/FunkinCrew/Funkin/commit/56a18e1cf6a15971feebcc828be8818037948cef)) - by @KoloInDaCrib in [#5245](https://github.com/FunkinCrew/Funkin/pull/5245)
- Freeplay styles are now reloaded when hot-reloading with F5. ([f54e140](https://github.com/FunkinCrew/Funkin/commit/f54e140b65e36fcf810c52ce464799dbc0c73c6d)) - by @Keoiki in [#5286](https://github.com/FunkinCrew/Funkin/pull/5286)
- Adjusted offsets for Freeplay DJ Pico's fistPump animation. ([382e286](https://github.com/FunkinCrew/funkin.assets/commit/382e286a2478939d3d6aca1c7c90719f33815014)) - by @AbnormalPoof in [funkin.assets#91](https://github.com/FunkinCrew/funkin.assets/pull/91)
- The "New Highscore" text no longer appears more than once in the Results screen. ([4e31003](https://github.com/FunkinCrew/Funkin/commit/4e31003a0f60cd394edc2bd4586f9f385b3d07bc)) - by @Lasercar in [#4319](https://github.com/FunkinCrew/Funkin/pull/4319)
- The Results Debug menu now shows the correct rank after recent scoring changes. ([11d9998](https://github.com/FunkinCrew/Funkin/commit/11d9998e5c73a3839ea39e06b7f217cbaab69c6d)) - by @NotHyper-474 in [#4905](https://github.com/FunkinCrew/Funkin/pull/4905)
- The Input Offsets menu now exits to the Options menu instead of the Main menu. ([5361df2](https://github.com/FunkinCrew/Funkin/commit/5361df254470e68d7571b4534cf456f08d5ffd60)) - by @JackXson-Real in [#5076](https://github.com/FunkinCrew/Funkin/pull/5076)
- The Debug Menu can no longer be opened after selecting an item in the Main Menu.
([5695bc2](https://github.com/FunkinCrew/Funkin/commit/5695bc20e721f0afd5b97a36167f13e550c12b16)) - by @Lasercar in [#4211](https://github.com/FunkinCrew/Funkin/pull/4211)
- The debug cursor is now always hidden when the game starts. ([6222c38](https://github.com/FunkinCrew/Funkin/commit/6222c389e301fa2bb4939697376c4e51e29a9977)) - by @Hundrec in [#4520](https://github.com/FunkinCrew/Funkin/pull/4520)
- The Story Mode Weekend 1 level title no longer clips into other level titles below it. ([19d1a8c](https://github.com/FunkinCrew/Funkin/commit/19d1a8c59380009f0d0814c94fd0b4eccb0c80cd)) - by @KoloInDaCrib in [#4348](https://github.com/FunkinCrew/Funkin/pull/4348)
- Hold note covers now display properly if a hold note was previously dropped. ([96d1324](https://github.com/FunkinCrew/Funkin/commit/96d1324af140858cb93edd07dc36a969c8ae84c0)) - by @T5mpler in [#5275](https://github.com/FunkinCrew/Funkin/pull/5275)
- Girlfriend's and Nene's combo drop animations now play consistently. ([34d5ed1](https://github.com/FunkinCrew/Funkin/commit/34d5ed11695cef7348c13505f13fb1da38b7988c)) - by @VioletSnowLeopard in [#4968](https://github.com/FunkinCrew/Funkin/pull/4968)
- Girlfriend (Tankman Stickup) now plays her combo drop animation. ([e329601](https://github.com/FunkinCrew/funkin.assets/commit/e329601834f270910ce80ea5539e4487b9895a8a)) - by @qt2k4 in [funkin.assets#149](https://github.com/FunkinCrew/funkin.assets/pull/149)
- Darnell's idle animation now loops consistently. ([df64586](https://github.com/FunkinCrew/funkin.assets/commit/df64586771ea41c544913e049fd0f32bdc655417)) - by @qt2k4 in [funkin.assets#159](https://github.com/FunkinCrew/funkin.assets/pull/159)
- Darnell's kneeCan animation now plays properly in 2hot. ([a2e9931](https://github.com/FunkinCrew/funkin.assets/commit/a2e993167aaa2ff6bff8806940f912e444608645)) - by @biomseed in [funkin.assets#78](https://github.com/FunkinCrew/funkin.assets/pull/78)
- Otis and Pico (Speaker) no longer spaz out when playtesting Stress. ([3f6d75f](https://github.com/FunkinCrew/funkin.assets/commit/3f6d75f3b6f6c8deb660323e3fb9bf1974c06520)) - by @Lasercar in [funkin.assets#124](https://github.com/FunkinCrew/funkin.assets/pull/124)
- The gasp sound now only plays once in the Week 3 Pico Mix doppelganger cutscene. ([ab4598b](https://github.com/FunkinCrew/funkin.assets/commit/ab4598baf3c6790d30cfb727d04c8b57fa18dd0d)) - by @KoloInDaCrib in [funkin.assets#126](https://github.com/FunkinCrew/funkin.assets/pull/126)
- Fixed a few issues with the train in Week 3. ([8db2426](https://github.com/FunkinCrew/funkin.assets/commit/8db2426991caebde44d19c81b198e8e2ad86f700)) - by @ShadzXD in [funkin.assets#180](https://github.com/FunkinCrew/funkin.assets/pull/180)
- The cars in Week 4 and Weekend 1 no longer get stuck when the song is restarted. ([9c511e3](https://github.com/FunkinCrew/funkin.assets/commit/9c511e371fd08a43ddf834766a6d35667bdef4f7)) - by @MetaBreeze in [funkin.assets#186](https://github.com/FunkinCrew/funkin.assets/pull/186)
- A-Bot's visualizer no longer jumps to a random volume when the song ends. ([51cc118](https://github.com/FunkinCrew/funkin.assets/commit/51cc1186bc77a2ee45a47fdbde2d75d9ec69de3a)) - by @VioletSnowLeopard in [funkin.assets#183](https://github.com/FunkinCrew/funkin.assets/pull/183)
- Pico's burpShit animation now re-enables volume for player vocals. ([cefda0e](https://github.com/FunkinCrew/funkin.assets/commit/cefda0e52fabbbe04afe60b7aed560267e2cb01e)) - by @Hundrec in [funkin.assets#71](https://github.com/FunkinCrew/funkin.assets/pull/71)
- Removed vocals from Monster's instrumental on web builds. ([1c9473f](https://github.com/FunkinCrew/funkin.assets/commit/1c9473f3dfdfb97d97f6c8457001055322abf5ab)) - by @JVNpixels in [funkin.assets#182](https://github.com/FunkinCrew/funkin.assets/pull/182)
- Fixed the retry sound not playing after a Tankman death quote finishes. ([e7c4b1b](https://github.com/FunkinCrew/Funkin/commit/e7c4b1ba38ba0739cfe347f6c4763f9811fb95b0)) - by @VioletSnowLeopard in [#4726](https://github.com/FunkinCrew/Funkin/pull/4726)
- Darnell (BF Mix)'s alternate instrumental is now properly accessible. ([5abdabf](https://github.com/FunkinCrew/funkin.assets/commit/5abdabf69b39ca4eebd36ae6bbd77fab736d0b86)) - by @Hundrec in [funkin.assets#168](https://github.com/FunkinCrew/funkin.assets/pull/168)
- Fixed Newgrounds score submissions for Lit Up and Lit Up (BF Mix). ([183cec6](https://github.com/FunkinCrew/Funkin/commit/183cec62dc1fd3c7f3f634dd3e2400e6ee77b476)) - by @Raltyro in [#4577](https://github.com/FunkinCrew/Funkin/pull/4577)
- Inputs are now disabled before Senpai's dialogue appears. ([c43d906](https://github.com/FunkinCrew/funkin.assets/commit/c43d906d19d91d71b9096e65d5e0d3543af8cd31)) - by @anysad in [funkin.assets#165](https://github.com/FunkinCrew/funkin.assets/pull/165)
- An easter egg now restarts the song using the correct instrumental. ([e657bc9](https://github.com/FunkinCrew/Funkin/commit/e657bc900bc62cc220276dc171dd47f0a176ac66)) - by @KoloInDaCrib in [#4956](https://github.com/FunkinCrew/Funkin/pull/4956)
- Encountering an easter egg during a Chart Editor playtest no longer crashes the game. ([b53b5bd](https://github.com/FunkinCrew/funkin.assets/commit/b53b5bdaecf975555538725a4cdfe71d38565b08)) - by @NotHyper-474 in [funkin.assets#133](https://github.com/FunkinCrew/funkin.assets/pull/133)
- Nonexistent characters no longer crash the Chart Editor. ([3bbb4b0](https://github.com/FunkinCrew/Funkin/commit/3bbb4b06c8c1a1885a18d4354fcfa4363a0c6c75)) - by @Lasercar in [#5008](https://github.com/FunkinCrew/Funkin/pull/5008)
- Holding Ctrl and clicking on a hold note trail no longer crashes the Chart Editor. ([dc56cca](https://github.com/FunkinCrew/Funkin/commit/dc56ccada50e671996caf0557de1977b7ff8d236)) - by @Lasercar in [#4203](https://github.com/FunkinCrew/Funkin/pull/4203)
- Tweens and timers are now canceled when returning to the Chart Editor. ([7e76cf6](https://github.com/FunkinCrew/Funkin/commit/7e76cf66340c00ef6ec84358e6304d62815173b6)) - by @KoloInDaCrib in [#5278](https://github.com/FunkinCrew/Funkin/pull/5278)
- Reduced the severity of a memory leak in the Chart Editor. ([cce8c18](https://github.com/FunkinCrew/Funkin/commit/cce8c18822e083910200597f5db4d87b6e3b521f)) - by @NotHyper-474 in [#5247](https://github.com/FunkinCrew/Funkin/pull/5247)
- Pressing the Chart Editor keybind during a song now opens to the variation and difficulty you were playing. ([e3fca16](https://github.com/FunkinCrew/Funkin/commit/e3fca167938642bea85398fe57347c10439c1892)) - by @Lasercar in [#4116](https://github.com/FunkinCrew/Funkin/pull/4116)
- The Chart Editor now properly saves audio levels when exiting. ([f78ab4d](https://github.com/FunkinCrew/Funkin/commit/f78ab4da1db4f9527a2e1715d5cfb37670e11a74)) - by @Lasercar in [#4149](https://github.com/FunkinCrew/Funkin/pull/4149)
- The Chart Editor "Load Metadata File" and "Load Chart File" buttons now function properly. ([9df5395](https://github.com/FunkinCrew/Funkin/commit/9df5395ff888cb6740e21204c8e19116e0472db4)) - by @Lasercar in [#4278](https://github.com/FunkinCrew/Funkin/pull/4278)
- FNF Legacy files can now be opened in the Chart Editor on MacOS. ([d98628c](https://github.com/FunkinCrew/Funkin/commit/d98628ca0f9f60357715bd7f95fc686a83201209)) - by @AbnormalPoof in [#4580](https://github.com/FunkinCrew/Funkin/pull/4580)
- The Chart Editor now consistently displays the correct waveform for vocal tracks. ([c0e0523](https://github.com/FunkinCrew/Funkin/commit/c0e0523651e8aaaae2a0eed6d5fef6c5ef1b7315)) - by @NotHyper-474 in [#5231](https://github.com/FunkinCrew/Funkin/pull/5231)
- Fixed selection boxes duplicating in the Chart Editor. ([65ed583](https://github.com/FunkinCrew/Funkin/commit/65ed58350b798bca0044603510540cfe81b48611)) - by @NotHyper-474 in [#5073](https://github.com/FunkinCrew/Funkin/pull/5073)
- Fixed the Chart Editor timer occasionally displaying incorrect millisecond values. ([26dc895](https://github.com/FunkinCrew/Funkin/commit/26dc895a27e0d7e49469251cd68b83be66384e15)) - by @Hundrec in [#4257](https://github.com/FunkinCrew/Funkin/pull/4257)
- The Chart Editor playhead can no longer be scrolled to before the beginning of the song. ([7c7dc11](https://github.com/FunkinCrew/Funkin/commit/7c7dc11f18644882444df97ac927e11adaa4ce50)) - by @Hundrec in [#5024](https://github.com/FunkinCrew/Funkin/pull/5024)
- The Chart Editor playbar no longer extends past the right of the grid. ([c7abb19](https://github.com/FunkinCrew/Funkin/commit/c7abb196989476cfa4db6354cc6fac5bacb2e56a)) - by @anysad in [#5090](https://github.com/FunkinCrew/Funkin/pull/5090)
- Dragging a hold note in the Chart Editor now drags its trail along with its head. ([d3d8aaa](https://github.com/FunkinCrew/Funkin/commit/d3d8aaae7bfbfa8975a9573807b9a3ca68a1ff55)) - by @KoloInDaCrib in [#4127](https://github.com/FunkinCrew/Funkin/pull/4127)
- Hold note trails will no longer disappear when dragged too far in the Chart Editor. ([37dc66b](https://github.com/FunkinCrew/Funkin/commit/37dc66bc189bc1941cf60587e1c068770aeec872)) - by @NotHyper-474 in
[#5261](https://github.com/FunkinCrew/Funkin/pull/5261)
- Undoing and redoing hold note length changes now visually updates the trail in the Chart Editor. ([06a440f](https://github.com/FunkinCrew/Funkin/commit/06a440f21c285666ce2d2bdf17a91ee82ab01061)) - by @NotHyper-474 in [#5265](https://github.com/FunkinCrew/Funkin/pull/5265)
- The Chart Editor hold note context menu now displays the correct options. ([4801316](https://github.com/FunkinCrew/Funkin/commit/48013168ef09ddc09549268a2e5309520d3fcc18)) - by @Lasercar in [#4231](https://github.com/FunkinCrew/Funkin/pull/4231)
- The buttons in the Chart Editor context menu for selections now do the right thing. ([62d24fc](https://github.com/FunkinCrew/Funkin/commit/62d24fcf4cbe7be328a995bad04f3eeb265262c5)) - by @Lasercar in [#4233](https://github.com/FunkinCrew/Funkin/pull/4233)
- The charter field in the song metadata now properly displays the charter in the Chart Editor. ([894d8cb](https://github.com/FunkinCrew/Funkin/commit/894d8cb4637fd0a64359a5edc805a23403f3045c)) - by @Lasercar in [#4879](https://github.com/FunkinCrew/Funkin/pull/4879)
- Chart Editor difficulties are now sorted in a consistent order. ([7aa77a1](https://github.com/FunkinCrew/Funkin/commit/7aa77a11cf7508fc05758045a13b2220aca96dd5)) - by @Lasercar in [#4528](https://github.com/FunkinCrew/Funkin/pull/4528)
- Chart Editor and Stage Editor windows now consistently show a close button. ([b23b7b8](https://github.com/FunkinCrew/funkin.assets/commit/b23b7b81d843c8fa2334fbdbe1ef979633956bb9)) - by @Lasercar in [funkin.assets#121](https://github.com/FunkinCrew/funkin.assets/pull/121)
- The Chart Editor playbar's font size no longer becomes too small. ([f9c1f7a](https://github.com/FunkinCrew/Funkin/commit/f9c1f7a5f7d3906155c2004ad2ec1d02556b9730)) - by @KoloInDaCrib in [#5253](https://github.com/FunkinCrew/Funkin/pull/5253)
- The Chart Editor copy notification no longer chases the mouse cursor. ([0ea42e1](https://github.com/FunkinCrew/Funkin/commit/0ea42e18e93b0b57f1ae5499d70c4681f191dacb)) - by @KoloInDaCrib in [#4029](https://github.com/FunkinCrew/Funkin/pull/4029)
- Changed "Tankman Battlefield (Erect)" to "Tankman Battlefield [Erect]" in the Chart Editor for consistency. ([52852a0](https://github.com/FunkinCrew/funkin.assets/commit/52852a02f60df81c281bfd0e49fd8fa09e118409)) - by @JVNpixels in [funkin.assets#155](https://github.com/FunkinCrew/funkin.assets/pull/155)
- Fixed Pico (Pixel) having the incorrect name in the Chart Editor. ([3ff0e9c](https://github.com/FunkinCrew/funkin.assets/commit/3ff0e9ca4f8cdc5734c335f2d7d72fa310686d46)) - by @ExtraCode75 in [funkin.assets#158](https://github.com/FunkinCrew/funkin.assets/pull/158)
- Fixed various issues and added missing functionalities to the Stage Editor. ([a776ce1](https://github.com/FunkinCrew/Funkin/commit/a776ce1a81a539f75f8bd2220a9768c03d347058)) - by @KoloInDaCrib in [#3974](https://github.com/FunkinCrew/Funkin/pull/3974)
- Stage Editor windows are now able to be closed. ([65461d8](https://github.com/FunkinCrew/Funkin/commit/65461d839b3764659aab33f1a35edf64ee514952)) - by @Lasercar in [#5238](https://github.com/FunkinCrew/Funkin/pull/5238)
- Fixed duplicate exit prompts appearing in the Stage Editor. ([136a5df](https://github.com/FunkinCrew/Funkin/commit/136a5dfad430b461a909be3a7e89f46c8be1d3b3)) - by @Lasercar in [#5239](https://github.com/FunkinCrew/Funkin/pull/5239)
- The help guide in the Stage Editor can no longer be opened multiple times. ([564d679](https://github.com/FunkinCrew/Funkin/commit/564d679f969c500834426ce3cf50507091d69697)) - by @Lasercar in [#4128](https://github.com/FunkinCrew/Funkin/pull/4128)
- Removed a spammy console trace from Spooky Kids (Dark). ([5935a61](https://github.com/FunkinCrew/funkin.assets/commit/5935a61dd71f51e6264dcd039f1164cd1ff295ef)) - by @NotHyper-474 in [funkin.assets#187](https://github.com/FunkinCrew/funkin.assets/pull/187)
- Removed spammy console traces from `DiscordClient`. ([e89f9f5](https://github.com/FunkinCrew/Funkin/commit/e89f9f50dc6085e3550736459ce9e4fd02c1fc5b)) - by @AbnormalPoof in [#4207](https://github.com/FunkinCrew/Funkin/pull/4207)
- Removed a spammy console trace from some Chart Editor events. ([b883ad3](https://github.com/FunkinCrew/Funkin/commit/b883ad3d50b990e605d7b79d042292c7371db5f0)) - by @anysad in [#5097](https://github.com/FunkinCrew/Funkin/pull/5097)
- ANSI colors now display in the console on more computers. ([3747b94](https://github.com/FunkinCrew/Funkin/commit/3747b942461c3644fe31f25d2ce847fd74d1b1e0)) - by @AbnormalPoof in [#4676](https://github.com/FunkinCrew/Funkin/pull/4676)
- Properly blacklist a certain class from scripts. ([3dc7699](https://github.com/FunkinCrew/Funkin/commit/3dc7699aac737998b637ff9a9f16986a434424be)) - by @charlesisfeline in [#4773](https://github.com/FunkinCrew/Funkin/pull/4773)

### Removed

- Removed the VSync preference from web builds, where it's non-functional. ([0b7a94b](https://github.com/FunkinCrew/Funkin/commit/0b7a94b1cc5c5d0dbac5a4c3d595349c4e6eb6e4)) - by @NotHyper-474 in [#5062](https://github.com/FunkinCrew/Funkin/pull/5062)
- Removed a few non-functional screenshot preferences. ([93e4f79](https://github.com/FunkinCrew/Funkin/commit/93e4f799f4f0ea435b3d77ca8ef2ab6beeb0a955)) - by @Lasercar in [#4895](https://github.com/FunkinCrew/Funkin/pull/4895)

## New Contributors for 0.7.0

* @KutikiPlayz made their first contribution in [#3544](https://github.com/FunkinCrew/Funkin/pull/3544)
* @xenkap made their first contribution in [#3732](https://github.com/FunkinCrew/Funkin/pull/3732)
* @Raltyro made their first contribution in [#4577](https://github.com/FunkinCrew/Funkin/pull/4577)
* @charlesisfeline made their first contribution in [#4773](https://github.com/FunkinCrew/Funkin/pull/4773)
* @T5mpler made their first contribution in [#5275](https://github.com/FunkinCrew/Funkin/pull/5275)
* @biomseed made their first contribution in [funkin.assets#78](https://github.com/FunkinCrew/funkin.assets/pull/78)
* @qt2k4 made their first contribution in [funkin.assets#149](https://github.com/FunkinCrew/funkin.assets/pull/149)
* @ExtraCode75 made their first contribution in [funkin.assets#158](https://github.com/FunkinCrew/funkin.assets/pull/158)
* @MetaBreeze made their first contribution in [funkin.assets#186](https://github.com/FunkinCrew/funkin.assets/pull/186)



## [0.6.4] - 2025-05-02

### Changed

- Misses now actually reduce your clear percentage and rank, as Eric intended. ([5fdbd23](https://github.com/FunkinCrew/Funkin/commit/5fdbd23a17b8eaf21582283400be2c6444e8b198)) - by @Lasercar in [#4880](https://github.com/FunkinCrew/Funkin/pull/4880)
- The miss rebalance is now reflected on the Freeplay clear percent display. ([f6ac4ca](https://github.com/FunkinCrew/Funkin/commit/f6ac4cad43f4834a86a3fc156d6d39eca2c47c7e)) - by @Lasercar, @Hundrec, and @NotHyper-474 in [#4898](https://github.com/FunkinCrew/Funkin/pull/4898) and [#4923](https://github.com/FunkinCrew/Funkin/pull/4923)

### Fixed

- HTML5 builds are no longer literally unplayable. ([6f43438](https://github.com/FunkinCrew/Funkin/commit/6f43438cdbfecf26d4bcf62a0d9ff71e40333ac2)) - by @cyn0x8 in [#4398](https://github.com/FunkinCrew/Funkin/pull/4398)
- Medals no longer crash the game when obtained. ([808698a](https://github.com/FunkinCrew/Funkin/commit/808698ace7457bc76a8a52d415d63fa4ee5b9400)) - by @KoloInDaCrib in [#4815](https://github.com/FunkinCrew/Funkin/pull/4815)
- The game no longer crashes when reaching the main menu before authenticating with Newgrounds. ([a83a4a5](https://github.com/FunkinCrew/Funkin/commit/a83a4a599c2e407832ef9bbe47bb8b8c07ce712a)) - by @NotHyper-474 in [#4871](https://github.com/FunkinCrew/Funkin/pull/4871)
- User preferences and other settings are now properly saved after restarting the game. ([23a9e7f](https://github.com/FunkinCrew/Funkin/commit/23a9e7f944fb703160c2ed7b0bef38c70c5370db)) - by @Lasercar in [#4881](https://github.com/FunkinCrew/Funkin/pull/4881)
- Texture atlas sprites no longer loop infinitely, fixing issues with multiple cutscenes. ([f385cf9](https://github.com/FunkinCrew/Funkin/commit/f385cf9fd33e5358427f40dad3fecfed233c1706)) - by @AbnormalPoof in [#4564](https://github.com/FunkinCrew/Funkin/pull/4564)
- The Week 3 Pico Mix cutscene no longer breaks with Naughtyness turned off. ([e3aba5c](https://github.com/FunkinCrew/funkin.assets/commit/e3aba5c4faa8e8c705c3e0daf04e30db7ac5a136)) - by @Lasercar in [funkin.assets#169](https://github.com/FunkinCrew/funkin.assets/pull/169)
- Adjusted the pixel strumline’s position when Downscroll is enabled to match the regular notestyle. ([ea93ec9](https://github.com/FunkinCrew/Funkin/commit/ea93ec90cb5c5dbd4a5bea64114af58c70cb43f4)) - by @Lasercar in [#4318](https://github.com/FunkinCrew/Funkin/pull/4318)
- The Main Menu now correctly remembers your most recently selected menu item. ([05b9d68](https://github.com/FunkinCrew/Funkin/commit/05b9d68645b71c9cc36a5cb0c0e93af6acb36132)) - by @Lasercar and @Hundrec in [#4227](https://github.com/FunkinCrew/Funkin/pull/4227)
- Fixed an occasional softlock when returning to the Freeplay menu from a song. ([b15e809](https://github.com/FunkinCrew/Funkin/commit/b15e809c63664e039781592dcbdee4383e73800e)) - by @TechnikTil in [#4665](https://github.com/FunkinCrew/Funkin/pull/4665)
- Switching to and from the Freeplay Random capsule now behaves more consistently. ([832bc5b](https://github.com/FunkinCrew/Funkin/commit/832bc5bd83d49a646b9c8cb2b767602c848be908)) - by @VioletSnowLeopard in [#4885](https://github.com/FunkinCrew/Funkin/pull/4885)
- Changing Freeplay filters with the Random capsule selected now behaves more consistently. ([edf6889](https://github.com/FunkinCrew/Funkin/commit/edf6889af9e7f68caead9b8139178a36b4b5b2d6)) - by @VioletSnowLeopard in [#4913](https://github.com/FunkinCrew/Funkin/pull/4913)
- Switching between identical Freeplay filters no longer makes the songlist invisible. ([8b9775d](https://github.com/FunkinCrew/Funkin/commit/8b9775d91f4f2b5896a637a014b4be770319968e)) - by @VioletSnowLeopard in [#4919](https://github.com/FunkinCrew/Funkin/pull/4919)
- The millions place digit of the Freeplay score display now updates properly. ([d9fcaf0](https://github.com/FunkinCrew/Funkin/commit/d9fcaf0e6382b121f7773d23f4864364a1e6a577)) - by @Lasercar in [#4065](https://github.com/FunkinCrew/Funkin/pull/4065)
- The Freeplay clear percent display is now more consistently aligned. ([329182e](https://github.com/FunkinCrew/funkin.assets/commit/329182ea1b6839187a1d800b2d009a4c1874479d)) - by @Hundrec in [funkin.assets#37](https://github.com/FunkinCrew/funkin.assets/pull/37)
- The Freeplay alternate instrumental selector now disables all other inputs. ([664d9e0](https://github.com/FunkinCrew/Funkin/commit/664d9e0fb3f8b93b1f941fb3b6724c37f5b9e5b5)) - @Lasercar in [#4214](https://github.com/FunkinCrew/Funkin/pull/4214)
- The Freeplay alternate instrumental selector no longer becomes offset when changing difficulties. ([664d9e0](https://github.com/FunkinCrew/Funkin/commit/664d9e0fb3f8b93b1f941fb3b6724c37f5b9e5b5)) - @Lasercar in [#4214](https://github.com/FunkinCrew/Funkin/pull/4214)
- Exiting and then navigating through the Freeplay alternate instrumental selector no longer crashes the game. ([664d9e0](https://github.com/FunkinCrew/Funkin/commit/664d9e0fb3f8b93b1f941fb3b6724c37f5b9e5b5)) - @Lasercar in [#4214](https://github.com/FunkinCrew/Funkin/pull/4214)
- Ranks no longer overwrite themselves in the Freeplay new rank animation. ([664d9e0](https://github.com/FunkinCrew/Funkin/commit/664d9e0fb3f8b93b1f941fb3b6724c37f5b9e5b5)) - @Lasercar in [#4214](https://github.com/FunkinCrew/Funkin/pull/4214)
- The debris in Pico’s Great Results animation no longer grows in size. ([c108a7f](https://github.com/FunkinCrew/funkin.assets/commit/c108a7ff0d11bf328e7b232160b8f68c71e21bca)) - by @ThatRozebudDude in [funkin.assets#73](https://github.com/FunkinCrew/funkin.assets/pull/73)
- Fixed the song not starting if more than 32 sounds are playing at once. ([31d3718](https://github.com/FunkinCrew/Funkin/commit/31d3718e5c33371cacd495219f9cc3908244bf71)) - by @KoloInDaCrib in [#4352](https://github.com/FunkinCrew/Funkin/pull/4352)
- Hot reloading (pressing F5) during dialogue no longer crashes the game. ([3e0dbe2](https://github.com/FunkinCrew/Funkin/commit/3e0dbe2758d68ccf4ded1d08bec247ab05d70829)) - by @KoloInDaCrib in [#4769](https://github.com/FunkinCrew/Funkin/pull/4769)
- Restarting a song without either a player or an opponent no longer crashes the game, fixing minimal playtest mode. ([bbc0546](https://github.com/FunkinCrew/Funkin/commit/bbc0546c7450b929dc78ad9271171ea899478e9d)) - by @thesuperpig56 in [#4778](https://github.com/FunkinCrew/Funkin/pull/4778)
- The sound tray no longer behaves incorrectly after wiping save data. ([afbb335](https://github.com/FunkinCrew/Funkin/commit/afbb3359938f020707efd92a17419e3658528ea5)) - by @Lasercar in [#4617](https://github.com/FunkinCrew/Funkin/pull/4617)
- Opening a chart from the “Open Recent” section no longer crashes the Chart Editor. ([def1b74](https://github.com/FunkinCrew/Funkin/commit/def1b74eb6987272bc360cbf586ddcd1c26c6381)) - by @CrusherNotDrip in [#4936](https://github.com/FunkinCrew/Funkin/pull/4936)
- Loading an invalid variation in the Chart Editor no longer crashes the game. ([c5f2a74](https://github.com/FunkinCrew/Funkin/commit/c5f2a744940dbc685b25373fa2dabb548f0b26fa)) - by @NotHyper-474 in [#4391](https://github.com/FunkinCrew/Funkin/pull/4391)
- Default difficulties are no longer re-added when saving and loading a .FNFC chart. ([8074d57](https://github.com/FunkinCrew/Funkin/commit/8074d571860aba2c2f6f1c642d8d0e671ff5355e)) - by @Lasercar in [#4216](https://github.com/FunkinCrew/Funkin/pull/4216)
- The Chart Editor now resizes properly after entering Fullscreen during a playtest. ([142ea6d](https://github.com/FunkinCrew/Funkin/commit/142ea6db0c53f6f9288109604702c2e7e5bc6f18)) - by @NotHyper-474 in [#4266](https://github.com/FunkinCrew/Funkin/pull/4266)
- Added three missing hotkeys to the Chart Editor user guide. ([73ccb9a](https://github.com/FunkinCrew/funkin.assets/commit/73ccb9a80d08f3311f51cf88950692d7c1ea5d60)) - by @NotHyper-474 and @Hundrec in [funkin.assets#83](https://github.com/FunkinCrew/funkin.assets/pull/83)
- The “Skip Forward” button is no longer named “Skip Back” in the Chart Editor. ([78f9fb7](https://github.com/FunkinCrew/funkin.assets/commit/78f9fb7cb6eaf7466826f144a0142c008fbff2f8)) - by @Hundrec in [funkin.assets#22](https://github.com/FunkinCrew/funkin.assets/pull/22)
- Exporting a character .JSON from the Animation Editor now fills in the file name. ([a8262a8](https://github.com/FunkinCrew/Funkin/commit/a8262a8d3b4d2169327131e21c98f803da4a5ee4)) - by @anysad in [#3090](https://github.com/FunkinCrew/Funkin/pull/3090)
- Properly credited MtH as a Charter in Monster’s metadata. ([6a10799](https://github.com/FunkinCrew/funkin.assets/commit/6a10799a40eb2b2deb364bcd3cc4387abe8e8bc4)) - by @ChillyBeanBAM in [funkin.assets#66](https://github.com/FunkinCrew/funkin.assets/pull/66)
- Corrected the chances of a Pause Menu easter egg appearing. ([0101bae](https://github.com/FunkinCrew/Funkin/commit/0101bae7ecc800e26efd9590fdfa1305039b4461)) - by @VioletSnowLeopard in [#4358](https://github.com/FunkinCrew/Funkin/pull/4358)
- Removed spammy traces for Playable Pico’s animations. ([f87255d](https://github.com/FunkinCrew/funkin.assets/commit/f87255d4bcb7a7ce0dc920aefc36b98a96115c75)) - by @VioletSnowLeopard in [funkin.assets#179](https://github.com/FunkinCrew/funkin.assets/pull/179)
- Fixed memory overflowing in crash logs. ([189e028](https://github.com/FunkinCrew/Funkin/commit/189e028442c7fb892ce4dab62a5d08db658f3b2b)) - by @ACrazyTown in [#4589](https://github.com/FunkinCrew/Funkin/pull/4589)

### Removed

- The CHANGELOG.md file will no longer be included in builds. Visit the [Funkin' GitHub](https://github.com/FunkinCrew/Funkin/blob/main/CHANGELOG.md) to view the latest changes! ([a7da71c](https://github.com/FunkinCrew/Funkin/commit/a7da71c8a87baa440a0bc6e23d7e9b36c7574e14)) - by @Hundrec and @NotHyper-474 in [#4868](https://github.com/FunkinCrew/Funkin/pull/4868)

## New Contributors for 0.6.4

* @thesuperpig56 made their first contribution in [#4778](https://github.com/FunkinCrew/Funkin/pull/4778)
* @CrusherNotDrip made their first contribution in [#4936](https://github.com/FunkinCrew/Funkin/pull/4936)
* @ChillyBeanBAM made their first contribution in [funkin.assets#66](https://github.com/FunkinCrew/funkin.assets/pull/66)
* @ThatRozebudDude made their first contribution in [funkin.assets#73](https://github.com/FunkinCrew/funkin.assets/pull/73)



## [0.6.3] - 2025-04-25

### Added

- New option in the Preferences menu: VSync!
  - Set it to Off, On, or Adaptive
  - Adaptive turns VSync off during FPS drops, which is better if supported by your graphics card.
  - Doesn't work on Mac, sorry!
- Otis now has muzzle flashes when shooting.
- Added a little easter egg to one of Pico's Results Screen animations.
- Overhauled the sticker system to allow modders to easily add custom sticker sets. ([cdc468b](https://github.com/FunkinCrew/Funkin/commit/cdc468ba15683b3c0f54015e337673c77ddd7962)) - by @AbnormalPoof in [#4003](https://github.com/FunkinCrew/Funkin/pull/4003)
- Implemented a macro to optimize registries and entries. ([1497521](https://github.com/FunkinCrew/Funkin/commit/14975212a918adb1a5d96a349ec9e8e63c9fc64b)) - by @lemz1 in [#3694](https://github.com/FunkinCrew/Funkin/pull/3694)
- The macro is now used to retrieve base game assets. ([963e2ec](https://github.com/FunkinCrew/Funkin/commit/963e2ecd630fae24dae4206d315618cf4c4be6db)) - by @lemz1 in [#4707](https://github.com/FunkinCrew/Funkin/pull/4707)
- The Chart Editor now displays the current beat and step of the playhead. ([83bb3bb](https://github.com/FunkinCrew/Funkin/commit/83bb3bb5074ecb5f50ee21979711efcda9d8017d)) - by @NotHyper-474 in [#4649](https://github.com/FunkinCrew/Funkin/pull/4649)

### Changed

- The mod API version is now 0.6.3.
  - Be sure to update the version in your mods' metadata, then ensure they are still working!
- Eric's scoring rebalance update!
  - Misses (not ghost misses) are now worth -100 points, up from -10.
  - Hold note trails now grant 20% less health.
  - Dropping a hold note early now plays the miss animation and deducts health and score.
- Made a LOT of charting changes!
  - Many missing, extra, and mistimed notes have been corrected.
  - Stacked notes that were preventing full combos have been removed.
  - Camera events have been adjusted to stay within the boundaries of the stage.
  - Some songs have been recharted.
- The Freeplay menu can now always switch between variations.
  - The nearest song with an Erect variation will be selected when switching.
- Switching difficulties now always plays the capsule jump-in animation.
- The "Random" capsule now plays animations consistent with other capsules.
- The Eggnog Erect cutscene can now be skipped. ([0303a03](https://github.com/FunkinCrew/funkin.assets/commit/1202651db8ea938fe11b6b734fbf7884d101e6ad)) - by @ShadzXD in [funkin.assets#62](https://github.com/FunkinCrew/funkin.assets/pull/62)
- Swapped the positions of “skip” and “restart” items in the dialogue pause menu for consistency. ([1f88a3b](https://github.com/FunkinCrew/Funkin/commit/1f88a3b6e13e9283ad680805deab5e27ba141d96)) - by @VioletSnowLeopard in [#4553](https://github.com/FunkinCrew/Funkin/pull/4553)
- The Controls menu now prevents unbinding essential UI controls to safeguard against softlocking save files. ([7eebce4](https://github.com/FunkinCrew/Funkin/commit/7eebce432d7627a1cf0bbd43f22a6f9bcb63ff65)) - by @VioletSnowLeopard in [#4382](https://github.com/FunkinCrew/Funkin/pull/4382)
- Renamed “Auto Pause” preference to “Pause on Unfocus” for clarity. ([52be941](https://github.com/FunkinCrew/Funkin/commit/52be941b4503da0ac76918e2482ab1804866f2cf)) - by @JackXson-Real in [#4346](https://github.com/FunkinCrew/Funkin/pull/4346)
- Overhauled `FileUtil`, introducing various fixes, new functions, and sandboxing. ([95ade2a](https://github.com/FunkinCrew/Funkin/commit/95ade2a08b7709e8208ec1b3e123bf5b4308ba10)) - by @cyn0x8 in [#3032](https://github.com/FunkinCrew/Funkin/pull/3032)

### Fixed

- Story mode medals are now awarded even without scoring a new personal best.
- Highscores are now submitted to Newgrounds even without scoring a new personal best.
- The Freeplay menu no longer displays songs without Erect variations when returning from an Erect variation song.
- Fixed Freeplay DJ animations for Boyfriend and Pico when idling (properly this time).
- Alternate instrumentals for Cocoa, Senpai, Roses, and Stress are now locked until their Pico Mix is beaten.
- The Roses Pico alternate instrumental is now offset to align with the original song's voices.
- Entering Stress or Stress (Pico Mix) a second time no longer crashes the game.
- Restarting Stress or Stress (Pico Mix) no longer spawns too many Tankmen in the background.
- Pico's game over animation now displays properly on Ugh (Pico Mix) and Guns (Pico Mix).
- Tankman's death lines now play for Boyfriend in Ugh, Guns, and Ugh Erect.
- Week 6 dialogue no longer plays for all non-default variations when entered through Freeplay.
- Nene (Pixel) now plays her knife raising animation when the player has low health.
- A-Bot's visualizer is now blank before the song starts.
- Debug editor tooltips no longer display behind windows.
- Clearing save data no longer crashes the game.
- Adding custom parameters to note kinds no longer crashes the Chart Editor. ([0a7bd31](https://github.com/FunkinCrew/Funkin/commit/0a7bd3111f59efbecfe097f8bbcfdefa5ace299d)) - by @Lasercar in [funkin.assets#136](https://github.com/FunkinCrew/funkin.assets/pull/136)
- Improved performance in the Freeplay menu before entering a song. ([2b7254f](https://github.com/FunkinCrew/Funkin/commit/2b7254fbd2356e9da91e216f178a88f17874a6eb)) - by @superpowers04 in [#4729](https://github.com/FunkinCrew/Funkin/pull/4729)
- Prevented a crash by capping Freeplay and Results screen score displays at their largest possible values (actual scores are not capped). ([51324e9](https://github.com/FunkinCrew/Funkin/commit/51324e9c283c43ca861d3369ba9b3e1db9c89765)) - by @KoloInDaCrib in [#3634](https://github.com/FunkinCrew/Funkin/pull/3634)
- The Animation Editor no longer crashes when opened. ([b40b4b0](https://github.com/FunkinCrew/Funkin/commit/b40b4b03692910afceff361cf6ca3298fd787e3c)) - by @sector-a in [#4582](https://github.com/FunkinCrew/Funkin/pull/4582)
- Disabled navigation in the Options menu while the Clear Save Data prompt is open. ([855deb5](https://github.com/FunkinCrew/Funkin/commit/855deb58280e850c0ad1581807c70f05d6b6a2cb)) - by @KoloInDaCrib in [#4703](https://github.com/FunkinCrew/Funkin/pull/4703)
- Save data is no longer wiped after failing to load the current save. ([068c9fb](https://github.com/FunkinCrew/Funkin/commit/068c9fb43d49ff6ea13e5a73f77a42207954be2c)) - by @KoloInDaCrib in [#4574](https://github.com/FunkinCrew/Funkin/pull/4574)
- Selecting a different type of event in the Chart Editor no longer crashes or resets the event to its default values. ([71ed154](https://github.com/FunkinCrew/Funkin/commit/71ed154b81abbd002d78c09c2dada8a2ad3fa73e)) - by @KoloInDaCrib in [#3913](https://github.com/FunkinCrew/Funkin/pull/3913)
- Deleting a stacked event in the Chart Editor now properly removes the deleted event’s sprite. ([3ad14ba](https://github.com/FunkinCrew/Funkin/commit/3ad14bac32096e45259997ab9957bec5fecf296f)) - by @NotHyper-474 in [#4724](https://github.com/FunkinCrew/Funkin/pull/4724)
- Patched a security vulnerability. ([53dec05](https://github.com/FunkinCrew/Funkin/commit/53dec057bee0a913d60e0c70d45dbb59a58620b0)) - by @nebulazorua in [#4740](https://github.com/FunkinCrew/Funkin/pull/4740)
- Added null safety to a bunch of classes.
- Even more tiny bug fixes.

## New Contributors for 0.6.3

* @JackXson-Real made their first contribution in [#4346](https://github.com/FunkinCrew/Funkin/pull/4346)
* @VioletSnowLeopard made their first contribution in [#4382](https://github.com/FunkinCrew/Funkin/pull/4382)
* @superpowers04 made their first contribution in [#4729](https://github.com/FunkinCrew/Funkin/pull/4729)
* @ShadzXD made their first contribution in [funkin.assets#62](https://github.com/FunkinCrew/funkin.assets/pull/62)



## [0.6.2] - 2025-03-31

### Added

- Updated the 0.6 credits list

### Fixed

- Additional shader fix for Stress (Pico Mix) crashing at the end (was the same issue as Senpai Pico shader error, just in a different shaderfile)



## [0.6.1] - 2025-03-31

### Fixed

- Hopefully Senpai Pico/Erect mix shader isn't brokey
- NG API encryption key was added proper, so medals + leaderboards posting should work



## [0.6.0] - 2025-03-31
The Pit Stop 2 update!

### Added

- Added six (!) new playable songs! Check them out in the Freeplay menu for their respective characters.
  - Cocoa (Pico Mix)
  - Senpai (Pico Mix)
  - Roses (Pico Mix)
  - Stress (Pico Mix)
  - Darnell Erect
  - Lit Up (BF Mix)
- Senpai (Pico Mix) and Roses (Pico Mix) take place on a new Erect variant of the Week 6 stage!
  - This stage is now used by Senpai Erect, Roses Erect, and Thorns Erect.
- Stress (Pico Mix) takes place on a new Erect variant of the Week 7 stage!
  - This stage is now used by Ugh Erect, Ugh (Pico Mix), and Guns (Pico Mix).
- Newly revamped Newgrounds integration! You can now earn Medals and submit scores to the Leaderboards while logged in on Newgrounds!
  - Existing medals have been re-enabled, and new medals have been added! Think you're a Rap God?
  - This feature is also available on desktop, check the options menu to find the prompt to login.
  - There is no feature to view unlocked medals in-game yet, but the feature is planned.
- Reworked the sticker system to allow different sets of stickers to be used for different characters and songs.
  - Added new stickers which appear when exiting Pico songs!
  - The new sticker system isn't fully available to mods yet, but we're working on it!
- New option in the Preferences menu: Strumline Backgrounds!
- Options in the Preferences menu now display an on-screen description when selected.
- New song event type in the Chart Editor: Set Health Icon!
  - This event is now used in Stress (Pico Mix).
- The HOME and END keys now jump to the top and bottom of the Freeplay song list, respectively. ([bb974c2](https://github.com/FunkinCrew/Funkin/commit/bb974c264270d10ff503784063e5d77bb352b3f7)) - by @AbnormalPoof in [#4103](https://github.com/FunkinCrew/Funkin/pull/4103)
- Added an option to launch the game in fullscreen. ([ee53ccd](https://github.com/FunkinCrew/Funkin/commit/ee53ccd32721e0790adfe82c60d4aca419db0a7f)) - by @AbnormalPoof in [#3738](https://github.com/FunkinCrew/Funkin/pull/3738)
- Added on-screen descriptions for each item in the Preferences menu. ([a17b0e8](https://github.com/FunkinCrew/Funkin/commit/a17b0e8b3cc1d56fcdc0b51eaca9fd57cdb5bce0)) - by @anysad in [#3872](https://github.com/FunkinCrew/Funkin/pull/3872)
- Added precise scrolling in the Chart Editor using Ctrl-Mouse Wheel. ([0d8e4a5](https://github.com/FunkinCrew/Funkin/commit/0d8e4a53305d6d069454812766300122f3581e31)) - by @ninjamuffin99 in [#3806](https://github.com/FunkinCrew/Funkin/pull/3806)
- Added a “None” option to the character selector in the Chart Editor. ([9c2ef02](https://github.com/FunkinCrew/Funkin/commit/9c2ef0236818883ad1275571dac49eab70ca0ea0)) - by @Lasercar in [#4279](https://github.com/FunkinCrew/Funkin/pull/4279)
- Added the ability to flip the character horizontally in the Animation Editor by pressing G. ([de02137](https://github.com/FunkinCrew/Funkin/commit/de02137d7c7d1779e85aeda34743f506a5b9cc27)) - by @AbnormalPoof in [#3028](https://github.com/FunkinCrew/Funkin/pull/3028)
- Added offsets support for album titles. ([69d8570](https://github.com/FunkinCrew/Funkin/commit/69d8570a9eb06011ed6dd95fcbef83d90f7f8684)) - by @AbnormalPoof in [#3618](https://github.com/FunkinCrew/Funkin/pull/3618)
- Added three new properties to stage data: `angle`, `scroll`, and `alpha`. ([ff56b19](https://github.com/FunkinCrew/Funkin/commit/ff56b1948aef42bbb6bb4ede4f9b2012d49ab044)) - by @AbnormalPoof in [#3720](https://github.com/FunkinCrew/Funkin/pull/3720)
- Added script events for losing/gaining focus. ([4b127b6](https://github.com/FunkinCrew/Funkin/commit/4b127b64130f6f753d0574ec66a1672322e4bd13)) - by @AbnormalPoof in [#3721](https://github.com/FunkinCrew/Funkin/pull/3721)
- Added 10 new functions to `ReflectUtil`. ([6216655](https://github.com/FunkinCrew/Funkin/commit/62166554e7a176245d1a63bd15122033044c4e40)) - by @AbnormalPoof in [#3622](https://github.com/FunkinCrew/Funkin/pull/3622), [#3809](https://github.com/FunkinCrew/Funkin/pull/3809), and [#4019](https://github.com/FunkinCrew/Funkin/pull/4019)
- Added `DEBUG_BUILD` value to `Constants` to indicate whether a build has debug functions enabled. ([ad45b72](https://github.com/FunkinCrew/Funkin/commit/ad45b72b1ae8eb73a12dc51bcb59f66cc55e7bbd)) - by @AbnormalPoof in [#3853](https://github.com/FunkinCrew/Funkin/pull/3853)

### Changed

- Switched from hxCodec to hxvlc for video playback. This may break a mod or two.
  - Check the [Funkin Modding Docs](https://funkincrew.github.io/funkin-modding-docs/09-migration/09-02-0.5.0-to-0.6.0.html) for more info on how to update your mods.
- Polymod should now ignore `.git` files when loading mods.
- The pause menu can now be opened and closed rapidly.
- Adjusted difficulty ratings and scroll speeds for many songs.
- Chart Editor event fields now allow for values to be as specific as desired.
  - For example, the Zoom Camera event can now be set to 0.9857.
- Lots of improvements to GitHub issue and pull request organization. - by @Hundrec and @AbnormalPoof
- Overhauled the Changelog to improve readability and properly credit contributors. ([4383fcf](https://github.com/FunkinCrew/Funkin/commit/4383fcf32c280a1c0ee7b9c80d255611d497cabc)) - by @Hundrec in [#4296](https://github.com/FunkinCrew/Funkin/pull/4296) and [#4298](https://github.com/FunkinCrew/Funkin/pull/4298)
- Made various improvements to the screenshot plugin. ([868932c](https://github.com/FunkinCrew/Funkin/commit/868932cd138fad4be5b541cbea3110e30479057b)) - by @Lasercar in [#4082](https://github.com/FunkinCrew/Funkin/pull/4082)
- Accept keybinds (Z and Space by default) can now be used to exit the Results screen. ([edb270d](https://github.com/FunkinCrew/Funkin/commit/edb270d15e41784dccbf75639ac731840e80fe23)) - by @JVNpixels in [#3799](https://github.com/FunkinCrew/Funkin/pull/3799)
- Reordered UI keybinds in the controls menu for consistency. ([a01bcc3](https://github.com/FunkinCrew/Funkin/commit/a01bcc3da836ec52851ca9de13ef459daf61269a)) - by @lemz1 in [#3027](https://github.com/FunkinCrew/Funkin/pull/3027)
- New save files now have default Freeplay controls for gamepads. ([2b7f62e](https://github.com/FunkinCrew/Funkin/commit/2b7f62edd33de5527e259d9e5643f926d35da734)) - by @MrMadera in [#3934](https://github.com/FunkinCrew/Funkin/pull/3934)
- Made scrolling smoother in the Chart Editor. ([20d9016](https://github.com/FunkinCrew/Funkin/commit/20d90169845f1e50f849e39f4c5f818359756c78)) - by @ninjamuffin99 in [#3768](https://github.com/FunkinCrew/Funkin/pull/3768)
- Mods with missing dependencies are now skipped instead of preventing all mods from loading. ([1c2fb43](https://github.com/FunkinCrew/Funkin/commit/1c2fb43ae16cf40be5ef94c40b047e8e772b1211)) - by @AbnormalPoof in [#3993](https://github.com/FunkinCrew/Funkin/pull/3993)
- Slightly improved flexibility for modding note hit animations. ([3aad825](https://github.com/FunkinCrew/Funkin/commit/3aad825f865c4ed87016983d44121e2c1610d332)) - by @TechnikTil in [#3936](https://github.com/FunkinCrew/Funkin/pull/3936)
- Introduced several QoL modding changes. ([785c4be](https://github.com/FunkinCrew/Funkin/commit/785c4be88b52dc1b5899013822fc004ba7d9894d)) - by @Kade-github in [#4009](https://github.com/FunkinCrew/Funkin/pull/4009)
- Lots of smaller changes.

### Fixed

- Shaders no longer create thin seams within atlas sprites.
- Completing a song in Practice Mode no longer plays a new rank animation in the Freeplay menu.
- Fixed lots of charting issues across many songs.
- The Chart Editor grid now properly adjusts to the new BPM after switching variations.
- Fixed a few crashes in the Stage Editor.
- Fixed a bug where the song would restart from the beginning instead of moving to the Results screen. ([3667c51](https://github.com/FunkinCrew/Funkin/commit/3667c51c1efe14cfe7c810e2f35991f08f50781a)) - by @KoloInDaCrib in [#4309](https://github.com/FunkinCrew/Funkin/pull/4309) and @Lasercar in [#4330](https://github.com/FunkinCrew/Funkin/pull/4330)
- Reduced stuttering when resyncing instrumental and voices tracks. ([22d41d2](https://github.com/FunkinCrew/Funkin/commit/22d41d21b88acb7422a0afcda8414682710bd2ed)) - by @TechnikTil in [#3955](https://github.com/FunkinCrew/Funkin/pull/3955)
- Songs with only instrumental tracks no longer stutter. ([dfe02ec](https://github.com/FunkinCrew/Funkin/commit/dfe02ec668b61d6308f459c978d12a7487f9dc28)) - by @KoloInDaCrib in [#3861](https://github.com/FunkinCrew/Funkin/pull/3861)
- The debug mouse cursor no longer flickers before the Title Screen loads. ([1c12b84](https://github.com/FunkinCrew/Funkin/commit/1c12b8467eca350eb28138473360d5358fa620e2)) - by @sphis-Sinco in [#3881](https://github.com/FunkinCrew/Funkin/pull/3881)
- Unbound keys now display as [N/A] instead of crashing the game. ([099c309](https://github.com/FunkinCrew/Funkin/commit/099c309f9babdc1ea99b7dbed3fdccf1e952fc8e)) - by @NotHyper-474 in [#4355](https://github.com/FunkinCrew/Funkin/pull/4355)
- Songs can no longer be spam-selected after selecting an instrumental in Freeplay. ([0e0c4ae](https://github.com/FunkinCrew/Funkin/commit/0e0c4aeb7745cfb9479685ccbb635cf3743cddbb)) - by @AbnormalPoof in [#3866](https://github.com/FunkinCrew/Funkin/pull/3866)
- The Random capsule can now switch to Erect/Nightmare difficulties in Freeplay. ([a90b911](https://github.com/FunkinCrew/Funkin/commit/a90b911653a1beaba57d64b1f05b840109fec42b)) - by @KoloInDaCrib in [#3838](https://github.com/FunkinCrew/Funkin/pull/3838)
- Fixed a rare bug where a song would not register as beaten. ([a3e2373](https://github.com/FunkinCrew/Funkin/commit/a3e23733db104b1ef00cfcff17db3a5d032a4d67)) - by @AbnormalPoof in [#3820](https://github.com/FunkinCrew/Funkin/pull/3820)
- The difficulty graphic on the Results screen no longer cuts off incorrectly. ([b13bf05](https://github.com/FunkinCrew/Funkin/commit/b13bf05d16ff2977309e0c7ba3f049c0134e8902)) - by @AbnormalPoof in [#4161](https://github.com/FunkinCrew/Funkin/pull/4161)
- Four-digit long Total Notes values in the Results screen no longer overflow to the right. ([91a594c](https://github.com/FunkinCrew/Funkin/commit/91a594cc858ed086cd2146a1ac5d2379c6fdd27a)) - by @Hundrec in [#4356](https://github.com/FunkinCrew/Funkin/pull/4356)
- The Character Select screen no longer plays the unlock animation for some locked characters. ([7058126](https://github.com/FunkinCrew/Funkin/commit/7058126e99adb55e43f5f487b007d3efa9f324d5)) - by @AbnormalPoof in [#3748](https://github.com/FunkinCrew/Funkin/pull/3748)
- All time signatures in the Chart Editor now display the correct number of beat/step tick lines. ([e570dfb](https://github.com/FunkinCrew/Funkin/commit/e570dfb8e754f9cb29ac2d8fff6e8513bc68b630)) - by @Keoiki in [#2860](https://github.com/FunkinCrew/Funkin/pull/2860)
- The Debug menu now opens with the correct camera position. ([090ddd1](https://github.com/FunkinCrew/Funkin/commit/090ddd1f1c2aa48fdb83127b2235041643c99af5)) - by @ninjamuffin99 in [#3769](https://github.com/FunkinCrew/Funkin/pull/3769)
- Finally added an outline to the third GF sticker. [9e62572](https://github.com/FunkinCrew/funkin.assets/commit/9e62572ae27dc676c624a81af5c755490eb2dafe) - @M7theguy in [funkin.assets#33](https://github.com/FunkinCrew/funkin.assets/pull/33)
- Removed an unused Freeplay class left over from legacy versions. ([abe4ac8](https://github.com/FunkinCrew/Funkin/commit/abe4ac8485539cbebe527a9a75698950232b68d2)) - by @AbnormalPoof in [#4370](https://github.com/FunkinCrew/Funkin/pull/4370)
- Blacklisted an additional class for security. ([3492d41](https://github.com/FunkinCrew/Funkin/commit/3492d412c65c7f3fd61e6fc6c9410d8467122ab0)) - by @AbnormalPoof in [#4074](https://github.com/FunkinCrew/Funkin/pull/4074)
- Removed an unused class from Polymod blacklist. ([06c12e3](https://github.com/FunkinCrew/Funkin/commit/06c12e36c6bd6df4e2be32a3bec540172e79e162)) - by @AbnormalPoof in [#3729](https://github.com/FunkinCrew/Funkin/pull/3729)
- Many additional small bug fixes.

## New Contributors for 0.6.0

* @PatoFlamejanteTV made their first contribution in [#3843](https://github.com/FunkinCrew/Funkin/pull/3843)
* @sphis-Sinco made their first contribution in [#3881](https://github.com/FunkinCrew/Funkin/pull/3881)
* @MrMadera made their first contribution in [#3934](https://github.com/FunkinCrew/Funkin/pull/3934)
* @MidyGamy made their first contribution in [#4068](https://github.com/FunkinCrew/Funkin/pull/4068)
* @Lasercar made their first contribution in [#4082](https://github.com/FunkinCrew/Funkin/pull/4082)
* @MrScottyPieey made their first contribution in [#4085](https://github.com/FunkinCrew/Funkin/pull/4085)
* @M7theguy made their first contribution in [funkin.assets#33](https://github.com/FunkinCrew/funkin.assets/pull/33)



## [0.5.3] - 2024-10-18
This patch resolves a critical issue that could cause user's save data to become corrupted. It is recommended that users switch to this version immediately and avoid using version 0.5.2.

### Fixed

- Fixed a critical issue in which the Stage Editor theme value could not be parsed by older versions of the game, resulting in all save data being destroyed.
  - Added a check that prevents save data from being loaded if it is corrupted rather than overwriting it.
- Converted `optionsStageEditor.theme`, `optionsChartEditor.theme`, and `optionsChartEditor.chartEditorLiveInputStyle` in the save data from an Enum to a String to fix save data compatibility issues.
  - In the future, Enum values should not be used in order to prevent incompatibilities caused by introducing new types to the save data that older versions cannot parse.



## [0.5.2] - 2024-10-11

### Added

- Added InverseDotsShader that emulates flash selections. ([097dbf5](https://github.com/FunkinCrew/Funkin/commit/097dbf5bb4346d431d8ca9f0ec4bc5b5e6f4523f)) - by @ninjamuffin99
- Added a new reworked Stage Editor. ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @KoloInDaCrib in [#3482](https://github.com/FunkinCrew/Funkin/pull/3482)
- Added the `color` attribute to stage prop JSON data to allow them to be tinted without code. ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @KoloInDaCrib in [#3482](https://github.com/FunkinCrew/Funkin/pull/3482)
- Added the `angle` attribute to stage prop JSON data to allow them to be rotated without code. ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @KoloInDaCrib in [#3482](https://github.com/FunkinCrew/Funkin/pull/3482)
- Added the `blend` attribute to the stage prop JSON data to allow blend modes to be applied without code. ([27a0b44](https://github.com/FunkinCrew/Funkin/pull/3482/commits/27a0b4426f86f04362f97e16e2eff580c9402f34)) - by @KoloInDaCrib in [#3482](https://github.com/FunkinCrew/Funkin/pull/3482)

### Fixed

- Input offsets no longer cause songs to stutter or skip. ([410cfe9](https://github.com/FunkinCrew/Funkin/commit/410cfe972d6df9de4d4d128375cf8380c4f06d92)) - by @KoloInDaCrib in [#3546](https://github.com/FunkinCrew/Funkin/pull/3546)
- Exiting the Input Offset menu no longer crashes the game. ([39b1a42](https://github.com/FunkinCrew/Funkin/commit/39b1a42cfeafe2b7be8b66e2fe529e853d9ae197)) - by @lemz1 in [#3493](https://github.com/FunkinCrew/Funkin/pull/3493)
- Pico's songs now display properly in the Freeplay Menu. ([1d2bd61](https://github.com/FunkinCrew/Funkin/commit/1d2bd61119e5f418df7f11d7ef2a0fdedee17d3d)) - by @ninjamuffin99 in [#3506](https://github.com/FunkinCrew/Funkin/pull/3506)
- Fixed issues with variation/difficulty loading for Freeplay Menu which caused some songs to disappear. ([c0314c8](https://github.com/FunkinCrew/Funkin/commit/c0314c85ecd5116641aff3de8e9153f7fe48e79c)) - by @ninjamuffin99 in [#3506](https://github.com/FunkinCrew/Funkin/pull/3506)
- `Song.getFirstValidVariation()` now properly takes into account multiple variation/difficulty inputs. ([d2e2987](https://github.com/FunkinCrew/Funkin/commit/d2e29879fe2acc6febfe0f335f655b741d630c34)) - by @ninjamuffin99 in [#3506](https://github.com/FunkinCrew/Funkin/pull/3506)
- Song previews no longer restart when changing difficulties within the same variation. ([903b3fc](https://github.com/FunkinCrew/Funkin/commit/903b3fc59905a70802618a1cd67407722ea956ed)) - by @KoloInDaCrib in [#3587](https://github.com/FunkinCrew/Funkin/pull/3587)
- Main menu music no longer cuts out when switching states. ([711e0a6](https://github.com/FunkinCrew/Funkin/commit/711e0a6b7547eb04113e9318dab900f01ad576a5)) - by @EliteMasterEric in [#3530](https://github.com/FunkinCrew/Funkin/pull/3530)
- Centered preloader 'fnf' and 'dsp' text so they don't clip anymore. ([165ad60](https://github.com/FunkinCrew/Funkin/commit/165ad6015539a295e9eefdaef291c312e9566b26)) - by @Burgerballs in [#3567](https://github.com/FunkinCrew/Funkin/pull/3567)
- FPS setting in options menu no longer flickers when selected. ([b2647fe](https://github.com/FunkinCrew/Funkin/commit/b2647fe09f5281ce7074b26d47bc1524764168ee)) - by @lemz1 in [#3629](https://github.com/FunkinCrew/Funkin/pull/3629)
- Volume sound tray is now anti-aliased/smoothed. ([e66290c](https://github.com/FunkinCrew/Funkin/commit/e66290c55f7141402223644f06ec8a69edeee089)) - by @Kn1ghtNight in [#2853](https://github.com/FunkinCrew/Funkin/pull/2853)
- Fixed looping animations for modded StrumlineNote sprites. ([bc546e8](https://github.com/FunkinCrew/Funkin/commit/bc546e86aa77ffc795b3f079de5f590289a9c583)) - by @DaWaterMalone in [#3577](https://github.com/FunkinCrew/Funkin/pull/3577)
- Stopped allowing inputs after selecting a character in Character Select. ([dbf66ac](https://github.com/FunkinCrew/Funkin/commit/dbf66ac250137262866d75f7c1387645b35d88d0)) - by @ACrazyTown in [#3398](https://github.com/FunkinCrew/Funkin/pull/3398)
- The player and girlfriend no longer disappear or overlap themselves in Character Select. ([9324359](https://github.com/FunkinCrew/Funkin/commit/9324359d2fce6a7097077d169a0efcd80e6fefa1)) - by @gamerbross in [#3457](https://github.com/FunkinCrew/Funkin/pull/3457)
- The player no longer enters twice after entering Character Select or when spamming buttons. ([30a9887](https://github.com/FunkinCrew/Funkin/commit/30a98871367b494c85934cd3fcfa91eeb774a7d5)) - by @gamerbross in [#3457](https://github.com/FunkinCrew/Funkin/pull/3457)
- The wrong girlfriend no longer appears in Character Select. ([9324359](https://github.com/FunkinCrew/Funkin/commit/9324359d2fce6a7097077d169a0efcd80e6fefa1)) - by @gamerbross in [#3457](https://github.com/FunkinCrew/Funkin/pull/3457)
- Cursor now updates properly when moving and selecting in Character Select. ([9324359](https://github.com/FunkinCrew/Funkin/commit/9324359d2fce6a7097077d169a0efcd80e6fefa1)) - by @gamerbross in [#3457](https://github.com/FunkinCrew/Funkin/pull/3457)
- Cursor now moves properly at lower framerates in Character Select. ([ab5bda3](https://github.com/FunkinCrew/Funkin/commit/ab5bda3ee573a6e03595ec6941e6de38df851889)) - by @ninjamuffin99 in [#3507](https://github.com/FunkinCrew/Funkin/pull/3507)
- Exiting the Chart Editor no longer crashes the game. ([f52472a](https://github.com/FunkinCrew/Funkin/commit/f52472a4767388b22cfbab0f5f7860f6e6762856)) - by @EliteMasterEric and @ianharrigan in [#3519](https://github.com/FunkinCrew/Funkin/pull/3519)
- The millisecond counter in the Chart Editor playbar is now properly formatted. ([f1b6e6c](https://github.com/FunkinCrew/Funkin/commit/f1b6e6c4e42455e0c2900d738ebc24893f2479a0)) - by @afreetoplaynoob in [#3537](https://github.com/FunkinCrew/Funkin/pull/3537)
- Pressing F1 multiple times no longer creates more than one help window in the Chart Editor. ([777978f](https://github.com/FunkinCrew/Funkin/commit/777978f5a544e1b7c89b47dcc365f734eb6d0df1)) - by @amyspark-ng in [#3552](https://github.com/FunkinCrew/Funkin/pull/3552)
- The dialog box now shows up in the Animation Editor. ([1fde59f](https://github.com/FunkinCrew/Funkin/commit/1fde59f999eac94eb10fc22094885de2f5310705)) - by @EliteMasterEric in [#3530](https://github.com/FunkinCrew/Funkin/pull/3530)
- (debug) No more fullscreening when typing "F" in the flixel debugger console. ([29b6763](https://github.com/FunkinCrew/Funkin/commit/29b6763290df05d42039806f3d142740568c80f0)) - by @ninjamuffin99
- Added additional classes to Polymod blacklist for security. ([b0b73c8](https://github.com/FunkinCrew/Funkin/commit/b0b73c83994f33118c6a69550da9ec8ec1c07adc)) - by @EliteMasterEric in [#3558](https://github.com/FunkinCrew/Funkin/pull/3558)

## New Contributors for 0.5.2

* @Kn1ghtNight made their first contribution in [#2853](https://github.com/FunkinCrew/Funkin/pull/2853)
* @Cartridge-Man made their first contribution in [#3082](https://github.com/FunkinCrew/Funkin/pull/3082)
* @afreetoplaynoob made their first contribution in [#3537](https://github.com/FunkinCrew/Funkin/pull/3537)
* @amyspark-ng made their first contribution in [#3552](https://github.com/FunkinCrew/Funkin/pull/3552)
* @DaWaterMalone made their first contribution in [#3577](https://github.com/FunkinCrew/Funkin/pull/3577)



## [0.5.1] - 2024-09-30

### Added

- Readded the Merch button to the main menu.
  - Click it to check out our Makeship campaign!
- Added Discord Rich Presence support. People can now see what song you are playing from Discord!
  - We'll get mod support working for this eventually.
- Added an FPS limit option to the Preferences menu.
  - You can now change how high the game tries to push your frame rate, from as little as 30 to as high as 300.
- Added support for the Tracy instrumentation-based profiling tool in development environments. Enable it with the `-DFEATURE_DEBUG_TRACY` compilation flag.
  - For the people who aren't nerds, this is a tool for tracking down performance issues!
- Playable Character data now defines an asset location for an Animate Atlas to display Girlfriend.
  - This includes the option to display a visualizer, if configured correctly.
- Separated the Perfect and Perfect (Gold) animations in the Playable Character data.
  - Base game just uses the same animation for both, but modders can split the animations up on their custom characters now.
- Added a bunch of Flash project files from the Weekend 1 and Playable Pico updates to the `funkin.art` repository.
- Added the `flipX` and `flipY` parameters to props in the Stage data. ([community feature by AbnormalPoof](https://github.com/FunkinCrew/Funkin/pull/3474))

### Changed

- Pico is no longer unlocked for all players automatically.
  - You need to beat Weekend 1 in Story Mode in order to unlock him in Character Select.
- The game's mod API version check is now more dynamic.
  - The update accepts mods with API version `0.5.0` as well as `0.5.1`.
- Removed some of the more spammy `trace()` calls to improve debugging a bit.
- The game now complains if you create a song variation with symbols in its name.
- Switched the force crash keybind from Ctrl-Shift-L to Ctrl-Alt-Shift-L.
- Added some additional functions to `funkin.Assets` after `openfl.utils.Assets` had to get blacklisted from scripts.

### Fixed

- Pico is no longer locked every time the game starts, so you no longer have to watch the unlock animation each game boot.
  - The animation should now play only once per save file.
- The clear % now displays in Freeplay after switching characters.
- Character remixes no longer display the base song's highscore in Freeplay.
- Freeplay no longer displays the wrong text on capsules.
- Freeplay now displays custom songs when switching characters.
- Duplicate difficulties from custom variations now display properly in Freeplay.
- DadBattle (Pico Mix) now has charts for Normal and Easy difficulties.
- DadBattle (Pico Mix) is now properly credited to `TeraVex (ft. Saruky)`.
- Spookeez (Pico Mix) is now properly credited to `Six Impala (ft. Saster)`.
- The audio track now unmutes if you miss a note just before Pico burps.
- Pico now plays out his full burp animation in South (Pico Mix).
- Removed a tap note stacked on top of a hold note in Cocoa Erect (Erect difficulty).
- Pico Erect can no longer be played with different instrumentals.
- The curtains in Week 1 no longer display in front of larger characters.
- Boyfriend now plays his death animation properly on the Week 2 Remix stage.
- The game no longer stutters when playing on the Week 5 Remix stage.
- The "Shit!" judgement no longer displays with anti-aliasing in Week 6.
- Spirit's trail in Week 6 now displays correctly.
- Pico now plays his shooting animations in Stress.
- Characters with high offsets no longer shift over after the player dies or restarts.
- Custom note styles no longer sometimes use default values rather than the fallback note style.
- Custom note styles no longer randomly fail to fetch information about their fallback note style.
- Screenshots and Chart Editor binds no longer display in the controls menu on Web builds (where they are disabled).
- Stage Editor bind no longer displays in the controls menu even when the feature is disabled.
- Freeplay Character Select keybind no longer displays strangely in the controls menu.
- Audio tracks no longer get destroyed if they are flagged as persistent.
- Video cutscenes now scale their volume properly.
- Results screen audio no longer continues into Freeplay or gameplay.
- The Results screen now plays the percentage tick sound when the value changes instead of spamming the sound.
- The save data version number is now written to the save data properly.
- The example mod can now be loaded.
- Pressing F5 to force reload a song no longer occasionally causes the game to crash.
- Animations on Animate Atlas characters no longer throw a bunch of warnings in the console.
- Entering Blazin' no longer displays a script error.
- The Input Offsets menu no longer crashes when entering it before playing a song on web builds.
- Setting the input offset or visual offset to high values no longer causes the song to skip.
- Classic FocusCamera song events no longer cause the camera to snap in place. ([community fix by nebulazorua](https://github.com/FunkinCrew/Funkin/pull/2331))
- Pixel hold note trails in Week 6 are now scaled/positioned correctly. ([community fix by dombomb64](https://github.com/FunkinCrew/Funkin/pull/3351))
- Achieving the same rank on a song with a lower clear % no longer overwrites your clear %. ([community fix by lemz1](https://github.com/FunkinCrew/Funkin/pull/3019))
- The FPS counter no longer displays if Debug Display is turned off. ([community fix by Lethrial](https://github.com/FunkinCrew/Funkin/pull/3356))
- The Chart Editor can now be interacted with properly. ([community fix by Kade-github](https://github.com/FunkinCrew/Funkin/pull/3337))
- Selecting the area to the left of the Chart Editor no longer selects some of the player's notes. ([community fix by NotHyper-474](https://github.com/FunkinCrew/Funkin/pull/3093))
- Pixel icons now display correctly in the Chart Editor. ([community fix by TechnikTil](https://github.com/FunkinCrew/Funkin/pull/3339))
- Audio offsets now interact with the Chart Editor properly. ([community fix by Kade-github](https://github.com/FunkinCrew/Funkin/pull/3384))
- Players can no longer crash the game by interacting with Character Select during the unlock sequence. ([community fix by ActualMandM](https://github.com/FunkinCrew/Funkin/pull/3355))
- `Stage.addCharacter` now properly assigns the `characterType`. ([community fix by Kade-github](https://github.com/FunkinCrew/Funkin/pull/3357))
- Fetching Modules during the `onDestroy` event no longer fails at random. ([community fix by cyn0x8](https://github.com/FunkinCrew/Funkin/pull/3131))
- `onSubStateOpenEnd` and `onSubStateCloseEnd` script events are now called consistently. ([community fix by lemz1](https://github.com/FunkinCrew/Funkin/pull/3138))

## New Contributors for 0.5.1

* @dombomb64 made their first contribution in [#3351](https://github.com/FunkinCrew/Funkin/pull/3351)
* @Lethrial made their first contribution in [#3356](https://github.com/FunkinCrew/Funkin/pull/3356)
* @KoloInDaCrib made their first contribution in [#3371](https://github.com/FunkinCrew/Funkin/pull/3371)



## [0.5.0] - 2024-09-12
The Playable Pico Update!

### Added

- Added a new Character Select screen to switch between playable characters in Freeplay.
  - Modding isn't 100% there but we're working on it!
- Added Pico as a playable character! Unlock him by completing Weekend 1 (if you haven't already done that).
  - The songs from Weekend 1 have moved; you must now switch to Pico via Character Select screen in Freeplay to access them.
- Added 11 new Pico remixes! Access them by selecting Pico in the Character Select screen.
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
- Added 1 new Boyfriend remix! Access it by completing Weekend 1 as Pico and then selecting Boyfriend in the Character Select screen.
  - Darnell (BF Mix)
- Added 2 new Erect remixes! Access them by switching difficulties on the songs.
  - Cocoa Erect
  - Ugh Erect
- Implemented support for a new Instrumental Selector in Freeplay.
  - Beating a Pico remix lets you use that instrumental when playing as Boyfriend.
- Added the first batch of Erect Stages! These graphical overhauls of the original stages will be used when playing Erect remixes and Pico remixes:
  - Week 1 Erect Stage
  - Week 2 Erect Stage
  - Week 3 Erect Stage
  - Week 4 Erect Stage
  - Week 5 Erect Stage
  - Weekend 1 Erect Stage
- Implemented alternate animations and music for Pico in the Results screen.
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
- Reworked the JSON merging system in Polymod; you can now include JSONPatch files under `_merge` in your mod folder to add, modify, or remove values in a JSON without replacing it entirely!
- The `danceEvery` property of characters and stage props can now use values with a precision of `0.25`, to play their idle animation up to four times per beat.
- Characters now respect the `danceEvery` property. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2925))
- Note style data can now specify custom combo count graphics, judgement graphics, countdown graphics, and countdown audio. ([community feature by anysad](https://github.com/FunkinCrew/Funkin/pull/3020))
  - These were previously using hardcoded values based on whether the stage was `school` or `schoolEvil`.
- The YEAH! events in Tutorial now use chart events rather than being hard-coded. ([community fix by anysad](https://github.com/FunkinCrew/Funkin/pull/3007))
- Cutscenes now automatically pause when tabbing out. ([community fix by AbnormalPoof](https://github.com/FunkinCrew/Funkin/pull/2903))
- The F5 function now reloads the current song's chart data from disk. ([community feature by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2990))
- Made several layout improvements and fixes to the Animation Offsets editor in the Debug menu. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2820))
- Animation offsets no longer directly modify the `x` and `y` position of props, making props work better with tweens. ([community fix by Sword352](https://github.com/FunkinCrew/Funkin/pull/2310))
- Fixed a bug where the Back sound would be not played when leaving the Story menu and Options menu. ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/2986))
- The player's Score now displays commas in it. (community fix by loggo)

## Fixed

- Songs with no notes no longer crash on the Results screen.
- Note inputs are no longer accepted during the Thorns cutscene.
- The old icon easter egg now works properly on pixel levels.
- The Heart icon is no longer malformed when favoriting a song in Freeplay.
- Freeplay songs with no `Normal` difficulty no longer crash the game. ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/3036) and [gamerbross](https://github.com/FunkinCrew/Funkin/pull/2712))
- Songs that aren't valid for the current variation can no longer be selected. ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/3037))
- The Freeplay song preview now respects the instrumental ID specified in the song metadata. ([community fix by AppleHair](https://github.com/FunkinCrew/Funkin/pull/2742))
- Modded songs now play previews in the Freeplay menu. ([community fix by KarimAkra](https://github.com/FunkinCrew/Funkin/pull/2724))
- The Story Mode menu can now be scrolled using the mouse wheel. ([community fix by JVNpixels](https://github.com/FunkinCrew/Funkin/pull/2873))
- Pressing F5 after seeing the sticker transition no longer crashes the game. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2863))
- Pausing the game during a camera zoom no longer zooms the pause menu as well. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2567))
- The song no longer majorly desyncs at times. ([community fix by Burgerballs](https://github.com/FunkinCrew/Funkin/pull/3058))
- Pico's death animation no longer displays a faint blue background. ([community fix by doggogit](https://github.com/FunkinCrew/funkin.assets/pull/1))
- The game now uses the placeholder health icon as a fallback. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/3005))
- Pressing the Chart Editor keybind while playtesting a chart no longer resets the Chart Editor. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2739))
- The Chart Editor no longer gets stuck creating a hold note when using Live Inputs. ([community fix by gamerbross](https://github.com/FunkinCrew/Funkin/pull/2992))
- Tankman's icon now displays in the Chart Editor. ([community fix by Hundrec](https://github.com/FunkinCrew/Funkin/pull/2912))
- The Memory Usage counter no longer overflows and displays a negative number. ([community fix by KarimAkra](https://github.com/FunkinCrew/Funkin/pull/2713))
- Certain UI elements now flash at a consistent rate. ([community fix by cyn0x8](https://github.com/FunkinCrew/Funkin/pull/2494))
- Character graphics can now be placed in week folders. ([community fix by 7oltan](https://github.com/FunkinCrew/Funkin/pull/3035))

## New Contributors for 0.5.0

* @Sword352 made their first contribution in [#2310](https://github.com/FunkinCrew/Funkin/pull/2310)
* @cyn0x8 made their first contribution in [#2494](https://github.com/FunkinCrew/Funkin/pull/2494)
* @KarimAkra made their first contribution in [#2713](https://github.com/FunkinCrew/Funkin/pull/2713)
* @tposejank made their first contribution in [#2717](https://github.com/FunkinCrew/Funkin/pull/2717)
* @AppleHair made their first contribution in [#2742](https://github.com/FunkinCrew/Funkin/pull/2742)
* @JVNpixels made their first contribution in [#2873](https://github.com/FunkinCrew/Funkin/pull/2873)
* @Flooferland made their first contribution in [#2942](https://github.com/FunkinCrew/Funkin/pull/2942)
* @Punkinator7 made their first contribution in [#2962](https://github.com/FunkinCrew/Funkin/pull/2962)
* @anysad made their first contribution in [#3007](https://github.com/FunkinCrew/Funkin/pull/3007)
* @7oltan made their first contribution in [#3035](https://github.com/FunkinCrew/Funkin/pull/3035)



## [0.4.1] - 2024-06-12

### Added

- Pressing ESCAPE on the title screen on desktop now exits the game, allowing you to exit the game while in fullscreen on desktop.
- Freeplay menu controls (favoriting and switching categories) are now rebindable from the Options menu, and now have default binds on controllers.

### Changed

- Highscores and ranks are now saved separately, fixing an issue where lower ranks would overwrite higher ranks if the player achieved a new highscore.
- A-Bot speaker now reacts to the user's volume preference on desktop. ([thanks to M7theguy for the issue report/suggestion](https://github.com/FunkinCrew/Funkin/issues/2744)!)
- Freeplay heart icons are now shifted to the right when favoriting a song with no rank.
- The `scrollMenu` sound effect now only plays when there's a real change on the Freeplay menu. ([thanks gamerbross for the PR!](https://github.com/FunkinCrew/Funkin/pull/2741))
- Applied anti-aliasing to the edge of the Freeplay Dad graphic.
- Rearranged some controls in the controls menu.
- Made several chart revisions:
  - Re-enabled custom camera events in Roses (Erect/Nightmare)
  - Tweaked chart for Lit Up (Hard)
  - Corrected difficulty ratings for M.I.L.F (Easy/Normal/Hard)

### Fixed

- Control binds in the controls menu no longer overlap their names.
- Attempting to exit the gameover screen and retry the song at the same time no longer crashes the game. ([thanks DM-kun for the PR!](https://github.com/FunkinCrew/Funkin/pull/2709))
- Botplay mode now handles the player's animations properly during hold notes. ([thanks Hundrec!](https://github.com/FunkinCrew/Funkin/pull/2683))
- Camera movement now pauses when the game is paused. ([thanks Matriculaso!](https://github.com/FunkinCrew/Funkin/pull/2684))
- Pico's gameplay sprite no longer appears on the gameover screen when dying from an explosion in 2hot.
- Freeplay previews now properly fade in volume during the DJ's idle animation.
- DadBattle no longer incorrectly appears as DadBattle Erect when returning to Freeplay on Hard.
- 2hot now appears under the "#" category in Freeplay menu.
- The Chart Editor no longer crashes when selecting an event with the Event toolbox open.
- Improved offsets for Pico and Tankman opponents so they don't slide around as much.
- The black "temp" graphic in Freeplay is now correctly sized/masked, now it's identical to the Dad Freeplay graphic.

## New Contributors for 0.4.1

* @Hundrec made their first contribution in [#2661](https://github.com/FunkinCrew/Funkin/pull/2661)
* @DM-kun made their first contribution in [#2709](https://github.com/FunkinCrew/Funkin/pull/2709)
* @eltociear made their first contribution in [#2730](https://github.com/FunkinCrew/Funkin/pull/2730)



## [0.4.0] - 2024-06-06
The Pit Stop 1 update!

### Added

- 2 new Erect remixes, Eggnog and Satin Panties. Check them out from the Freeplay menu!
- Major visual improvements to the Results screen, with additional animations and audio based on your performance.
- Major visual improvements to the Freeplay screen, with song difficulty ratings and player rank displays.
  - Freeplay now plays a preview of songs when you hover over them.
- Added a Charter field to the chart format, to allow for crediting the creator of a level's chart.
  - You can see who charted a song from the Pause menu.
- Added a new Scroll Speed chart event to change the note speed mid-song. ([thanks Burgerballs!](https://github.com/FunkinCrew/Funkin/pull/2409))

### Changed

- Tweaked charts for several songs:
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

- Nene's visualizer now plays on Desktop builds.
- The game no longer silently fails to load saves on HTML5.
- Props on the Story Menu now bop properly.
- Additional fixes for the loading bar on HTML5. ([thanks lemz1!](https://github.com/FunkinCrew/Funkin/pull/2553))
- Fixed several bugs with the TitleState, including missing music when returning from the Main Menu. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2539))
- The Main Menu camera now properly follows the selected item. ([thanks richTrash21!](https://github.com/FunkinCrew/Funkin/pull/2576))
- Changing difficulties in Story Mode now updates the score text. ([thanks sector-a!](https://github.com/FunkinCrew/Funkin/pull/2585))
- Fixed a crash in Freeplay caused by a level referencing an invalid song. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2457))
- Pressing the volume keys no longer stops the Toy commercial. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2540))
- Playtesting in the Chart Editor no longer crashes when losing. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2518))
- Hold notes now display properly in the Chart Editor when downscroll is enabled for gameplay. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2565))
- Hold notes are now positioned correctly with downscroll enabled. ([thanks MaybeMaru!](https://github.com/FunkinCrew/Funkin/pull/2488))
- Removed a large number of unused imports to optimize builds. ([thanks Ethan-makes-music!](https://github.com/FunkinCrew/Funkin/pull/2624))
- Improved debug logging for unscripted stages. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2603))
- Fixed a crash on Linux caused by an old version of hxCodec. ([thanks Noobz4Life!](https://github.com/FunkinCrew/Funkin/pull/2472))
- Optimized animation handling for characters. ([thanks richTrash21!](https://github.com/FunkinCrew/Funkin/pull/2493))
- The Chart Editor no longer uses an incorrect instrumental on imported Legacy songs. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2604))
- Opening the game from the command line no longer crashes the preloader. ([thanks NotHyper-474!](https://github.com/FunkinCrew/Funkin/pull/2629))
- Characters no longer use the wrong scale value sometimes. ([thanks PurSnake!](https://github.com/FunkinCrew/Funkin/pull/2610))
- Additional bug fixes and optimizations.

## New Contributors for 0.4.0

* @doggogit made their first contribution in [#2325](https://github.com/FunkinCrew/Funkin/pull/2325)
* @Noobz4Life made their first contribution in [#2472](https://github.com/FunkinCrew/Funkin/pull/2472)
* @MaybeMaru made their first contribution in [#2488](https://github.com/FunkinCrew/Funkin/pull/2488)
* @NotHyper-474 made their first contribution in [#2490](https://github.com/FunkinCrew/Funkin/pull/2490)
* @richTrash21 made their first contribution in [#2493](https://github.com/FunkinCrew/Funkin/pull/2493)
* @TechnikTil made their first contribution in [#2508](https://github.com/FunkinCrew/Funkin/pull/2508)
* @SanicBTW made their first contribution in [#2544](https://github.com/FunkinCrew/Funkin/pull/2544)
* @EnterTheVoid-x86 made their first contribution in [#2573](https://github.com/FunkinCrew/Funkin/pull/2573)
* @Keoiki made their first contribution in [#2581](https://github.com/FunkinCrew/Funkin/pull/2581)
* @sector-a made their first contribution in [#2585](https://github.com/FunkinCrew/Funkin/pull/2585)
* @PurSnake made their first contribution in [#2610](https://github.com/FunkinCrew/Funkin/pull/2610)
* @Ethan-makes-music made their first contribution in [#2624](https://github.com/FunkinCrew/Funkin/pull/2624)
* @An-enderman made their first contribution in [#2662](https://github.com/FunkinCrew/Funkin/pull/2662)
* @moondroidcoder made their first contribution in [#2701](https://github.com/FunkinCrew/Funkin/pull/2701)



## [0.3.3] - 2024-05-14

### Changed

- Cleaned up some code in `PlayAnimationSongEvent.hx`. ([thanks Burgerballs!](https://github.com/FunkinCrew/Funkin/pull/2308))

### Fixed

- Fixes for the Loading bar on HTML5. ([thanks lemz1!](https://github.com/FunkinCrew/Funkin/pull/2499))
- Don't allow inputs when exiting Freeplay. ([thanks gamerbross!](https://github.com/FunkinCrew/Funkin/pull/2470))
- Fixed mouse wheel scrolling in Freeplay. ([thanks JugieNoob!](https://github.com/FunkinCrew/Funkin/pull/2466))
- Health icons, score, and notes now reset properly when re-entering gameplay from gameover. ([thanks ImCodist!](https://github.com/FunkinCrew/Funkin/pull/2390))
- Fixed the character selector's hitbox width in the Chart Editor. ([thanks MadBear422!](https://github.com/FunkinCrew/Funkin/pull/2370))
- Fixed camera stutter once a wipe transition to the Main Menu completes. ([thanks ImCodist!](https://github.com/FunkinCrew/Funkin/pull/2315))
- Hold notes no longer become invisible for a single frame. ([thanks ImCodist!](https://github.com/FunkinCrew/Funkin/pull/2309))
- Tweens no longer accumulate on the Title screen when pressing Y multiple times. ([thanks TheGaloXx!](https://github.com/FunkinCrew/Funkin/pull/2300))
- Fixed a crash when querying FlxG.state in the crash handler.
- Fixed a game over easter egg so you don't accidentally exit it when viewing.
- The Freeplay menu can now display 100% clear.
- Weekend 1 Pico no longer attempts to retrieve a missing asset.
- Fixed an issue where duplicate keybinds would be stored, potentially causing a crash.
- Chart debug key now properly returns you to the previous chart editor session if you were playtesting a chart. ([thanks nebulazorua!](https://github.com/FunkinCrew/Funkin/pull/2323))
- Fixed a crash on Freeplay found on AMD graphics cards.

## New Contributors for 0.3.3

* @Chubercik made their first contribution in [#2297](https://github.com/FunkinCrew/Funkin/pull/2297)
* @TheGaloXx made their first contribution in [#2300](https://github.com/FunkinCrew/Funkin/pull/2300)
* @Burgerballs made their first contribution in [#2308](https://github.com/FunkinCrew/Funkin/pull/2308)
* @ImCodist made their first contribution in [#2309](https://github.com/FunkinCrew/Funkin/pull/2309)
* @nebulazorua made their first contribution in [#2323](https://github.com/FunkinCrew/Funkin/pull/2323)
* @MadBear422 made their first contribution in [#2370](https://github.com/FunkinCrew/Funkin/pull/2370)
* @JugieNoob made their first contribution in [#2466](https://github.com/FunkinCrew/Funkin/pull/2466)
* @gamerbross made their first contribution in [#2470](https://github.com/FunkinCrew/Funkin/pull/2470)
* @lemz1 made their first contribution in [#2499](https://github.com/FunkinCrew/Funkin/pull/2499)



## [0.3.2] - 2024-05-03

### Added

- Added `,` and `.` keybinds to the Chart Editor. These place Focus Camera events at the playhead, for the opponent and player respectively.
- Implemented a blacklist to prevent mods from calling system functions.
  - Added a couple utility functions to call useful stuff that got blacklisted.
- Added an `onSongLoad` script event which allows for mutation of notes and events.
- Added the currently loaded modlist to crash logs.
- Added the `visible` attribute to Level JSON data.
- Enabled ZIP file system support for Polymod (make sure the metadata is in the root of the ZIP).

### Changed

- Songs in the mod folders will display in Freeplay without any extra scripting.
- Story levels in the mod folders will display in Story without any extra scripting.
- All audio should sound better in HTML5, less muddy.

### Fixed

- Fixed a typo in the credits folder (`Custcene` -> `Cutscene`)
- Health icon transition animations now finish properly instead of looping forever.
- Video cutscenes flagged as mid-song no longer crash the game when they finish.
- Substate lifecycle events are now dispatched consistently.
- Trying to load into the Animation Offsets menu with an invalid character no longer crashes the game.
- The preloader no longer spams the logs when it is complete and waiting for user input.
- Should definitely have the fix for Freeplay where it stops taking control of the main menu below it.
- Changed the code for the Story Mode menu difficulties so that "normal" doesn't overlap the arrows after leaving Weekend 1.

### Removed

- Removed some unused `.txt` files in the `assets/data` folder.



## [0.3.1] - 2024-05-01

### Changed

- Ensure the Git commit hash always displays in the log files.
- Added whether the local Git repo was modified to the log files.
- Removed "PROTOTYPE" text on release builds only (it still shows on debug builds).
- Added additional credits and special thanks.
- Updated peepo in creds to peepo173.

### Fixed

- Fixed a crash when retrieving system specs while handing a crash.
- Fixed a crash triggered when pausing before the song starts.
- Fixed a crash triggered when dying before the song starts.
- Fixed a crash triggered when unloading certain graphics.
- Pico game over confirm now plays correctly.
- When exiting from a song into Freeplay, main menu no longer takes inputs unintentionally (aka issues with merch links opening up when selecting songs).
- Arrow keys no longer cause the web browser page to scroll.



## [0.3.0] - 2024-04-30
The Weekend 1 update!

### Added

- New Story Level: Weekend 1, starring Pico, Darnell, and Nene.
  - Beat the level in Story Mode to unlock the songs for Freeplay!
- 12 new Erect remixes, featuring Kawai Sprite, Saruky, Kohta Takahashi, and Saster.
  - Unlocked instantly in Freeplay
- New visually enhanced Freeplay menu.
  - Sorting, favorites, and more
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
