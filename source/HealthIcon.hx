package;

import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	var char:String = 'bf';
	var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		this.char = char;

		loadIcon(char);
		antialiasing = true;
		scrollFactor.set();
	}

	public var isOldIcon:Bool = false;

	public function swapOldIcon():Void
	{
		isOldIcon = !isOldIcon;

		if (isOldIcon)
		{
			loadGraphic(Paths.image('icons/icon-bf-old'), true, 150, 150);
			animation.add('bf-old', [0, 1], 0, false, isPlayer);
			animation.play('bf-old');
		}
		else
			loadIcon(char);
	}

	function loadIcon(char:String):Void
	{
		var realChar:String = char.split('-')[0].trim();
		loadGraphic(Paths.image('icons/icon-' + realChar), true, 150, 150);
		animation.add(realChar, [0, 1], 0, false, isPlayer);
		animation.play(realChar);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
