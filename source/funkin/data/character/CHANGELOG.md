# Character Data Schema Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0]
### Changed
- Character offsets are now automatically flipped horizontally when the character is flipped.
  - This makes the character look correct when reused between player and opponent, but is a breaking change.
  - Automatic migration is implemented, so characters using version `1.0.1` won't break.

## [1.0.1]
### Added
- `death.cameraOffsets` to specify the camera position during the death animation.

## [1.0.0]
Initial release.
