package;

import DifficultyIcons;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import haxe.Json;
import lime.utils.Assets;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
import sys.FileSystem;
#end
using StringTools;
typedef StorySongsJson = {
	var songs: Array<Array<String>>;
	var weekNames: Array<String>;
	var characters: Array<Array<String>>;
}
typedef DifficultysJson = {
	var difficulties:Array<Dynamic>;
	var defaultDiff:Int;
}
class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;

	var weekData:Array<Dynamic> = [];
	var weekNames:Array<String> = [];
	var curDifficulty:Int = 1;

	public static var weekUnlocked:Array<Bool> = [true, true, true, true, true, true, true];

	var weekCharacters:Array<Dynamic> = [];
	var lastWeek:Int = 0;
	/*var weekNames:Array<String> = [
		"",
		"Daddy Dearest",
		"Spooky Month",
		"PICO",
		"MOMMY MUST MURDER",
		"RED SNOW",
		"hating simulator ft. moawling"
	];*/
	var weekTitles:Array<String> = [];
	var curWeek:Int = 0;
	var txtWeekTitle:FlxText;
	var txtTracklist:FlxText;
	var weekCharactersArray:FlxTypedGroup<FlxTypedGroup<MenuCharacter>>;
	var grpWeekText:FlxTypedGroup<MenuItem>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var grpDifficulty:DifficultyIcons;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	override function create()
	{
		trace(DifficultyIcons.getDefaultDiffFP());
		curDifficulty = DifficultyIcons.getDefaultDiffFP();
		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);
		}
		var storySongJson:StorySongsJson = Json.parse(Assets.getText('assets/data/storySonglist.json'));
		persistentUpdate = persistentDraw = true;
		for (storySongList in storySongJson.songs) {
			var weekSongs = [];
			for (song in storySongList) {
				if (storySongList[0] == song) {
					weekNames.push(song);
				} else {
					weekSongs.push(song);
				}
			}
			weekData.push(weekSongs);
		}
		for (weekTitle in storySongJson.weekNames) {
			weekTitles.push(weekTitle);
		}
		for (storyCharList in storySongJson.characters) {
			var weekChars = [];
			for (char in storyCharList) {
				weekChars.push(char);
			}
			weekCharacters.push(weekChars);
		}
		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat("assets/fonts/vcr.ttf", 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = FlxAtlasFrames.fromSparrow('assets/images/campaign_menu_UI_assets.png', 'assets/images/campaign_menu_UI_assets.xml');
		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);


		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);
		weekCharactersArray = new FlxTypedGroup<FlxTypedGroup<MenuCharacter>>();
		trace("Line 70");

		for (i in 0...weekData.length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, i);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			var group = new FlxTypedGroup<MenuCharacter>();
			trace("before new group");

			weekCharactersArray.add(group);
			trace("after new group");
			for (char in 0...3)
			{
				var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, weekCharacters[i][char]);
				weekCharacterThing.y += 70;
				weekCharacterThing.antialiasing = true;
				switch (weekCharacterThing.like)
				{
					case 'dad':
						weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
						weekCharacterThing.updateHitbox();
						trace("like dad?");
					case 'bf':
						weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
						weekCharacterThing.updateHitbox();
						weekCharacterThing.x -= 80;
						trace("like bf?");
					case 'gf':
						weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
						weekCharacterThing.updateHitbox();
						trace("like gf?");
					case 'pico':
						weekCharacterThing.y += 40;
						weekCharacterThing.flipX = true;
						weekCharacterThing.x -= 40;
						weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.6));
						weekCharacterThing.updateHitbox();
						trace("like pico?");
					case 'parents-christmas':
						weekCharacterThing.x -= 150;
						weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.4));
						weekCharacterThing.updateHitbox();
						trace("like parents?");
					case 'mom':
						weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.45));
						weekCharacterThing.updateHitbox();
						trace("like mom?");
					case 'spooky':
						weekCharacterThing.y += 30;
						weekCharacterThing.x -= 30;
						weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
						weekCharacterThing.updateHitbox();
						trace("like spooky kids?");
				}

				weekCharactersArray.members[i].add(weekCharacterThing);
			}
			if (i != curWeek) {
				weekCharactersArray.members[i].kill();
			}
		}

		trace("Line 96");


		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		trace("Line 124");
		var diffJson:DifficultysJson = Json.parse(Assets.getText("assets/images/custom_difficulties/difficulties.json"));
		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);
		trace("line 186");
		var difficultyLevels:Array<String> = [];
		for (i in diffJson.difficulties) {
			difficultyLevels.push(i.name);
		}
		grpDifficulty = new DifficultyIcons(difficultyLevels, curDifficulty, leftArrow.x + 130, leftArrow.y);
		trace("line 188");

		difficultySelectors.add(grpDifficulty.group);
		trace("line 190");
		trace(grpDifficulty.activeDiff);
		trace(grpDifficulty.activeDiff.width);
		trace(leftArrow.y);
		rightArrow = new FlxSprite(grpDifficulty.activeDiff.x + grpDifficulty.activeDiff.width + 50, leftArrow.y);
		trace("line 192");
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		trace("Line 150");

		add(yellowBG);
		add(weekCharactersArray);


		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		trace("Line 165");

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		txtWeekTitle.text = weekTitles[curWeek].toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);
		// damn you!!!!!!!
		// difficultySelectors.visible = weekUnlocked[curWeek];
		difficultySelectors.visible = true;
		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UP_P)
				{
					changeWeek(-1);
				}

				if (controls.DOWN_P)
				{
					changeWeek(1);
				}

				if (controls.RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.RIGHT_P)
					changeDifficulty(1);
				if (controls.LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play('assets/sounds/cancelMenu' + TitleState.soundExt);
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
	if (true)
		{
			if (stopspamming == false)
			{
				FlxG.sound.play('assets/sounds/confirmMenu' + TitleState.soundExt);

				weekCharactersArray.members[curWeek].members[1].animation.play('bfConfirm');
				stopspamming = true;
			}

			PlayState.storyPlaylist = weekData[curWeek];
			PlayState.defaultPlaylistLength = weekData[curWeek].length;
			PlayState.isStoryMode = true;
			ModifierState.isStoryMode = true;
			selectedWeek = true;

			var diffic = "";

			diffic = grpDifficulty.getDiffEnding();

			PlayState.storyDifficulty = curDifficulty;
			for (peckUpAblePath in PlayState.storyPlaylist) {
				if (!FileSystem.exists('assets/data/'+peckUpAblePath.toLowerCase()+'/'+peckUpAblePath.toLowerCase() + diffic+'.json')) {
					// probably messed up difficulty
					trace("UH OH DIFFICULTY DOESN'T EXIST FOR A SONG");
					trace("CHANGING TO DEFAULT DIFFICULTY");
					diffic = "";
					PlayState.storyDifficulty = DifficultyIcons.getDefaultDiffFP();
				}
			}
			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				var optionsJson = Json.parse(Assets.getText('assets/data/options.json'));
				if (!optionsJson.skipModifierMenu)
				 	FlxG.switchState(new ModifierState());
				else {
					if (FlxG.sound.music != null)
						FlxG.sound.music.stop();
					FlxG.switchState(new PlayState());
				}
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		grpDifficulty.changeDifficulty(change);
		curDifficulty = grpDifficulty.difficulty;



		grpDifficulty.activeDiff.alpha = 0;
		grpDifficulty.activeDiff.y = leftArrow.y - 15;
		rightArrow.setPosition(grpDifficulty.activeDiff.x + grpDifficulty.activeDiff.width + 50, leftArrow.y);
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end

		FlxTween.tween(grpDifficulty.activeDiff, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		lastWeek = curWeek;
		curWeek += change;

		if (curWeek >= weekData.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekData.length - 1;

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			bullShit++;
		}

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt);
		updateText();
	}

	function updateText()
	{

		weekCharactersArray.members[lastWeek].kill();
		weekCharactersArray.members[curWeek].revive();
		txtTracklist.text = "Tracks\n";

		switch (weekCharactersArray.members[curWeek].members[0].like)
		{
			case 'parents-christmas':
				weekCharactersArray.members[curWeek].members[0].offset.set(200, 200);
				weekCharactersArray.members[curWeek].members[0].setGraphicSize(Std.int(weekCharactersArray.members[curWeek].members[0].width * 0.99));

			case 'senpai':
				weekCharactersArray.members[curWeek].members[0].offset.set(130, 0);
				weekCharactersArray.members[curWeek].members[0].setGraphicSize(Std.int(weekCharactersArray.members[curWeek].members[0].width * 0.9));

			case 'mom':
				weekCharactersArray.members[curWeek].members[0].offset.set(100, 200);
				weekCharactersArray.members[curWeek].members[0].setGraphicSize(Std.int(weekCharactersArray.members[curWeek].members[0].width * 1));

			case 'dad':
				weekCharactersArray.members[curWeek].members[0].offset.set(120, 200);
				weekCharactersArray.members[curWeek].members[0].setGraphicSize(Std.int(weekCharactersArray.members[curWeek].members[0].width * 1));

			default:
				weekCharactersArray.members[curWeek].members[0].offset.set(100, 100);
				weekCharactersArray.members[curWeek].members[0].setGraphicSize(Std.int(weekCharactersArray.members[curWeek].members[0].width * 1));
				// weekCharactersArray.members[curWeek].members[0].updateHitbox();
		}

		var stringThing:Array<String> = weekData[curWeek];

		for (i in stringThing)
		{
			txtTracklist.text += "\n" + i;
		}

		txtTracklist.text = StringTools.replace(txtTracklist.text.toUpperCase(), "-", " ");

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
		#end
	}
}
