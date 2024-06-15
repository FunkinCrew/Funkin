# Compiling Friday Night Funkin'

0. Setup
    - Download Haxe from [Haxe.org](https://haxe.org)
    - Download Git from [git-scm.com](https://www.git-scm.com)
    - Do NOT download the repository using the Download ZIP button on GitHub or you may run into errors!
    - Instead, open a command prompt and do the following steps...
1. Run `git clone --recurse-submodules https://github.com/FunkinCrew/funkin.git` to clone the repository with the necessary assets submodule
    - _If you accidentally cloned without the `assets` submodule (aka didn't follow the step above), you can run `git submodule update --init --recursive` to get the assets in a foolproof way._
2. Run `haxelib --global install hmm` and then `haxelib --global run hmm setup` to install hmm.json
3. Run `hmm install` to install all haxelibs of the current branch
4. Run `haxelib run lime setup` to set up lime
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

