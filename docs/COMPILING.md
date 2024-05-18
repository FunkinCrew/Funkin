# Compiling Friday Night Funkin'

0. Setup
    - Download Haxe from [Haxe.org](https://haxe.org)
1. Cloning the Repository: Make sure when you clone, you clone the submodules to get the assets repo:
    - `git clone --recurse-submodules https://github.com/FunkinCrew/funkin.git`
    - If you accidentally cloned without the `assets` submodule (aka didn't follow the step above), you can run `git submodule update --init --recursive` to get the assets in a foolproof way.
2. Install `hmm` (run `haxelib --global install hmm` and then `haxelib --global run hmm setup`)
3. Install all haxelibs of the current branch by running `hmm install`
4. Setup lime: `haxelib run lime setup`
5. Platform setup
   - For Windows, download the [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe)
        - When prompted, select "Individual Components" and make sure to download the following:
        - MSVC v143 VS 2022 C++ x64/x86 build tools
        - Windows 10/11 SDK
    - Mac: [`lime setup mac` Documentation](https://lime.openfl.org/docs/advanced-setup/macos/)
    - Linux: [`lime setup linux` Documentation](https://lime.openfl.org/docs/advanced-setup/linux/)
    - HTML5: Compiles without any extra setup
6. If you are targeting for native, you may need to run `lime rebuild PLATFORM` and `lime rebuild PLATFORM -debug`
7. `lime test PLATFORM` ! Add `-debug` to enable several debug features such as time travel (`PgUp`/`PgDn` in Play State).

# Troubleshooting

- During the cloning process, you may experience an error along the lines of `error: RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR (err 1)` due to poor connectivity. A common fix is to run ` git config --global http.postBuffer 4096M`.
