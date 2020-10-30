package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.text.FlxText;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;

	var weekData:Array<Dynamic> = [['Tutorial', 'Bopeebo', 'Fresh', 'Dad Battle'], ['Spookeez', 'South', 'Monster']];

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	override function create()
	{
		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);
		add(scoreText);

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat("assets/fonts/vcr.ttf", 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);
		add(rankText);

		var ui_tex = FlxAtlasFrames.fromSparrow(AssetPaths.campaign_menu_UI_assets__png, AssetPaths.campaign_menu_UI_assets__xml);
		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		for (i in 0...weekData.length)
		{
			var unlocked:Bool = true;

			if (i == 1)
				unlocked = false;

			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, i, unlocked);
			add(weekThing);
		}

		add(yellowBG);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);

		updateText();

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		// scoreText.text = "Score SHIT";
		// FlxG.watch.addQuick('font', scoreText.font);

		if (controls.UP_P)
			changeWeek(-1);
		if (controls.DOWN_P)
			changeWeek(1);

		super.update(elapsed);
	}

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= weekData.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekData.length - 1;

		updateText();
	}

	function updateText()
	{
		txtTracklist.text = "Tracks\n";

		var stringThing:Array<String> = weekData[curWeek];

		for (i in stringThing)
		{
			txtTracklist.text += "\n" + i;
		}

		txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;
	}
}
