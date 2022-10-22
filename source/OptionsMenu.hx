package;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUITooltip;
import Options.PauseCountdownOption;
import flixel.FlxG;
import flixel.FlxSprite;

class OptionsMenu extends MusicBeatState
{
	//var categories:Array<String> = ["Pause Countdown", "Test", "Test SEQUEL"];
	var categories:Array<Dynamic> = [
		["Pause Countdown", "A countdown timer when you resume the game", FlxG.save.data.pauseCountdown],
		["Freeplay Bop", "Toggle for the camera zooming to the beat in Freeplay", FlxG.save.data.freeplayBop]
	];
	var categoryGrp:FlxTypedGroup<Alphabet>;
	//var bitch:PauseCountdownOption;

	var descTxt:FlxText;

	var curSelected:Int = 0;

	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		categoryGrp = new FlxTypedGroup<Alphabet>();
		add(categoryGrp);

		for (i in 0...categories.length)
		{
			var categoryName:Alphabet = new Alphabet(0, (i * 70), categories[i][0] + (categories[i][2] ? " ON" : " OFF"), true, false);
			categoryName.isMenuItem = true;
			categoryName.targetY = i;
			categoryGrp.add(categoryName);
		}

		var descBG:FlxSprite = new FlxSprite(0, (FlxG.height - 40)).makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		descBG.alpha = 0.6;
		add(descBG);

		descTxt = new FlxText(10, 0, 0, "Description:", 24);
		descTxt.y = (FlxG.height - descTxt.height);
		descTxt.setFormat(Paths.font("vcr.ttf"), 24);
		add(descTxt);

		//bitch = new PauseCountdownOption("Fuck you");

		changeSelection();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (controls.ACCEPT)
		{
			updateOption();
		}

		if (controls.UP_P)
			changeSelection(1);
		if (controls.DOWN_P)
			changeSelection(-1);

		FlxG.save.flush();
		super.update(elapsed);
	}

	function refreshPos()
	{
		var bullShit:Int = 0;

		for (item in categoryGrp.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = categories.length - 1;
		if (curSelected >= categories.length)
			curSelected = 0;

		var bullShit:Int = 0;

		descTxt.text = "Description: " + categories[curSelected][1];

		for (item in categoryGrp.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function updateOption()
	{
		var bullShit:Int = 0;

		categories[curSelected][2] = !categories[curSelected][2];
		trace(categories[curSelected][2]);

		for (item in categoryGrp.members)
		{
			item.targetY = bullShit - curSelected;

			if (item.targetY == 0)
			{
				/*
				switch (curSelected)
				{
					case 0:
						FlxG.save.data.pauseCountdown = !FlxG.save.data.pauseCountdown;
						trace(FlxG.save.data.pauseCountdown);

					case 1:
						FlxG.save.data.freeplayBop = !FlxG.save.data.freeplayBop;
						trace(FlxG.save.data.freeplayBop);
				}
				*/

				categoryGrp.clear();

				for (i in 0...categories.length)
				{
					var categoryName:Alphabet = new Alphabet(0, (i * 70), categories[i][0] + (categories[i][2] ? " ON" : " OFF"), true, false);
					categoryName.isMenuItem = true;
					categoryName.targetY = curSelected;
					categoryGrp.add(categoryName);
				}

				//refreshPos();
				//item.text = categories[curSelected][0] + (categories[curSelected][2] ? " ON" : " OFF");
			}
		}
	}
}