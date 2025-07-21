@echo off

set ZIP_FILE="./temp/_temp_jdk.zip"
set OUTPUT_DIR="./temp/"
set SIX_LINK="https://drive.usercontent.google.com/download?id=1GqFpIk_bkxFb0tNN3x9LxnN-Zh_oDUX5&export=download&authuser=0&confirm=t&uuid=43108c0a-bd53-4465-86f3-80aaceaa7a38&at=APZUnTVNS_BV9cNyC_iicDInosmz%3A1718921284514"
set EIGHT_LINK="https://drive.usercontent.google.com/download?id=1X8jjtYYos8aDfZKwehGS9B3zFQa-sCb-&export=download&authuser=0&confirm=t&uuid=07b24a6c-5352-4ba5-9fb8-cff151a6d91e&at=APZUnTUfw26NBAl0nCMn6HBKgHwK%3A1718922303598"

echo MAKING TEMP
mkdir %OUTPUT_DIR%
echo MADE TEMP



echo INSTALLING ANDROID BUILD TOOLS
call .\asclt\bin\sdkmanager "build-tools;32.0.0" --sdk_root="%LOCALAPPDATA%/Android/Sdk/"
call .\asclt\bin\sdkmanager "build-tools;32.1.0-rc1" --sdk_root="%LOCALAPPDATA%/Android/Sdk/"
echo INSTALLED ANDROID BUILD TOOLS



echo INSTALLING ANDROID SDK
REM First install the sdks
call .\asclt\bin\sdkmanager "platforms;android-29" --sdk_root="%LOCALAPPDATA%/Android/Sdk/"
echo ANDROID SDK INSTALLED



echo INSTALLING ANDROID NDK
REM then the ndks
call ./asclt/bin/sdkmanager "ndk;21.4.7075529" --sdk_root="%LOCALAPPDATA%/Android/Sdk/"
echo ANDROID NDK INSTALLED



echo DOWNLOADING JDK
call curl -o %ZIP_FILE% %SIX_LINK%
echo DOWNLOADED JDK



echo UNZIPPING JDK
call powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%OUTPUT_DIR%' -Force"
echo UNZIPPED JDK



echo MAKING JDK PATH
mkdir "%LOCALAPPDATA%/Android/jdk"
echo MADE JDK PATH



echo MOVING JDK TO PROPER PATH
call move "%OUTPUT_DIR%/jdk-17.0.11+9" "%LOCALAPPDATA%/Android/jdk/"
echo MOVED JDK



echo LIME SETTING UP
haxelib run lime config ANDROID_SDK %LOCALAPPDATA%\Android\Sdk
haxelib run lime config ANDROID_NDK_ROOT %LOCALAPPDATA%\Android\Sdk\ndk\21.4.7075529
haxelib run lime config JAVA_HOME %LOCALAPPDATA%\Android\Sdk\jdk\jdk-17.0.11+9
haxelib run lime config ANDROID_SETUP true
echo DONE

pause
