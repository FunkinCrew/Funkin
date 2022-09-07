package funkin;

import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.MenuItem.WeekType;
import funkin.play.PlayState;
import lime.net.curl.CURLCode;
import openfl.Assets;

using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end

class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;

	var weekData:Array<Array<String>> = [
		['Tutorial'],
		['Bopeebo', 'Fresh', 'Dadbattle'],
		['Spookeez', 'South', "Monster"],
		['Pico', 'Philly', "Blammed"],
		['Satin-Panties', "High", "Milf"],
		['Cocoa', 'Eggnog', 'Winter-Horrorland'],
		['Senpai', 'Roses', 'Thorns'],
		['Ugh', 'Guns', 'Stress'],
		['Darnell', "lit-up", "2hot"]
	];
	var curDifficulty:Int = 1;

	// TODO: This info is just hardcoded right now.
	// We should probably make it so that weeks must be completed in order to unlock the next week.
	public static var weekUnlocked:Array<Bool> = [true, true, true, true, true, true, true, true, true];

	var weekCharacters:Array<Dynamic> = [
		['dad', 'bf', 'gf'],
		['dad', 'bf', 'gf'],
		['spooky', 'bf', 'gf'],
		['pico', 'bf', 'gf'],
		['mom', 'bf', 'gf'],
		['parents-christmas', 'bf', 'gf'],
		['senpai', 'bf', 'gf'],
		['tankman', 'bf', 'gf'],
		['darnell', 'pico', 'nene']
	];

	var weekNames:Array<String> = [
		"",
		"Daddy Dearest",
		"Spooky Month",
		"PICO",
		"MOMMY MUST MURDER",
		"RED SNOW",
		"hating simulator ft. moawling",
		"TANKMAN",
		"Due Debts"
	];

	var weekType:Array<WeekType> = [WEEK, WEEK, WEEK, WEEK, WEEK, WEEK, WEEK, WEEK, WEEKEND];
	var weekTypeInc:Map<WeekType, Int> = new Map();

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekCharacters:Array<FlxTypedGroup<MenuCharacter>>;

	// var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var yellowBG:FlxSprite; // not actually, yellow, lol!
	var targetColor:Int = 0xFFF9CF51;

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		yellowBG = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, FlxColor.WHITE);
		yellowBG.color = 0xFFF9CF51;
		// 0xFF413CAE blue
		// 0xFFF9CF51 yello

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		// grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		grpWeekCharacters = [];

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...weekData.length)
		{
			if (!weekTypeInc.exists(weekType[i]))
				weekTypeInc[weekType[i]] = 1;

			if (i == 0 && weekType[i] == WEEK)
				weekTypeInc[weekType[i]] = 0; // set week to 0 by default?

			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, weekTypeInc[weekType[i]], weekType[i]);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekTypeInc[weekType[i]] += 1;

			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			if (!weekUnlocked[i])
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = true;
				grpLocks.add(lock);
			}
		}

		var sizeChart:Map<String, Array<Float>> = new Map();

		var sizeTxt:Array<String> = Assets.getText(Paths.file("data/storychardata.txt")).split("\n");

		for (item in sizeTxt)
		{
			var items:Array<String> = item.split(" ");

			var stuf:Array<Float> = [];
			var name:String = items.shift();

			for (num in items)
				stuf.push(Std.parseFloat(num));

			sizeChart.set(name, stuf);
		}

		for (index => week in weekCharacters)
		{
			grpWeekCharacters.push(new FlxTypedGroup<MenuCharacter>());

			for (char in 0...week.length)
			{
				var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, weekCharacters[index][char]);
				weekCharacterThing.y += 70;
				weekCharacterThing.antialiasing = true;

				var size:Float = 0.9;

				switch (char)
				{
					case 0 | 2:
						size = 0.5;
						if (char == 0 && weekCharacterThing.character == "pico")
							weekCharacterThing.flipX = true;
					case 1:
						size = 0.9;
						weekCharacterThing.x -= 80;
				}

				if (sizeChart.exists(weekCharacterThing.character))
				{
					var nums:Array<Float> = sizeChart[weekCharacterThing.character];
					size = nums[char];

					// IDK, this might be busted ass null shit?
					if (char != 1)
					{
						weekCharacterThing.x += nums[3];
						weekCharacterThing.y += nums[4];
					}
				}

				weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * size));
				weekCharacterThing.updateHitbox();

				grpWeekCharacters[index].add(weekCharacterThing);
				trace("ADD CHARACTER");
			}

			trace(grpWeekCharacters[index].toString());
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		sprDifficulty.frames = ui_tex;
		sprDifficulty.animation.addByPrefix('easy', 'EASY');
		sprDifficulty.animation.addByPrefix('normal', 'NORMAL');
		sprDifficulty.animation.addByPrefix('hard', 'HARD');
		sprDifficulty.animation.play('easy');
		changeDifficulty();

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(yellowBG);
		for (grp in grpWeekCharacters)
		{
			add(grp);
			// trace("ADDED GRP");
		}

		// add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);

		yellowBG.color = FlxColor.interpolate(yellowBG.color, targetColor, 0.06);

		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.5);

		scoreText.text = "WEEK SCORE:" + Math.round(lerpScore);

		txtWeekTitle.text = weekNames[curWeek].toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = weekUnlocked[curWeek];

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UI_UP_P)
				{
					changeWeek(-1);
				}

				if (controls.UI_DOWN_P)
				{
					changeWeek(1);
				}

				if (controls.UI_RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.UI_LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.UI_RIGHT_P)
					changeDifficulty(1);
				if (controls.UI_LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
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
		if (weekUnlocked[curWeek])
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				grpWeekCharacters[curWeek].members[1].animation.play('bfConfirm');
				stopspamming = true;
			}

			PlayState.storyPlaylist = weekData[curWeek];
			PlayState.isStoryMode = true;
			selectedWeek = true;

			PlayState.currentSong = SongLoad.loadFromJson(PlayState.storyPlaylist[0].toLowerCase(), PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;

			PlayState.storyDifficulty = curDifficulty;
			SongLoad.curDiff = switch (curDifficulty)
			{
				case 0:
					'easy';
				case 1:
					'normal';
				case 2:
					'hard';
				default:
					'normal';
			};

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		sprDifficulty.offset.x = 0;

		switch (curDifficulty)
		{
			case 0:
				sprDifficulty.animation.play('easy');
				sprDifficulty.offset.x = 20;
			case 1:
				sprDifficulty.animation.play('normal');
				sprDifficulty.offset.x = 70;
			case 2:
				sprDifficulty.animation.play('hard');
				sprDifficulty.offset.x = 20;
		}

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);

		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= weekData.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekData.length - 1;

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && weekUnlocked[curWeek])
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();
	}

	function updateText()
	{
		switch (weekType[curWeek])
		{
			case WEEK:
				targetColor = 0xFFF9CF51;
			case WEEKEND:
				targetColor = 0xFF413CAE;
		}

		for (ind => grp in grpWeekCharacters)
			grp.visible = ind == curWeek;

		txtTracklist.text = "Tracks\n";

		var trackNames:Array<String> = weekData[curWeek];
		for (i in trackNames)
		{
			txtTracklist.text += '\n${i}';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
	}
}
