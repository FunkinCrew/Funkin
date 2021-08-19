package animate;

import flixel.FlxSprite;
import flixel.util.FlxColor;

class TimelineFrame extends FlxSprite
{
	public function new(x:Float, y:Float, length:Int = 0)
	{
		super(x, y);

		makeGraphic((10 * length) + (2 * (length - 1)), 10, FlxColor.RED);
	}
}
