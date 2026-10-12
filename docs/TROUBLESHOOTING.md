# Troubleshooting Common Compilation Issues

- Any output containing `WARNING` or `(WDeprecated)`
  - Will not disrupt compilation and can be safely ignored.

- `This version of hxcpp` ... `Would you like to do this now [y/n]`
  - Type "y" into the console and press Enter.

- Weird macro error with a very tall call stack: Restart Visual Studio Code
  - NOTE: This is caused by Polymod somewhere, and seems to only occur when there is another compile error somewhere in the program. There is a bounty up for it.

- `Get Thread Context Failed`
  - Turn off other expensive applications while building.

- `Type not found: T1`
  - This is thrown by `json2object`, make sure the data type of `@:default` is correct.
  - NOTE: `flixel.util.typeLimit.OneOfTwo` isn't supported.

- `Class lists not properly generated. Try cleaning out your export folder, restarting your IDE, and rebuilding your project.`
  - This is a bug specific to HTML5. Simply perform the steps listed (don't forget to restart the IDE too).

- `LINK : fatal error LNK1201: error writing to program database ''; check for insufficient disk space, invalid path, or insufficient privilege`
  - This error occurs if the PDB file located in your `export` folder is in use or exceeds 4 GB. Try deleting the `export` folder and building again from scratch.

- `error: RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR (err 1)`
  - This error can happen during cloning as a result of poor network connectivity. A common fix is to run `git config --global http.postBuffer 4096M` in your terminal.

- Repository is missing an `assets` folder, or `assets` folder is empty.
  - You did not clone the repository correctly! Copy the path to your `funkin` folder and run `cd the\path\you\copied`. Then follow the compilation guide starting from **Step 4**.

- Other compilation issues may be caused by installing bad library versions. Try deleting the `.haxelib` folder and following the guide starting from **Step 5**.

## Lime Related Issues
- Segmentation fault and/or crash after `Done mapping time changes: [SongTimeChange(0ms,102bpm)]`
  - Caused by using official Lime instead of Funkin's fork. Reinstalling Lime should fix it.  
    (NOTE: Make sure you do this via `hmm` (e.g `hmm reinstall -f lime`) to guarantee you get Funkin's version of Lime.)

- `Uncaught exception - Could not find lime.ndll.` ... `Advanced users may run "lime rebuild cpp" instead.`
  - If on Linux:
    - The binaries GLibC version might more recent than the one your system supports. Running the commands below should fix it.
      ```
      cd .haxelib/lime/git
      git submodule init
      git submodule sync
      git submodule update
      cd ../../..
      # Note: The command and packages here might be different depending on your distro.
      sudo apt install libgl1-mesa-dev libglu1-mesa-dev g++ g++-multilib gcc-multilib libasound2-dev libx11-dev libxext-dev libxi-dev libxrandr-dev libxinerama-dev libpulse-dev
      lime rebuild cpp -64 -release -clean
      ```
      
  - The binaries are missing for some reason. You can download pre-built binaries from [Funkin's Lime](https://github.com/FunkinCrew/lime/tree/dev-funkin/ndll).  
    You should copy them to `.haxelib/lime/git/ndll/<PLATFORM>64/`, where `<PLATFORM>` is the current platform you're on, which can be either Windows, Linux or MacOS.
