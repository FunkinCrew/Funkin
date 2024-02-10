# Compiling Friday Night Funkin'

0. Setup
  a. Download Haxe from [Haxe.org](https://haxe.org)
1. Cloning the Repository: Make sure when you clone, you clone the submodules to get the assets repo:
    - `git clone --recurse-submodules https://github.com/FunkinCrew/funkin-secret.git`
    - If you accidentally cloned without the `assets` submodule (aka didn't follow the step above), you can run `git submodule update --init --recursive` to get the assets in a foolproof way.
2. Install `hmm` (run `haxelib --global install hmm` and then `haxelib --global run hmm setup`)
3. Install all haxelibs of the current branch by running `hmm install`
4. Platform setup
    - Windows: [`lime setup windows` Documentation](https://lime.openfl.org/docs/advanced-setup/windows/)
    - Mac: [`lime setup mac` Documentation](https://lime.openfl.org/docs/advanced-setup/macos/)
    - Linux: [`lime setup linux` Documentation](https://lime.openfl.org/docs/advanced-setup/linux/)
    - HTML5: Compiles without any extra setup
5. If you are targeting for native, you likely need to run `lime rebuild PLATFORM` and `lime rebuild PLATFORM -debug`
6. `lime test PLATFORM` !
