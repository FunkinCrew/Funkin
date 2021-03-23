# Friday Night Funkin!

![FNF_Logo](https://user-images.githubusercontent.com/72235309/112068307-08fe8d80-8b40-11eb-84d0-fc64a10dd845.png "FNF Logo")

### This is the repository for Friday Night Funkin, a game originally made for Ludum Dare 47 "Stuck In a Loop".

Play the Ludum Dare prototype [here](https://ninja-muffin24.itch.io/friday-night-funkin)!

Play the Newgrounds one [here](https://www.newgrounds.com/portal/view/770371)!

Support the project on the [Itch.io page](https://ninja-muffin24.itch.io/funkin)!

## Credits / Shoutouts
### Programmers:
💻 [ninjamuffin99 (me!)](https://twitter.com/ninja_muffin99) 

### Artists:
🎨 [PhantomArcade3K](https://twitter.com/phantomarcade3k)

🎨 [Evilsk8r](https://twitter.com/evilsk8r)

### Musicians:
🎶 [Kawaisprite](https://twitter.com/kawaisprite)

### Special Thanks 💖

This game was made with love to Newgrounds and it's community. Extra love to Tom Fulp. 💖

![newgrounds_logo](https://user-images.githubusercontent.com/72235309/112079926-681bcc80-8b57-11eb-9249-989b37c8fad3.png)

## What can I do with compiling the game? Why should I compile the game instead of downloading it from [the Itch.io page of the game](https://ninja-muffin24.itch.io/friday-night-funkin)?

Compiling the game gives access to the `/source` folder, allowing you to change the code of the game. You can add a lot of cool things with the open source code!

I recommend having a good idea on how to program. Compiling the game isn't for everyone!

If you just want to download and play the game normally, you can click [here to go to the Itch.io page of the game](https://ninja-muffin24.itch.io/friday-night-funkin)

### **If you do want to compile, continue reading!**

# Installing the Required Programs

![haxe-logo-white-background](https://user-images.githubusercontent.com/72235309/112079978-81247d80-8b57-11eb-8735-bea15b9f4658.png)

First you need to install Haxe and HaxeFlixel.
1. [Install Haxe 4.1.5](https://haxe.org/download/version/4.1.5/) (Download 4.1.5 instead of 4.2.0 because 4.2.0 is broken and is not working with gits properly...)
2. [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/) after downloading Haxe

Other installations you'd need is the additional libraries. A fully updated list will be in `Project.xml` in the project root. Currently, these are all of the things you need to install:
```
flixel
flixel-addons
flixel-ui
hscript
newgrounds
```
So for each of those type `haxelib install [library]` so shit like `haxelib install newgrounds`

You'll also need to install a couple things that involve Gits. To do this, you need to do a few things first.
1. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
2. Follow instructions to install the application properly.
3. Run `haxelib git polymod https://github.com/larsiusprime/polymod.git` to install Polymod.
4. Run `haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc` to install Discord RPC.
5. Optional: - Run `haxelib git flixel-addons https://github.com/HaxeFlixel/flixel-addons` to update Flixel-Addons. This fixes the transition bug for zoomed out stage cameras.

You should have everything ready for compiling the game! Follow the guide below to continue!

# Adding `APIStuff.hx` into `/source`

![APIStuff.hx_picture](https://user-images.githubusercontent.com/72235309/112080256-00b24c80-8b58-11eb-9499-524bf45a00eb.png)

The creator gitignored the API keys of the game so no one could post fake high scores onto the leaderboards in Newgrounds. Unfortunatly, because this game requires the `API` and `EncKey` values to compile, you will need to add a file called `APIStuff.hx` into `/source`. How do I do that?

1. Create a new text file called `APIStuff.hx` inside of the `/source` folder.
2. Copy the following text:
```haxe
package;
class APIStuff
{
	public static var API:String = "";
	public static var EncKey:String = "";
}
```
3. Paste the text into the APIStuff.hx file and save the file.

You should be good from there! Now, onto compiling!

# Compiling the Game

## HTML Building:

Compiling the game is rather simple for HTML5 builds.
1. Open your machine's command prompt/terminal and navigate to your root folder of the game. [An easy guide can be found here!](https://ninjamuffin99.newgrounds.com/news/post/1090480)
2. Type `lime build html5` to build the HTML5 version of the game.
3. Type `lime run html5` to run the HTML5 version of the game from the command prompt/terminal. (You can also run the game from `funkin/export/release/html5/bin`)

You should be all good to play the HTML5 version of the game!

## Desktop Building:

Desktop building can be a bit tedious. Each different version requires a different setup.

### Linux Building:

1. Open your machine's command prompt/terminal and navigate to your root folder of the game. [An easy guide can be found here!](https://ninjamuffin99.newgrounds.com/news/post/1090480)
2. Type `lime build linux` to build the Linux version of the game.
3. Type `lime run linux` to run the Linux version of the game from the command prompt/terminal. (You can also run the game from `funkin/export/release/linux/bin`)

### Mac Building:

1. Open your machine's command prompt/terminal and navigate to your root folder of the game. [An easy guide can be found here!](https://ninjamuffin99.newgrounds.com/news/post/1090480)
2. Type `lime build mac` to build the Mac version of the game.
3. Type `lime run mac` to run the Mac version of the game from the command prompt/terminal. (You can also run the game from `funkin/export/release/mac/bin`)

### Windows Building:
**THIS METHOD REQUIRES AROUND 22 GIGABYTES OF STORAGE.**
1. Install [Visual Studio Community 2019](https://visualstudio.microsoft.com/downloads/).
2. Open the installer and go to the individual workloads tab and download the following:
```
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
```
3. Wait for the install to finish, which might take a while.
4. Open your machine's command prompt/terminal and navigate to your root folder of the game. [An easy guide can be found here!](https://ninjamuffin99.newgrounds.com/news/post/1090480)
5. Once everything is installed, type `lime build windows` to build the windows version of the game.
6. Type `lime run windows` after the game is compiled to run the windows version of the game. (You can also run the game from `funkin/export/release/windows/bin`)

# All done!
You should have been able to compile the whole game now! What can you do now? Well, you can mod to your heart's desire! Since this game is open source, the creator loves seeing what other tallented artists and programmers can make!

Special thanks to the amazing group of dedicated people that are making this game amazing!

💖💖
