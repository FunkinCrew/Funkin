# Funkin' Repo Code Style Guide

This short document is designed to give a run-down on how code should be formatted to maintain a consistent style throughout, making the repo easier to maintain.

## Notes on IDEs and Extensions

The Visual Studio Code IDE is highly recommended, as this repo contains various configurations that work with VSCode extensions to automatically style certain things for you.

VSCode is also the only IDE that has any good tools for Haxe so yeah.

## Whitespace and Indentation

The Haxe extension of VSCode will use the repo's `hxformat.json` to tell VSCode how to format the code files of the repo. Enabling VSCode's "Format on Save" feature is recommended.

## Variable and Function Names

It is recommended to name variables and functions with descriptive titles, in lowerCamelCase. There is no penalty for giving a variable a longer name as long as it isn't excessive.

## Code Comments

The CodeDox extension for VSCode provides extensive support for JavaDoc-style code comments, and these should be used for public functions wherever possible to ensure the usage of each function is clear.

Example:
```
/**
 * Finds the largest deviation from the desired time inside this VoicesGroup.
 *
 * @param targetTime	The time to check against.
 * 						If none is provided, it checks the time of all members against the first member of this VoicesGroup.
 * @return The largest deviation from the target time found.
 */
public function checkSyncError(?targetTime:Float):Float
```

## Commenting Unused Code

Do not comment out sections of code that are unused. Keep these snippets elsewhere or remove them. Older chunks of code can be retrieved by referring to the older Git commits, and having large chunks of commented code makes files longer and more confusing to navigate.

## License Headers

Do not include headers specifying code license on individual files in the repo, since the main `LICENSE.md` file covers all of them.

## Imports

Imports should be placed in a single group, in alphabetical order, at the top of the code file. The exception is conditional imports (using compile defines), which should be placed at the end of the list (and sorted alphabetically where possible).

Example:
```
import haxe.format.JsonParser;
import openfl.Assets;
import openfl.geom.Matrix;
import openfl.geom.Matrix3D;
#if sys
import funkin.io.FileUtil;
import sys.io.File;
#end
```

## Argument Formatting

[Optional arguments](https://haxe.org/manual/types-function-optional-arguments.html) and [default arguments](https://haxe.org/manual/types-function-default-values.html) should be mutually exclusive and not used together!

For example, `myFunction(?input:Int)` should be used if you want the argument to be a `Null<Int>` whose value is `null` if no value is passed, and `myFunction(input:Int = 0)` should be used if you want the argument to be an `Int`, whose value is `0` if no value is passed.

Using both at the same time is considered valid by Haxe, but `myFunction(?input:Int = 0)` results in a `Null<Int>` whose value defaults to 0 anyway, so it's never null, but it's annotated as nullable! The biggest consequence of this is that it makes null safety more annoying.
