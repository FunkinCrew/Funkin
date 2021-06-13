# Latest changelog

Changes marked with 💖 will be listed in the short version of the changelog in `version.downloadMe`.

### Additions
- [PR #307](https://github.com/KadeDev/Kade-Engine/pulls/307): Fix freeplay lag, add freeplay background changes, and add icons updating in charting state
- Updated to Week 7 input with anti mash
- 💖 Added toggle for ghost tapping
- (maybe 💖) [PR #328](https://github.com/KadeDev/Kade-Engine/pulls/328) and [PR #331](https://github.com/KadeDev/Kade-Engine/pulls/331): Distractions toggle
- [PR #341](https://github.com/KadeDev/Kade-Engine/pull/341): Update heads in realtime in charting state
- 💖 [PR #362](https://github.com/KadeDev/Kade-Engine/pull/362): Officially support macOS (and add macOS requirements to docs)
- Set up macOS CI builds
- [PR #373](https://github.com/KadeDev/Kade-Engine/pull/373): Add tweens to modcharts
- [PR #367](https://github.com/KadeDev/Kade-Engine/pull/367): Add labels to charting state
- [PR #374](https://github.com/KadeDev/Kade-Engine/pull/374): Add more icon sizes
- 💖 [PR #385](https://github.com/KadeDev/Kade-Engine/pull/385): Autoplay
- (maybe 💖) [#353](https://github.com/KadeDev/Kade-Engine/issues/353) ([PR #400](https://github.com/KadeDev/Kade-Engine/pulls/400)): Clap assist for syncing charts
- [PR #413](https://github.com/KadeDev/Kade-Engine/pulls/413): Option to disable flashing lights in menus
- [PR #428](https://github.com/KadeDev/Kade-Engine/pulls/428): Move documentation to GitHub Pages + new changelog system
- [PR #431](https://github.com/KadeDev/Kade-Engine/pull/431): Add Max NPS counter
- [PR #447](https://github.com/KadeDev/Kade-Engine/pull/447): New outdated version screen with small patch notes
- (maybe 💖) [PR #490](https://github.com/KadeDev/Kade-Engine/pull/490): Bring back `R` to reset, but now you can toggle it in the options
- [PR #551](https://github.com/KadeDev/Kade-Engine/pull/551): Add setActorScaleXY, setActorFlipX, setActorFlipY, setStrumlineY to lua modcharts
- [PR #582](https://github.com/KadeDev/Kade-Engine/pull/582): Add changeDadCharacter, changeBoyfriendCharacter, keyPressed to lua modcharts
- [PR #603](https://github.com/KadeDev/Kade-Engine/pull/603) and [PR #604](https://github.com/KadeDev/Kade-Engine/pull/604): Add note shifting to the chart editor
- [PR #672](https://github.com/KadeDev/Kade-Engine/pull/672): Add getWindowWidth, getWindowHeight to lua modcharts
- 💖 You can now fully customize your keybinds
- Added new animations for the main menu and options menu
- You can now place notes in the chart editor with 1-8 on your keyboard

### Changes
- Tutorial is now a modchart instead of being hardcoded
- [PR #332](https://github.com/KadeDev/Kade-Engine/pull/332): Move the beatbox in Fresh to the vocal track
- [PR #334](https://github.com/KadeDev/Kade-Engine/pull/334): Unhardcode GF Version, stages, and noteskins and make them loaded from chart
- [PR #291](https://github.com/KadeDev/Kade-Engine/pull/291): Make it so you can compile with 4.0.x
- 💖 [PR #440](https://github.com/KadeDev/Kade-Engine/pull/440): Change how replays work + store scroll speed and direction in replays
- [PR #480](https://github.com/KadeDev/Kade-Engine/pull/480): Alphabet now supports spaces, songs now use spaces instead of dashes internally
- (maybe 💖) [PR #504](https://github.com/KadeDev/Kade-Engine/pull/504): Opponent strumline now lights up when they hit a note, like the player's does
- 💖 [PR #519](https://github.com/KadeDev/Kade-Engine/pull/519): Now using the new recharts from Funkin v0.2.8
- [PR #528](https://github.com/KadeDev/Kade-Engine/pull/528): setCamZoom and setHudZoom now use floats in lua modcharts
- [PR #590](https://github.com/KadeDev/Kade-Engine/pull/590): The license is now automatically distributed with the game
- (maybe 💖) [PR #612](https://github.com/KadeDev/Kade-Engine/pull/612): BPM is now a float (can have decimals)
- The strumline in the chart editor now snaps to the time axis (toggle with Ctrl)
- Change the look of judgements (sick, good, bad, shit)

### Bugfixes
- [PR #289](https://github.com/KadeDev/Kade-Engine/pulls/289): Player 2 now plays idle animation properly when camera zooms in
- (maybe 💖) [PR #314](https://github.com/KadeDev/Kade-Engine/pulls/314): Fix note trails
- [PR #330](https://github.com/KadeDev/Kade-Engine/pull/330): Fix spelling errors in options
- [#329](https://github.com/KadeDev/Kade-Engine/issues/329) ([PR #341](https://github.com/KadeDev/Kade-Engine/pull/341)): Fix crash when changing characters in charting state on web
- [PR #341](https://github.com/KadeDev/Kade-Engine/pull/341): Fix html5 crash (when building), fix layering issues in charting state, fix charting state crashes in html5
- [PR #376](https://github.com/KadeDev/Kade-Engine/pull/376): Fix must hit sections
- [#368](https://github.com/KadeDev/Kade-Engine/issues/368) ([PR #392](https://github.com/KadeDev/Kade-Engine/pull/392)): Fix enemy idle animations not playing before first note
- [PR #399](https://github.com/KadeDev/Kade-Engine/pulls/399): Fix downscroll typo
- [PR #431](https://github.com/KadeDev/Kade-Engine/pull/431): Fix NPS counter
- [#404](https://github.com/KadeDev/Kade-Engine/issues/404) ([PR #446](https://github.com/KadeDev/Kade-Engine/pull/446)): Fix bug where Alt Animation in charting state doesn't stay checked after going to another section then back
- [PR #503](https://github.com/KadeDev/Kade-Engine/pull/503): Fix menu jittering
- [PR #600](https://github.com/KadeDev/Kade-Engine/pull/600): Fix bug where modcharts would break pausing
- [PR #638](https://github.com/KadeDev/Kade-Engine/pull/638): Fix bug with Girlfriend's dance in the tutorial
- [PR #678](https://github.com/KadeDev/Kade-Engine/pull/678): Fix opening URLs on Linux
- [PR #672](https://github.com/KadeDev/Kade-Engine/pull/672): Fix getScreenWidth and getScreenHeight in lua modcharts
- Fixed early hit window
