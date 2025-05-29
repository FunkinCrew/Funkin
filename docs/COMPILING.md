# Compiling Friday Night Funkin'

0. Setup
    - Download Haxe from [Haxe.org](https://haxe.org)
    - Download Git from [git-scm.com](https://www.git-scm.com)
    - Do NOT download the repository using the Download ZIP button on GitHub or you may run into errors!
    - Instead, open a command prompt and do the following steps...
1. Run `cd the\directory\you\want\the\source\code\in` to specify which folder the command prompt is working in.
    - For example, `cd C:\Users\YOURNAME\Documents` would instruct the command prompt to perform the next steps in your Documents folder.
2. Run `git clone https://github.com/FunkinCrew/funkin.git` to clone the base repository.
3. Run `cd funkin` to enter the cloned repository's directory.
4. Run `git submodule update --init --recursive` to download the game's assets.
    - NOTE: By performing this operation, you are downloading Content which is proprietary and protected by national and international copyright and trademark laws. See [the LICENSE.md file for the Funkin.assets](https://github.com/FunkinCrew/funkin.assets/blob/main/LICENSE.md) repo for more information.
5. Run `haxelib --global install hmm` and then `haxelib --global run hmm setup` to install hmm.json
6. Run `hmm install` to install all haxelibs of the current branch
    - If you have issues installing Lime, try utilizing Funkin's patched libraries for hmm and haxelib: `haxelib --global git haxelib https://github.com/FunkinCrew/haxelib.git` and `haxelib --global git hmm  https://github.com/FunkinCrew/hmm.git`
8. Run `haxelib run lime setup` to set up Lime
9. Perform additional platform setup
   - For Windows, download the [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe)
        - When prompted, select "Individual Components" and make sure to download the following:
        - MSVC v143 VS 2022 C++ x64/x86 build tools
        - Windows 10/11 SDK
    - Mac: [`lime setup mac` Documentation](https://lime.openfl.org/docs/advanced-setup/macos/)
    - Linux: [`lime setup linux` Documentation](https://lime.openfl.org/docs/advanced-setup/linux/)
        - One of Funkin's dependencies uses libVLC, which requires you to install some development packages to be able to compile.
          Command for Ubuntu/Debian based systems: `sudo apt install libvlc-dev libvlccore-dev libvlccore9`, and for other distros, please refer to [hxvlc's documentation](https://github.com/MAJigsaw77/hxvlc?tab=readme-ov-file#dependencies)
    - HTML5: Compiles without any extra setup
10. If you are targeting for native, you may need to run `lime rebuild <PLATFORM>` and `lime rebuild <PLATFORM> -debug`
11. `lime test <PLATFORM>` to build and launch the game for your platform (for example, `lime test windows`)

## Build Flags

There are several useful build flags you can add to a build to affect how it works. A full list can be found in `project.hxp`, but here's information on some of them:

- `-debug` to build the game in debug mode. This automatically enables several useful debug features.
    - This includes enabling in-game debug functions, disables compile-time optimizations, enabling asset redirection (see below), and enabling the VSCode debug server (which can slow the game on some machines but allows for powerful debugging through breakpoints).
    - `-DGITHUB_BUILD` will enable in-game debug functions (such as the ability to time travel in a song by pressing `PgUp`/`PgDn`), without enabling the other stuff
- `-DFEATURE_POLYMOD_MODS` or `-DNO_FEATURE_POLYMOD_MODS` to forcibly enable or disable modding support.
- `-DREDIRECT_ASSETS_FOLDER` or `-DNO_REDIRECT_ASSETS_FOLDER` to forcibly enable or disable asset redirection.
    - This feature causes the game to load exported assets from the project's assets folder rather than the exported one. Great for fast iteration, but the game will break if you try to zip it up and send it to someone, so it's disabled for release builds.
- `-DFEATURE_DISCORD_RPC` or `-DNO_FEATURE_DISCORD_RPC` to forcibly enable or disable support for Discord Rich Presence.
- `-DFEATURE_VIDEO_PLAYBACK` or `-DNO_FEATURE_VIDEO_PLAYBACK` to forcibly enable or disable video cutscene support.
- `-DFEATURE_SCREENSHOTS` or `-DNO_FEATURE_SCREENSHOTS` to forcibly enable or disable the screenshots feature.
- `-DFEATURE_CHART_EDITOR` or `-DNO_FEATURE_CHART_EDITOR` to forcibly enable or disable the chart editor in the Debug menu.
- `-DFEATURE_STAGE_EDITOR` to forcibly enable the experimental stage editor.
- `-DFEATURE_GHOST_TAPPING` to forcibly enable an experimental gameplay change to the anti-mash system.

# Troubleshooting

If you experience any issues during the compilation process, DO NOT open an issue on GitHub. Instead, check the [Troubleshooting Guide](TROUBLESHOOTING.md) for steps on how to resolve common problems.
