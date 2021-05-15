# Friday Night Funkin
[![Build](https://github.com/TheDrawingCoder-Gamer/Funkin/actions/workflows/build.yml/badge.svg)](https://github.com/TheDrawingCoder-Gamer/Funkin/actions/workflows/build.yml)

This is the repository for Friday Night Funkin Modding Plus, a mod for FNF to add more features for modders and players alike.

Any mods made with this mod must have express permission from the creator of songs included. 
(for example, if you include the Whitty Mod, you should have express permission from Nate Anim8, KadeDev, and SockClip.
I at least would like to see the main author and a majority of secondary offers get express permission)
If an author gives express disapproval, and the mod is up, you should take your mod down. I own the code to this mod so I can (and will)
take down mods that don't follow this rule.


- Download on GameBanana: https://gamebanana.com/gamefiles/14264
- Get the cutting edge build: https://dev.azure.com/benharless820/FNF%20Modding%20Plus/_build
- Play the Original Game: https://github.com/ninjamuffin99/Funkin
- Need Help? FNF Modding Plus Discord: https://discord.gg/96nV4Q5HMr
- Trello Page (todo list): https://trello.com/b/cFjJJIjF/fnf-modding-plus
## Credits for the Original Game

- [ninjamuffin99](https://twitter.com/ninja_muffin99) - Programmer
- [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
- [KawaiSprite](https://twitter.com/kawaisprite) - Musician
## Modding+ Credits

- [BulbyVR](https://gamebanana.com/members/1776425) - Owner/Programmer
- [DJ Popsicle](https://gamebanana.com/members/1780306) - Co-Owner/Coding
- [Matheus L/Mlops](https://gamebanana.com/members/1767306) and [AndreDoodles](https://gamebanana.com/members/1764840) - Artist for the Poison Icons

This game was made with love to Newgrounds and it's community. Extra love to Tom Fulp.

## Build instructions

THESE INSTRUCTIONS ARE FOR COMPILING THE GAME'S SOURCE CODE!!!

IF YOU WANT TO JUST DOWNLOAD AND INSTALL AND PLAY THE GAME NORMALLY, GO TO GAMEBANANA TO DOWNLOAD THE GAME FOR PC!!

https://gamebanana.com/gamefiles/14264

IF YOU WANT TO COMPILE THE GAME YOURSELF, OR PLAY ON MAC OR LINUX, CONTINUE READING!!!

IF YOU MAKE A MOD AND DISTRIBUTE A MODIFIED / RECOMIPLED VERSION, YOU MUST OPEN SOURCE YOUR MOD AS WELL

### Installing shit

First you need to install Haxe and HaxeFlixel. I'm too lazy to write and keep updated with that setup (which is pretty simple).
The link to that is on the [HaxeFlixel website](https://haxeflixel.com/documentation/getting-started/)

Other installations you'd need is the additional libraries, a fully updated list will be in `Project.xml` in the project root, but here are the one's I'm using as of writing.

```
hscript
flixel-ui
tjson
json2object
uniontypes
hxcpp-debug-server
```

So for each of those type `haxelib install [library]` so shit like `haxelib install hscript`

You'll also need to install hscript-ex. Do this with

```
haxelib git hscript-ex https://github.com/ianharrigan/hscript-ex
```


### Compiling game


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
