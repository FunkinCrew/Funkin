package;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var charac:String;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		charac = char;
		super();
		loadGraphic(Paths.image('iconGrid'), true, 150, 150);

		antialiasing = true;
		animation.add('bf', [0, 1, 30], 0, false, isPlayer);
		animation.add('bf-car', [0, 1, 30], 0, false, isPlayer);
		animation.add('bf-christmas', [0, 1, 30], 0, false, isPlayer);
		animation.add('bf-holding-gf', [0, 1, 30], 0, false, isPlayer);
		animation.add('bf-pixel', [21, 41, 40], 0, false, isPlayer);
		animation.add('spooky', [2, 3, 31], 0, false, isPlayer);
		animation.add('pico', [4, 5, 32], 0, false, isPlayer);
		animation.add('mom', [6, 7, 33], 0, false, isPlayer);
		animation.add('mom-car', [6, 7, 33], 0, false, isPlayer);
		animation.add('tankman', [8, 9, 50], 0, false, isPlayer);
		animation.add('dad', [12, 13, 34], 0, false, isPlayer);
		animation.add('senpai', [22, 42, 43], 0, false, isPlayer);
		animation.add('senpai-angry', [44, 45, 46], 0, false, isPlayer);
		animation.add('spirit', [23, 47, 48], 0, false, isPlayer);
		animation.add('bf-old', [14, 15, 39], 0, false, isPlayer);
		animation.add('parents-christmas', [17, 18, 36], 0, false, isPlayer);
		animation.add('monster', [19, 20, 37], 0, false, isPlayer);
		animation.add('monster-christmas', [19, 20, 37], 0, false, isPlayer);
		animation.add('gf', [16, 49, 35], 0, false, isPlayer);
		animation.add('gf-car', [16, 49, 35], 0, false, isPlayer);
		animation.add('gf-pixel', [16, 49, 35], 0, false, isPlayer);
		animation.play(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
