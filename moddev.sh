#Update & install
sudo apt update && sudo apt upgrade -y

#Haxe
sudo add-apt-repository ppa:haxe/releases -y && sudo apt install haxe -y && mkdir ~/haxelib && haxelib setup ~/haxelib

#MoreHaxe (Flixel)
haxelib setup && haxelib install lime && haxelib install flixel && haxelib install openfl && haxelib run lime setup -y

#Setup
haxelib install flixel && haxelib install flixel-addons && haxelib install flixel-ui && haxelib install hscript && haxelib install newgrounds

#PolyMod & Discord RPC
haxelib git polymod https://github.com/larsiusprime/polymod.git && haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc

#apistuff (new folder in /source and call it APIStuff.hx) Remove #'s.

#package;

#class APIStuff
##{
#	public static var API:String = "";
#	public static var EncKey:String = "";
#}

#Compile & Run
lime test html5 -debug
