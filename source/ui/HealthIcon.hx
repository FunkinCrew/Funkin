package ui;

#if sys
import polymod.backends.PolymodAssetLibrary;
import polymod.Polymod;
import polymod.backends.PolymodAssets;
#end
import openfl.display.BitmapData;
import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;
	public var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;

		// plays anim lol
		playSwagAnim(char);
		scrollFactor.set();
	}

	public function playSwagAnim(?char:String = 'bf')
	{		
		changeIconSet(char);
	}

	public function changeIconSet(char:String = 'bf')
	{
		antialiasing = true;

		loadGraphic(Paths.image('icons/' + char + '-icons'), true, 150, 150);

		animation.add(char, [0, 1, 2], 0, false, isPlayer);
		animation.play(char);

		// antialiasing override
		switch(char)
		{
			case 'bf-pixel' | 'senpai' | 'senpai-angry' | 'spirit':
				antialiasing = false;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
