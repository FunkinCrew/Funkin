package engine.io;

import sys.io.File;
import sys.FileSystem;

using StringTools;

/**
 * @since 1.3.0-SC542
 */
class ModManager
{
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
                if (file.startsWith("mod_"))
                {
                    trace("found mod: " + file);
                    loaded.push({
                        name: file.split("mod_")[1],
                        path: modFolderPath + file
                    });
                }
            }
        }
        trace("Found " + loaded.length + " mod(s).");
    }
}

typedef Mod = 
{
    name:String,
    path:String,
}