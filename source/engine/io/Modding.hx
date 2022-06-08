package engine.io;

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
}