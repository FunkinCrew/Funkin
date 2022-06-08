package engine.base;

import openfl.media.Sound;
import haxe.Json;
import sys.io.File;
import sys.FileSystem;

using StringTools;

/**
 * Raw modding API. It's recommended to use the Modding class instead as it acts as a wrapper to make things easier.
 * 
 * ### FOR ADVANCED USERS ONLY
 * @since 1.3.0-SC542
 */
class ModAPI
{
    /**
     * List of currently loaded mods.
     * @since 1.3.0-SC542
     */
    public var loaded:Array<Mod>;

    public function new()
    {
        loaded = new Array<Mod>();
    }

    public function init(modFolderPath:String)
    {
        for (file in FileSystem.readDirectory(modFolderPath))
        {
            trace("Inspecting file: " + modFolderPath + file);
            if (FileSystem.isDirectory(modFolderPath + file))
            {
                trace("Found mod folder: " + file);
                if (file.startsWith("SM."))
                {
                    trace("found mod: " + file);
                    loaded.push({
                        name: file.split("SM.")[1],
                        path: modFolderPath + file
                    });
                }
            }
        }
        trace("Found " + loaded.length + " mod(s).");
    }

    public function initWeeks():Array<Weeks>
    {
        var weeks:Array<Weeks> = [];
        for (mod in loaded)
        {
            var rawJson = File.getContent(mod.path + "/weeks.json");
            trace("Parsing weeks.json for mod: " + mod.name);
            var week:Weeks = Json.parse(rawJson);
            week.mod = mod.name;
            weeks.push(week);
        }
        return weeks;
    }

    /**
     * Gets a text file from a mod.
     * @param path the path to the file
     * @param mod the mod to get it from. if `null`, it will loop over all mods and get the first occurance of the file.
     * @return String
     */
    public function getTextShit(path:String, ?mod:Mod):String
    {
        trace("looking for text file: " + path);
        var shit = "";
        if (mod != null)
        {
            trace("getting the path: " + mod.path + path);
            shit = File.getContent(mod.path + path);
        }
        else 
        {
            for (mod in loaded)
            {
                trace("scanning mod: " + mod.name);
                if (FileSystem.exists(mod.path + path))
                {
                    trace("getting the path: " + mod.path + path);
                    shit = File.getContent(mod.path + path);
                    break;
                }
            }
        }
        trace("Final shit: " + shit);
        return shit;
    }

    public function getSoundShit(path:String, ?mod:Mod):Sound
    {
        trace("looking for sound file: " + path);
        var shit:Sound = null;
        if (mod != null)
        {
            trace("getting the path: " + mod.path + path);
            shit = Sound.fromFile(mod.path + path);
        }
        else 
        {
            for (mod in loaded)
            {
                trace("scanning mod: " + mod.name);
                if (FileSystem.exists(mod.path + path))
                {
                    trace("getting the path: " + mod.path + path);
                    shit = Sound.fromFile(mod.path + path);
                    break;
                }
            }
        }
        return shit;
    }
}

typedef Mod = 
{
    name:String,
    path:String,
}

typedef Weeks =
{
    mod:String,
    weeks:Array<Week>,
}

typedef Week =
{
    name:String,
    graphic:String,
    songs:Array<String>
}