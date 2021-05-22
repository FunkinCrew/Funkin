package;

import haxe.macro.Expr.Case;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import DifficultyIcons;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import sys.FileSystem;
import flash.media.Sound;
#end
import haxe.Json;
import tjson.TJSON;
using StringTools;

class SelectSortState extends MusicBeatState
{

	var songs:Array<String> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var usingCategoryScreen:Bool = false;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	override function create()
	{
		songs = ["songs", "categories", "weeks"];


		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}


		changeSelection();

		// FlxG.sound.playMusic('assets/music/title' + TitleState.soundExt, 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/*
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}


		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			LoadingState.loadAndSwitchState(new SaveDataState());
		}

		if (accepted)
		{
			trace(songs[curSelected]);
			switch (songs[curSelected]) {
				case "songs":
					CategoryState.choosingFor = "sorting";
					LoadingState.loadAndSwitchState(new CategoryState());
				case "categories":
					var coolCategoryJson:Array<SelectSongsState.TCategory> = CoolUtil.parseJson(Assets.getText('assets/data/freeplaySongJson.jsonc'));
					var coolCategories:Array<String> = [];
					for (coolCategory in coolCategoryJson)
					{
						coolCategories.push(coolCategory.name);
					}
					SortState.stuffToSort = coolCategories;
					SortState.sorting = "categories";
					LoadingState.loadAndSwitchState(new SortState());
				case "weeks":
					// gonna be reallllllllll fucky renaming files
					SortState.sorting = "weeks";
					// gonna do weeks ourselves?
					var coolWeekJson:StoryMenuState.StorySongsJson = CoolUtil.parseJson(Assets.getText('assets/data/storySonglist.json'));
					var coolWeeks:Array<String> = [];
					if (coolWeekJson.version == 1 || coolWeekJson.version == null)
						for (i in 0...coolWeekJson.songs.length) {
							coolWeeks.push("week"+i);
						}
					else if (coolWeekJson.version == 2)
						for (i in 0...coolWeekJson.weeks.length)
							coolWeeks.push("week" + i);
					
					SortState.stuffToSort = coolWeeks;
					LoadingState.loadAndSwitchState(new SortState());
			}

		}
	}

	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
		var bullShit:Int = 0;

		for (item in grpSongs.members)
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
