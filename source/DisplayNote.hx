package;

import flixel.FlxSprite;
import flixel.ui.FlxSpriteButton;

class DisplayNote extends FlxSpriteButton
{
	public var strumTime:Float = 0;

	public function new(x:Float, y:Float, label:FlxSprite, onClick:Void->Void)
	{
		super(x, y, label, onClick);
	}
}
