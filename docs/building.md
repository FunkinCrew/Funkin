## Dependencies
 1. [Install Haxe 4.1.5](https://haxe.org/download/version/4.1.5/). You should use 4.1.5 instead of the latest version because the latest version has some problems with Friday Night Funkin': Kade Engine.
 2. After installing Haxe, [Install HaxeFlixel](https://haxeflixel.com/documentation/install-haxeflixel/).
 3. Install `git`.
	 - Windows: install from the [git-scm](https://git-scm.com/downloads) website.
	 - Linux: install the `git` package: `sudo apt install git` (ubuntu), `sudo pacman -S git` (arch), etc... (you probably already have it)
 4. Install and set up the necessary libraries:
	 - `haxelib install lime 7.9.0`
	 - `haxelib install openfl`
	 - `haxelib install flixel`
	 - `haxelib install flixel-tools`
	 - `haxelib install flixel-ui`
	 - `haxelib install hscript`
	 - `haxelib install flixel-addons`
	 - `haxelib install actuate`
	 - `haxelib install newgrounds`
	 - `haxelib run lime setup`
	 - `haxelib run lime setup flixel`
	 - `haxelib run flixel-tools setup`
	 - `haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit.git`
	 - `haxelib git hxvm-luajit https://github.com/nebulazorua/hxvm-luajit`
	 - `haxelib git faxe https://github.com/uhrobots/faxe`
	 - `haxelib git polymod https://github.com/MasterEric/polymod.git`
	 - `haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc`
	 - `haxelib git extension-webm https://github.com/SuperDev-funkin/extension-webm`
	 - `lime rebuild extension-webm <ie. windows, macos, linux>`
	      - Note: for Linux, you need to install the `g++-multilib` and `gcc-multilib` packages respectively. (use apt to install them.)

### Windows-only dependencies (only for building *to* Windows. Building html5 on Windows does not require this)
If you are planning to build for Windows, you also need to install **Visual Studio 2019**. FROM MICROSOFT STORE. While installing it, *don't click on any of the options to install workloads*. Instead, go to the **individual components** tab and choose the following:

-   MSVC v142 - VS 2019 C++ x64/x86 build tools
-   Windows SDK (10.0.17763.0)

This will install about 5 GB of crap, but is necessary to build for Windows.
