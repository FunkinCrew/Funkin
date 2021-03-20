![KadeEngineLogo](https://user-images.githubusercontent.com/26305836/110529589-4b4eb600-80ce-11eb-9c44-e899118b0bf0.png)

**Download the latest release [here](https://github.com/KadeDev/Kade-Engine/releases/latest)**

![image](https://user-images.githubusercontent.com/26305836/110532077-3c1d3780-80d1-11eb-8348-0e63d5c0f4f1.png)

![image](https://user-images.githubusercontent.com/26305836/110532103-450e0900-80d1-11eb-857e-d8ea1a1b8d7e.png)

![image](https://user-images.githubusercontent.com/26305836/110532136-51926180-80d1-11eb-838f-1b4a1e49e1bd.png)

![image](https://user-images.githubusercontent.com/26305836/110532204-63740480-80d1-11eb-9641-bf5a641e6d77.png)


# Friday Night Funkin Kade Engine

This is the repository for Friday Night Funkin' Kade Engine, a game originally made for Ludum Dare 47 "Stuck In a Loop". And a completely reworked engine.

Play the Ludum Dare prototype here: https://ninja-muffin24.itch.io/friday-night-funkin
Play the Newgrounds one here: https://www.newgrounds.com/portal/view/770371
Support the project on the itch.io page: https://ninja-muffin24.itch.io/funkin

Mod Page: https://gamebanana.com/gamefiles/16761
	
## What is Kade Engine?

Kade Engine is an engine rework of the OG games engine. Simply put, we give you some great new features while also giving you the latest GitHub features.

## Features

The features that Kade Engine implements are:
- New Input System

*Hate the old engine because your inputs are delayed? Are inputs being dropped? Well with this input system, inputs rarely get dropped! If you wanna see an example of what it feels like, play any 4k rhythm game like Quaver or Etterna!*

- Accuracy Mod

*We've modified the accuracy mod to create an amazing accuracy display, which shows your accuracy and misses. While giving you a basic ranking on how you are currently playing.*

- FPS Increase

*We always love more FPS, and this is what you'll get. We've increased the FPS cap to 120.*

- DFJK Support

*As standard 4k practice, the default keybinds for many rhythm games are DFJK. We've allowed you to swap from WASD to DFJK in the options menu now.*

- Replays

*Ever wanted to show your friend a crazy score? Well, the replay system lets you do that without recording videos!*

**please note the replay system is in beta, and is not 100% accurate YET*

- Offset

*Do your headphones have an audio delay? Well, you can set a note offset in the options menu!*

- Latest FNF Github Features

*Have you ever seen a feature shown in the GitHub repo, and you don't know how to build the game? Well, features from there get ported into here, and then we can add them into this mod and build it for you!*

**HUGE NOTICE**

This is a **MOD**. This is not Vanilla and should be treated as a **MODIFICATION**. This will probably never be official, so don't get confused.

## Credits / shoutouts

- [ninjamuffin99 (me!)](https://twitter.com/ninja_muffin99) - Programmer
- [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
- [Kawaisprite](https://twitter.com/kawaisprite) - Musician

This game was made with love to Newgrounds and it's community. Extra love to Tom Fulp.

## Build instructions

THESE INSTRUCTIONS ARE FOR COMPILING THE GAME'S SOURCE CODE!!!

IF YOU WANT TO JUST DOWNLOAD AND INSTALL AND PLAY THE GAME NORMALLY, GO TO ITCH.IO TO DOWNLOAD THE GAME FOR PC, MAC, AND LINUX!!

https://ninja-muffin24.itch.io/friday-night-funkin

IF YOU WANT TO COMPILE THE GAME YOURSELF, CONTINUE READING!!!

### Installing the Required Programs

First you need to install Haxe and HaxeFlixel. I'm too lazy to write and keep updated with that setup (which is pretty simple). 
1. [Install Haxe 4.1.5](https://haxe.org/download/version/4.1.5/) (Download 4.1.5 instead of 4.2.0 because 4.2.0 is broken and is not working with gits properly...)
2. [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/) after downloading Haxe

Other installations you'd need is the additional libraries, a fully updated list will be in `Project.xml` in the project root. Currently, these are all of the things you need to install:
```
flixel
flixel-addons
flixel-ui
hscript
newgrounds
```
So for each of those type `haxelib install [library]` so shit like `haxelib install newgrounds`

You'll also need to install polymod. To do this, you need to do a few things first.
1. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
2. Follow instructions to install the application properly.
3. Run `haxelib git polymod https://github.com/larsiusprime/polymod.git` in terminal/command-prompt after your git program is installed.

You should have everything ready for compiling the game! Follow the guide below to continue!

At the moment, you can optionally fix the transition bug in songs with zoomed out cameras.
- Run `haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons` in the terminal/command-prompt.

### Ignored files

I gitignore the API keys for the game, so that no one can nab them and post fake highscores on the leaderboards. But because of that the game
doesn't compile without it.

Just make a file in `/source` and call it `APIStuff.hx`, and copy paste this into it

```haxe
package;

class APIStuff
{
	public static var API:String = "";
	public static var EncKey:String = "";
}

```

and you should be good to go there.

### Compiling game

Once you have all those installed, it's pretty easy to compile the game. You just need to run 'lime test html5 -debug' in the root of the project to build and run the HTML5 version. (command prompt navigation guide can be found here: [https://ninjamuffin99.newgrounds.com/news/post/1090480](https://ninjamuffin99.newgrounds.com/news/post/1090480))

To run it from your desktop (Windows, Mac, Linux) it can be a bit more involved. For Linux, you only need to open a terminal in the project directory and run 'lime test linux -debug' and then run the executible file in export/release/linux/bin. For Windows, you need to install Visual Studio Community 2019. While installing VSC, don't click on any of the options to install workloads. Instead, go to the individual components tab and choose the following:
* MSVC v142 - VS 2019 C++ x64/x86 build tools
* Windows SDK (10.0.17763.0)
* C++ Profiling tools
* C++ CMake tools for windows
* C++ ATL for v142 build tools (x86 & x64)
* C++ MFC for v142 build tools (x86 & x64)
* C++/CLI support for v142 build tools (14.21)
* C++ Modules for v142 build tools (x64/x86)
* Clang Compiler for Windows
* Windows 10 SDK (10.0.17134.0)
* Windows 10 SDK (10.0.16299.0)
* MSVC v141 - VS 2017 C++ x64/x86 build tools
* MSVC v140 - VS 2015 C++ build tools (v14.00)

This will install about 22GB of crap, but once that is done you can open up a command line in the project's directory and run `lime test windows -debug`. Once that command finishes (it takes forever even on a higher end PC), you can run FNF from the .exe file under export\release\windows\bin
As for Mac, 'lime test mac -debug' should work, if not the internet surely has a guide on how to compile Haxe stuff for Mac.

### Additional guides

- [Command line basics](https://ninjamuffin99.newgrounds.com/news/post/1090480)
