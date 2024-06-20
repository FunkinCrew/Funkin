@echo off

set ZIP_FILE="./temp/_temp_jdk.zip"
set OUTPUT_DIR="./temp/"
set SIX_LINK="https://download1326.mediafire.com/z0ecgdkuzfogLku0fmPps4X90mDN1VYj2pvfO3MmQKU2kmM5-MHEIEDsAfqIsmr6iWPjym7NKixK058SkwJtAK9_pM-yM9pdcCltXtxgakb7SWriW_OHpMV4JVeY9YJKhPebfP4zHDDs24YffZo7-pu1y5GJyqf-gpqQ_4kChktTqw/hl5ubksdmetvfcb/windows-jdk-64.zip"
set EIGHT_LINK="https://download948.mediafire.com/1uri3yg8byugo6K5uv2c5kpOFf2ayY-dpy3BqlIKK6v1jPaw_BhRQNS5HatXsIbTBl-VrmTD8j0scEGGi3jWXI0Rgjr4ruyy51KQMy61CrMbauT0vk4zx7mLKHXHVJzOkQJmuWENfwnKeOT66b-PCgwiwFJ2-CKUERd4gOk_0TO54A/xw4f5db6cxjmbdb/windows-jdk-86.zip"

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
(
  echo %LOCALAPPDATA%\Android\Sdk
  echo %LOCALAPPDATA%\Android\Sdk\ndk\21.4.7075529
  echo %LOCALAPPDATA%\Android\Sdk\jdk\jdk-17.0.11+9
) | lime setup android
echo DONE

pause
