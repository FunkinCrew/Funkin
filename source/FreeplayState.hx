package;

import flash.text.TextField;
import flixel.FlxCamera;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import freeplayStuff.BGScrollingText;
import freeplayStuff.DJBoyfriend;
import freeplayStuff.SongMenuItem;
import lime.app.Future;
import lime.utils.Assets;
import shaderslmfao.AngleMask;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	// var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	var coolColors:Array<Int> = [
		0xff9271fd,
		0xff9271fd,
		0xff223344,
		0xFF941653,
		0xFFfc96d7,
		0xFFa0d1ff,
		0xffff78bf,
		0xfff6b604
	];

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpCapsules:FlxTypedGroup<SongMenuItem>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];
	var scoreBG:FlxSprite;

	override function create()
	{
		FlxTransitionableState.skipNextTransIn = true;

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		addSong('Test', 1, 'bf-pixel');
		#end

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length)
		{
			songs.push(new SongMetadata(initSonglist[i], 1, 'gf'));
		}

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 1, ['dad']);

		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Spookeez', 'South', 'Monster'], 2, ['spooky', 'spooky', 'monster']);

		if (StoryMenuState.weekUnlocked[3] || isDebug)
			addWeek(['Pico', 'Philly', 'Blammed'], 3, ['pico']);

		if (StoryMenuState.weekUnlocked[4] || isDebug)
			addWeek(['Satin-Panties', 'High', 'Milf'], 4, ['mom']);

		if (StoryMenuState.weekUnlocked[5] || isDebug)
			addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 5, ['parents-christmas', 'parents-christmas', 'monster-christmas']);

		if (StoryMenuState.weekUnlocked[6] || isDebug)
			addWeek(['Senpai', 'Roses', 'Thorns'], 6, ['senpai', 'senpai', 'spirit']);

		if (StoryMenuState.weekUnlocked[7] || isDebug)
			addWeek(['Ugh', 'Guns', 'Stress'], 7, ['tankman']);

		addWeek(["Darnell", "lit-up", "2hot"], 8, ['darnell']);
		addWeek(["bro"], 1, ['gf']);

		// LOAD MUSIC

		// LOAD CHARACTERS

		trace(FlxG.width);
		trace(FlxG.camera.zoom);
		trace(FlxG.camera.initialZoom);
		trace(FlxCamera.defaultZoom);
		trace(FlxG.initialZoom);

		var pinkBack:FlxSprite = new FlxSprite().loadGraphic(Paths.image('freeplay/pinkBack'));
		pinkBack.color = 0xFFffd4e9; // sets it to pink!
		pinkBack.x -= pinkBack.width;

		FlxTween.tween(pinkBack, {x: 0}, 0.6, {ease: FlxEase.quartOut});
		add(pinkBack);

		var orangeBackShit:FlxSprite = new FlxSprite(84, FlxG.height * 0.68).makeGraphic(Std.int(pinkBack.width), 50, 0xFFffd400);
		add(orangeBackShit);

		var alsoOrangeLOL:FlxSprite = new FlxSprite(0, orangeBackShit.y).makeGraphic(100, Std.int(orangeBackShit.height), 0xFFffd400);
		add(alsoOrangeLOL);

		FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);
		orangeBackShit.visible = false;
		alsoOrangeLOL.visible = false;

		var grpTxtScrolls:FlxGroup = new FlxGroup();
		add(grpTxtScrolls);
		grpTxtScrolls.visible = false;

		var moreWays:BGScrollingText = new BGScrollingText(0, 200, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width);
		moreWays.funnyColor = 0xFFfff383;
		moreWays.speed = 2;
		grpTxtScrolls.add(moreWays);

		var funnyScroll:BGScrollingText = new BGScrollingText(0, 250, "BOYFRIEND", FlxG.width / 2);
		funnyScroll.funnyColor = 0xFFff9963;
		funnyScroll.speed = -0.5;
		grpTxtScrolls.add(funnyScroll);

		var txtNuts:BGScrollingText = new BGScrollingText(0, 300, "PROTECT YO NUTS", FlxG.width / 2);
		grpTxtScrolls.add(txtNuts);

		var funnyScroll2:BGScrollingText = new BGScrollingText(0, 340, "BOYFRIEND", FlxG.width / 2);
		funnyScroll2.funnyColor = 0xFFff9963;
		funnyScroll2.speed = -0.6;
		grpTxtScrolls.add(funnyScroll2);

		var moreWays2:BGScrollingText = new BGScrollingText(0, 400, "HOT BLOODED IN MORE WAYS THAN ONE", FlxG.width);
		moreWays2.funnyColor = 0xFFfff383;
		moreWays2.speed = 2.2;
		grpTxtScrolls.add(moreWays2);

		var funnyScroll3:BGScrollingText = new BGScrollingText(0, orangeBackShit.y, "BOYFRIEND", FlxG.width / 2);
		funnyScroll3.funnyColor = 0xFFff9963;
		funnyScroll3.speed = -0.4;
		grpTxtScrolls.add(funnyScroll3);

		var dj:DJBoyfriend = new DJBoyfriend(0, -100);
		add(dj);

		var bgDad:FlxSprite = new FlxSprite(FlxG.width, 0).loadGraphic(Paths.image('freeplay/freeplayBGdad'));
		bgDad.setGraphicSize(0, FlxG.height);
		bgDad.updateHitbox();
		bgDad.shader = new AngleMask();

		var blackOverlayBullshitLOLXD:FlxSprite = new FlxSprite(pinkBack.width * 0.75).makeGraphic(Std.int(bgDad.width), Std.int(bgDad.height),
			FlxColor.BLACK);
		add(blackOverlayBullshitLOLXD); // used to mask the text lol!

		add(bgDad);

		blackOverlayBullshitLOLXD.shader = bgDad.shader;

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpCapsules = new FlxTypedGroup<SongMenuItem>();
		add(grpCapsules);

		var overhangStuff:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
		overhangStuff.y -= overhangStuff.height;
		add(overhangStuff);
		FlxTween.tween(overhangStuff, {y: 0}, 0.3, {ease: FlxEase.quartOut});

		var fnfFreeplay:FlxText = new FlxText(0, 12, 0, "FREEPLAY", 48);
		fnfFreeplay.font = "VCR OSD Mono";
		fnfFreeplay.visible = false;
		add(fnfFreeplay);

		dj.animHITsignal.add(function()
		{
			pinkBack.color = 0xFFffd863;
			fnfFreeplay.visible = true;
			FlxTween.tween(bgDad, {x: pinkBack.width * 0.75}, 1, {ease: FlxEase.quintOut});
			orangeBackShit.visible = true;
			alsoOrangeLOL.visible = true;
			grpTxtScrolls.visible = true;
		});

		for (i in 0...songs.length)
		{
			var funnyMenu:SongMenuItem = new SongMenuItem(FlxG.width, (i * 150) + 160, songs[i].songName);
			funnyMenu.targetPos.x = funnyMenu.x;
			funnyMenu.ID = i;
			funnyMenu.alpha = 0.5;
			funnyMenu.songText.visible = false;

			new FlxTimer().start((0.06 * i) + 0, function(lerpTmr)
			{
				funnyMenu.doLerp = true;
			});

			new FlxTimer().start(((0.20 * i) / (1 + i)) + 0.75, function(swagShi)
			{
				funnyMenu.songText.visible = true;
				funnyMenu.alpha = 1;
			});

			grpCapsules.add(funnyMenu);

			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.x += 100;
			songText.isMenuItem = true;
			songText.targetY = i;

			// grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			// add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0x99000000);
		scoreBG.antialiasing = false;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		// selector = new FlxText();

		// selector.size = 40;
		// selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

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

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	var touchY:Float = 0;
	var touchX:Float = 0;
	var dxTouch:Float = 0;
	var dyTouch:Float = 0;
	var velTouch:Float = 0;

	var veloctiyLoopShit:Float = 0;
	var touchTimer:Float = 0;

	var initTouchPos:FlxPoint = new FlxPoint();

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			}
		}

		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.4);

		scoreText.text = "PERSONAL BEST:" + Math.round(lerpScore);

		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (FlxG.onMobile)
		{
			for (touch in FlxG.touches.list)
			{
				if (touch.justPressed)
				{
					initTouchPos.set(touch.screenX, touch.screenY);
				}
				if (touch.pressed)
				{
					var dx = initTouchPos.x - touch.screenX;
					var dy = initTouchPos.y - touch.screenY;

					var angle = Math.atan2(dy, dx);
					var length = Math.sqrt(dx * dx + dy * dy);

					FlxG.watch.addQuick("LENGTH", length);
					FlxG.watch.addQuick("ANGLE", Math.round(FlxAngle.asDegrees(angle)));
					trace("ANGLE", Math.round(FlxAngle.asDegrees(angle)));
				}

				/* switch (inputID)
					{
						case FlxObject.UP:
							return
						case FlxObject.DOWN:
					}
				 */
			}

			if (FlxG.touches.getFirst() != null)
			{
				if (touchTimer >= 1.5)
					accepted = true;

				touchTimer += FlxG.elapsed;
				var touch:FlxTouch = FlxG.touches.getFirst();

				velTouch = Math.abs((touch.screenY - dyTouch)) / 50;

				dyTouch = touch.screenY - touchY;
				dxTouch = touch.screenX - touchX;

				if (touch.justPressed)
				{
					touchY = touch.screenY;
					dyTouch = 0;
					velTouch = 0;

					touchX = touch.screenX;
					dxTouch = 0;
				}

				if (Math.abs(dxTouch) >= 100)
				{
					touchX = touch.screenX;
					if (dxTouch != 0)
						dxTouch < 0 ? changeDiff(1) : changeDiff(-1);
				}

				if (Math.abs(dyTouch) >= 100)
				{
					touchY = touch.screenY;

					if (dyTouch != 0)
						dyTouch < 0 ? changeSelection(1) : changeSelection(-1);
					// changeSelection(1);
				}
			}
			else
			{
				touchTimer = 0;

				/* if (velTouch >= 0)
					{
						trace(velTouch);
						velTouch -= FlxG.elapsed;

						veloctiyLoopShit += velTouch;

						trace("VEL LOOP: " + veloctiyLoopShit);

						if (veloctiyLoopShit >= 30)
						{
							veloctiyLoopShit = 0;
							changeSelection(1);
						}

						// trace(velTouch);
				}*/
			}
		}

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				// accepted = true;
			}
		}
		#end

		if (upP)
			changeSelection(-1);
		if (downP)
			changeSelection(1);

		if (FlxG.mouse.wheel != 0)
			changeSelection(-Math.round(FlxG.mouse.wheel / 4));

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			// if (Assets.exists())

			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			// does not work properly, always just accidentally sets it to normal anyways!
			/* if (!Assets.exists(Paths.json(songs[curSelected].songName + '/' + poop)))
				{
					// defaults to normal if HARD / EASY doesn't exist
					// does not account if NORMAL doesn't exist!
					FlxG.log.warn("CURRENT DIFFICULTY IS NOT CHARTED, DEFAULTING TO NORMAL!");
					poop = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), 1);
					curDifficulty = 1;
			}*/

			PlayState.SONG = SongLoad.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			// SongLoad.curDiff = Highscore.formatSong()
			SongLoad.curDiff = 'normal';

			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	override function switchTo(nextState:FlxState):Bool
	{
		clearDaCache(songs[curSelected].songName);
		return super.switchTo(nextState);
	}

	function changeDiff(change:Int = 0)
	{
		touchTimer = 0;

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		PlayState.storyDifficulty = curDifficulty;

		diffText.text = "< " + CoolUtil.difficultyString() + " >";
		positionHighscore();
	}

	// Clears the cache of songs, frees up memory, they'll have to be loaded in later tho
	function clearDaCache(actualSongTho:String)
	{
		for (song in songs)
		{
			if (song.songName != actualSongTho)
			{
				trace('trying to remove: ' + song.songName);
				// openfl.Assets.cache.clear(Paths.inst(song.songName));
			}
		}
	}

	function changeSelection(change:Int = 0)
	{
		NGio.logEvent('Fresh');

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;

		#if PRELOAD_ALL
		// FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (index => capsule in grpCapsules.members)
		{
			capsule.selected = false;

			capsule.targetPos.y = ((index - curSelected) * 150) + 160;
			capsule.targetPos.x = 270 + (60 * (Math.sin(index - curSelected)));
		}

		grpCapsules.members[curSelected].selected = true;
	}

	function positionHighscore()
	{
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;

		diffText.x = Std.int(scoreBG.x + scoreBG.width / 2);
		diffText.x -= (diffText.width / 2);
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
