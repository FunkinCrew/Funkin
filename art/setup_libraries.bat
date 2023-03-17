@echo off
color 0a
cd ..
echo Install the latest Haxe ( https://haxe.org/download/ ) and Git ( https://git-scm.com/downloads ). After that, press the Enter key.
pause
@echo on
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib run lime setup flixel
haxelib run lime setup
haxelib install flixel-tools
haxelib run flixel-tools setup
haxelib install flixel-addons
haxelib install flixel-ui
haxelib install hscript
haxelib install newgrounds 1.1.5
haxelib install hxCodec
haxelib install hxcpp-debug-server
haxelib git polymod https://github.com/larsiusprime/polymod.git
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons
@echo off
echo Setup Successful!
pause