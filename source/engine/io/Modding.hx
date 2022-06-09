package engine.io;

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
}