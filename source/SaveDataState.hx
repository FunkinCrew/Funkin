package;

import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import sys.io.File;
import haxe.Json;
using StringTools;
class SaveDataState extends MusicBeatState
{

	var saves:FlxTypedGroup<SaveFile>;
	var curSelected:Int = 0;
	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuDesat.png');
		saves = new FlxTypedGroup<SaveFile>();
		menuBG.color = 0xFF7194fc;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		trace("before");
		for (i in 0...3) {
			var saveFile = new SaveFile(500, 0, i);

			saves.add(saveFile);
		}
		add(menuBG);
		add(saves);
		super.create();
	}
	override function update(elapsed:Float) {
		super.update(elapsed);
		if (controls.BACK) {
			if (!saves.members[curSelected].askingToConfirm) {
				FlxG.switchState(new MainMenuState());
			} else {
				saves.members[curSelected].askToConfirm(false);
			}
		}
		if (!saves.members[curSelected].askingToConfirm) {
			if (controls.UP_P)
			{
				changeSelection(-1);
			}
			if (controls.DOWN_P)
			{
				changeSelection(1);
			}
			if (controls.RIGHT_P) {
				saves.members[curSelected].changeSelection();
			}
			if (controls.LEFT_P) {
				saves.members[curSelected].changeSelection();
			}
		}
		if (controls.ACCEPT) {
			if (!saves.members[curSelected].askingToConfirm) {
				if (saves.members[curSelected].selectingLoad) {
					var saveName = "save" + curSelected;
					trace(saveName);
					var optionsJson = Json.parse(Assets.getText('assets/data/options.json'));
					optionsJson.preferredSave = curSelected;
					File.saveContent('assets/data/options.json', Json.stringify(optionsJson));
					FlxG.save.close();
					FlxG.save.bind(saveName, "bulbyVR");
					FlxG.sound.play('assets/sounds/selectfile.ogg');
					if (FlxG.save.data.songScores == null) {
						FlxG.save.data.songScores = ["tutorial" => 0];
					}
					Highscore.load();
				} else {
					saves.members[curSelected].askToConfirm(true);
				}

			} else {
				// this means the user confirmed!
				var saveName = "save" + curSelected;
				FlxG.save.bind(saveName, "bulbyVR");
				FlxG.save.erase();
				saves.members[curSelected].askToConfirm(false);
				FlxG.sound.play('assets/sounds/deletefile.ogg');
				FlxG.save.data.songScores = ["tutorial" => 0];
				Highscore.load();
			}
		}

	}
	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = saves.members.length - 1;
		if (curSelected >= saves.members.length)
			curSelected = 0;


		var bullShit:Int = 0;

		for (item in saves.members)
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
}
