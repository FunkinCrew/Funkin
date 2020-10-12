package;

import flixel.FlxSprite;
import flixel.ui.FlxSpriteButton;

class DisplayNote extends FlxSpriteButton
{
	public var strumTime:Float = 0;
	public var type:Int = 0;

	public static inline var PLAY_NOTE:Int = 10;
	public static inline var SECTION:Int = 20;

	public var selected:Bool = false;

	// SECTION SPECIFIC DATA
	// If it's a simon says type section
	public var doesLoop:Bool = true;
	public var lengthInSteps:Int = 16;

	public function new(x:Float, y:Float, label:FlxSprite, onClick:Void->Void)
	{
		super(x, y, label, onClick);
	}
}
