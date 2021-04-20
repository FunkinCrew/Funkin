#One liner:
sudo add-apt-repository ppa:haxe/releases -y && sudo apt install haxe -y && mkdir ~/haxelib && haxelib setup ~/haxelib && haxelib install lime && haxelib install flixel && haxelib install openfl && haxelib run lime setup && haxelib install flixel-addons && haxelib install flixel-ui && haxelib install hscript && haxelib install newgrounds && haxelib git polymod https://github.com/larsiusprime/polymod.git && haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc && haxelib run lime setup flixel

#Update & Upgrade
sudo apt update && sudo apt upgrade -y

#Haxe
sudo add-apt-repository ppa:haxe/releases -y && sudo apt install haxe -y && mkdir ~/haxelib && haxelib setup ~/haxelib

#Haxeflixel
haxelib install lime && haxelib install flixel && haxelib install openfl && haxelib run lime setup

#Setup
haxelib install flixel-addons && haxelib install flixel-ui && haxelib install hscript && haxelib install newgrounds && haxelib run lime setup flixel

#PolyMod & Discord RPC
haxelib git polymod https://github.com/larsiusprime/polymod.git && haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc

#apistuff
#/source and call it APIStuff.hx
#package;

#class APIStuff
##{
#	public static var API:String = "";
#	public static var EncKey:String = "";
#}


#Compile & Run
# Refer to https://github.com/ninjamuffin99/Funkin/blob/a97a6c206deffee9751a4f628465763d39cddb39/README.md for detailed instructions.
