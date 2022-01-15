@echo off
title FNF Setup - Start
echo Make sure Haxe 4.1.5 and HaxeFlixel is installed (4.1.5 is important)!
echo Press any key to install required libraries.
pause >nul
title FNF Setup - Installing libraries
echo Installing haxelib libraries...
haxelib install lime 7.8.0
haxelib install openfl
haxelib install flixel 4.8.1
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install hscript
haxelib install newgrounds
haxelib run lime setup
haxelib install flixel-tools
title FNF Setup - User action required
cls
haxelib run flixel-tools setup
cls
echo Make sure you have git installed. You can download it here: https://git-scm.com/downloads
echo Press any key to install polymod.
pause >nul
title FNF Setup - Installing libraries
haxelib git polymod https://github.com/larsiusprime/polymod.git
cls
echo Press any key to install discord rpc.
pause >nul
title FNF Setup - Installing libraries
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
cls
goto UserActions1

:UserActions1
title FNF Setup - User action required
set /p menu="Would you like to fix the transition bug? [Y/N]"
       if %menu%==Y goto FixTransitionBug
       if %menu%==y goto FixTransitionBug
       if %menu%==N goto UserActions2
       if %menu%==n goto UserActions2
       cls

:UserActions2
cls
title FNF Setup - User action required
set /p menu2="Would you like to automatically make the APIStuff file? [Y/N]"
       if %menu2%==Y goto APIStuffYes
       if %menu2%==y goto APIStuffYes
       if %menu2%==N goto APIStuffNo
       if %menu2%==n goto APIStuffNo
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
goto APIStuffNo


:APIStuffNo
cls
title FNF Setup - User action required
set /p menu="Would you like to install Visual Studio Community and components? (Necessary to compile/ 5.5GB) [Y/N]"
       if %menu%==Y goto InstallVSCommunity
       if %menu%==y goto InstallVSCommunity
       if %menu%==N goto SkipVSCommunity
       if %menu%==n goto SkipVSCommunity
       cls


:SkipVSCommunity
cls
title FNF Setup - Success
echo Setup successful. Press any key to exit.
pause >nul
exit

:FixTransitionBug
title FNF Setup - Installing libraries
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons
goto UserActions2

:InstallVSCommunity
title FNF Setup - Installing Visual Studio Community
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
del vs_Community.exe
goto SkipVSCommunity
