package utilities;

import flixel.FlxG;

class NoteHandler
{
    public static function getBinds(keyCount:Int):Array<String>
    {
        return utilities.Options.getData("binds", "binds")[keyCount - 1];
    }
}