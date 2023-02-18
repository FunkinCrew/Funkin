# Friday Night Funkin'
> Uh oh! Your tryin to kiss ur hot girlfriend, but her MEAN and EVIL dad is trying to KILL you! He's an ex-rockstar, the only way to get to his heart? The power of music...

[Github](https://github.com/FunkinCrew/Funkin) | [itch.io](https://ninja-muffin24.itch.io/funkin) | [newgrounds](https://www.newgrounds.com/portal/view/770371)  

IF YOU MAKE A MOD AND DISTRIBUTE A MODIFIED / RECOMPILED VERSION, YOU MUST OPEN SOURCE YOUR MOD AS WELL
# Friday Night Funkin': nekoEngine2
#### This engine includes the following features.
* neko Input
* Haxe 4.2.5 and Flixel 5.x.x Support
#### Here are the features we plan to add in the future.
* Options Menu
* Key Config
# Build Of nekoEngine2
Please stop using Haxe 4.1.5 and use [the latest Haxe.](https://haxe.org/download/)  
Then execute this command.
```
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
```
Next, [install Git.](https://git-scm.com/downloads)  
Then, execute this command.
```
haxelib git polymod https://github.com/larsiusprime/polymod.git
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
```
At the moment, you can optionally fix the transition bug in songs with zoomed-out cameras.
<<<<<<< HEAD
=======
- Run `haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons` in the terminal/command-prompt.

### Ignored files

I gitignore the API keys for the game so that no one can nab them and post fake high scores on the leaderboards. But because of that the game
doesn't compile without it.

Just make a file in `/source` and call it `APIStuff.hx`, and copy & paste this into it

```haxe
package;

class APIStuff
{
	inline public static var API:String = "51348:TtzK0rZ8";
	inline public static var EncKey:String = "5NqKsSVSNKHbF9fPgZPqPg==";
	inline public static var SESSION:String = null;
}

>>>>>>> 65310c965b34ee16588e03d012c3d5be4c6a1679
```
haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons
```
Run build-Itch-WINDOWS.bat in /art/ and build.
# Credits
## Friday Night Funkin': neko Engine2
* nennneko5787 - Programmer
## Funkin
* ninjamuffin99 - Programmer
* PhantomArcade3K and Evilsk8r - Art
* Kawaisprite - Musician