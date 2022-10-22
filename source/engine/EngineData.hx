package engine;

import flixel.FlxG;

class EngineData
{
    //static var swagArray:Array<Dynamic> = [];

    // We init the save data! woohoo!
    public static function initSave()
    {
        if (FlxG.save.data.antialiasing == null)
            FlxG.save.data.antialiasing = true;

        if (FlxG.save.data.pauseCountdown == null)
            FlxG.save.data.pauseCountdown = true;

        if (FlxG.save.data.freeplayBop == null)
            FlxG.save.data.freeplayBop = true;
    }
}