# funkin.ui.loading.preload

This package contains code powering the HTML5 preloader screen.

The preloader performs the following tasks:
- **Downloading assets**: Downloads the `core` asset library and loads its manifest
- **Preloading play assets**: Downloads the `gameplay` asset library (manifest only)
- **Initializing scripts**: Downloads and registers stage scripts, character scripts, song scripts, and module scripts.
- **Caching graphics**: Downloads all graphics from the `core` asset library, uploads them to the GPU, then dumps them from RAM. This prepares them to be used very quickly in-game.
- **Caching audio**: Downloads all audio files from the `core` asset library, and caches them. This prepares them to be used very quickly in-game.
- **Caching data**: Downloads and caches all TXT files, all JSON files (it also parses them), and XML files (from the `core` library only). This prepares them to be used in the next steps.
- **Parsing stages**: Parses all stage data and instantiates associated stage scripts. This prepares them to be used in-game.
- **Parsing characters**: Parses all character data and instantiates associated character scripts. This prepares them to be used in-game.
- **Parsing songs**: Parses all song data and instantiates associated song scripts. This prepares them to be used in-game.
- **Finishing up**: Waits for the screen to fade out. Then, it loads the first state of the app.

Due to the first few steps not being relevant on desktop, and due to this preloader being built in Lime rather than HaxeFlixel because of how Lime handles asset loading, this preloader is not used on desktop. The splash loader is used instead.
