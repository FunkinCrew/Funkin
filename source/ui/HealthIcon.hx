package ui;

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
		changeIconSet(charToAnimName(char));
	}

	public static function charToAnimName(char:String = 'bf'):String
	{
		// CONVERTING CERTAIN CHARS
		switch(char)
		{
			case 'mom-car':
				char = 'mom';
			case 'gf-car' | 'gf-christmas' | 'gf-old' | 'gf-pixel':
				char = 'gf';
			case 'bf-car' | 'bf-christmas':
				char = 'bf';
			case 'monster-christmas':
				char = 'monster';
		}

		return char;
	}

	public function changeIconSet(char:String = 'bf')
	{
		antialiasing = true;
		loadGraphic(Paths.image('icons/' + char + '-icons'), true, 150, 150);

		// antialiasing override
		switch(char)
		{
			case 'bf-pixel' | 'gf-pixel' | 'senpai' | 'senpai-angry' | 'spirit':
				antialiasing = false;
		}

		animation.add(char, [0, 1, 2], 0, false, isPlayer);
		animation.play(char);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
