package;

import flixel.FlxSprite;

class BGSprite extends FlxSprite
{
	/**
		Cool lil utility thing just so that it can easy do antialiasing and scrollfactor bullshit
	 */
	public var idleAnim:String;

	public function new(image:String, x:Float = 0, y:Float = 0, parX:Float = 1, parY:Float = 1, ?daAnimations:Array<String>, ?loopingAnim:Bool = false)
	{
		super(x, y);

		if (daAnimations != null)
		{
			frames = Paths.getSparrowAtlas(image);
			for (anims in daAnimations)
			{
				animation.addByPrefix(anims, anims, 24, loopingAnim);
				animation.play(anims);

				if (idleAnim == null)
					idleAnim = anims;
			}
		}
		else
		{
			loadGraphic(Paths.image(image));
			active = false;
		}

		scrollFactor.set(parX, parY);
		antialiasing = true;
	}

	public function dance():Void
	{
		if (idleAnim != null)
			animation.play(idleAnim);
	}
}
