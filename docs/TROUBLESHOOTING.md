# Troubleshooting Common Compilation Issues

- Weird macro error with a very tall call stack: Restart Visual Studio Code
  - NOTE: This is caused by Polymod somewhere, and seems to only occur when there is another compile error somewhere in the program. There is a bounty up for it.

- `Get Thread Context Failed`: Turn off other expensive applications while building

- `Type not found: T1`: This is thrown by `json2object`, make sure the data type of `@:default` is correct.
  - NOTE: `flixel.util.typeLimit.OneOfTwo` isn't supported.

- `Class lists not properly generated. Try cleaning out your export folder, restarting your IDE, and rebuilding your project.`
  - This is a bug specific to HTML5. Simply perform the steps listed (don't forget to restart the IDE too).

- `LINK : fatal error LNK1201: error writing to program database ''; check for insufficient disk space, invalid path, or insufficient privilege`
  - This error occurs if the PDB file located in your `export` folder is in use or exceeds 4 GB. Try deleting the `export` folder and building again from scratch.

- `error: RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR (err 1)`
  - This error can happen during cloning as a result of poor network connectivity. A common fix is to run `git config --global http.postBuffer 4096M` in your terminal.

- Repository is missing an `assets` folder, or `assets` folder is empty.
  - You did not clone the repository correctly! Copy the path to your `Funkin` folder and run `cd the\path\you\copied`. Then follow the compilation guide starting from **Step 4**.

- Other compilation issues may be caused by installing bad library versions. Try deleting the `.haxelib` folder and following the guide starting from **Step 5**.
