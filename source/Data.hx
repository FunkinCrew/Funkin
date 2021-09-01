package;

import flixel.FlxG;

class Data
{
    public static function init():Void
    {
        if (FlxG.save.data.fps = null)
			FlxG.save.data.fps = true;
        if (FlxG.save.data.cpuStrums = null)
            FlxG.save.data.cpuStrums = false;
    }
}