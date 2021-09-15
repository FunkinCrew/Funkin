# Troubleshooting

This document lists common problems alongside their solutions. If you try to post an issue about one of these, either give details on why the solution below didn't work, or prepare for [vicious mockery](https://roll20.net/compendium/dnd5e/Vicious%20Mockery#content).

If you have solved a commonly experienced issue, please feel free to expand on it here.

## Error: Source path "C:/HaxeToolkit/haxe/lib/extension-webm/git/ndll/Windows64/extension-webm.ndll" does not exist

If someone linked you to this, you were a dumbass who didn't read the **Build Documentation** properly.

Run the following lines in your command prompt:

```
haxelib git extension-webm https://github.com/KadeDev/extension-webm
lime rebuild extension-webm windows
```

## GetThreadContext failed!

As best I can tell, this issue is caused by an out-of-memory error when trying to build the game. If this error occurs, you're probably multi-tasking by running something computationally expensive in the background.

## source/WebmHandler.hx:33: characters 8-12 : webm.WebmPlayer has no field fuck

You are using an incorrect version of extension-webm. See **extension-webm.ndll** does not exist.

## Could not find haxelib "hxvm-luajit", does it need to be installed?

With Kade Engine v1.7, a new library is used to power ModCharts. You'll need to uninstall the old one and install the new one. Run the following lines in your command prompt:

```
haxelib remove linc_luajit
haxelib remove hxvm-luajit
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit.git
haxelib git hxvm-luajit https://github.com/nebulazorua/hxvm-luajit
```

## Type not found : StatePointer

See **Could not find haxelib "hxvm-luajit", does it need to be installed?**.

## ../lib/lua/src/lua.hpp: No such file or directory

This error may occur if you are building Kade Engine v1.7 on a aystem with case sensitive file system (MacOS or Linux). This is an issue with the linc_luajit and a pull request needs to be merged in order to fix it.

In the meantime, run the following lines in your command prompt to use a fork:

```
haxelib remove linc_luajit
haxelib git linc_luajit https://github.com/MasterEric/linc_luajit.git
```

## Warning: Could not find Visual Studio 2017 VsDevCmd

```
Warning: Could not find Visual Studio 2017 VsDevCmd
Missing HxCppVars
Error: Could not automatically setup MSVC
```

This error occurs if you don't have the proper Windows build dependencies installed.

See the **Windows-only dependencies section of the Build documentation**.

## Error: Cannot copy to "export/debug/windows/bin/lime.ndll", is the file in use?

This error occurs if you try to compile the game while it's running in the background. Please close the game, then try again.

## Null Object Reference

This is a coding error. It occurs when you attempt to access an attribute of a null object. Check your code and look for places where the object may not be defined.

## Null Function Reference

This is a coding error. It occurs when you attempt to call a function on an object but that function does not exist. Check your code and look for places where the object may be a different type than expected.

## Visual C++ Runtime Library: Assertion Failed!

I get this error all the time, but I haven't the foggiest what's causing it. The program will often work if you abort the program and start it again.
