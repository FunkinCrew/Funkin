package utilities;

import flixel.FlxG;

class NoteHandler
{
    public static function getBinds(keyCount:Int):Array<String>
    {
        return FlxG.save.data.binds[keyCount - 1];
    }
}