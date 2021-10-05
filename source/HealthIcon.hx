package;

import flixel.FlxSprite;
import utils.AndroidData;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;
	var data:AndroidData = new AndroidData();

	public var iconScale:Float = 1;
	public var iconSize:Float;
	public var defaultIconScale:Float = 1;

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
		animation.add('bf', [0, 1], 0, false, isPlayer);
		if (shit){
	    	animation.add('bf-car', [0, 1], 0, false, isPlayer);
		}
		else{
		    animation.add('bf-car', [28, 29], 0, false, isPlayer);
		}
		animation.add('bf-christmas', [22, 23], 0, false, isPlayer);
		animation.add('bf-pixel', [0, 1], 0, false, isPlayer);
		animation.add('bf-holding-gf', [26, 27], 0, false, isPlayer);
		animation.add('spooky', [10, 11], 0, false, isPlayer);
		animation.add('pico', [4, 5], 0, false, isPlayer);
		animation.add('mom', [6, 7], 0, false, isPlayer);
		animation.add('mom-car', [6, 7], 0, false, isPlayer);
		animation.add('tankman', [8, 9], 0, false, isPlayer);
		animation.add('face', [12, 13], 0, false, isPlayer);
		animation.add('dad', [2, 3], 0, false, isPlayer);
		animation.add('senpai', [18, 19], 0, false, isPlayer);
		animation.add('senpai-angry', [18, 19], 0, false, isPlayer);
		animation.add('spirit', [20, 21], 0, false, isPlayer);
		animation.add('bf-old', [12, 13], 0, false, isPlayer);
		animation.add('gf', [24, 25], 0, false, isPlayer);
		animation.add('parents-christmas', [14, 15], 0, false, isPlayer);
		animation.add('monster', [16, 17], 0, false, isPlayer);
		animation.add('monster-christmas', [16, 17], 0, false, isPlayer);
		
		antialiasing = !pixelIcons.contains(char);
		
		animation.play(char);
		scrollFactor.set();
		
		iconScale = defaultIconScale;
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
