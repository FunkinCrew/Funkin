package states;

import utilities.Options;
import utilities.NoteVariables;
#if discord_rpc
import utilities.Discord.DiscordClient;
#end

import flixel.system.FlxVersion;
import substates.OutdatedSubState;
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

	static var firstTimeStarting:Bool = false;

	override public function create():Void
	{
		MusicBeatState.windowNameSuffix = "";

		if(!firstTimeStarting)
		{
			persistentUpdate = true;
			persistentDraw = true;
	
			FlxG.fixedTimestep = false;
	
			SaveData.init();

			#if desktop
			PolymodHandler.loadMods();
			#end

			MusicBeatState.windowNamePrefix = Assets.getText(Paths.txt("windowTitleBase", "preload"));

			NoteVariables.init();

			Options.fixBinds();

			if(utilities.Options.getData("flashingLights") == null)
				FlxG.switchState(new FlashingLightsMenu());
	
			curWacky = FlxG.random.getObject(getIntroTextShit());

			super.create();
	
			#if discord_rpc
			if(!DiscordClient.started && utilities.Options.getData("discordRPC"))
				DiscordClient.initialize();

			Application.current.onExit.add(function (exitCode) {
				DiscordClient.shutdown();
			}, false, 100);
			#end

			Application.current.onExit.add(function (exitCode) {
				for(key in Options.saves.keys())
				{
					if(key != null)
						Options.saves.get(key).close();
				}
			}, false, 101);

			firstTimeStarting = true;
		}

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});
	}

	var old_logo:FlxSprite;
	var old_logo_black:FlxSprite;

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	public static var version:String = "v0.3";

	public static var version_New:String = "v0.3";

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

			if (utilities.Options.getData("oldTitle"))
			{
				playTitleMusic();
			}
			else {
				if (Date.now().getDay() == 5 && Date.now().getHours() >= 18 || utilities.Options.getData("nightMusic"))
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

			Main.toggleFPS(utilities.Options.getData("fpsCounter"));
			Main.toggleMem(utilities.Options.getData("memoryCounter"));
			Main.toggleVers(utilities.Options.getData("versionDisplay"));

			Main.changeFont(utilities.Options.getData("infoDisplayFont"));
		}

		version = MusicBeatState.windowNamePrefix + " Release v" + Assets.getText("version.txt");

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();

		if (utilities.Options.getData("oldTitle"))
		{
			bg.loadGraphic(Paths.image("title/stageback"));
			bg.antialiasing = true;
			bg.setGraphicSize(Std.int(FlxG.width * 1.1));
			bg.updateHitbox();
			bg.screenCenter();
		}
		else
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		add(bg);

		if (utilities.Options.getData("oldTitle"))
		{
			old_logo = new FlxSprite().loadGraphic(Paths.image('title/logo'));
			old_logo.screenCenter();
			old_logo.antialiasing = true;

			old_logo_black = new FlxSprite().loadGraphicFromSprite(old_logo);
			old_logo_black.screenCenter();
			old_logo_black.color = FlxColor.BLACK;
		}
		else
		{
			logoBl = new FlxSprite(0, 0);
			
			if(utilities.Options.getData("watermarks"))
				logoBl.frames = Paths.getSparrowAtlas('title/leatherLogoBumpin');
			else
				logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');

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

		if (!utilities.Options.getData("oldTitle"))
		{
			add(logoBl);
			add(gfDance);
			add(titleText);
		}

		if (utilities.Options.getData("oldTitle"))
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

		if(utilities.Options.getData("watermarks"))
			titleTextData = CoolUtil.coolTextFile(Paths.txt("watermarkTitleText", "preload"));
		else
			titleTextData = CoolUtil.coolTextFile(Paths.txt("titleText", "preload"));

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

			if(utilities.Options.getData("flashingLights"))
				FlxG.camera.flash(FlxColor.WHITE, 1);

			if (utilities.Options.getData("oldTitle"))
				FlxG.sound.play(Paths.music("titleShoot"), 0.7);
			else
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				var http = new haxe.Http("https://raw.githubusercontent.com/Leather128/LeatherEngine/master/version.txt");
				
				http.onData = function(data:String)
				{
					trace(data);
					
					var new_Vers:Array<String> = data.split(".");
					var old_Vers:Array<String> = Assets.getText("version.txt").split(".");

					var new_Ver:FlxVersion = new FlxVersion(Std.parseInt(new_Vers[0]), Std.parseInt(new_Vers[1]), Std.parseInt(new_Vers[2]));
					var old_Ver:FlxVersion = new FlxVersion(Std.parseInt(old_Vers[0]), Std.parseInt(old_Vers[1]), Std.parseInt(old_Vers[2]));

					var older:Bool = false;

					if(
						new_Ver.patch > old_Ver.patch && new_Ver.minor >= old_Ver.minor && new_Ver.major >= old_Ver.major || 
						new_Ver.minor > old_Ver.minor && new_Ver.major >= old_Ver.major || 
						new_Ver.major > old_Ver.major
					)
						older = true;

				  	if(older)
					{
						trace('outdated lmao! ' + new_Vers + ' != ' + old_Vers);

						version_New = "v" + data;
						FlxG.switchState(new OutdatedSubState());
					}
					else
					{
						FlxG.switchState(new MainMenuState());
					}
				}
				
				http.onError = function (error) {
					trace('error: $error');
					FlxG.switchState(new MainMenuState()); // fail so we go anyway
				}
				
				http.request();
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
			addMoreText(textArray[i]);
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

	function textDataText(line:Int)
	{
		var lineText:Null<String> = titleTextData[line];

		if(lineText != null)
		{
			if(lineText.contains("~"))
			{
				var coolText = lineText.split("~");
				createCoolText(coolText);
			}
			else
				addMoreText(lineText);
		}
	}

	public var titleTextData:Array<String>;

	override function beatHit()
	{
		super.beatHit();

		if (!utilities.Options.getData("oldTitle"))
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
					textDataText(0);
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 12";
					else
						MusicBeatState.windowNameSuffix = "";
				case 3:
					textDataText(1);
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 11";
					else
						MusicBeatState.windowNameSuffix = "";
				case 4:
					deleteCoolText();
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 10";
					else
						MusicBeatState.windowNameSuffix = "";
				case 5:
					textDataText(2);
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 9";
					else
						MusicBeatState.windowNameSuffix = "";
				case 7:
					textDataText(3);
					ngSpr.visible = true;
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 8";
					else
						MusicBeatState.windowNameSuffix = "";
				case 8:
					deleteCoolText();
					ngSpr.visible = false;
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 7";
					else
						MusicBeatState.windowNameSuffix = "";
				case 9:
					createCoolText([curWacky[0]]);
					if(!skippedIntro)	
						MusicBeatState.windowNameSuffix = " 6";
					else
						MusicBeatState.windowNameSuffix = "";
				case 11:
					addMoreText(curWacky[1]);
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 5";
					else
						MusicBeatState.windowNameSuffix = "";
				case 12:
					deleteCoolText();
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 4";
					else
						MusicBeatState.windowNameSuffix = "";
				case 13:
					textDataText(4);
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 3";
					else
						MusicBeatState.windowNameSuffix = "";
				case 14:
					textDataText(5);
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 2";
					else
						MusicBeatState.windowNameSuffix = "";
				case 15:
					textDataText(6);
					if(!skippedIntro)
						MusicBeatState.windowNameSuffix = " 1";
					else
						MusicBeatState.windowNameSuffix = "";
				case 16:
					skipIntro();
			}
		} else {
			remove(ngSpr);
			remove(credGroup);
			skippedIntro = true;
			MusicBeatState.windowNameSuffix = "";
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			MusicBeatState.windowNameSuffix = "";
			
			if(utilities.Options.getData("flashingLights"))
				FlxG.camera.flash(FlxColor.WHITE, 4);

			remove(ngSpr);
			remove(credGroup);
			skippedIntro = true;
		}
	}
}
