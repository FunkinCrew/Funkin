# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Changed
- ASSET LOADING OVERHAUL, WAY FASTER LOAD TIMES ON WEB!!! (THANKS TO GEOKURELI WOKE KING)
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
