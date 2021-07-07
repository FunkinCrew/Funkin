package;

import flixel.FlxSprite;
import utils.AndroidData;

class CreditIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
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
		
		if (!shit){
	    	loadGraphic(Paths.image('iconGrid'), true, 150, 150);
		}
		else{
		    loadGraphic(Paths.image('iconGridB'), true, 150, 150);
		}

		antialiasing = true;
		animation.add('lucky', [0, 1], 0, false, isPlayer);
		animation.add('zack', [0, 1], 0, false, isPlayer);
		animation.add('schepka', [22, 23], 0, false, isPlayer);
		animation.add('goldie', [0, 1], 0, false, isPlayer);
		animation.add('idioticlucas', [26, 27], 0, false, isPlayer);
		animation.add('maskedpump', [10, 11], 0, false, isPlayer);
		animation.add('aarontal', [4, 5], 0, false, isPlayer);
		animation.add('mark', [6, 7], 0, false, isPlayer);
		animation.add('smokey', [6, 7], 0, false, isPlayer);
		animation.add('tankman', [8, 9], 0, false, isPlayer);
		animation.add('peppy', [12, 13], 0, false, isPlayer);
		animation.add('klavier', [2, 3], 0, false, isPlayer);
		animation.add('gamerbros', [18, 19], 0, false, isPlayer);
		animation.add('muffin', [18, 19], 0, false, isPlayer);
		animation.add('kawaii', [20, 21], 0, false, isPlayer);
		animation.add('evil', [12, 13], 0, false, isPlayer);
		animation.add('phantom', [24, 25], 0, false, isPlayer);
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
