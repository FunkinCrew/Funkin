package funkin;

import flixel.FlxSprite;
import openfl.utils.Assets;
import funkin.play.PlayState;

using StringTools;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var char:String = '';

	var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;

		antialiasing = true;
		changeIcon(char);
		scrollFactor.set();
	}

	public var isOldIcon:Bool = false;

	public function swapOldIcon():Void
	{
		isOldIcon = !isOldIcon;

		if (isOldIcon)
			changeIcon('bf-old');
		else
			changeIcon(PlayState.SONG.player1);
	}

	var pixelArrayFunny:Array<String> = CoolUtil.coolTextFile(Paths.file('images/icons/pixelIcons.txt'));

	public function changeIcon(newChar:String):Void
	{
		if (newChar != 'bf-pixel' && newChar != 'bf-old')
			newChar = newChar.split('-')[0].trim();

		if (!Assets.exists(Paths.image('icons/icon-' + newChar)))
		{
			FlxG.log.warn('No icon with data: $newChar : using default placeholder face instead!');
			newChar = "face";
		}

		if (newChar != char)
		{
			if (animation.getByName(newChar) == null)
			{
				var imgSize:Int = 150;

				if (newChar.endsWith('pixel') || pixelArrayFunny.contains(newChar))
					imgSize = 32;

				loadGraphic(Paths.image('icons/icon-' + newChar), true, imgSize, imgSize);

				animation.add(newChar, [0, 1], 0, false, isPlayer);
			}
			animation.play(newChar);
			char = newChar;

			if (newChar.endsWith('pixel') || pixelArrayFunny.contains(newChar))
				antialiasing = false;
			else
				antialiasing = true;
			setGraphicSize(150);
			updateHitbox();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
