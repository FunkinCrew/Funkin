# Changelog
All notable changes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.2]
### Changed
- Trails on notes are more consistent
- Title now shows "Friday Night Funkin' Kade Engine"
- **THIS UPDATE WILL RESET YOUR SAVE FOR KADE ENGINE**, so you gotta redo all of ur settings.

### Added
- Lua Modchart support [(documentation located here)](https://github.com/KadeDev/Kade-Engine/blob/master/ModCharts.md)
- New option called watermarks which removes all watermarks from Kade Engine
- Chart spesfic offsets

## [1.4.1]
### Fixed
- Rating's and Accuracy calculation (they actually work now)
- Deleting notes
### Added
- Accuracy mod toggle (complex = ms based, accurate = normal rating based. ex sick = 1, good = 0.75, bad = 0.50, shit = 0.25)
- Judgement Selector (safe frames)

## [1.4.1 Nightly2]
### Fixed
- Scroll Speed messing up hold note parts
- Added caps for Safe Frames (so you couldn't break the game)
### Changed
- Changed the fundamentals of how Ratings and other timing-related things like MS Acc are calculated.
- and of course. hit window update

## [1.4.1 Nightly1]
### Fixed
- Notes can be deleted
- Hit window updates
### Changed
- FPS Cap can now go faster or slower depending on whether you are holding shift or not.
### Added
- Safe Frames (the ability to change your hit windows)

## [1.4]
### Edited
- offsets work. fucking contributors
### Changed
- Updated Judgements to contrast better with each other.
- Changed Auto Offset to use the tutorial chart instead of a custom one
- The file in data called "freeplaySonglist.txt" is now fully used.
- Song Position now works a lot better

## [1.3.1 Nightly3]
### Added
- Auto Offset (Kinda works
- CTRL-Z Support for the charter
- NPS Display
### Fixed
- You can delete notes
- FPS No longer resets on changing screens
- Some of the Rankings didn't work how they were supposed to, now they work.

## [1.3.1 Nightly2]
### Added
- Option Categories
- FPS Cap Option
- FPS Rainbow Toggle
- Scroll Speed Option
### Changed
- Offset now allows you to hold down to change values
- Rating hit windows update
### Fixed
- Tails being FUCKED

## [1.3.1 Nightly]
### Added
- Gameplay Customization
- The ability to change rating text's position
### Fixed
- You can now get a shit
- Downscroll arrows are 100% fixed.
### Redone
- The rating system has been completely rewritten.

## [1.3.1]
### Added
- Timing text in ms
### Changed
- Most UI elements now work based off the camera instead of real-world space (I.E combo, watermark, song bar, etc)
- New Accuracy calculation (based off of Wife3 from Etterna a Stepmania Mod)
### Fixed
- Deleting notes
- Misses due to the other player not hitting notes and thus it makes you miss because there wasn't a check. Now there is.
- Downscroll tail ends being upside down.

## [1.3]
### Added
- Wife3 Accuracy System
- Wife3 Ranking (Letter Grades/FC Conditions)
- A Reset chart button on the song tab in the debug menu.
- Pressing ALT when the note tab is open in the debug menu will allow you to write notes (by playing them, aka pressing DFJK/WASD/Arrow Keys) Press ALT again to toggle off.
- Etterna Mode (by default this is off) Etterna Mode basicily puts all of the hit timings to Judgement 4. Which is harsher then the base game.
### Tweaked
- In the section tab (where it normally says 16) this now works. This is the sections length in steps. It allows you to chart 1/16,1/24,1/32 notes. etc etc.
- The BPM stepper now allows you to go into decimals (ALLOWS FOR DECIMAL BPMS!!!!)
### Fixed
- Song Progress bar no longer clips into the strumline on upscroll on non-pixel charts.
- Deleting notes now works
- Kade Engine Watermark not showing on all charts.

## [1.2.2]
### Added
- A optional bar at the top (or bottom if you have downscroll) that shows the current progress of the song. By default this is turned off.
- Discord Rich Presence (including accuracy, misses, and score)
### Tweaked
- How saving is handled and general code cleanup.

## [1.2.1]
### Fixed
- Accuracy toggle now works
### Tweaks
- HP Drain Tweaks
### Added
- Anti-Mash

## [1.2]
### Minor fixes
- Combo can now go above 999
- Accuracy display is now togglable
### Fixed
- Controls now save and reload upon startup instead of just not loading.
- Random misses no longer happen.
- REMOVED THE RESET KEYBIND (POG)

## [1.1.3]
quick patch
### Fixed
- random misses when not missing
- monster's icon in freeplay

## [1.1.2]
ok i lied another release
### Fixed
- Misses not being counted
- Replays just not at all attempting to work
- Camera Zoom being WAYY too fast or slow
- Healthbar in Downscroll not moving

## [1.1.1]
Ok this should be the last 1.1.x release for awhile lol. My bad.

## [1.1]
I'm really dumb lol

## [1.0]
Initial release poggers!
