# Latest (master) changelog/Changelog

Changes marked with 💖 will be listed in the short version of the changelog in `version.downloadMe`.

### Additions
- New options menu 💖
- New animation debug screen 💖
- Asset replacing mods are now fully supported (docs are [here](https://github.com/KadeDev/Kade-Engine/blob/master/example_mods/README.md))
- Middle scroll 💖
- Lane transparency 💖
- Toggelabe health bar
- Added noteskin support + new circle skin 💖
- Added an hotkey (r) to reset the rate in freeplay
- Added the ability to customize judgements
- Added a border around the FPS Counter

### Changes
- You can now view the options menu in the pause menu 💖
- Editor claps are more consistant
- Changed logging system to a custom one, logs output into logs/
- Changed some stuff on customize gameplay
- Allowed VolumeUp, VolumeDown, VolumeMute, Pause, Reset, and Fullscreen keybinds to bindable
- Controllers can now bind more keys that were previously blacklisted
- Removed version identifier in gameplay
- Removed some stuff from the results screen
- Made the FPS text nicer
- The game no longer freezes when it has lost focus

### Bugfixes
- Fix linux and mac compiling and running
- Fix failing on 20/21 on debug mode
- Fixed a memory leak with note XML assets
- Fixed crashing at the end of a song in the charter
- Fixed playing music when paused
- Fixed a bug where a song would end early if the rate was lower than 1
- Fixed a bug where a song would end earlier than the end of the song if the rate was higher than 1
- Fixed the results screen being skewed on higher or lower rates
- Fixed FPS Cap resetting itself on focusing out of the window
- Fixed sustain rendering so it doesn't break itself on rates
- Fixed input on rates 💖
- Fixed rates on longer maps so they are more stable 💖