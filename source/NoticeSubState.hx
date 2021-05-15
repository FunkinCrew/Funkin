package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class NoticeSubState extends MusicBeatState
{
	public static var leftState:Bool = false;

	public function new(inText:String = "")
	{
		super();

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuNotice'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		var text:String = "";

		if (inText == "") {
			var textList:Array<String> = CoolUtil.coolTextFile(Paths.txt("notice"));

			for (i in 0...textList.length)
			{
				text = text + "\n" + textList[i];
			}
		} else {
			text = inText;
		}

		var txt:FlxText = new FlxText(0, 0, FlxG.width, text, 32);
		txt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.screenCenter();
		add(txt);
	}

	override function update(elapsed:Float)
	{
		if (controls.ACCEPT)
		{
			leftState = true;
			FlxG.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}
