@echo off
echo What would you like to build for?
echo H - HTML5
echo M - macOS
echo W - Windows
set /p menu="Your answer: "
       if %menu%==H goto BuildHTML5
       if %menu%==M goto BuildMacOS
       if %menu%==W goto BuildWindows
       cls
       
:BuildHTML5
echo.
echo Starting HTML5 build...
lime test html5 -debug
echo Done. Press any key to exit.
pause >nul
exit

:BuildMacOS
echo.
echo Starting macOS build...
lime test mac -debug
echo Done. Press any key to exit.
pause >nul
exit

:BuildWindows
echo.
echo This will require the following installed:
echo * Visual Studio 2019
echo * MSVC v142 - VS 2019 C++ x64/x86 build tools
echo * Windows SDK (10.0.17763.0)
echo * C++ Profiling tools
echo * C++ CMake tools for windows
echo * C++ ATL for v142 build tools (x86 & x64)
echo * C++ MFC for v142 build tools (x86 & x64)
echo * C++/CLI support for v142 build tools (14.21)
echo * C++ Modules for v142 build tools (x64/x86)
echo * Clang Compiler for Windows
echo * Windows 10 SDK (10.0.17134.0)
echo * Windows 10 SDK (10.0.16299.0)
echo * MSVC v141 - VS 2017 C++ x64/x86 build tools
echo * MSVC v140 - VS 2015 C++ build tools (v14.00)
echo You can find these in the Visual Studio Installer, seen here: https://visualstudio.microsoft.com
echo Press any key to start building.
pause >nul
echo Starting Windows build...
lime test windows -debug
echo Done. Press any key to exit.
pause >nul
exit
