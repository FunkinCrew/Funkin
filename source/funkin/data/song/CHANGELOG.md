# Song Chart Data Schema Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.5]
### Added
- Added `playData.stickerPack` to specify which sticker pack to use when transitioning into and out of a song.
  - If the value isn't present, it will use the character's sticker pack instead.

## [2.2.4]
### Added
- Added `playData.characters.opponentVocals` to specify which vocal track(s) to play for the opponent.
  - If the value isn't present, it will use the `playData.characters.opponent`, but if it is present, it will be used (even if it's empty, in which case no vocals will be used for the opponent)
- Added `playData.characters.playerVocals` to specify which vocal track(s) to play for the player.
  - If the value isn't present, it will use the `playData.characters.player`, but if it is present, it will be used (even if it's empty, in which case no vocals will be used for the player)
- Added `offsets.altVocals` field to apply vocal offsets when alternate instrumentals are used.


## [2.2.3]
### Added
- Added `charter` field to denote authorship of a chart.

## [2.2.2]
### Added
- Added `playData.previewStart` and `playData.previewEnd` fields to specify when in the song should the song's audio should be played as a preview in Freeplay.

## [2.2.1]
### Added
- Added `playData.offsets` field to specify instrumental and vocal offsets.

## [2.2.0]
### Added
- Added `playData.album` to specify the album art to display in Freeplay.
- Added `playData.ratings` for difficulty ratings displayed in Freeplay.
### Changed
- Renamed `playData.noteSkin` to `playData.noteStyle`.

## [2.1.0]
### Changed
- Rearranged the `playData` field.
  - Refactored the `playableChars`
### Removed
- Removed the `variation` field.

## [2.0.0]
Full refactor of the chart format for improved structure.
### Added
- Added a semantic version field for migration tracking.

## [1.0.0]
Initial version from 2020.
