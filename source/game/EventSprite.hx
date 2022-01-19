package game;

import flixel.FlxSprite;

class EventSprite extends FlxSprite
{
    public var strumTime:Float = 0.0;

    public function new(strumTime:Float = 0.0, x:Float = 0.0, y:Float = 0.0)
    {
        super(x, y);

        this.strumTime = strumTime;
    }
}