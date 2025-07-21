# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
  - Fixed null-safe field access not working properly for functions (ex. `class?.someFunction()). (Thanks KoloInDaCrib!)

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
* @ShadzXD made their first contribution in [#62](https://github.com/FunkinCrew/Funkin/pull/4729)



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
- Attempting to exit the gameover screen and retry the song at the same time no longer crashes the game. ([thanks DMMaster636 for the PR!](https://github.com/FunkinCrew/Funkin/pull/2709))
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
* @DMMaster636 made their first contribution in [#2709](https://github.com/FunkinCrew/Funkin/pull/2709)
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
