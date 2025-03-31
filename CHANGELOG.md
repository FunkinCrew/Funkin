# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.2] - 2024-03-31
### Added
- 0.6 credits list updated
### Fixed
- Additional shader fix for Stress Pico crashing at the end (was the same issue as Senpai Pico shader error, just in a different shaderfile)

## [0.6.1] - 2024-03-31
### Fixed
- Hopefully Senpai Pico/Erect mix shader isn't brokey
- NG API encryption key was added proper, so medals + leaderboards posting should work

## [0.6.0] - 2024-03-31
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
- Added a little easter egg to Pico's Good Results Screen animation.
- The HOME and END keys now jump to the top and bottom of the Freeplay song list, respectively. ([bb974c2](https://github.com/FunkinCrew/Funkin/commit/bb974c264270d10ff503784063e5d77bb352b3f7)) - by @AbnormalPoof in [#4103](https://github.com/FunkinCrew/Funkin/pull/4103)
- Added an option to launch the game in fullscreen. ([ee53ccd](https://github.com/FunkinCrew/Funkin/commit/ee53ccd32721e0790adfe82c60d4aca419db0a7f)) - by @AbnormalPoof in [#3738](https://github.com/FunkinCrew/Funkin/pull/3738)
- Added descriptions for each item in the Preferences menu. ([a17b0e8](https://github.com/FunkinCrew/Funkin/commit/a17b0e8b3cc1d56fcdc0b51eaca9fd57cdb5bce0)) - by @anysad in [#3872](https://github.com/FunkinCrew/Funkin/pull/3872)
- Added precise scrolling in the Chart Editor using Ctrl-Mouse Wheel. ([0d8e4a5](https://github.com/FunkinCrew/Funkin/commit/0d8e4a53305d6d069454812766300122f3581e31)) - by @ninjamuffin99 in [#3806](https://github.com/FunkinCrew/Funkin/pull/3806)
- Added a “None” option to the character selector in the Chart Editor. ([d9637d3](https://github.com/FunkinCrew/Funkin/commit/d9637d3a19466b9fc68a102676c46a74ef504909)) - by @Lasercar in [#4279](https://github.com/FunkinCrew/Funkin/pull/4279)
- Added the ability to flip the character in the Animation Editor. ([de02137](https://github.com/FunkinCrew/Funkin/commit/de02137d7c7d1779e85aeda34743f506a5b9cc27)) - by @AbnormalPoof in [#3028](https://github.com/FunkinCrew/Funkin/pull/3028)
- Added offsets support for album titles. ([69d8570](https://github.com/FunkinCrew/Funkin/commit/69d8570a9eb06011ed6dd95fcbef83d90f7f8684)) - by @AbnormalPoof in [#3618](https://github.com/FunkinCrew/Funkin/pull/3618)
- Added three new properties to stage data: `angle`, `scroll`, and `alpha`. ([ff56b19](https://github.com/FunkinCrew/Funkin/commit/ff56b1948aef42bbb6bb4ede4f9b2012d49ab044)) - by @AbnormalPoof in [#3720](https://github.com/FunkinCrew/Funkin/pull/3720)
- Added script events for losing/gaining focus. ([4b127b6](https://github.com/FunkinCrew/Funkin/commit/4b127b64130f6f753d0574ec66a1672322e4bd13)) - by @AbnormalPoof in [#3721](https://github.com/FunkinCrew/Funkin/pull/3721)
- Added 10 new functions to `ReflectUtil`.([6216655](https://github.com/FunkinCrew/Funkin/commit/62166554e7a176245d1a63bd15122033044c4e40)) - by @AbnormalPoof in [#3622](https://github.com/FunkinCrew/Funkin/pull/3622), [#3809](https://github.com/FunkinCrew/Funkin/pull/3809), and [#4019](https://github.com/FunkinCrew/Funkin/pull/4019)
- Added `DEBUG_BUILD` value to `Constants` to indicate whether a build has debug functions enabled. ([ad45b72](https://github.com/FunkinCrew/Funkin/commit/ad45b72b1ae8eb73a12dc51bcb59f66cc55e7bbd)) - by @AbnormalPoof in [#3853](https://github.com/FunkinCrew/Funkin/pull/3853)

### Changed
- Switched from hxCodec to hxvlc for video playback. This may break a mod or two.
  - Check the [Funkin Modding Docs](https://funkincrew.github.io/funkin-modding-docs/09-migration/09-02-0.5.0-to-0.6.0.html) for more info on how to update your mods.
- Polymod should now ignore `.git` files when loading mods.
- Lots of improvements to issue and pull request organization. - by @Hundrec and @AbnormalPoof
- Overhauled the Changelog to improve readability and properly credit contributors. ([4383fcf](https://github.com/FunkinCrew/Funkin/commit/4383fcf32c280a1c0ee7b9c80d255611d497cabc)) - by @Hundrec in [#4296](https://github.com/FunkinCrew/Funkin/pull/4296) and [#4298](https://github.com/FunkinCrew/Funkin/pull/4298)
- Made various improvements to the screenshot function. ([9ce7bbc](https://github.com/FunkinCrew/Funkin/commit/9ce7bbcfbb8f30ae120c876194f89bc4c787f585)) - by @Lasercar in [#4082](https://github.com/FunkinCrew/Funkin/pull/4082)
- Accept keybinds (Z and Space by default) can now be used to exit the Results screen. ([edb270d](https://github.com/FunkinCrew/Funkin/commit/edb270d15e41784dccbf75639ac731840e80fe23)) - by @JVNpixels in [#3799](https://github.com/FunkinCrew/Funkin/pull/3799)
- Reordered UI keybinds in the controls menu for consistency. ([a01bcc3](https://github.com/FunkinCrew/Funkin/commit/a01bcc3da836ec52851ca9de13ef459daf61269a)) - by @lemz1 in [#3027](https://github.com/FunkinCrew/Funkin/pull/3027)
- New save files now have default Freeplay controls for gamepads. ([2b7f62e](https://github.com/FunkinCrew/Funkin/commit/2b7f62edd33de5527e259d9e5643f926d35da734)) - by @MrMadera in [#3934](https://github.com/FunkinCrew/Funkin/pull/3934)
- Renamed “Auto Pause” preference to “Pause on Unfocus” for clarity. ([49a21c1](https://github.com/FunkinCrew/Funkin/commit/49a21c198236fbecbe5902bb106f78939cc6442a)) - by @JackXson-Real in [#4346](https://github.com/FunkinCrew/Funkin/pull/4346)
- Made scrolling smoother in the Chart Editor. ([20d9016](https://github.com/FunkinCrew/Funkin/commit/20d90169845f1e50f849e39f4c5f818359756c78)) - by @ninjamuffin99 in [#3768](https://github.com/FunkinCrew/Funkin/pull/3768)
- The Chart Editor now clears the undo/redo history after loading a new song. ([c7bdc1a](https://github.com/FunkinCrew/Funkin/commit/c7bdc1abe265678468920ca3cc3d7eface5d6925)) - by @Lasercar in [#4308](https://github.com/FunkinCrew/Funkin/pull/4308)
- Mods with missing dependencies are now skipped instead of preventing all mods from loading. ([1c2fb43](https://github.com/FunkinCrew/Funkin/commit/1c2fb43ae16cf40be5ef94c40b047e8e772b1211)) - by @AbnormalPoof in [#3993](https://github.com/FunkinCrew/Funkin/pull/3993)
- Slightly improved flexibility for modding note hit animations. ([3aad825](https://github.com/FunkinCrew/Funkin/commit/3aad825f865c4ed87016983d44121e2c1610d332)) - by @TechnikTil in [#3936](https://github.com/FunkinCrew/Funkin/pull/3936)
- Introduced several QoL modding changes. ([785c4be](https://github.com/FunkinCrew/Funkin/commit/785c4be88b52dc1b5899013822fc004ba7d9894d)) - by @Kade-github in [#4009](https://github.com/FunkinCrew/Funkin/pull/4009)
- Lots of smaller bug fixes.

## New Contributors for 0.6.0

* @PatoFlamejanteTV made their first contribution in [#3843](https://github.com/FunkinCrew/Funkin/pull/3843)
* @sphis-Sinco made their first contribution in [#3881](https://github.com/FunkinCrew/Funkin/pull/3881)
* @MrMadera made their first contribution in [#3934](https://github.com/FunkinCrew/Funkin/pull/3934)
* @Lasercar made their first contribution in [#4100](https://github.com/FunkinCrew/Funkin/pull/4065)
* @MidyGamy made their first contribution in [#4068](https://github.com/FunkinCrew/Funkin/pull/4068)
* @MrScottyPieey made their first contribution in [#4085](https://github.com/FunkinCrew/Funkin/pull/4085)
* @JackXson-Real made their first contribution in [#4346](https://github.com/FunkinCrew/Funkin/pull/4346)

# Fixed
- Fixed a bug where the song would restart from the beginning instead of moving to the Results screen. ([3667c51](https://github.com/FunkinCrew/Funkin/commit/3667c51c1efe14cfe7c810e2f35991f08f50781a)) - by @KoloInDaCrib in [#4309](https://github.com/FunkinCrew/Funkin/pull/4309) and @Lasercar in [#4330](https://github.com/FunkinCrew/Funkin/pull/4330)
- Reduced stuttering when resyncing instrumental and voices tracks. ([22d41d2](https://github.com/FunkinCrew/Funkin/commit/22d41d21b88acb7422a0afcda8414682710bd2ed)) - by @TechnikTil in [#3955](https://github.com/FunkinCrew/Funkin/pull/3955)
- Songs with only instrumental tracks no longer stutter. ([dfe02ec](https://github.com/FunkinCrew/Funkin/commit/dfe02ec668b61d6308f459c978d12a7487f9dc28)) - by @KoloInDaCrib in [#3861](https://github.com/FunkinCrew/Funkin/pull/3861)
- The mouse cursor is no longer visible outside of debug editors. ([1c12b84](https://github.com/FunkinCrew/Funkin/commit/1c12b8467eca350eb28138473360d5358fa620e2)) - by @sphis-Sinco in [#3881](https://github.com/FunkinCrew/Funkin/pull/3881)
- Unbound keys now display as [N/A] instead of crashing the game. ([94e5d3c](https://github.com/FunkinCrew/Funkin/commit/94e5d3ca258cbaa5d9ab6f0cb26feda83b3433a2)) - by @NotHyper-474 in [#4355](https://github.com/FunkinCrew/Funkin/pull/4355)
- Songs can no longer be spam-selected after selecting an instrumental in Freeplay. ([0e0c4ae](https://github.com/FunkinCrew/Funkin/commit/0e0c4aeb7745cfb9479685ccbb635cf3743cddbb)) - by @AbnormalPoof in [#3866](https://github.com/FunkinCrew/Funkin/pull/3866)
- The Random capsule can now switch to Erect/Nightmare difficulties in Freeplay. ([6f32747](https://github.com/FunkinCrew/Funkin/commit/6f327474f30374f50774f432ea3ccb6d02579445)) - by @KoloInDaCrib in [#3838](https://github.com/FunkinCrew/Funkin/pull/3838)
- The millions place digit of the Freeplay score now updates properly. ([3719ca6](https://github.com/FunkinCrew/Funkin/commit/3719ca6ce7a170c3c890cdb2aeea3e4534b91736)) - by @Lasercar in [#4065](https://github.com/FunkinCrew/Funkin/pull/4065)
- Fixed a rare bug where a song would not register as beaten. ([a3e2373](https://github.com/FunkinCrew/Funkin/commit/a3e23733db104b1ef00cfcff17db3a5d032a4d67)) - by @AbnormalPoof in [#3820](https://github.com/FunkinCrew/Funkin/pull/3820)
- The difficulty graphic on the Results screen no longer cuts off incorrectly. ([b13bf05](https://github.com/FunkinCrew/Funkin/commit/b13bf05d16ff2977309e0c7ba3f049c0134e8902)) - by @AbnormalPoof in [#4161](https://github.com/FunkinCrew/Funkin/pull/4161)
- Four-digit long Total Notes values in the Results screen no longer overflow to the right. ([2be4c0c](https://github.com/FunkinCrew/Funkin/commit/2be4c0c7196e018a43f9697f015179f3efc3fcdb)) - by @Hundrec in [#4356](https://github.com/FunkinCrew/Funkin/pull/4356)
- The Character Select screen no longer plays the unlock animation for some locked characters. ([7058126](https://github.com/FunkinCrew/Funkin/commit/7058126e99adb55e43f5f487b007d3efa9f324d5)) - by @AbnormalPoof in [#3748](https://github.com/FunkinCrew/Funkin/pull/3748)
- All time signatures in the Chart Editor now display the correct number of beat/step tick lines. ([e570dfb](https://github.com/FunkinCrew/Funkin/commit/e570dfb8e754f9cb29ac2d8fff6e8513bc68b630)) - by @Keoiki in [#2860](https://github.com/FunkinCrew/Funkin/pull/2860)
- The Debug menu now opens with the correct camera position. ([090ddd1](https://github.com/FunkinCrew/Funkin/commit/090ddd1f1c2aa48fdb83127b2235041643c99af5)) - by @ninjamuffin99 in [#3769](https://github.com/FunkinCrew/Funkin/pull/3769)
- Removed some Freeplay variables left over from legacy versions. ([6f6529f](https://github.com/FunkinCrew/Funkin/commit/6f6529f3c460721755dfdd0a7a26578c0de429d2)) - by @AbnormalPoof in [#4370](https://github.com/FunkinCrew/Funkin/pull/4370)
- Blacklisted an additional class for security. ([3492d41](https://github.com/FunkinCrew/Funkin/commit/3492d412c65c7f3fd61e6fc6c9410d8467122ab0)) - by @AbnormalPoof in [#4074](https://github.com/FunkinCrew/Funkin/pull/4074)
- Removed an unused class from Polymod blacklist. ([06c12e3](https://github.com/FunkinCrew/Funkin/commit/06c12e36c6bd6df4e2be32a3bec540172e79e162)) - by @AbnormalPoof in [#3729](https://github.com/FunkinCrew/Funkin/pull/3729)
- Many additional small bug fixes.


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
- Freeplay previews now properly fade in volume during the BF idle animation.
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
  - This is not the Ludum Dare game held together with sticks and glue you played three years ago.
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
