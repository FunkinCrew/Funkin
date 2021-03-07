package;

import flixel.FlxSprite;

class BGSprite extends FlxSprite
{
	/**
		Cool lil utility thing just so that it can easy do antialiasing and scrollfactor bullshit
	 */
	public function new(image:String, x:Float = 0, y:Float = 0, parX:Float = 1, parY:Float = 1)
	{
		super(x, y);

		loadGraphic(Paths.image(image));
		scrollFactor.set(parX, parY);
		antialiasing = true;
		active = false;
	}
}
