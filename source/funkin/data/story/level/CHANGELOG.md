# Story Mode Level Data Schema Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.4]
### Added
- Added `visibleFreeplay` attribute to allow weeks to be hidden in the Freeplay menu.

## [1.0.3]
### Added
- Added `loadEntries()`.
- Added `loadEntriesAsync()`.
- Added `populateReverseSongMap()` which creates a `song => level` map for easy lookup.
- Added `clearEntries()`.
- Added `fetchDefault()` to fetch the data for the default level.
- Added `fetchEntryBySongId()` to fetch the level that contains the song with the given ID.

## [1.0.2]
### Added
- Added `capsule` field to change the Level's capsule name on the Freeplay menu.
- Added `unlocked` attribute to allow weeks to be locked by default in the Story menu.
  - This value defaults to `true`, so you shouldn't experience any different behavior.

## [1.0.1]
### Added
- Added `visible` attribute to allow weeks to be hidden in the Story menu.

## [1.0.0]
Initial release.
