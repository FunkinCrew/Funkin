# Compiling Friday Night Funkin'


 1. Setup
    * Download Haxe from [Haxe.org](https://haxe.org)
 2. Cloning the Repository: Make sure when you clone, you clone the submodules to get the assets repo:
    * `git clone --recurse-submodules https://github.com/FunkinCrew/funkin.git`
    * If you accidentally cloned without the `assets` submodule (aka didn't follow the step above), you can run `git submodule update --init --recursive` to get the assets in a foolproof way.
 3. Install `hmm` (run `haxelib --global install hmm` and then `haxelib --global run hmm setup`)
 4. Download Git from [git-scm.com](https://www.git-scm.com)
 5. Install all haxelibs of the current branch by running `hmm install`
 6. [Update your JDK/JRE](https://www.oracle.com/java/technologies/downloads/?er=221886#java17) to atleast 17.
 7. Setup lime: `haxelib run lime setup`
 8. Platform setup
    * For Windows, download the [Visual Studio Build Tools](https://aka.ms/vs/17/release/vs_BuildTools.exe)
      * When prompted, select "Individual Components" and make sure to download the following:
      * MSVC v143 VS 2022 C++ x64/x86 build tools
      * Windows 10/11 SDK
    * Mac: `lime setup mac` Documentation
    * Linux: `lime setup linux` Documentation
    * HTML5: Compiles without any extra setup
    * Android:
      * Run `setup-android-[yourOS].bat` in the docs folder by clicking it to install the required development kits on your machine.
      * If for some reason the downloads don’t work (most likely JDK) [Download it directly.](https://adoptium.net/temurin/releases/?version=17)
      * (ONLY DO THIS STEP IF THE DOWNLOAD FAILED) After installing the JDK, make sure you know where it installed! If you installed using a `.msi` file, it should be somewhere around `C:\Program Files\`. Go and look for an`Eclipse Adoptium` folder and open it.
      * (ONLY DO THIS STEP IF THE DOWNLOAD FAILED look for a folder named something like `jdk-17`. Right click and click on `Copy as path`.
      * (ONLY DO THIS STEP IF THE DOWNLOAD FAILED) Go to your command prompt and type `haxelib run lime config JAVA_HOME [JdkPathYouCopied]`
      * after that is done delete the `temp` folder that just got made.
    * iOS:
      * Get Xcode from the app store on your MacOS Machine.
      * Download the iPhone SDK (First thing that pops up in Xcode)
      * Open up a terminal tab and do `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
 9. If you are targeting for native, you may need to run `lime rebuild PLATFORM` and `lime rebuild PLATFORM -debug`
10. `lime test PLATFORM` ! Add `-debug` to enable several debug features such as time travel (`PgUp`/`PgDn` in Play State).

# Troubleshooting

* During the cloning process, you may experience an error along the lines of `error: RPC failed; curl 92 HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR (err 1)` due to poor connectivity. A common fix is to run ` git config --global http.postBuffer 4096M`.


