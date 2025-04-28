# Compiling Friday Night Funkin' for Mobile Devices

This guide walks through the process of building for Android and iOS

## Android
0. Build the game for desktop to make sure everything works. Check [COMPILING.md](./COMPILING.md).
1. Run `setup-android-[yourOS].bat` in the docs folder to automatically download the required development kits on your machine.
      - If for some reason the downloads don’t work (most likely JDK) [Download it directly.](https://adoptium.net/temurin/releases/?version=17)
      - (ONLY DO THIS STEP IF THE DOWNLOAD FAILED) After installing the JDK, make sure you know where it installed! If you installed using a `.msi` file, it should be somewhere around `C:\Program Files\`. Go and look for an`Eclipse Adoptium` folder and open it.
      - (ONLY DO THIS STEP IF THE DOWNLOAD FAILED) look for a folder named something like `jdk-17`. Right click and click on `Copy as path`.
      - (ONLY DO THIS STEP IF THE DOWNLOAD FAILED) Go to your command prompt and type `haxelib run lime config JAVA_HOME [JdkPathYouCopied]`
      - after that is done delete the `temp` folder that just got made.

## iOS
Note that you can only build the game for iOS on a computer running MacOS.

0. Build the game for desktop to make sure everything works. Check [COMPILING.md](./COMPILING.md).
1. Get Xcode from the app store on your MacOS Machine.
2. Download the iPhone SDK (First thing that pops up in Xcode)
3. Open up a terminal tab and do `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
