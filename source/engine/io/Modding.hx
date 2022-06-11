package engine.io;

import sys.io.File;
import openfl.display.BitmapData;
import lime.app.Application;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.media.Sound;
import sys.FileSystem;
import engine.base.ModAPI;

/**
 * Contains helper functions for modding. Also contains a global wrapper of the `ModAPI` class.
 */
class Modding
{
    /**
     * Global wrapper for the `ModAPI` class.
     */
    public static var api:ModAPI;

    /**
     * Weeks of the mods
     */
    public static var weeks:Array<engine.base.ModAPI.Weeks>;

    /**
     * Initializes the modding API.
     */
    public static function init()
    {
        api = new ModAPI();
        api.init("./mods/");
        weeks = api.initWeeks();
    }

    /**
     * Finds a mod by its name. Returns null if not found.
     * @param name the name of the mod
     * @return engine.base.ModAPI.Mod
     */
    public static function findModOfName(name:String):engine.base.ModAPI.Mod
    {
        trace("Looking for mod of name: " + name);
        for (mod in api.loaded)
        {
            if (mod.name == name)
            {
                trace("Found mod: " + mod.name);
                return mod;
            }
        }
        return null;
    }

    /**
     * Seeks for an asset.
     * 
     * Looks through normal assets first, then through the mods.
     * 
     * Doesn't obey the `libInclude` week attribute.
     * @param key the song to look for
     * @param mod the specific mod to look in, if null the first occurance is returned
     * @return the asset, null if not found
     */
    public static function getInst(key:String, ?mod:Mod):Sound
    {
        trace("./assets/songs/" + key.toLowerCase() + "/Inst." + Paths.SOUND_EXT + "=>" + FileSystem.exists("./assets/songs/" + key.toLowerCase() + "/Inst." + Paths.SOUND_EXT));
        if (FileSystem.exists("./assets/songs/" + key.toLowerCase() + "/Inst." + Paths.SOUND_EXT))
        {
            trace("Found file in normal assets: " + key.toLowerCase());
            return Sound.fromFile("./assets/songs/" + key.toLowerCase() + "/Inst." + Paths.SOUND_EXT);
        }
        else
        {
            trace("Looking for file in mods: " + key);
            return api.getSoundShit("/songs/" + key + "/Inst." + Paths.SOUND_EXT, mod);
        }
    }

    /**
     * Seeks for an asset.
     * 
     * Looks through normal assets first, then through the mods.
     * 
     * Doesn't obey the `libInclude` week attribute.
     * @param key the song to look for
     * @param mod the specific mod to look in, if null the first occurance is returned
     * @return the asset, null if not found
     */
    public static function getVoices(key:String, ?mod:Mod):Sound
    {
        
        trace("./assets/songs/" + key.toLowerCase() + "/Voices." + Paths.SOUND_EXT + "=>" + FileSystem.exists("./assets/songs/" + key.toLowerCase() + "/Voices." + Paths.SOUND_EXT));
        if (FileSystem.exists("./assets/songs/" + key.toLowerCase() + "/Voices." + Paths.SOUND_EXT))
        {
            trace("Found file in normal assets: " + key.toLowerCase());
            return Sound.fromFile("./assets/songs/" + key.toLowerCase() + "/Voices." + Paths.SOUND_EXT);
        }
        else
        {
            trace("Looking for file in mods: " + key);
            return api.getSoundShit("/songs/" + key + "/Voices." + Paths.SOUND_EXT, mod);
        }
    }

    /**
     * Seeks for an asset.
     * 
     * Looks through normal assets first, then through the mods.
     * 
     * Obeys the `libInclude` week attribute.
     * @param key 
     * @param mod 
     * @return FlxAtlasFrames
     */
    public static function getSparrow(key:String, ?seekIn:Array<String>, ?mod:Mod):FlxAtlasFrames
    {
        trace("GETTING SPARROW: " + key);

        if (FileSystem.exists("./assets/images/" + key + ".png"))
        {
            trace("Found file in preload: " + key);
            return Paths.getSparrowAtlas(key, 'preload');
        }

        if (FileSystem.exists("./assets/shared/images/" + key + ".png"))
        {
            trace("Found file in shared: " + key);
            return Paths.getSparrowAtlas(key, 'shared');
        }

        for (weeksT in weeks)
        {
            for (week in weeksT.weeks)
            {
                for (included in week.libInclude)
                {
                    trace("Seeking included lib: " + included);
                    if (FileSystem.exists("./assets/" + included + "/images/" + key + ".png"))
                    {
                        trace("Found file in included lib: " + included);
                        return FlxAtlasFrames.fromSparrow(BitmapData.fromFile("./assets/" + included + "/images/" + key + ".png"), File.getContent("./assets/" + included + "/images/" + key + ".xml"));
                    }
                }
                if (seekIn != null)
                {
                    for (included in seekIn)
                    {
                        trace("Seeking forced lib: " + included);
                        if (FileSystem.exists("./assets/" + included + "/images/" + key + ".png"))
                        {
                            trace("Found file in forced lib: " + included);
                            return FlxAtlasFrames.fromSparrow(BitmapData.fromFile("./assets/" + included + "/images/" + key + ".png"), File.getContent("./assets/" + included + "/images/" + key + ".xml"));
                        }
                    }
                }
            }
        }
        trace("Couldn't find file in included assets: " + key);
        return api.getSparrowShit("/images/" + key + ".png", "/images/" + key + ".xml", mod);
    }

    /**
     * Seeks for an asset.
     * 
     * Looks through normal assets first, then through the mods.
     * 
     * Obeys the `libInclude` week attribute.
     * @param key 
     * @param mod 
     * @return FlxAtlasFrames
     */
     public static function getPacker(key:String, ?seekIn:Array<String>, ?mod:Mod):FlxAtlasFrames
    {
        trace("GETTING PACKER: " + key);

        if (FileSystem.exists("./assets/images/" + key + ".png"))
        {
            trace("Found file in preload: " + key);
            return Paths.getPackerAtlas(key, 'preload');
        }

        if (FileSystem.exists("./assets/shared/images/" + key + ".png"))
        {
            trace("Found file in shared: " + key);
            return Paths.getPackerAtlas(key, 'shared');
        }

        for (weeksT in weeks)
        {
            for (week in weeksT.weeks)
            {
                for (included in week.libInclude)
                {
                    trace("Seeking included lib: " + included);
                    if (FileSystem.exists("./assets/" + included + "/images/" + key + ".png"))
                    {
                        trace("Found file in included lib: " + included);
                        return FlxAtlasFrames.fromSpriteSheetPacker(BitmapData.fromFile("./assets/" + included + "/images/" + key + ".png"), File.getContent("./assets/" + included + "/images/" + key + ".txt"));
                    }
                }
                if (seekIn != null)
                {
                    for (included in seekIn)
                    {
                        trace("Seeking forced lib: " + included);
                        if (FileSystem.exists("./assets/" + included + "/images/" + key + ".png"))
                        {
                            trace("Found file in forced lib: " + included);
                            return FlxAtlasFrames.fromSpriteSheetPacker(BitmapData.fromFile("./assets/" + included + "/images/" + key + ".png"), File.getContent("./assets/" + included + "/images/" + key + ".txt"));
                        }
                    }
                }
            }
        }
        trace("Couldn't find file in included assets: " + key);
        return api.getPackerShit("/images/" + key + ".png", "/images/" + key + ".xml", mod);
    }
}