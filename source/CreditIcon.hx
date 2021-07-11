package;

import flixel.FlxSprite;
import utils.AndroidData;

class CreditIcon extends FlxSprite
{
	/**
	 * Used for CreditState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;
	var data:AndroidData = new AndroidData();

	public var iconScale:Float = 1;
	public var iconSize:Float;
	public var defualtIconScale:Float = 1;

	var pixelIcons:Array<String> = ["bf-pixel", "senpai", "senpai-angry", "spirit"];

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		var shit:Bool = data.getIcon();
		
	    loadGraphic(Paths.image('credIcon'), true, 150, 150);

		antialiasing = true;
		animation.add('lucky', [3], 0, false, isPlayer);
		animation.add('zack', [2], 0, false, isPlayer);
		animation.add('schepka', [7], 0, false, isPlayer);
		animation.add('goldie', [8], 0, false, isPlayer);
		animation.add('idioticlucas', [14], 0, false, isPlayer);
		animation.add('maskedpump', [5], 0, false, isPlayer);
		animation.add('aarontal', [0], 0, false, isPlayer);
		animation.add('mark', [15], 0, false, isPlayer);
		animation.add('smokey', [16], 0, false, isPlayer);
		animation.add('peppy', [1], 0, false, isPlayer);
		animation.add('klavier', [4], 0, false, isPlayer);
		animation.add('gamerbros', [6], 0, false, isPlayer);
		animation.add('muffin', [12], 0, false, isPlayer);
		animation.add('kawaii', [13], 0, false, isPlayer);
		animation.add('evil', [10], 0, false, isPlayer);
		animation.add('phantom', [11], 0, false, isPlayer);
		animation.add('parents-christmas', [14, 15], 0, false, isPlayer);
		animation.add('monster', [16, 17], 0, false, isPlayer);
		animation.add('monster-christmas', [16, 17], 0, false, isPlayer);
		
		antialiasing = !pixelIcons.contains(char);
		
		animation.play(char);
		scrollFactor.set();
		
		iconScale = defualtIconScale;
		iconSize = width;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		setGraphicSize(Std.int(iconSize * iconScale));
		updateHitbox();

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
