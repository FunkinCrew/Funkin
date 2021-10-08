package states;

import openfl.Lib;
import modding.PolymodHandler;
import modding.ModList;
import utilities.SaveData;
import utilities.MusicUtilities;
import utilities.CoolUtil;
import game.Conductor;
import game.Highscore;
import utilities.PlayerSettings;
import ui.Alphabet;
#if desktop
import utilities.Discord.DiscordClient;
import sys.thread.Thread;
import polymod.Polymod;
import sys.FileSystem;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import states.StoryMenuState;

using StringTools;

class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	override public function create():Void
	{
		SaveData.init();

		/* cool fps shit thx kade */
		(cast (Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);

		#if desktop
		PolymodHandler.loadMods();
		#end

		curWacky = FlxG.random.getObject(getIntroTextShit());
		super.create();

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});

		#if desktop
		if(!DiscordClient.started && FlxG.save.data.discordRPC)
		{
			DiscordClient.initialize();
		
			Application.current.onExit.add(function (exitCode) {
				DiscordClient.shutdown();
			});
		}
		#end
	}

	var old_logo:FlxSprite;
	var old_logo_black:FlxSprite;

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	public static var version:String = "v0.0";

	public static function playTitleMusic()
	{
		FlxG.sound.playMusic(MusicUtilities.GetTitleMusicPath(), 0);
	}

	function startIntro()
	{
		if (!initialized)
		{
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			if (FlxG.save.data.oldTitle)
			{
				playTitleMusic();
			}
			else {
				if (Date.now().getDay() == 5 && Date.now().getHours() >= 18 || FlxG.save.data.nightMusic)
				{
					playTitleMusic();
					Conductor.changeBPM(117);
				} else
				{
					playTitleMusic();
					Conductor.changeBPM(102);
				}
			}

			FlxG.sound.music.fadeIn(4, 0, 0.7);

			Main.toggleFPS(FlxG.save.data.fpsCounter);
			Main.toggleMem(FlxG.save.data.memoryCounter);
		}

		version = "Leather's Funkin' Engine" + " Release v" + Application.current.meta.get('version');

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();

		if (FlxG.save.data.oldTitle)
		{
			bg.loadGraphic(Paths.image("title/stageback"));
			bg.antialiasing = true;
			bg.setGraphicSize(Std.int(FlxG.width * 1.1));
			bg.updateHitbox();
			bg.screenCenter();
		}
		else
		{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}

		add(bg);

		if (FlxG.save.data.oldTitle)
		{
			old_logo = new FlxSprite().loadGraphic(Paths.image('title/logo'));
			old_logo.screenCenter();
			old_logo.antialiasing = true;

			old_logo_black = new FlxSprite().loadGraphic(Paths.image("title/logo"));
			old_logo_black.screenCenter();
			old_logo_black.color = FlxColor.BLACK;
		}
		else
		{
			logoBl = new FlxSprite(-150, -100);
			
			#if sys
			if(FlxG.save.data.watermarks)
				logoBl.frames = Paths.getSparrowAtlasSYS('title/leatherLogoBumpin');
			else
				logoBl.frames = Paths.getSparrowAtlasSYS('title/logoBumpin');
			#else
			if(FlxG.save.data.watermarks)
				logoBl.frames = Paths.getSparrowAtlas('title/leatherLogoBumpin');
			else
				logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
			#end

			logoBl.antialiasing = true;
			logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
			logoBl.animation.play('bump');
			logoBl.updateHitbox();
		}

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();

		if (!FlxG.save.data.oldTitle)
		{
			add(logoBl);
			add(gfDance);
			add(titleText);
		}

		if (FlxG.save.data.oldTitle)
		{
			add(old_logo_black);
			add(old_logo);

			FlxTween.tween(old_logo_black, {y: old_logo_black.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
			FlxTween.tween(old_logo, {y: old_logo.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});
		}

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('title/newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxG.mouse.visible = false;

		if (initialized)
			skipIntro();
		else
			initialized = true;
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if(titleText != null)
				titleText.animation.play('press');

			FlxG.camera.flash(FlxColor.WHITE, 1);

			if (FlxG.save.data.oldTitle)
				FlxG.sound.play(Paths.music("titleShoot"), 0.7);
			else
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				// Check if version is outdated
				trace("Current version of the game is: " + version + "!");

				FlxG.switchState(new MainMenuState());
			});

			// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
		}

		if (pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i].toUpperCase(), true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String)
	{
		var coolText:Alphabet = new Alphabet(0, 0, text.toUpperCase(), true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (!FlxG.save.data.oldTitle)
		{
			logoBl.animation.play('bump');
			danceLeft = !danceLeft;
	
			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
	
			switch (curBeat)
			{
				case 1:
					createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8r']);
				case 3:
					addMoreText('present');
				case 4:
					deleteCoolText();
				case 5:
					createCoolText(['In association', 'with']);
				case 7:
					addMoreText('newgrounds');
					ngSpr.visible = true;
				case 8:
					deleteCoolText();
					ngSpr.visible = false;
				case 9:
					createCoolText([curWacky[0]]);
				case 11:
					addMoreText(curWacky[1]);
				case 12:
					deleteCoolText();
				case 13:
					addMoreText('Friday');
				case 14:
					addMoreText('Night');
				case 15:
					addMoreText('Funkin');
				case 16:
					skipIntro();
			}
		} else {
			remove(ngSpr);
			remove(credGroup);
			skippedIntro = true;
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(ngSpr);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
