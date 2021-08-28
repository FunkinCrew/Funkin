package;

import flixel.FlxSprite;

class BGSprite extends FlxSprite
{
	/**
		Cool lil utility thing just so that it can easy do antialiasing and scrollfactor bullshit
	 */
	public var idleAnim:String;

	/**
	 * NOTE: loadOldWay param is just for current backward compatibility! Will be moved later!
	 */
	public function new(image:String, x:Float = 0, y:Float = 0, parX:Float = 1, parY:Float = 1, ?daAnimations:Array<String>, ?loopingAnim:Bool = false,
			?loadOldWay:Bool = true)
	{
		super(x, y);

		if (loadOldWay)
		{
			if (daAnimations != null)
			{
				setupSparrow(image, daAnimations, loopingAnim);
			}
			else
			{
				justLoadImage(image);
			}
		}

		scrollFactor.set(parX, parY);
		antialiasing = true;
	}

	public function setupSparrow(image:String, daAnimations:Array<String>, ?loopingAnim:Bool = false)
	{
		frames = Paths.getSparrowAtlas(image);
		for (anims in daAnimations)
		{
			var daLoop:Bool = loopingAnim;
			if (loopingAnim == null)
				daLoop = false;

			animation.addByPrefix(anims, anims, 24, daLoop);
			animation.play(anims);

			if (idleAnim == null)
				idleAnim = anims;
		}
	}

	public function justLoadImage(image:String)
	{
		loadGraphic(Paths.image(image));
		active = false;
	}

	public function dance():Void
	{
		if (idleAnim != null)
			animation.play(idleAnim);
	}
}
