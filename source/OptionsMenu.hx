package;

import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;

class OptionsMenu extends MusicBeatState
{
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		var title:FlxText = new FlxText(0, 0, FlxG.width, "Options will go here at some point");
		title.setFormat(null, 16, 0xFFFFFFFF, 'center');
		title.screenCenter();
		add(title);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK) {
			FlxG.switchState(new MainMenuState());
		}
	}
}
