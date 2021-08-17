@echo off
title FNF Build - User action required
echo What would you like to build for?
echo H - HTML5
echo M - macOS
echo W - Windows
set /p menu="Your answer: "
       if %menu%==H goto BuildHTML5
       if %menu%==M goto BuildMacOS
       if %menu%==W goto BuildWindows
       if %menu%==h goto BuildHTML5
       if %menu%==m goto BuildMacOS
       if %menu%==w goto BuildWindows
       cls
       
:BuildHTML5
title FNF Build - Building for HTML5
echo.
echo Starting HTML5 build...
lime test html5 -debug
echo Done. Press any key to exit.
pause >nul
exit

:BuildMacOS
title FNF Build - Building for macOS
echo.
echo Starting macOS build...
lime test mac -debug
echo Done. Press any key to exit.
pause >nul
exit

:BuildWindows
echo.
echo These will require dependencies. You can find them in the README. It will also take *forever*.
echo Press any key to start building.
pause >nul
title FNF Build - Building for Windows
echo Starting Windows build...
lime test windows -debug
echo Done. Press any key to exit.
pause >nul
exit
