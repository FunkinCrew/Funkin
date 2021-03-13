@echo off
echo Make sure Haxe 4.1.5 and HaxeFlixel is installed (4.1.5 is important)!
echo Press any key to install required libraries.
pause >nul
echo Installing haxelib libraries...
haxelib install flixel
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install hscript
haxelib install newgrounds
echo Make sure you have git installed. You can download it here: https://git-scm.com/downloads
echo Press any key to install polymod.
pause >nul
haxelib git polymod https://github.com/larsiusprime/polymod.git
set /p menu="Would you like to fix the transition bug? [Y/N]"
       if %menu%==Y haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons
       if %menu%==2 rem Nothing done
       cls
set /p menu2="Would you like to automatically make the APIStuff file? [Y/N]"
       if %menu2%==Y goto APIStuffYes
       if $menu2%==N goto APIStuffNo
       cls
       
:APIStuffYes
rem Stores the APIStuff.hx contents automatically
cd source
(
echo package;
echo class APIStuff
echo {
echo         public static var API:String = "";
echo         public static var EncKey:String = "";
echo }
)>APIStuff.hx
cd ..
echo Setup successful. Press any key to exit.
pause >nul
exit

:APIStuffNo
echo Setup successful. Press any key to exit.
pause >nul
exit
