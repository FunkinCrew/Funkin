package;

import flixel.FlxSprite;

using StringTools;

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

		for (tchar in CoolUtil.coolTextFile(Paths.txt('healthicons'))) {
			if (!tchar.startsWith('#')) {
				var eugh = tchar.split(':');

				animation.add(eugh[0], [Std.parseInt(eugh[1]), Std.parseInt(eugh[2])], 0, false, isPlayer);
			}
		}

		antialiasing = true;
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
