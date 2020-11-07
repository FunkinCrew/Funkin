package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class OptionsMenu extends MusicBeatState
{
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.menuDesat__png);
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
			FlxG.switchState(new MainMenuState());

		super.update(elapsed);
	}
}
