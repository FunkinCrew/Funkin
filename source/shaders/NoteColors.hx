package shaders;

class NoteColors
{
    public static var noteColors:Map<String, Array<Int>> = new Map<String, Array<Int>>();

    public static function setNoteColor(note:String, color:Array<Int>):Void
    {
        noteColors.set(note, color);

        utilities.Options.setData(noteColors, "noteColors", "noteColors");
    }

    public static function getNoteColor(note:String):Array<Int>
    {
        if (!noteColors.exists(note))
            setNoteColor(note, [0,0,0]);

        return noteColors.get(note);
    }

    public static function load():Void
    {
        if(utilities.Options.getData("noteColors", "noteColors") != null)
            noteColors = utilities.Options.getData("noteColors", "noteColors");
    }
}