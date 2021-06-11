# Latest changelog

Changes marked with 💖 will be listed in the short version of the changelog in `version.downloadMe`.

### Additions
- [PR #307](https://github.com/KadeDev/Kade-Engine/pulls/307): Fix freeplay lag, add freeplay background changes, and add icons updating in charting state
- Updated to Week 7 input with anti mash
- 💖 Added toggle for ghost tapping
- 💖 [PR #328](https://github.com/KadeDev/Kade-Engine/pulls/328) and [PR #331](https://github.com/KadeDev/Kade-Engine/pulls/331): Distractions toggle
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

### Changes
- Tutorial is now a modchart instead of being hardcoded
- [PR #332](https://github.com/KadeDev/Kade-Engine/pull/332): Move the beatbox in Fresh to the vocal track
- [PR #334](https://github.com/KadeDev/Kade-Engine/pull/334): Unhardcode GF Version, stages, and noteskins and make them loaded from chart
- [PR #291](https://github.com/KadeDev/Kade-Engine/pull/291): Make it so you can compile with 4.0.x
- 💖 [PR #440](https://github.com/KadeDev/Kade-Engine/pull/440): Change how replays work + store scroll speed and direction in replays

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
