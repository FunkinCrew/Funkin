package;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		loadGraphic(Paths.image('iconGrid'), true, 150, 150);

		antialiasing = true;
		// the player character
		animation.add('bf-old', [14, 15], 0, false, isPlayer);
		animation.add('bf', [0, 1], 0, false, isPlayer);
		animation.add('bf-pixel', [21, 21], 0, false, isPlayer);

		// the dearest family
		animation.add('gf', [16], 0, false, isPlayer);
		animation.add('gf-pixel', [24], 0, false, isPlayer);

		animation.add('dad', [12, 13], 0, false, isPlayer);
		animation.add('mom', [6, 7], 0, false, isPlayer);
		animation.add('parents-christmas', [17], 0, false, isPlayer);

		// spooky kids
		animation.add('spooky', [2, 3], 0, false, isPlayer);

		// pico
		animation.add('pico', [4, 5], 0, false, isPlayer);

		// spooky monster
		animation.add('monster', [19, 20], 0, false, isPlayer);

		// hating sim
		animation.add('senpai', [22, 22], 0, false, isPlayer);
		animation.add('spirit', [23, 23], 0, false, isPlayer);

		// placeholder / coming soon
		animation.add('tankman', [8, 9], 0, false, isPlayer);
		animation.add('face', [10, 11], 0, false, isPlayer);

		// custom goes here

		// coolio
		switch(char)
		{
			case 'mom-car':
				char = 'mom';
			case 'gf-car' | 'gf-christmas':
				char = 'gf';
			case 'senpai-angry':
				char = 'senpai';
			case 'bf-car' | 'bf-christmas':
				char = 'bf';
			case 'monster-christmas':
				char = 'monster';
		}
		
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
