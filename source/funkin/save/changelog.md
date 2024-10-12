# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.6] - 2024-10-11
### Added
- `optionsStageEditor` to `Save` for storing user preferences for the stage editor.

## [2.0.5] - 2024-05-21
### Fixed
- Resolved an issue where HTML5 wouldn't store the semantic version properly, causing the game to fail to load the save.

## [2.0.4] - 2024-05-21
### Added
- `unlocks.charactersSeen:Array<String>` to `Save`
- `unlocks.oldChar:Bool` to `Save`
- `favoriteSongs:Array<String>` to `Save`

## [2.0.3] - 2024-01-09
### Added
- `inputOffset:Float` to `SongDataOptions`
- `audioVisualOffset:Float` to `SongDataOptions`
