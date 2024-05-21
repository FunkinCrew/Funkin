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

While performing the process of compilation, you may experience one of the following issues:

## PolymodHandler: extra field coreAssetRedirect

```
Installing funkin.vis from https://github.com/FunkinCrew/funkVis branch: 98c9db09f0bbfedfe67a84538a5814aaef80bdea
Error: std@sys_remove_dir
Execution error: command "haxelib --never git funkin.vis https://github.com/FunkinCrew/funkVis 98c9db09f0bbfedfe67a84538a5814aaef80bdea" failed with status: 1 in cwd
```

If you receive this error, you are on an outdated version of Polymod.

To solve, you should try reinstalling Polymod:

```
haxelib run hmm reinstall --force polymod
```

You can also try deleting your `.haxelib` folder in your Funkin' project, then reinstalling all your Haxelibs to prevent any other errors:

```
rm -rf ./.haxelib
haxelib run hmm reinstall --force
```

## PolymodHandler: Couldn't find a match for this asset library: (vlc)

```
source/funkin/modding/PolymodErrorHandler.hx:84: [ERROR] Your Lime/OpenFL configuration is using custom asset libraries, and you provided frameworkParams in Polymod.init(), but we couldn't find a match for this asset library: (vlc)
source/funkin/modding/PolymodHandler.hx:158: An error occurred! Failed when loading mods!
source/funkin/util/logging/CrashHandler.hx:62: Error while handling crash: Null Object Reference
```

This error is specific to Linux targets. If you receive this error, you are on an outdated verison of hxCodec.

To solve, you should try reinstalling hxCodec:

```
haxelib run hmm reinstall --force hxCodec
```

You can also try deleting your `.haxelib` folder in your Funkin' project, then reinstalling all your Haxelibs to prevent any other errors:

```
rm -rf ./.haxelib
haxelib run hmm reinstall --force
```

## Git: stream 0 was not closed cleanly: PROTOCOL_ERROR

```
error: RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR (err 1)
```

If you receive this error while cloning, you may be experiencing issues with your network connection.

To solve, you should try modifying your git configuration before cloning again:

```
git config --global http.postBuffer 4096M
```
