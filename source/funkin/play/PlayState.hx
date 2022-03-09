package funkin.play;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.Note;
import funkin.Section.SwagSection;
import funkin.SongLoad.SwagSong;
import funkin.charting.ChartingState;
import funkin.play.stage.Stage;
import funkin.play.stage.StageData;
import funkin.shaderslmfao.ColorSwap;
import funkin.ui.PopUpStuff;
import funkin.ui.PreferencesMenu;
import haxe.Json;
import lime.ui.Haptic;
import lime.utils.Assets;

using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end

class PlayState extends MusicBeatState
{
	// TODO: Reorganize these variables (maybe there should be a separate class like Conductor just to hold them?)
	public static var curStageId:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var deathCounter:Int = 0;
	public static var practiceMode:Bool = false;
	public static var needsReset:Bool = false;

	private var vocals:VoicesGroup;
	private var vocalsFinished:Bool = false;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	/**
	 * Notes that should be ON SCREEN and have UPDATES running on them!
	 */
	private var notes:FlxTypedGroup<Note>;

	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;

	/**
	 * The currently active PlayState.
	 */
	public static var instance:PlayState = null;

	/**
	 * Strumline for player
	 */
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;

	public static var health:Float = 1;

	private var healthDisplay:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var dialogue:Array<String>;

	public static var seenCutscene:Bool = false;

	var talking:Bool = true;
	var songScore:Int = 0;
	var scoreTxt:FlxText;

	// Dunno why its called doof lol, it's just the dialogue box
	var doof:DialogueBox;

	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var inCutscene:Bool = false;

	#if discord_rpc
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var camPos:FlxPoint;

	var comboPopUps:PopUpStuff;

	override public function create()
	{
		instance = this;

		initCameras();

		// Starting health.
		health = 1;

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = SongLoad.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		// dialogue init shit, just for week 5 really (for now...?)
		switch (SONG.song.toLowerCase())
		{
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('songs/senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('songs/roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('songs/thorns/thornsDialogue'));
		}

		#if discord_rpc
		initDiscord();
		#end

		initStage();
		initCharacters();

		if (dialogue != null)
		{
			doof = new DialogueBox(false, dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
			doof.cameras = [camHUD];
		}

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);

		if (PreferencesMenu.getPref('downscroll'))
			strumLine.y = FlxG.height - 150; // 150 just random ass number lol

		strumLine.scrollFactor.set();
		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		// fake notesplash cache type deal so that it loads in the graphic?

		comboPopUps = new PopUpStuff();
		add(comboPopUps);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(noteSplash);
		noteSplash.alpha = 0.1;

		add(grpNoteSplashes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		generateSong();

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		resetCamFollow();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		if (PreferencesMenu.getPref('downscroll'))
			healthBarBG.y = FlxG.height * 0.1;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'healthDisplay', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, "", 20);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			seenCutscene = true;

			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					schoolIntro(doof); // doof is assumed to be non-null, lol!
				case 'ugh':
					ughIntro();
				case 'stress':
					stressIntro();
				case 'guns':
					gunsIntro();

				default:
					startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				// REMOVE THIS LATER
				// case 'ugh':
				// 	ughIntro();
				// case 'stress':
				// 	stressIntro();
				// case 'guns':
				// 	gunsIntro();

				default:
					startCountdown();
			}
		}

		super.create();
	}

	function initCameras()
	{
		defaultCamZoom = FlxCamera.defaultZoom;

		defaultCamZoom *= 1.05;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.sound.cache(Paths.inst(PlayState.SONG.song));
		FlxG.sound.cache(Paths.voices(PlayState.SONG.song));

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
	}

	function initStage()
	{
		// TODO: Move stageId to the song file.
		switch (SONG.song.toLowerCase())
		{
			case 'spookeez' | 'monster' | 'south':
				curStageId = "spookyMansion";
			case 'pico' | 'blammed' | 'philly':
				curStageId = 'phillyTrain';
			case "milf" | 'satin-panties' | 'high':
				curStageId = 'limoRide';
			case "cocoa" | 'eggnog':
				curStageId = 'mallXmas';
			case 'winter-horrorland':
				curStageId = 'mallEvil';
			case 'pyro':
				curStageId = 'pyro';
			case 'senpai' | 'roses':
				curStageId = 'school';
			case "darnell":
				curStageId = 'phillyStreets';
			case 'thorns':
				curStageId = 'schoolEvil';
			case 'guns' | 'stress' | 'ugh':
				curStageId = 'tankmanBattlefield';
			default:
				curStageId = "mainStage";
		}
		loadStage(curStageId);
	}

	function initCharacters()
	{
		// all dis is shitty, redo later for stage shit
		var gfVersion:String = 'gf';

		switch (curStageId)
		{
			case 'limoRide':
				gfVersion = 'gf-car';
			case 'mallXmas' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school' | 'schoolEvil':
				gfVersion = 'gf-pixel';
			case 'tankmanBattlefield':
				gfVersion = 'gf-tankmen';
		}

		if (SONG.player1 == "pico")
		{
			gfVersion = "nene";
		}

		if (SONG.song.toLowerCase() == 'stress')
			gfVersion = 'pico-speaker';

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		switch (gfVersion)
		{
			case 'pico-speaker':
				gf.x -= 50;
				gf.y -= 200;
		}

		dad = new Character(100, 100, SONG.player2);

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai' | 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'tankman':
				dad.y += 180;
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);

		// REPOSITIONING PER STAGE
		switch (curStageId)
		{
			case 'schoolEvil':
				// trailArea.scrollFactor.set();

				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
			// evilTrail.scrollFactor.set(1.1, 1.1);
			case "tank":
				gf.y += 10;
				gf.x -= 30;
				boyfriend.x += 40;
				boyfriend.y += 0;
				dad.y += 60;
				dad.x -= 80;

				if (gfVersion != 'pico-speaker')
				{
					gf.x -= 170;
					gf.y -= 75;
				}
		}

		if (curStage != null)
		{
			// We're using Eric's stage handler.
			// Characters get added to the stage, not the main scene.
			curStage.addCharacter(gf, GF);
			curStage.addCharacter(boyfriend, BF);
			curStage.addCharacter(dad, DAD);

			// Redo z-indexes.
			curStage.refresh();
		}
		else
		{
			add(gf);
			add(dad);
			add(boyfriend);
		}
	}

	function ughIntro()
	{
		inCutscene = true;

		var blackShit:FlxSprite = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);

		#if html5
		var vid:FlxVideo = new FlxVideo('music/ughCutscene.mp4');
		vid.finishCallback = function()
		{
			remove(blackShit);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
			startCountdown();
			cameraMovement();
		};
		#else
		remove(blackShit);
		FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
		startCountdown();
		cameraMovement();
		#end

		FlxG.camera.zoom = defaultCamZoom * 1.2;

		camFollow.x += 100;
		camFollow.y += 100;

		/* 
			FlxG.sound.playMusic(Paths.music('DISTORTO'), 0);
			FlxG.sound.music.fadeIn(5, 0, 0.5);

			dad.visible = false;
			var tankCutscene:TankCutscene = new TankCutscene(-20, 320);
			tankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong1');
			tankCutscene.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
			tankCutscene.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
			tankCutscene.animation.play('wellWell');
			tankCutscene.antialiasing = true;
			gfCutsceneLayer.add(tankCutscene);

			camHUD.visible = false;

			FlxG.camera.zoom *= 1.2;
			camFollow.y += 100;

			tankCutscene.startSyncAudio = FlxG.sound.load(Paths.sound('wellWellWell'));

			new FlxTimer().start(3, function(tmr:FlxTimer)
			{
				camFollow.x += 800;
				camFollow.y += 100;
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 0.27, {ease: FlxEase.quadInOut});

				new FlxTimer().start(1.5, function(bep:FlxTimer)
				{
					boyfriend.playAnim('singUP');
					// play sound
					FlxG.sound.play(Paths.sound('bfBeep'), function()
					{
						boyfriend.playAnim('idle');
					});
				});

				new FlxTimer().start(3, function(swaggy:FlxTimer)
				{
					camFollow.x -= 800;
					camFollow.y -= 100;
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 0.5, {ease: FlxEase.quadInOut});
					tankCutscene.animation.play('killYou');
					FlxG.sound.play(Paths.sound('killYou'));
					new FlxTimer().start(6.1, function(swagasdga:FlxTimer)
					{
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});

						FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 5, 0);

						new FlxTimer().start((Conductor.crochet / 1000) * 5, function(money:FlxTimer)
						{
							dad.visible = true;
							gfCutsceneLayer.remove(tankCutscene);
						});

						cameraMovement();

						startCountdown();
						camHUD.visible = true;
					});
				});
		});*/
	}

	/**
	 * Removes any references to the current stage, then clears the stage cache,
	 * then reloads all the stages.
	 * 
	 * This is useful for when you want to edit a stage without reloading the whole game.
	 * Reloading works on both the JSON and the HXC, if applicable.
	 * 
	 * Call this by pressing F5 on a debug build.
	 */
	function debug_refreshStages()
	{
		// Remove the current stage. If the stage gets deleted while it's still in use,
		// it'll probably crash the game or something.
		if (this.curStage != null)
		{
			remove(curStage);
			curStage.kill();
			curStage = null;
		}

		// Forcibly reload scripts so that scripted stages can be edited.
		polymod.hscript.PolymodScriptClass.clearScriptClasses();
		polymod.hscript.PolymodScriptClass.registerAllScriptClasses();

		// Reload the stages in cache. This might cause a lag spike but who cares this is a debug utility.
		StageDataParser.loadStageCache();

		// Reload the level. This should use new data from the assets folder.
		LoadingState.loadAndSwitchState(new PlayState());
	}

	public var curStage:Stage;

	/**
	 * Loads stage data from cache, assembles the props,
	 * and adds it to the state.
	 * @param id 
	 */
	function loadStage(id:String)
	{
		curStage = StageDataParser.fetchStage(id);

		if (curStage != null)
		{
			// Actually create and position the sprites.
			curStage.buildStage();

			// Apply camera zoom.
			defaultCamZoom *= curStage.camZoom;

			// Add the stage to the scene.
			this.add(curStage);
		}
	}

	function gunsIntro()
	{
		inCutscene = true;

		var blackShit:FlxSprite = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);

		#if html5
		var vid:FlxVideo = new FlxVideo('music/gunsCutscene.mp4');
		vid.finishCallback = function()
		{
			remove(blackShit);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
			startCountdown();
			cameraMovement();
		};
		#else
		remove(blackShit);

		FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
		startCountdown();
		cameraMovement();
		#end

		/* camFollow.setPosition(camPos.x, camPos.y);

			camHUD.visible = false;

			FlxG.sound.playMusic(Paths.music('DISTORTO'), 0);
			FlxG.sound.music.fadeIn(5, 0, 0.5);

			camFollow.y += 100;

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.3}, 4, {ease: FlxEase.quadInOut});

			dad.visible = false;
			var tankCutscene:TankCutscene = new TankCutscene(20, 320);
			tankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong2');
			tankCutscene.animation.addByPrefix('tankyguy', 'TANK TALK 2', 24, false);
			tankCutscene.animation.play('tankyguy');
			tankCutscene.antialiasing = true;
			gfCutsceneLayer.add(tankCutscene); // add();

			tankCutscene.startSyncAudio = FlxG.sound.load(Paths.sound('tankSong2'));

			new FlxTimer().start(4.1, function(ugly:FlxTimer)
			{
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.4}, 0.4, {ease: FlxEase.quadOut});
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.3}, 0.7, {ease: FlxEase.quadInOut, startDelay: 0.45});

				gf.playAnim('sad');
			});

			new FlxTimer().start(11, function(tmr:FlxTimer)
			{
				FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 5, 0);

				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet * 5) / 1000, {ease: FlxEase.quartIn});
				startCountdown();
				new FlxTimer().start((Conductor.crochet * 25) / 1000, function(daTim:FlxTimer)
				{
					dad.visible = true;
					gfCutsceneLayer.remove(tankCutscene);
				});

				camHUD.visible = true;
		});*/
	}

	/**
	 * [
	 * 	[0, function(){blah;}],
	 * 	[4.6, function(){blah;}],
	 * 	[25.1, function(){blah;}],
	 * 	[30.7, function(){blah;}]
	 * ]
	 * SOMETHING LIKE THIS
	 */
	// var cutsceneFunctions:Array<Dynamic> = [];

	function stressIntro()
	{
		inCutscene = true;

		var blackShit:FlxSprite = new FlxSprite(-200, -200).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackShit.scrollFactor.set();
		add(blackShit);

		#if html5
		var vid:FlxVideo = new FlxVideo('music/stressCutscene.mp4');
		vid.finishCallback = function()
		{
			remove(blackShit);

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
			startCountdown();
			cameraMovement();
		};
		#else
		remove(blackShit);

		FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
		startCountdown();
		cameraMovement();
		#end

		/* camHUD.visible = false;

			// for story mode shit
			camFollow.setPosition(camPos.x, camPos.y);

			var dummyLoaderShit:FlxGroup = new FlxGroup();

			add(dummyLoaderShit);

			for (i in 0...7)
			{
				var dummyLoader:FlxSprite = new FlxSprite();
				dummyLoader.loadGraphic(Paths.image('cutsceneStuff/gfHoldup-' + i));
				dummyLoaderShit.add(dummyLoader);
				dummyLoader.alpha = 0.01;
				dummyLoader.y = FlxG.height - 20;
				// dummyLoader.drawFrame(true);
			}

			dad.visible = false;

			// gf.y += 300;
			gf.alpha = 0.01;

			var gfTankmen:FlxSprite = new FlxSprite(210, 70);
			gfTankmen.frames = Paths.getSparrowAtlas('characters/gfTankmen');
			gfTankmen.animation.addByPrefix('loop', 'GF Dancing at Gunpoint', 24, true);
			gfTankmen.animation.play('loop');
			gfTankmen.antialiasing = true;
			gfCutsceneLayer.add(gfTankmen);

			var tankCutscene:TankCutscene = new TankCutscene(-70, 320);
			tankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong3-pt1');
			tankCutscene.animation.addByPrefix('tankyguy', 'TANK TALK 3 P1 UNCUT', 24, false);
			// tankCutscene.animation.addByPrefix('weed', 'sexAmbig', 24, false);
			tankCutscene.animation.play('tankyguy');

			tankCutscene.antialiasing = true;
			bfTankCutsceneLayer.add(tankCutscene); // add();

			var alsoTankCutscene:FlxSprite = new FlxSprite(20, 320);
			alsoTankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong3-pt2');
			alsoTankCutscene.animation.addByPrefix('swagTank', 'TANK TALK 3 P2 UNCUT', 24, false);
			alsoTankCutscene.antialiasing = true;

			bfTankCutsceneLayer.add(alsoTankCutscene);

			alsoTankCutscene.y = FlxG.height + 100;

			camFollow.setPosition(gf.x + 350, gf.y + 560);
			FlxG.camera.focusOn(camFollow.getPosition());

			boyfriend.visible = false;

			var fakeBF:Character = new Character(boyfriend.x, boyfriend.y, 'bf', true);
			bfTankCutsceneLayer.add(fakeBF);

			// var atlasCutscene:Animation
			// var animAssets:AssetManager = new AssetManager();

			// var url = 'images/gfDemon';

			// // animAssets.enqueueSingle(Paths.file(url + "/spritemap1.png"));
			// // animAssets.enqueueSingle(Paths.file(url + "/spritemap1.json"));
			// // animAssets.enqueueSingle(Paths.file(url + "/Animation.json"));

			// animAssets.loadQueue(function(asssss:AssetManager)
			// {
			// 	var daAnim:Animation = asssss.createAnimation('GF Turnin Demon W Effect');
			// 	FlxG.addChildBelowMouse(daAnim);
			// });

			var bfCatchGf:FlxSprite = new FlxSprite(boyfriend.x - 10, boyfriend.y - 90);
			bfCatchGf.frames = Paths.getSparrowAtlas('cutsceneStuff/bfCatchesGF');
			bfCatchGf.animation.addByPrefix('catch', 'BF catches GF', 24, false);
			bfCatchGf.antialiasing = true;
			add(bfCatchGf);
			bfCatchGf.visible = false;

			if (PreferencesMenu.getPref('censor-naughty'))
				tankCutscene.startSyncAudio = FlxG.sound.play(Paths.sound('stressCutscene'));
			else
			{
				tankCutscene.startSyncAudio = FlxG.sound.play(Paths.sound('song3censor'));
				// cutsceneSound.loadEmbedded(Paths.sound('song3censor'));

				var censor:FlxSprite = new FlxSprite();
				censor.frames = Paths.getSparrowAtlas('cutsceneStuff/censor');
				censor.animation.addByPrefix('censor', 'mouth censor', 24);
				censor.animation.play('censor');
				add(censor);
				censor.visible = false;
				//

				new FlxTimer().start(4.6, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 160, dad.y + 180);

					new FlxTimer().start(0.2, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});

				new FlxTimer().start(25.1, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 120, dad.y + 170);

					new FlxTimer().start(0.9, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});

				new FlxTimer().start(30.7, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 210, dad.y + 190);

					new FlxTimer().start(0.4, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});

				new FlxTimer().start(33.8, function(censorTimer:FlxTimer)
				{
					censor.visible = true;
					censor.setPosition(dad.x + 180, dad.y + 170);

					new FlxTimer().start(0.6, function(endThing:FlxTimer)
					{
						censor.visible = false;
					});
				});
			}

			// new FlxTimer().start(0.01, function(tmr) cutsceneSound.play()); // cutsceneSound.play();
			// cutsceneSound.play();
			// tankCutscene.startSyncAudio = cutsceneSound;
			// tankCutscene.animation.curAnim.curFrame

			FlxG.camera.zoom = defaultCamZoom * 1.15;

			camFollow.x -= 200;

			// cutsceneSound.onComplete = startCountdown;

			// Cunt 1
			new FlxTimer().start(31.5, function(cunt:FlxTimer)
			{
				camFollow.x += 400;
				camFollow.y += 150;
				FlxG.camera.zoom = defaultCamZoom * 1.4;
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.1}, 0.5, {ease: FlxEase.elasticOut});
				FlxG.camera.focusOn(camFollow.getPosition());
				boyfriend.playAnim('singUPmiss');
				boyfriend.animation.finishCallback = function(animFinish:String)
				{
					camFollow.x -= 400;
					camFollow.y -= 150;
					FlxG.camera.zoom /= 1.4;
					FlxG.camera.focusOn(camFollow.getPosition());

					boyfriend.animation.finishCallback = null;
				};
			});

			new FlxTimer().start(15.1, function(tmr:FlxTimer)
			{
				camFollow.y -= 170;
				camFollow.x += 200;
				FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom * 1.3}, 2.1, {
					ease: FlxEase.quadInOut
				});

				new FlxTimer().start(2.2, function(swagTimer:FlxTimer)
				{
					// FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.7, {ease: FlxEase.elasticOut});
					FlxG.camera.zoom = 0.8;
					// camFollow.y -= 100;
					boyfriend.visible = false;
					bfCatchGf.visible = true;
					bfCatchGf.animation.play('catch');

					bfTankCutsceneLayer.remove(fakeBF);

					bfCatchGf.animation.finishCallback = function(anim:String)
					{
						bfCatchGf.visible = false;
						boyfriend.visible = true;
					};

					new FlxTimer().start(3, function(weedShitBaby:FlxTimer)
					{
						camFollow.y += 180;
						camFollow.x -= 80;
					});

					new FlxTimer().start(2.3, function(gayLol:FlxTimer)
					{
						bfTankCutsceneLayer.remove(tankCutscene);
						alsoTankCutscene.y = 320;
						alsoTankCutscene.animation.play('swagTank');
						// tankCutscene.animation.play('weed');
					});
				});

				gf.visible = false;
				var cutsceneShit:CutsceneCharacter = new CutsceneCharacter(210, 70, 'gfHoldup');
				gfCutsceneLayer.add(cutsceneShit);
				gfCutsceneLayer.remove(gfTankmen);

				cutsceneShit.onFinish = function()
				{
					gf.alpha = 1;
					gf.visible = true;
				};

				// add(cutsceneShit);
				new FlxTimer().start(20, function(alsoTmr:FlxTimer)
				{
					dad.visible = true;
					bfTankCutsceneLayer.remove(alsoTankCutscene);
					startCountdown();
					remove(dummyLoaderShit);
					dummyLoaderShit.destroy();
					dummyLoaderShit = null;

					gfCutsceneLayer.remove(cutsceneShit);
				});
		});*/
	}

	function initDiscord():Void
	{
		#if discord_rpc
		storyDifficultyText = difficultyString();
		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		detailsText = isStoryMode ? "Story Mode: Week " + storyWeek : "Freeplay";
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * daPixelZoom));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		camFollow.setPosition(camPos.x, camPos.y);

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
			else
				FlxG.sound.play(Paths.sound('ANGRY'));
			// moved senpai angry noise in here to clean up cutscene switch case lol
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
								swagTimer.reset();
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer = new FlxTimer();
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;
		camHUD.visible = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;

		restartCountdownTimer();
	}

	function restartCountdownTimer():Void
	{
		startedCountdown = true;

		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer.start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			// this just based on beatHit stuff but compact
			if (swagCounter % gfSpeed == 0)
				gf.dance();
			if (swagCounter % 2 == 0)
			{
				if (boyfriend.animation != null)
				{
					if (!boyfriend.animation.curAnim.name.startsWith("sing"))
						boyfriend.playAnim('idle');
				}

				if (dad.animation != null)
				{
					if (!dad.animation.curAnim.name.startsWith("sing"))
						dad.dance();
				}
			}
			else if (dad.curCharacter == 'spooky' && !dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
			if (generatedMusic)
				notes.sort(sortNotes, FlxSort.DESCENDING);

			var introSprPaths:Array<String> = ["ready", "set", "go"];
			var altSuffix:String = "";

			if (curStageId.startsWith("school"))
			{
				altSuffix = '-pixel';
				introSprPaths = ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel'];
			}

			var introSndPaths:Array<String> = [
				"intro3" + altSuffix, "intro2" + altSuffix,
				"intro1" + altSuffix, "introGo" + altSuffix
			];

			if (swagCounter > 0)
				readySetGo(introSprPaths[swagCounter - 1]);
			FlxG.sound.play(Paths.sound(introSndPaths[swagCounter]), 0.6);

			/* switch (swagCounter)
				{
					case 0:
						
					case 1:
						
					case 2:
						
					case 3:
						
			}*/

			swagCounter += 1;
		}, 4);
	}

	function readySetGo(path:String):Void
	{
		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(path));
		spr.scrollFactor.set();

		if (curStageId.startsWith('school'))
			spr.setGraphicSize(Std.int(spr.width * daPixelZoom));

		spr.updateHitbox();
		spr.screenCenter();
		add(spr);
		FlxTween.tween(spr, {y: spr.y += 100, alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				spr.destroy();
			}
		});
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		if (!paused)
		{
			// if (FlxG.sound.music != null)
			// FlxG.sound.music.play(true);
			// else
			FlxG.sound.playMusic(Paths.inst(SONG.song), 1, false);
		}

		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		#if discord_rpc
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end
	}

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());

		Conductor.changeBPM(SONG.bpm);

		curSong = SONG.song;

		if (SONG.needsVoices)
			vocals = new VoicesGroup(SONG.song, SONG.voiceList);
		else
			vocals = new VoicesGroup(SONG.song, null, false);

		vocals.members[0].onComplete = function()
		{
			vocalsFinished = true;
		};

		notes = new FlxTypedGroup<Note>();
		add(notes);

		regenNoteData();

		generatedMusic = true;
	}

	function regenNoteData():Void
	{
		// make unspawn notes shit def empty
		unspawnNotes = [];

		notes.forEach(function(nt)
		{
			nt.followsTime = false;
			FlxTween.tween(nt, {y: FlxG.height + nt.y}, 0.5, {
				ease: FlxEase.expoIn,
				onComplete: function(twn)
				{
					nt.kill();
					notes.remove(nt, true);
					nt.destroy();
				}
			});
		});

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = SongLoad.getSong();

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes.strumTime;
				var daNoteData:Int = Std.int(songNotes.noteData % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes.highStakes)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.data = songNotes;
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.data.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.round(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}
		}

		unspawnNotes.sort(sortByShit);
	}

	// Now you are probably wondering why I made 2 of these very similar functions
	// sortByShit(), and sortNotes(). sortNotes is meant to be used by both sortByShit(), and the notes FlxGroup
	// sortByShit() is meant to be used only by the unspawnNotes array.
	// and the array sorting function doesnt need that order variable thingie
	// this is good enough for now lololol HERE IS COMMENT FOR THIS SORTA DUMB DECISION LOL
	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return sortNotes(FlxSort.ASCENDING, Obj1, Obj2);
	}

	function sortNotes(order:Int = FlxSort.ASCENDING, Obj1:Note, Obj2:Note)
	{
		return FlxSort.byValues(order, Obj1.data.strumTime, Obj2.data.strumTime);
	}

	// ^ These two sorts also look cute together ^

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			var colorswap:ColorSwap = new ColorSwap();
			babyArrow.shader = colorswap.shader;
			colorswap.update(Note.arrowColors[i]);

			switch (curStageId)
			{
				case 'school' | 'schoolEvil':
					babyArrow.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels'), true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
					}

				default:
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 1');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 2');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 4');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrow static instance 3');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (player == 1)
				playerStrums.add(babyArrow);

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3 * FlxCamera.defaultZoom}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if discord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		super.closeSubState();
	}

	#if discord_rpc
	override public function onFocus():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
		{
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);

		super.onFocusLost();
	}
	#end

	function resyncVocals():Void
	{
		if (_exiting)
			return;

		vocals.pause();
		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time + Conductor.offset;

		if (vocalsFinished)
			return;

		vocals.time = FlxG.sound.music.time;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		healthDisplay = FlxMath.lerp(healthDisplay, health, 0.15);

		if (needsReset)
		{
			resetCamFollow();

			paused = false;
			persistentUpdate = true;
			persistentDraw = true;

			startingSong = true;

			FlxG.sound.music.pause();
			vocals.pause();

			curStage.resetStage();

			FlxG.sound.music.time = 0;
			regenNoteData(); // loads the note data from start
			health = 1;
			restartCountdownTimer();

			needsReset = false;

			// FlxScreenGrab.grab(null, true, true);

			/* 
				var png:ByteArray = new ByteArray();
				png = FlxG.camera.screen.pixels.encode(FlxG.camera.screen.pixels.rect, new PNGEncoderOptions());
				var f = sys.io.File.write('./swag.png', true);
				f.writeString(png.readUTFBytes(png.length));
				f.close();
			 */
			// sys.io.File.saveContent('./swag.png', png.readUTFBytes(png.length));
		}

		#if !debug
		perfectMode = false;
		#else
		if (FlxG.keys.justPressed.H)
			camHUD.visible = !camHUD.visible;
		if (FlxG.keys.justPressed.K)
		{
			// @:privateAccess
			// var funnyData:Array<Int> = cast FlxG.sound.music._channel.__source.buffer.data;

			// funnyData.reverse();

			// @:privateAccess
			// FlxG.sound.music._channel.__source.buffer.data = cast funnyData;
		}
		#end

		// do this BEFORE super.update() so songPosition is accurate
		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			if (Paths.SOUND_EXT == 'mp3')
				Conductor.offset = -13; // DO NOT FORGET TO REMOVE THE HARDCODE! WHEN I MAKE BETTER OFFSET SYSTEM!

			Conductor.songPosition = FlxG.sound.music.time + Conductor.offset; // 20 is THE MILLISECONDS??
			// Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}
			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		super.update(elapsed); // idk if there's a particular reason why some code is before super.update(), and some is after. Prob nothing too much to worry about.

		var androidPause:Bool = false;

		#if android
		androidPause = FlxG.android.justPressed.BACK;
		#end

		if ((controls.PAUSE || androidPause) && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// There is a 1/1000 change to use a special pause menu.
			// This prevents the player from resuming, but that's the point.
			// It's a reference to Gitaroo Man, which doesn't let you pause the game.
			if (FlxG.random.bool(1 / 1000))
			{
				FlxG.switchState(new GitarooPause());
			}
			else
			{
				var boyfriendPos = boyfriend.getScreenPosition();
				var pauseSubState = new PauseSubState(boyfriendPos.x, boyfriendPos.y);
				openSubState(pauseSubState);
				pauseSubState.camera = camHUD;
				boyfriendPos.put();
			}

			#if discord_rpc
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());

			#if discord_rpc
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// UI UPDATES
		scoreTxt.text = "Score:" + songScore;

		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new funkin.ui.animDebugShit.DebugBoundingState());

		if (FlxG.keys.justPressed.F5)
			debug_refreshStages();

		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon();

		iconP1.setGraphicSize(Std.int(CoolUtil.coolLerp(iconP1.width, 150, 0.15)));
		iconP2.setGraphicSize(Std.int(CoolUtil.coolLerp(iconP2.width, 150, 0.15)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.value, 0, 2, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.value, 0, 2, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();

		if (FlxG.keys.justPressed.PAGEUP)
			changeSection(1);
		if (FlxG.keys.justPressed.PAGEDOWN)
			changeSection(-1);
		#end

		if (generatedMusic && SongLoad.getSong()[Std.int(curStep / 16)] != null)
		{
			cameraRightSide = SongLoad.getSong()[Std.int(curStep / 16)].mustHitSection;

			cameraMovement();
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1 * FlxCamera.defaultZoom, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
			}
		}

		if (!inCutscene && !_exiting)
		{
			// RESET = Quick Game Over Screen
			if (controls.RESET)
			{
				health = 0;
				trace("RESET = True");
			}

			#if CAN_CHEAT // brandon's a pussy
			if (controls.CHEAT)
			{
				health += 1;
				trace("User is cheating!");
			}
			#end

			if (health <= 0 && !practiceMode)
			{
				// boyfriend.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.pause();
				FlxG.sound.music.pause();

				// unloadAssets();

				deathCounter += 1;

				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if discord_rpc
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
				#end
			}
		}

		while (unspawnNotes[0] != null && unspawnNotes[0].data.strumTime - Conductor.songPosition < 1800 / SongLoad.getSpeed())
		{
			var dunceNote:Note = unspawnNotes[0];
			notes.add(dunceNote);

			unspawnNotes.shift();
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if ((PreferencesMenu.getPref('downscroll') && daNote.y < -daNote.height)
					|| (!PreferencesMenu.getPref('downscroll') && daNote.y > FlxG.height))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				var strumLineMid = strumLine.y + Note.swagWidth / 2;

				if (daNote.followsTime)
					daNote.y = (Conductor.songPosition - daNote.data.strumTime) * (0.45 * FlxMath.roundDecimal(SongLoad.getSpeed(),
						2) * daNote.noteSpeedMulti);

				if (PreferencesMenu.getPref('downscroll'))
				{
					daNote.y += strumLine.y;
					if (daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith("end") && daNote.prevNote != null)
							daNote.y += daNote.prevNote.height;
						else
							daNote.y += daNote.height / 2;

						if ((!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
							&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLineMid)
						{
							applyClipRect(daNote);
						}
					}
				}
				else
				{
					if (daNote.followsTime)
						daNote.y = strumLine.y - daNote.y;
					if (daNote.isSustainNote
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
						&& daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
					{
						applyClipRect(daNote);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SongLoad.getSong()[Math.floor(curStep / 16)] != null)
					{
						if (SongLoad.getSong()[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					if (daNote.data.altNote)
						altAnim = '-alt';

					if (!daNote.isSustainNote)
					{
						dad.playAnim('sing' + daNote.dirNameUpper + altAnim, true);
					}

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * SONG.speed[SongLoad.curDiff]));

				// removing this so whether the note misses or not is entirely up to Note class
				// var noteMiss:Bool = daNote.y < -daNote.height;

				// if (PreferencesMenu.getPref('downscroll'))
				// noteMiss = daNote.y > FlxG.height;

				if (daNote.isSustainNote && daNote.wasGoodHit)
				{
					if ((!PreferencesMenu.getPref('downscroll') && daNote.y < -daNote.height)
						|| (PreferencesMenu.getPref('downscroll') && daNote.y > FlxG.height))
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
				else if (daNote.tooLate || daNote.wasGoodHit)
				{
					// TODO: Why the hell is the noteMiss logic in two different places?
					if (daNote.tooLate)
					{
						if (curStage != null)
						{
							curStage.onNoteMiss(daNote);
						}
						health -= 0.0775;
						vocals.volume = 0;
						killCombo();
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!inCutscene)
			keyShit();

		if (curStage != null)
		{
			// We're using Eric's stage handler.
			curStage.onUpdate(elapsed);
		}
	}

	function applyClipRect(daNote:Note):Void
	{
		// clipRect is applied to graphic itself so use frame Heights
		var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
		var strumLineMid = strumLine.y + Note.swagWidth / 2;

		if (PreferencesMenu.getPref('downscroll'))
		{
			swagRect.height = (strumLineMid - daNote.y) / daNote.scale.y;
			swagRect.y = daNote.frameHeight - swagRect.height;
		}
		else
		{
			swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
			swagRect.height -= swagRect.y;
		}

		daNote.clipRect = swagRect;
	}

	function killCombo():Void
	{
		if (combo > 5 && gf.animOffsets.exists('sad'))
			gf.playAnim('sad');

		if (combo != 0)
		{
			combo = comboPopUps.displayCombo(0);
		}
	}

	#if debug
	function changeSection(sec:Int):Void
	{
		FlxG.sound.music.pause();

		var daBPM:Float = SONG.bpm;
		var daPos:Float = 0;
		for (i in 0...(Std.int(curStep / 16 + sec)))
		{
			if (SongLoad.getSong()[i].changeBPM)
			{
				daBPM = SongLoad.getSong()[i].bpm;
			}
			daPos += 4 * (1000 * 60 / daBPM);
		}
		Conductor.songPosition = FlxG.sound.music.time = daPos;
		Conductor.songPosition += Conductor.offset;
		updateCurStep();
		resyncVocals();
	}
	#end

	function endSong():Void
	{
		seenCutscene = false;
		deathCounter = 0;
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore)
		{
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				switch (PlayState.storyWeek)
				{
					case 7:
						FlxG.switchState(new VideoState());
					default:
						FlxG.switchState(new StoryMenuState());
				}

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (SONG.validScore)
				{
					NGio.unlockMedal(60961);
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}

				FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficulty == 0)
					difficulty = '-easy';

				if (storyDifficulty == 2)
					difficulty = '-hard';

				trace('LOADING NEXT SONG');
				trace(storyPlaylist[0].toLowerCase() + difficulty);

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;

				FlxG.sound.music.stop();
				vocals.stop();

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					inCutscene = true;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'), function()
					{
						// no camFollow so it centers on horror tree
						SONG = SongLoad.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
						LoadingState.loadAndSwitchState(new PlayState());
					});
				}
				else
				{
					prevCamFollow = camFollow;

					SONG = SongLoad.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			// unloadAssets();
			FlxG.switchState(new FreeplayState());
		}
	}

	// gives score and pops up rating
	private function popUpScore(strumtime:Float, daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var score:Int = 350;
		var daRating:String = "sick";
		var isSick:Bool = false;
		var healthMulti:Float = 1;

		healthMulti *= daNote.lowStakes ? 0.002 : 0.033;

		if (noteDiff > Note.HIT_WINDOW * Note.BAD_THRESHOLD)
		{
			healthMulti *= 0; // no health on shit note
			daRating = 'shit';
			score = 50;
		}
		else if (noteDiff > Note.HIT_WINDOW * Note.GOOD_THRESHOLD)
		{
			healthMulti *= 0.2;
			daRating = 'bad';
			score = 100;
		}
		else if (noteDiff > Note.HIT_WINDOW * Note.SICK_THRESHOLD)
		{
			healthMulti *= 0.78;
			daRating = 'good';
			score = 200;
		}
		else
			isSick = true;

		health += healthMulti;

		// TODO: Redo note hit logic to make sure this always gets called
		if (curStage != null)
		{
			curStage.onNoteHit(daNote);
		}

		if (isSick)
		{
			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(daNote.x, daNote.y, daNote.data.noteData);
			// new NoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}

		// Only add the score if you're not on practice mode
		if (!practiceMode)
			songScore += score;

		comboPopUps.displayRating(daRating);

		if (combo >= 10 || combo == 0)
			comboPopUps.displayCombo(combo);
	}

	var cameraRightSide:Bool = false;

	function cameraMovement()
	{
		if (camFollow.x != dad.getMidpoint().x + 150 && !cameraRightSide)
		{
			camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

			switch (dad.curCharacter)
			{
				case 'mom':
					camFollow.y = dad.getMidpoint().y;
				case 'senpai' | 'senpai-angry':
					camFollow.y = dad.getMidpoint().y - 430;
					camFollow.x = dad.getMidpoint().x - 100;
			}

			if (dad.curCharacter == 'mom')
				vocals.volume = 1;

			if (SONG.song.toLowerCase() == 'tutorial')
				tweenCamIn();
		}

		if (cameraRightSide && camFollow.x != boyfriend.getMidpoint().x - 100)
		{
			camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStageId)
			{
				case 'limo':
					camFollow.x = boyfriend.getMidpoint().x - 300;
				case 'mall':
					camFollow.y = boyfriend.getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					camFollow.x = boyfriend.getMidpoint().x - 200;
					camFollow.y = boyfriend.getMidpoint().y - 200;
			}

			if (SONG.song.toLowerCase() == 'tutorial')
				FlxTween.tween(FlxG.camera, {zoom: 1 * FlxCamera.defaultZoom}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
		}
	}

	private function keyShit():Void
	{
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [controls.NOTE_LEFT, controls.NOTE_DOWN, controls.NOTE_UP, controls.NOTE_RIGHT];
		var pressArray:Array<Bool> = [
			controls.NOTE_LEFT_P,
			controls.NOTE_DOWN_P,
			controls.NOTE_UP_P,
			controls.NOTE_RIGHT_P
		];
		var releaseArray:Array<Bool> = [
			controls.NOTE_LEFT_R,
			controls.NOTE_DOWN_R,
			controls.NOTE_UP_R,
			controls.NOTE_RIGHT_R
		];
		/* 
			var widHalf = FlxG.width / 2;
			var heightHalf = FlxG.height / 2;

			if (FlxG.onMobile)
			{
				for (touch in FlxG.touches.list)
				{
					var getHeight:Int = Math.floor(touch.justPressedPosition.y / (FlxG.height / 3));
					var getWid:Int = Math.floor(touch.justPressedPosition.x / (FlxG.width / 4));
					if (touch.justPressed)
					{
						switch (getWid)
						{
							case 1:
								pressArray[3] = true;
							case 2:
								pressArray[0] = true;
							default:
								switch (getHeight)
								{
									case 0:
										pressArray[2] = true;
									case 1:
										touch.justPressedPosition.x < widHalf ? pressArray[0] = true : pressArray[3] = true;
									case 2:
										pressArray[1] = true;
								}
						}
					}

					switch (getWid)
					{
						case 1:
							holdArray[3] = true;

						case 2:
							holdArray[0] = true;

						default:
							switch (getHeight)
							{
								case 0:
									holdArray[2] = true;
								case 1:
									touch.justPressedPosition.x < widHalf ? holdArray[0] = true : holdArray[3] = true;
								case 2:
									holdArray[1] = true;
							}
					}
				}
			}
		 */

		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.data.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!boyfriend.stunned && */ generatedMusic)
		{
			Haptic.vibrate(100, 100);

			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (directionList.contains(daNote.data.noteData))
					{
						for (coolNote in possibleNotes)
						{
							if (coolNote.data.noteData == daNote.data.noteData
								&& Math.abs(daNote.data.strumTime - coolNote.data.strumTime) < 10)
							{ // if it's the same note twice at < 10ms distance, just delete it
								// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
								dumbNotes.push(daNote);
								break;
							}
							else if (coolNote.data.noteData == daNote.data.noteData && daNote.data.strumTime < coolNote.data.strumTime)
							{ // if daNote is earlier than existing note (coolNote), replace
								possibleNotes.remove(coolNote);
								possibleNotes.push(daNote);
								break;
							}
						}
					}
					else
					{
						possibleNotes.push(daNote);
						directionList.push(daNote.data.noteData);
					}
				}
			});

			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.data.strumTime);
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.data.strumTime - b.data.strumTime));

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0)
			{
				for (shit in 0...pressArray.length)
				{ // if a direction is hit that shouldn't be
					if (pressArray[shit] && !directionList.contains(shit))
						noteMiss(shit);
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.data.noteData])
						goodNoteHit(coolNote);
				}
			}
			else
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit);
			}
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !holdArray.contains(true))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !curStageId.startsWith('school'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function performCleanup()
	{
		// Uncache the song.
		openfl.utils.Assets.cache.clear(Paths.inst(SONG.song));
		openfl.utils.Assets.cache.clear(Paths.voices(SONG.song));

		// Remove reference to stage and remove sprites from it to save memory.
		if (curStage != null)
		{
			remove(curStage);
			curStage.kill();
			curStage = null;
		}

		// Clear the static reference to this state.
		instance = null;
	}

	/**
	 * This function is called before switching to a new FlxState.
	 */
	override function switchTo(nextState:FlxState):Bool
	{
		performCleanup();

		return super.switchTo(nextState);
	}

	function noteMiss(direction:NoteDir = 1):Void
	{
		// whole function used to be encased in if (!boyfriend.stunned)
		health -= 0.07;
		killCombo();

		if (!practiceMode)
			songScore -= 10;

		vocals.volume = 0;
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		/* boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
		});*/

		boyfriend.playAnim('sing' + direction.nameUpper + 'miss', true);
	}

	/* not used anymore lol

		function badNoteHit()
		{
			// just double pasting this shit cuz fuk u
			// REDO THIS SYSTEM!
			var leftP = controls.NOTE_LEFT_P;
			var downP = controls.NOTE_DOWN_P;
			var upP = controls.NOTE_UP_P;
			var rightP = controls.NOTE_RIGHT_P;

			if (leftP)
				noteMiss(0);
			if (downP)
				noteMiss(1);
			if (upP)
				noteMiss(2);
			if (rightP)
				noteMiss(3);
	}*/
	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note.data.strumTime, note);
			}

			boyfriend.playAnim('sing' + note.dirNameUpper, true);

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.data.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function resetCamFollow():Void
	{
		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());
	}

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if (curStage != null)
		{
			// We're using Eric's stage handler. The stage should know that a beat has been hit.
			curStage.onStepHit(curBeat);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(sortNotes, FlxSort.DESCENDING);
		}

		if (SongLoad.getSong()[Math.floor(curStep / 16)] != null)
		{
			if (SongLoad.getSong()[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SongLoad.getSong()[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[SongLoad.curDiff][Std.int(curStep / 16)].changeBPM);

		// HARDCODING FOR MILF ZOOMS!

		if (PreferencesMenu.getPref('camera-zoom'))
		{
			if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015 * FlxCamera.defaultZoom;
				camHUD.zoom += 0.03;
			}

			if (camZooming && FlxG.camera.zoom < (1.35 * FlxCamera.defaultZoom) && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015 * FlxCamera.defaultZoom;
				camHUD.zoom += 0.03;
			}
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var song = SongLoad.getSong();
		var step = Math.floor(curStep / 16);
		if (curBeat % 8 == 7
			&& song[step].mustHitSection
			&& combo > 5
			&& song.length > step + 1 // GK: this fixes an error on week 1 where song[step + 1] was null
			&& !song[step + 1].mustHitSection)
		{
			var animShit:ComboCounter = new ComboCounter(-100, 300, combo);
			animShit.scrollFactor.set(0.6, 0.6);
			// add(animShit);

			var frameShit:Float = (1 / 24) * 2; // equals 2 frames in the animation

			new FlxTimer().start(((Conductor.crochet / 1000) * 1.25) - frameShit, function(tmr)
			{
				animShit.forceFinish();
			});
		}

		if (curBeat % gfSpeed == 0)
			gf.dance();

		if (curBeat % 2 == 0)
		{
			if (boyfriend.animation != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
				boyfriend.playAnim('idle');
			if (dad.animation != null && !dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}
		else if (dad.curCharacter == 'spooky')
		{
			if (!dad.animation.curAnim.name.startsWith("sing"))
				dad.dance();
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		if (curStage != null)
		{
			// We're using Eric's stage handler. The stage should know that a beat has been hit.
			curStage.onBeatHit(curBeat);
		}
	}

	var curLight:Int = 0;
}

typedef StageData =
{
	var camZoom:Float;
	var propsBackground:Array<Props>;
}

typedef Props =
{
	var x:Float;
	var y:Float;
	var scrollX:Float;
	var scrollY:Float;
	var propname:String;
	var path:String;
	var scaleX:Float;
	var scaleY:Float;
	var ?animBullshit:PropAnimData;
	var ?updateHitbox:Bool;
	var ?antialiasing:Bool;
}

typedef PropAnimData =
{
	var isLooping:Bool;
	var anims:Array<String>;
}
