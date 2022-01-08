package shaders;

import flixel.FlxG;

class NoteColors
{
    public static var noteColors:Map<String, Array<Int>> = new Map<String, Array<Int>>();

    public static function setNoteColor(note:String, color:Array<Int>):Void
    {
        noteColors.set(note, color);
        FlxG.save.data.noteColors = noteColors;
        FlxG.save.flush();
    }

    public static function getNoteColor(note:String):Array<Int>
    {
        if (!noteColors.exists(note))
            setNoteColor(note, [0,0,0]);

        return noteColors.get(note);
    }

    public static function load():Void
    {
        if (FlxG.save.data.noteColors != null)
            noteColors = FlxG.save.data.noteColors;

        FlxG.save.flush();
    }
}