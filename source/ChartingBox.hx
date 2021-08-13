import flixel.util.FlxColor;
import flixel.FlxSprite;

class ChartingBox extends FlxSprite
{
    public var connectedNote:Note;
    public var connectedNoteData:Array<Dynamic>;

    public function new(x,y, originalNote:Note)
    {
        super(x,y);
        connectedNote = originalNote;

        makeGraphic(40,40,FlxColor.fromRGB(173, 216, 230));
        alpha = 0.4;
    }
}