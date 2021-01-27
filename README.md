# Friday Night Funkin'
This is the repository for Friday Night Funkin, a game originally made for Ludum Dare 47 "Stuck In a Loop".

Play the Ludum Dare prototype here: https://ninja-muffin24.itch.io/friday-night-funkin
Play the Newgrounds one here: https://www.newgrounds.com/portal/view/770371
Support the project on the itch.io page: https://ninja-muffin24.itch.io/funkin

## Credits / shoutouts
- [ninjamuffin99 (me!)](https://twitter.com/ninja_muffin99) - Programmer
- [PhantomArcade3K](https://twitter.com/phantomarcade3k) and [Evilsk8r](https://twitter.com/evilsk8r) - Art
- [Kawaisprite](https://twitter.com/kawaisprite) and [Bassetfilms](https://twitter.com/Bassetfilms) - Musician

This game was made with love to Newgrounds and it's community. Extra love to Tom Fulp.

## Build instructions
### Installing shit
First you need to install Haxe and HaxeFlixel. I'm too lazy to write and keep updated with that setup (which is pretty simple).

The link to that is on the [HaxeFlixel website](https://haxeflixel.com/documentation/getting-started/).

That should give you HaxeFlixel and all of it's setup and shit. If you run into issues, ask them in the #flixel channel in the [Haxe Discord server](https://discord.gg/5ybrNNWx9S).

Other installations you'd need is the additional libraries, a fully updated list will be in `Project.xml` in the project root, but here are the one's I'm using as of writing.

Run each command to install the libary.

```
haxelib install hscript
haxelib install flixel-ui
haxelib install newgrounds
haxelib git polymod https://github.com/larsiusprime/polymod.git
```

### Ignored files
I gitignore the API keys for the game, so that no one can nab them and post fake highscores on the leaderboards. But, the game requires the file to complie.

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
Once you have all those installed, it's pretty easy to compile the game. 

#### HTML5
For `HTML5`, You just need to run the command in the root of the project to build and run the `HTML5` version.

```sh
lime test html5 -debug
```

#### Windows
To run it from your desktop on Windows, it can be a bit more involved. You'll need to install Visual Studio Community 2019 components using the Video Studio Installer.

You can grab the installer from Microsft [here](https://visualstudio.microsoft.com/vs/community/).

##### Automatically Installing Components
1. Download the [.vsconfig](https://github.com/ninjamuffin99/Funkin/blob/master/.vsconfig) file at the root of this repo.
2. Click "More ▼" next to Visual Studio Community 2019.
3. Click "Import configuration."
4. Navigate to the `.vsconfig` file.
5. Click "Review details."
6. Click "Install."
7. Click "Continue."

##### Manually Installing Components
1. Click "Install" next to Visual Studio Community 2019.
2. Click "Individual components," then select each of the components below.
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
3. Click "Install."
4. Click "Continue."

It's going to take a while to install 23GB of applications. Hope you like waiting!

After installing the required components, but once that is done you can open up a command line in the project's directory and run the command below.

```sh
lime test windows -debug
```

Once that command finishes (it takes forever even on a higher end PC), you can run FNF from the `.exe` file under `export\release\windows\bin`. FNF also needs it's assets to run, so don't delete those.

#### Linux
For Linux, you only need to open a terminal in the project directory and run ```lime test linux -debug``` and then run the executible file in export/release/linux/bin. For Windows, 

#### Mac
// TODO: build it on a mac

### Additional guides
* New to the command line? Read [this short guide on command line basics](https://ninjamuffin99.newgrounds.com/news/post/1090480).
