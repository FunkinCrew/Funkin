@echo off
color 0a
cd ..
echo update the latest Haxe ( https://haxe.org/download/ ) and Git ( https://git-scm.com/downloads ). After that, press the Enter key.
pause
@echo on
haxelib update lime
haxelib update openfl
haxelib update flixel
haxelib run lime setup flixel
haxelib run lime setup
haxelib update flixel-tools
haxelib run flixel-tools setup
haxelib update flixel-addons
haxelib update flixel-ui
haxelib update hscript
haxelib update hxCodec
haxelib update hxcpp-debug-server
haxelib git polymod https://github.com/larsiusprime/polymod.git
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons
@echo off
echo Update Successful!
pause