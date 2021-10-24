# How do mods work?

ModCore makes it easy to append, replace, or merge files without editing the game's code.

Kade Engine's ModCore is powered by [Polymod](https://github.com/larsiusprime/polymod). Polymod is what handles loading the relevant assets, ensuring they are injected properly. It also handles ensuring mods are loaded in the proper order.

Example mod created by [Master Eric](https://twitter.com/EliteMasterEric) > [here](https://github.com/EnigmaEngine/ModCore-Tricky-Mod) <

## Using mods

To install a mod, place the folder inside the `mods` folder. To disable or uninstall a mod, take it out of the folder.

One day, we'll probably have a modloader that lets you control what order mods are loaded in.

## Metadata

You will want several pieces of metadata in order for Polymod to identify and display your mod. Note that only one of these is mandatory.

* _polymod_meta.json
  * This file tells Polymod all about your mod, such as name and description. This file is **MANDATORY**.
  * Learn more about how to write this file below.
* _polymod_icon.png
  * This icon will be used by mod browsers in the future. Make sure to provide one, 256x256 should be pretty good.
* LICENSE.txt
  * This is the general sofware license used by the mod. Without a license, your mod is under All Rights Reserved.
* ASSET_LICENSE.txt
  * This is the license specifically for the mod's assets.
  * Creative Commons is recommended.
* CODE_LICENSE.txt (for code/script-specific licensing terms.
  * GPLv3, Apache, or MIT are recommended.
* _polymod_pack.txt
  * Used for modpacks.

### _polymod_meta.json

Here is an example of a valid mod metadata file.

Note that both `api_version` and `mod_version` should use valid [Semantic Versioning 2.0.0](https://semver.org/) values.

```
{
	"title":"Daisy",
	"description":"This mod has a daisy",
	"author":"Lars A. Doucet",
	"api_version":"0.1.0",
	"mod_version":"1.0.0-alpha",
	"license":"CC BY 4.0,MIT"
}
```

## Assets

### Replacing

Asset replacements are simple; just place the assets in the relevant subfolder.

Here's what the mod folder might look like for a simple "XXX over Boyfriend" mod.

```
<modRoot> (name this anything)
|- _polymod_meta.json
|- images
  |- characters
    |- BOYFRIEND.xml
    |- BOYFRIEND.png
```

By the way, 

### Appending

Appending to assets is only slightly more involved. Appending is used when you want to add to the end of a particular text file without getting rid of what's already there.

For example, using replacement on `introText.txt` will get rid of the base game's intro text values, as well as any that other mods may have added. This may or may not be what you want. Appending will put your values at the end of the file for other mods to add to.

To perfrom asset appending, place the assets in the relevant subfolder under the `_append` folder, like so. Note the underscore before it.

```
<modRoot> (name this anything)
|- _polymod_meta.json
|- _append
  |- data
    |- introText.txt
```

### Merging

Merging is the most convoluted. Use it only if you can't use replacement or appending.

Merging locates a given key in a file and replaces it with the intended value.

* For `CSV` and `TSV` files, the value in the first column is assumed to be the ID. Each ID in the merge CSV is located in the base CSV, and that row is replaced with the row from the merge CSV.
* For `LINES` text files, Polymod will check 
* For `PLAINTEXT` text files, Polymod will throw a warning that merging is not supported.
* For `XML` files, you need to add a child key called `merge` which specifies the key and value to match on. All other values will be replaced. [See here for more info](https://github.com/larsiusprime/polymod#_merge-folder).
* For `JSON` files, create a single top-level array named `merge`. Each element is an object with two keys: A key `target` like `abc.d[3].e`, and a value `payload`.

## Modpacks

If you have a mod with several parts that you want people to be able to install separately, the best way to do that is to make them separate mods, then make a modpack. This is an empty mod containing only a file defining the other mods that the game should load.

To create a modpack, make a mod containing a `_polymod_pack.txt` file with the following text:

```
foo:1.0.0,bar:1.*.*,abc,xyz
```

ModCore will search for, and load, the mods with the IDs `foo`, `bar`, `abc`, and `xyz`, in that order. It will fail any mods that fail the version check (`foo` must be exactly `1.0.0` while `bar` allows any `1.x` version) and only load the mods which don't fail.

## Scripts

Coming soon...
