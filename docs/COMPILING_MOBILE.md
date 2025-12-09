# Compiling Friday Night Funkin' for Mobile Devices

Before starting, **make sure your game builds on desktop.**
Check [COMPILING.md](./COMPILING.md) if you haven’t done that yet.

## Android

0. **Create a new folder** – this will store Android tools (remember where you put it!).
1. **Open a terminal as Administrator.**
2. Run this in the terminal (replace the path with your actual folder):
   ```bash
   setx ANDROID_HOME "C:\path\to\your\folder" /M
   ```
3. Download [Android Studio Command-line Tools](https://developer.android.com/studio#command-line-tools-only).
4. Extract the ZIP into your folder from step 1.
5. (Optional) Close and reopen the terminal if needed.
6. Run:
   ```bash
   sdkmanager --install "build-tools;35.0.0" "ndk;29.0.13113456" "platforms;android-29" "platforms;android-35"
   ```
   - The latest NDK is not compatible with Lime you have to use the old one.
7. Download and install [JDK 17 (MSI)](https://adoptium.net/temurin/releases/?version=17&os=windows).
8. Run:
   ```bash
   lime setup android
   ```
   Use these when asked:
   - **Android SDK:** `C:\path\to\your\folder`
   - **Android NDK:** `C:\path\to\your\folder\ndk\29.0.13113456`
   - **JDK:** `C:\Program Files\Java\jdk-17`

9. Now build your game:
    ```bash
    lime test android
    ```


### macOS

0. **Create a new folder** – this will store Android tools (remember where you put it!).
1. Open **Terminal** (Command ⌘ + Space → type “terminal” → Enter).
2. In Terminal:
   ```bash
   cd /path/to/your/folder
   export ANDROID_HOME=/path/to/your/folder
   export PATH=$PATH:$ANDROID_HOME/cmdline-tools:$ANDROID_HOME/cmdline-tools/bin:$ANDROID_HOME/platform-tools
   ```
3. Download [Android Studio Command-line Tools](https://developer.android.com/studio#command-line-tools-only).
4. Extract the ZIP into your folder from step 1.
5. (Optional) Restart Terminal if needed.
6. Run:
   ```bash
   sdkmanager --install "build-tools;35.0.0" "ndk;29.0.13113456" "platforms;android-29" "platforms;android-35"
   ```
7. Download and install [JDK 17 for macOS](https://adoptium.net/temurin/releases/?os=mac&version=17).
8. Run:
   ```bash
   lime setup android
   ```
   Use these when asked:
   - **Android SDK:** `/path/to/your/folder`
   - **Android NDK:** `/path/to/your/folder/ndk/28.0.13004108`
   - **JDK:** `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`
     _(If not asked for JDK, don’t worry — just skip it.)_

9. Build your game:
    ```bash
    lime test android
    ```

## iOS
Note that you can only build the game for iOS on a computer running MacOS.

0. Build the game for desktop to make sure everything works. Check [COMPILING.md](./COMPILING.md).
1. Get Xcode from the app store on your MacOS Machine.
2. Download the iPhone SDK (First thing that pops up in Xcode)
3. Open up a terminal tab and run `lime test ios -xcode`
4. You will need to sign your own copy in order to run the game with a real iOS device! That requires an Apple Developer account, sorry!
   - To run with an iOS simulator instead of `-xcode` use `-simulator`

### iOS Troubleshooting

- **A required plugin failed to load. Please ensure system content is up-to-date — try running 'xcodebuild -runFirstLaunch'.**
Make sure you have the iOS SDK isntalled, see Step 2.

- **error: No Accounts: Add a new account in Accounts settings. (in target 'Funkin' from project 'Funkin')**

Open XCode, press CMD+, to open Settings, select Accounts, add an Apple ID.

- error: No Account for Team "Z7G7AVNGSH". Add a new account in Accounts settings or verify that your accounts have valid credentials.

Open `project.hxp` and change `IOS_TEAM_ID` to your personal team's ID.

- error: Failed Registering Bundle Identifier: The app identifier "me.funkin.fnf" cannot be registered to your development team because it is not available.

The Funkin' Crew are the only ones that can build an iOS app with the identifier `me.funkin.fnf`. Open `project.hxp` and change `PACKAGE_NAME` to a unique value.

- error: No profiles for 'me.funkin.fnf' were found: Xcode couldn't find any iOS App Development provisioning profiles matching 'me.funkin.fnf'
