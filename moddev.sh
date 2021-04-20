#Update & install
sudo apt update && sudo apt upgrade -y

#Haxe
sudo add-apt-repository ppa:haxe/releases -y && sudo apt install haxe -y && mkdir ~/haxelib && haxelib setup ~/haxelib

#Haxeflixel
haxelib install lime && haxelib install flixel && haxelib install openfl && haxelib run lime setup

#Setup
haxelib install flixel-addons && haxelib install flixel-ui && haxelib install hscript && haxelib install newgrounds

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
lime test html5 -debug
