package states;

import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
#if sys
import sys.FileSystem;
#end

#if BIT_64
import modding.FlxVideo;
#end

#if discord_rpc
import utilities.Discord.DiscordClient;
#end

#if polymod
import polymod.backends.PolymodAssets;
#end

import flixel.system.FlxAssets.FlxShader;
import flixel.addons.display.FlxShaderMaskCamera;
import substates.ResultsScreenSubstate;
import haxe.Json;
import game.Replay;
import lime.utils.Assets;
import game.StrumNote;
import game.Cutscene;
import game.NoteSplash;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.tweens.misc.VarTween;
import modding.ModchartUtilities;
import lime.app.Application;
import utilities.NoteVariables;
import flixel.input.FlxInput.FlxInputState;
import utilities.NoteHandler;
import flixel.group.FlxGroup;
import utilities.Ratings;
import debuggers.ChartingState;
import game.Section.SwagSection;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import game.Note;
import ui.HealthIcon;
import ui.DialogueBox;
import game.Character;
import game.Boyfriend;
import game.StageGroup;
import game.Conductor;
import game.Song;
import utilities.CoolUtil;
import substates.PauseSubState;
import substates.GameOverSubstate;
import game.Highscore;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var storyDifficultyStr:String = "NORMAL";

	var halloweenLevel:Bool = false;

	private var vocals:FlxSound;

	public static var dad:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	public var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var stage:StageGroup;

	public static var strumLineNotes:FlxTypedGroup<StrumNote>;
	public static var playerStrums:FlxTypedGroup<StrumNote>;
	public static var enemyStrums:FlxTypedGroup<StrumNote>;
	private var splashes:FlxTypedGroup<NoteSplash>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var healthShown:Float = 1;
	private var maxHealth:Int = 2;
	private var combo:Int = 0;

	public var misses:Int = 0;
	public var mashes:Int = 0;
	public var accuracy:Float = 100.0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var timeBarBG:FlxSprite;
	private var timeBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;

	public static var currentBeat = 0;

	public var gfVersion:String = 'gf';

	var songScore:Int = 0;

	var scoreTxt:FlxText;
	var infoTxt:FlxText;

	public static var campaignScore:Int = 0;

	private var totalNotes:Int = 0;
	private var hitNotes:Float = 0.0;

	public var foregroundSprites:FlxGroup = new FlxGroup();

	var defaultCamZoom:Float = 1.05;
	var altAnim:String = "";

	public static var stepsTexts:Array<String>;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var inCutscene:Bool = false;

	public static var groupWeek:String = "";

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";

	var executeModchart:Bool = false;

	#if linc_luajit
	public static var luaModchart:ModchartUtilities = null;
	#end
	#end

	var binds:Array<String>;

	public var ui_Settings:Array<String>;
	public var mania_size:Array<String>;
	public var mania_offset:Array<String>;
	public var mania_gap:Array<String>;
	public var types:Array<String>;

	public var arrow_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();
	public var type_Configs:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function removeObject(object:FlxBasic)
	{
		remove(object);
	}

	var missSounds:Array<FlxSound> = [];

	public var splash_Texture:FlxFramesCollection;

	public var arrow_Type_Sprites:Map<String, FlxFramesCollection> = [];

	public static var songMultiplier:Float = 1;
	public static var previousScrollSpeedLmao:Float = 0;

	var hasUsedBot:Bool = false;
	var splashesSkin:String = "default";

	public var splashesSettings:Array<String>;

	var cutscene:Cutscene;

	public static var fromPauseMenu:Bool = false;

	var time:Float = 0.0;

	public var ratings:Map<String, Int> = [
		"marvelous" => 0,
		"sick" => 0,
		"good" => 0,
		"bad" => 0,
		"shit" => 0
	];

	public var ratingText:FlxText;

	public var stopSong:Bool = false;

	public var replay:Replay;
	public var inputs:Array<Array<Dynamic>> = [];

	public static var playingReplay:Bool = false;

	public function new(?_replay:Replay)
	{
		super();

		if(_replay != null)
		{
			replay = _replay;
			playingReplay = true;
		}
		else
			replay = new Replay();
	}

	public var characterPlayingAs:Int = 0;

	var hitSoundString:String = FlxG.save.data.hitsound;

	public var yoWaitThisIsCharter:Bool = false;

	override public function create()
	{
		if(!yoWaitThisIsCharter)
		{
			if(hitSoundString != "none")
				hitsound = FlxG.sound.load(Paths.sound("hitsounds/" + Std.string(hitSoundString).toLowerCase(), "shared"));

			switch(FlxG.save.data.playAs)
			{
				case "bf":
					characterPlayingAs = 0;
				case "opponent":
					characterPlayingAs = 1;
				case "both":
					characterPlayingAs = -1;
				default:
					characterPlayingAs = 0;
			}

			if(characterPlayingAs == 1)
			{
				var oldRegKeyCount = SONG.keyCount;
				var oldPlrKeyCount = SONG.playerKeyCount;

				SONG.keyCount = oldPlrKeyCount;
				SONG.playerKeyCount = oldRegKeyCount;
			}

			instance = this;

			if(FlxG.save.data.bot)
				hasUsedBot = true;

			if(FlxG.save.data.noDeath)
				hasUsedBot = true;

			if(characterPlayingAs != 0)
				hasUsedBot = true;

			if(playingReplay)
			{
				hasUsedBot = true;

				Conductor.offset = replay.offset;
				FlxG.save.data.judgementTimings = replay.judgementTimings;
				FlxG.save.data.ghostTapping = replay.ghostTapping;

				for(i in 0...replay.inputs.length)
				{
					var input = replay.inputs[i];

					if(input.length > 3)
						inputs.push([Std.int(input[0]), FlxMath.roundDecimal(input[1], 2), Std.int(input[2]), FlxMath.roundDecimal(input[3], 2)]);
					else
						inputs.push([Std.int(input[0]), FlxMath.roundDecimal(input[1], 2), Std.int(input[2])]);
				}
			}

			for(i in 0...2)
			{
				var sound = FlxG.sound.load(Paths.sound('missnote' + Std.string((i + 1))), 0.2);
				missSounds.push(sound);
			}

			binds = NoteHandler.getBinds(SONG.playerKeyCount);

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			camGame = new FlxCamera();
			camHUD = new FlxCamera();
			camHUD.bgColor.alpha = 0;

			FlxG.cameras.reset();
			FlxG.cameras.add(camGame, true);
			FlxG.cameras.add(camHUD, false);

			FlxG.cameras.setDefaultDrawTarget(camGame, true);

			FlxG.camera = camGame;
			
			persistentUpdate = true;
			persistentDraw = true;

			if (SONG == null)
				SONG = Song.loadFromJson('tutorial');

			#if !sys
			songMultiplier = 1;
			#end

			if(songMultiplier < 0.25)
				songMultiplier = 0.25;

			Conductor.mapBPMChanges(SONG, songMultiplier);
			Conductor.changeBPM(SONG.bpm, songMultiplier);

			previousScrollSpeedLmao = SONG.speed;

			SONG.speed /= songMultiplier;

			if(SONG.speed < 0.1 && songMultiplier > 1)
				SONG.speed = 0.1;

			Conductor.recalculateStuff(songMultiplier);
			Conductor.safeZoneOffset *= songMultiplier;

			noteBG = new FlxSprite(0,0);
			noteBG.cameras = [camHUD];
			noteBG.makeGraphic(1,1000,FlxColor.BLACK);

			add(noteBG);

			if(SONG.stage == null)
			{
				switch(storyWeek)
				{
					case 0 | 1:
						SONG.stage = 'stage';
					case 2:
						SONG.stage = 'spooky';
					case 3:
						SONG.stage = 'philly';
					case 4:
						SONG.stage = 'limo';
					case 5:
						SONG.stage = 'mall';
					case 6:
						SONG.stage = 'school';
					default:
						SONG.stage = 'chromatic-stage';
				}

				if(SONG.song.toLowerCase() == "winter horrorland")
					SONG.stage = 'evil-mall';

				if(SONG.song.toLowerCase() == "roses")
					SONG.stage = 'school-mad';

				if(SONG.song.toLowerCase() == "thorns")
					SONG.stage = 'evil-school';
			}
		}

		if(Std.string(SONG.ui_Skin) == "null")
			SONG.ui_Skin = SONG.stage == "school" || SONG.stage == "school-mad" || SONG.stage == "evil-school" ? "pixel" : "default";

		// yo poggars
		if(SONG.ui_Skin == "default")
			SONG.ui_Skin = FlxG.save.data.uiSkin;

		ui_Settings = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/config"));
		mania_size = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniasize"));
		mania_offset = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniaoffset"));

		if(Assets.exists(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniagap")))
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/maniagap"));
		else
			mania_gap = CoolUtil.coolTextFile(Paths.txt("ui skins/default/maniagap"));

		types = CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/types"));

		arrow_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("ui skins/" + SONG.ui_Skin + "/default")));
		type_Configs.set("default", CoolUtil.coolTextFile(Paths.txt("arrow types/default")));

		arrow_Type_Sprites.set("default", Paths.getSparrowAtlas('ui skins/' + SONG.ui_Skin + "/arrows/default", 'shared'));

		if(Std.parseInt(ui_Settings[6]) == 1)
		{
			splash_Texture = Paths.getSparrowAtlas('ui skins/' + SONG.ui_Skin + "/arrows/Note_Splashes", 'shared');

			splashesSettings = ui_Settings;
		}
		else
		{
			splash_Texture = Paths.getSparrowAtlas("ui skins/default/arrows/Note_Splashes", 'shared');
			splashesSettings = CoolUtil.coolTextFile(Paths.txt("ui skins/default/config"));
		}

		uiMap.set("marvelous", BitmapData.fromFile(PolymodAssets.getPath(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/" + "marvelous"))));
		uiMap.set("sick", BitmapData.fromFile(PolymodAssets.getPath(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/" + "sick"))));
		uiMap.set("good", BitmapData.fromFile(PolymodAssets.getPath(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/" + "good"))));
		uiMap.set("bad", BitmapData.fromFile(PolymodAssets.getPath(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/" + "bad"))));
		uiMap.set("shit", BitmapData.fromFile(PolymodAssets.getPath(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/" + "shit"))));

		for(i in 0...10)
		{
			uiMap.set(Std.string(i), BitmapData.fromFile(PolymodAssets.getPath(Paths.image("ui skins/" + SONG.ui_Skin + "/numbers/num" + Std.string(i)))));	
		}

		if(!yoWaitThisIsCharter)
		{
			if(SONG.gf == null)
			{
				switch(storyWeek)
				{
					case 4:
						SONG.gf = 'gf-car';
					case 5:
						SONG.gf = 'gf-christmas';
					case 6:
						SONG.gf = 'gf-pixel';
					default:
						SONG.gf = 'gf';
				}
			}

			/* character time :) */
			gfVersion = SONG.gf;

			if(!FlxG.save.data.chrsAndBGs)
			{
				gf = new Character(400, 130, "");
				gf.scrollFactor.set(0.95, 0.95);
		
				dad = new Character(100, 100, "");
				boyfriend = new Boyfriend(770, 450, "");
			}
			else
			{
				gf = new Character(400, 130, gfVersion);
				gf.scrollFactor.set(0.95, 0.95);
		
				dad = new Character(100, 100, SONG.player2);
				boyfriend = new Boyfriend(770, 450, SONG.player1);
			}
			/* end of character time */

			#if discord_rpc
			storyDifficultyText = storyDifficultyStr;
			iconRPC = dad.icon;

			// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
			if (isStoryMode)
				detailsText = "Story Mode: Week " + storyWeek;
			else
				detailsText = "Freeplay";

			// String for when the game is paused
			detailsPausedText = "Paused - " + detailsText;
			
			// Updating Discord Rich Presence.
			DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end

			curStage = SONG.stage;

			if(!FlxG.save.data.chrsAndBGs)
				stage = new StageGroup("");
			else
				stage = new StageGroup(curStage);

			add(stage);

			defaultCamZoom = stage.camZoom;

			var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

			if(SONG.player2.startsWith("gf"))
			{
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}
			}

			// REPOSITIONING PER STAGE
			if(FlxG.save.data.chrsAndBGs)
				stage.setCharOffsets();

			if(gf.otherCharacters == null)
			{
				if(gf.coolTrail != null)
					add(gf.coolTrail);

				add(gf);
			}
			else
			{
				for(character in gf.otherCharacters)
				{
					if(character.coolTrail != null)
						add(character.coolTrail);
					
					add(character);
				}
			}

			add(stage.infrontOfGFSprites);

			// fuck haxeflixel and their no z ordering or somnething AAAAAAAAAAAAA
			if(curStage == 'limo' && FlxG.save.data.chrsAndBGs)
				add(stage.limo);

			if(dad.otherCharacters == null)
			{
				if(dad.coolTrail != null)
					add(dad.coolTrail);

				add(dad);
			}
			else
			{
				for(character in dad.otherCharacters)
				{
					if(character.coolTrail != null)
						add(character.coolTrail);

					add(character);
				}
			}

			/* we do a little trolling */
			var midPos = (FlxG.save.data.cameraTracksDirections ? dad.getGraphicMidpoint() : dad.getMidpoint());

			camPos.set(midPos.x + 150 + dad.cameraOffset[0], midPos.y - 100 + dad.cameraOffset[1]);

			switch (dad.curCharacter)
			{
				case 'mom':
					camPos.y = midPos.y;
				case 'senpai':
					camPos.y = midPos.y - 430;
					camPos.x = midPos.x - 100;
				case 'senpai-angry':
					camPos.y = midPos.y - 430;
					camPos.x = midPos.x - 100;
			}

			if(boyfriend.otherCharacters == null)
			{
				if(boyfriend.coolTrail != null)
					add(boyfriend.coolTrail);
				
				add(boyfriend);
			}
			else
			{
				for(character in boyfriend.otherCharacters)
				{
					if(character.coolTrail != null)
						add(character.coolTrail);

					add(character);
				}
			}

			add(stage.foregroundSprites);

			Conductor.songPosition = -5000;

			strumLine = new FlxSprite(0, 100).makeGraphic(FlxG.width, 10);

			if (FlxG.save.data.downscroll)
				strumLine.y = FlxG.height - 100;

			strumLine.scrollFactor.set();

			strumLineNotes = new FlxTypedGroup<StrumNote>();
			add(strumLineNotes);

			playerStrums = new FlxTypedGroup<StrumNote>();
			enemyStrums = new FlxTypedGroup<StrumNote>();
			splashes = new FlxTypedGroup<NoteSplash>();

			generateSong(SONG.song);

			camFollow = new FlxObject(0, 0, 1, 1);

			camFollow.setPosition(camPos.x, camPos.y);

			if (prevCamFollow != null)
			{
				camFollow = prevCamFollow;
				prevCamFollow = null;
			}

			add(camFollow);

			if(FlxG.save.data.chrsAndBGs)
			{
				FlxG.camera.follow(camFollow, LOCKON, 0.04 * (60 / Main.display.currentFPS));
				FlxG.camera.zoom = defaultCamZoom;
				FlxG.camera.focusOn(camFollow.getPosition());
			}

			FlxG.fixedTimestep = false;

			var healthBarPosY = FlxG.height * 0.9;

			if(FlxG.save.data.downscroll)
				healthBarPosY = 60;

			/*
			better solution for future: make this process a freaking shader lmao
			*/
			healthBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('ui skins/' + SONG.ui_Skin + '/other/healthBar', 'shared'));
			healthBarBG.screenCenter(X);
			healthBarBG.scrollFactor.set();
			healthBarBG.pixelPerfectPosition = true;
			add(healthBarBG);
			
			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
				'healthShown', 0, maxHealth);
			healthBar.scrollFactor.set();
			healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
			healthBar.pixelPerfectPosition = true;
			add(healthBar);

			var scoreTxtSize:Int = 16;
			var funnyBarOffset:Int = 45;

			if(FlxG.save.data.biggerScoreInfo == true)
				scoreTxtSize = 22;

			scoreTxt = new FlxText(0, healthBarBG.y + funnyBarOffset, 0, "", 20);
			scoreTxt.screenCenter(X);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), scoreTxtSize, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.scrollFactor.set();
			add(scoreTxt);

			timeBarBG = new FlxSprite(0, healthBarPosY).loadGraphic(Paths.image('ui skins/' + SONG.ui_Skin + '/other/healthBar', 'shared'));
			timeBarBG.screenCenter(X);
			timeBarBG.scrollFactor.set();
			timeBarBG.pixelPerfectPosition = true;
			
			if(FlxG.save.data.downscroll)
				timeBarBG.y = FlxG.height - (timeBarBG.height + 1);
			else
				timeBarBG.y = 1;
			
			add(timeBarBG);
			
			timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
				'time', 0, FlxG.sound.music.length);
			timeBar.scrollFactor.set();
			timeBar.createFilledBar(FlxColor.BLACK, FlxColor.CYAN);
			timeBar.pixelPerfectPosition = true;
			add(timeBar);

			var infoTxtSize:Int = 16;

			if(FlxG.save.data.biggerInfoText == true)
				infoTxtSize = 22;

			infoTxt = new FlxText(0, 0, 0, SONG.song + " - " + storyDifficultyStr + (FlxG.save.data.bot ? " (BOT)" : ""), 20);
			infoTxt.setFormat(Paths.font("vcr.ttf"), infoTxtSize, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			infoTxt.screenCenter(X);
			
			if(FlxG.save.data.downscroll)
				infoTxt.y = timeBarBG.y - timeBarBG.height - 1;
			else
				infoTxt.y = timeBarBG.y + timeBarBG.height + 1;
			
			infoTxt.scrollFactor.set();
			add(infoTxt);

			if(FlxG.save.data.showRatingsOnSide)
			{
				ratingText = new FlxText(0,0,0,"bruh");
				ratingText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				ratingText.screenCenter(Y);
		
				ratingText.scrollFactor.set();
				add(ratingText);
			}

			iconP1 = new HealthIcon(boyfriend.icon, true);
			iconP1.y = healthBar.y - (iconP1.height / 2);
			add(iconP1);

			iconP2 = new HealthIcon(dad.icon, false);
			iconP2.y = healthBar.y - (iconP2.height / 2);
			add(iconP2);

			strumLineNotes.cameras = [camHUD];
			notes.cameras = [camHUD];
			healthBar.cameras = [camHUD];
			healthBarBG.cameras = [camHUD];
			iconP1.cameras = [camHUD];
			iconP2.cameras = [camHUD];
			scoreTxt.cameras = [camHUD];
			infoTxt.cameras = [camHUD];

			if(FlxG.save.data.showRatingsOnSide)
				ratingText.cameras = [camHUD];

			timeBar.cameras = [camHUD];
			timeBarBG.cameras = [camHUD];

			startingSong = true;

			playCutsceneLmao = (!playingReplay && ((isStoryMode && FlxG.save.data.cutscenePlays == "story") || (!isStoryMode && FlxG.save.data.cutscenePlays == "freeplay") || (FlxG.save.data.cutscenePlays == "both")) && !fromPauseMenu);

			if (playCutsceneLmao)
			{
				if(SONG.cutscene != null && SONG.cutscene != "")
				{
					cutscene = CutsceneUtil.loadFromJson(SONG.cutscene);

					switch(cutscene.type.toLowerCase())
					{
						case "video":
							startVideo(cutscene.videoPath, cutscene.videoExt, false);

						case "dialogue":
							var box:DialogueBox = new DialogueBox(cutscene);
							box.scrollFactor.set();
							box.finish_Function = function() { bruhDialogue(false); };
							box.cameras = [camHUD];

							startDialogue(box, false);

						default:
							startCountdown();
					}
				}
				else
					startCountdown();
			}
			else
			{
				switch (curSong.toLowerCase())
				{
					default:
						startCountdown();
				}
			}

			// WINDOW TITLE POG
			MusicBeatState.windowNameSuffix = " - " + SONG.song + " " + (isStoryMode ? "(Story Mode)" : "(Freeplay)");

			fromPauseMenu = false;

			if(FlxG.save.data.showRatingsOnSide)
				updateRatingText();
		}

		super.create();
	}

	public static var playCutsceneLmao:Bool = false;

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
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
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
							{
								swagTimer.reset();
							}
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
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function startDialogue(?dialogueBox:DialogueBox, ?endSongVar:Bool = false):Void
	{
		if(endSongVar)
		{
			paused = true;
			canPause = false;
			switchedStates = true;
			endingSong = true;
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			trace("Start Dialogue");

			if (dialogueBox != null)
				add(dialogueBox);
			else
			{
				if(cutscene.cutsceneAfter == null)
				{
					if(!endSongVar)
						startCountdown();
					else
						openSubState(new ResultsScreenSubstate());
				}
				else
				{
					var oldcutscene = cutscene;

					cutscene = CutsceneUtil.loadFromJson(oldcutscene.cutsceneAfter);

					switch(cutscene.type.toLowerCase())
					{
						case "video":
							startVideo(cutscene.videoPath, cutscene.videoExt, endSongVar);
	
						case "dialogue":
							var box:DialogueBox = new DialogueBox(cutscene);
							box.scrollFactor.set();
							box.finish_Function = function() { bruhDialogue(endSongVar); };
							box.cameras = [camHUD];
	
							startDialogue(box, endSongVar);
	
						default:
							if(!endSongVar)
								startCountdown();
							else
								openSubState(new ResultsScreenSubstate());
					}
				}
			}
		});
	}

	public function startVideo(name:String, ?ext:String, ?endSongVar:Bool = false):Void {
		#if BIT_64
		#if VIDEOS_ALLOWED
		if(endSongVar)
		{
			paused = true;
			canPause = false;
			switchedStates = true;
			endingSong = true;
		}
		
		var foundFile:Bool = false;
		var fileName:String = #if sys Sys.getCwd() + PolymodAssets.getPath(Paths.video(name, ext)) #else Paths.video(name, ext) #end;

		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);

			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);

				if(endingSong) {
					openSubState(new ResultsScreenSubstate());
				} else {
					if(cutscene.cutsceneAfter == null)
					{
						if(!endSongVar)
							startCountdown();
						else
							openSubState(new ResultsScreenSubstate());
					}
					else
					{
						var oldcutscene = cutscene;

						cutscene = CutsceneUtil.loadFromJson(oldcutscene.cutsceneAfter);

						switch(cutscene.type.toLowerCase())
						{
							case "video":
								startVideo(cutscene.videoPath, cutscene.videoExt, endSongVar);
		
							case "dialogue":
								var box:DialogueBox = new DialogueBox(cutscene);
								box.scrollFactor.set();
								box.finish_Function = function() { bruhDialogue(endSongVar); };
								box.cameras = [camHUD];
		
								startDialogue(box, endSongVar);
		
							default:
								if(!endSongVar)
									startCountdown();
								else
									openSubState(new ResultsScreenSubstate());
						}
					}
				}
			}
			return;
		} else {
			FlxG.log.warn('Couldnt find video file: ' + fileName);
		}
		#end

		if(endingSong) {
			openSubState(new ResultsScreenSubstate());
		} else { #end
			if(!endSongVar)
				startCountdown();
			else
				openSubState(new ResultsScreenSubstate());
		#if BIT_64
		}
		#end
	}

	function bruhDialogue(?endSongVar:Bool = false):Void
	{
		if(cutscene.cutsceneAfter == null)
		{
			if(!endSongVar)
				startCountdown();
			else
				openSubState(new ResultsScreenSubstate());
		}
		else
		{
			var oldcutscene = cutscene;

			cutscene = CutsceneUtil.loadFromJson(oldcutscene.cutsceneAfter);

			switch(cutscene.type.toLowerCase())
			{
				case "video":
					startVideo(cutscene.videoPath, cutscene.videoExt, endSongVar);

				case "dialogue":
					var box:DialogueBox = new DialogueBox(cutscene);
					box.scrollFactor.set();
					box.finish_Function = function() { bruhDialogue(endSongVar); };
					box.cameras = [camHUD];

					startDialogue(box, endSongVar);

				default:
					if(!endSongVar)
						startCountdown();
					else
						openSubState(new ResultsScreenSubstate());
			}
		}
	}

	var startTimer:FlxTimer;

	function startCountdown():Void
	{
		inCutscene = false;
		paused = false;
		canPause = true;

		if(FlxG.save.data.middleScroll)
		{
			generateStaticArrows(50, false);
			generateStaticArrows(0.5, true);
		}
		else
		{
			if(characterPlayingAs == 0)
			{
				generateStaticArrows(0, false);
				generateStaticArrows(1, true);
			}
			else
			{
				generateStaticArrows(1, false);
				generateStaticArrows(0, true);
			}
		}

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		#if linc_luajit
		executeModchart = !(PlayState.SONG.modchartPath == '' || PlayState.SONG.modchartPath == null);

		if(executeModchart)
		{
			if(Assets.exists(Paths.lua("modcharts/" + PlayState.SONG.modchartPath)))
			{
				luaModchart = ModchartUtilities.createModchartUtilities();
				luaModchart.executeState('start', [PlayState.SONG.song.toLowerCase()]);
			}
		}
		#end

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance(altAnim);
			gf.dance();
			boyfriend.dance();

			var introAssets:Array<String> = [
				"ui skins/" + SONG.ui_Skin + "/countdown/ready",
				"ui skins/" + SONG.ui_Skin + "/countdown/set",
				"ui skins/" + SONG.ui_Skin + "/countdown/go"
			];

			var altSuffix = SONG.ui_Skin == 'pixel' ? "-pixel" : "";

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAssets[0], 'shared'));
					ready.scrollFactor.set();
					ready.updateHitbox();

					ready.setGraphicSize(Std.int(ready.width * Std.parseFloat(ui_Settings[0]) * Std.parseFloat(ui_Settings[7])));
					ready.updateHitbox();

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAssets[1], 'shared'));
					set.scrollFactor.set();
					set.updateHitbox();

					set.setGraphicSize(Std.int(set.width * Std.parseFloat(ui_Settings[0]) * Std.parseFloat(ui_Settings[7])));
					set.updateHitbox();

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAssets[2], 'shared'));
					go.scrollFactor.set();
					go.updateHitbox();

					go.setGraphicSize(Std.int(go.width * Std.parseFloat(ui_Settings[0]) * Std.parseFloat(ui_Settings[7])));
					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	var invincible:Bool = false;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.music.play();

		vocals.play();

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		Conductor.recalculateStuff(songMultiplier);

		// Updating Discord Rich Presence (with Time Left)
		#if discord_rpc
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength / songMultiplier);
		#end
		#end

		resyncVocals();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm, songMultiplier);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song, storyDifficultyStr.toLowerCase()));
		else
			vocals = new FlxSound();

		// LOADING MUSIC FOR CUSTOM SONGS
		if(FlxG.sound.music.active)
			FlxG.sound.music.stop();

		FlxG.sound.music = new FlxSound().loadEmbedded(Paths.inst(SONG.song, storyDifficultyStr.toLowerCase()));
		FlxG.sound.music.persist = true;

		vocals.persist = false;
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		for (section in noteData)
		{
			Conductor.recalculateStuff(songMultiplier);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0] + Conductor.offset + SONG.chartOffset;

				var gottaHitNote:Bool = section.mustHitSection;

				if(songNotes[1] >= (!gottaHitNote ? SONG.keyCount : SONG.playerKeyCount))
					gottaHitNote = !section.mustHitSection;

				if(characterPlayingAs == 1)
					gottaHitNote = !gottaHitNote;

				if(characterPlayingAs == -1)
					gottaHitNote = true;

				var daNoteData:Int = Std.int(songNotes[1] % (!gottaHitNote ? SONG.keyCount : SONG.playerKeyCount));

				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				
				if(!Std.isOfType(songNotes[0], Float) && !Std.isOfType(songNotes[0], Int))
					songNotes[0] = 0;

				if(!Std.isOfType(songNotes[1], Int))
					songNotes[1] = 0;

				if(!Std.isOfType(songNotes[2], Int) && !Std.isOfType(songNotes[2], Float))
					songNotes[2] = 0;

				if(!Std.isOfType(songNotes[3], Int) && !Std.isOfType(songNotes[3], Array))
				{
					if(Std.string(songNotes[3]).toLowerCase() == "hurt note")
						songNotes[4] = "hurt";
					
					songNotes[3] = 0;
				}

				if(!Std.isOfType(songNotes[4], String))
					songNotes[4] = "default";

				var char:Dynamic = songNotes[3];

				var chars:Array<Int> = [];

				if(Std.isOfType(char, Array))
				{
					chars = char;
					char = chars[0];
				}

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, char, songNotes[4], null, chars, gottaHitNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Std.int(Conductor.nonmultilmao_stepCrochet);
				unspawnNotes.push(swagNote);

				var sustainGroup:Array<Note> = [];

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Std.int(Conductor.nonmultilmao_stepCrochet) * susNote) + Std.int(Conductor.nonmultilmao_stepCrochet), daNoteData, oldNote, true, char, songNotes[4], null, chars, gottaHitNote);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset

					sustainGroup.push(sustainNote);
					sustainNote.sustains = sustainGroup;
				}

				swagNote.sustains = sustainGroup;

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}

			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	var noteBG:FlxSprite;

	private function generateStaticArrows(player:Float, ?isPlayer:Bool = false):Void
	{
		var usedKeyCount = SONG.keyCount;

		if(isPlayer)
			usedKeyCount = SONG.playerKeyCount;

		for (i in 0...usedKeyCount)
		{
			var babyArrow:StrumNote = new StrumNote(0, strumLine.y, i);

			babyArrow.frames = arrow_Type_Sprites.get("default");

			babyArrow.antialiasing = ui_Settings[3] == "true";

			babyArrow.setGraphicSize(Std.int((babyArrow.width * Std.parseFloat(ui_Settings[0])) * (Std.parseFloat(ui_Settings[2]) - (Std.parseFloat(mania_size[usedKeyCount-1])))));
			babyArrow.updateHitbox();
			
			var animation_Base_Name = NoteVariables.Note_Count_Directions[usedKeyCount - 1][Std.int(Math.abs(i))].toLowerCase();

			babyArrow.animation.addByPrefix('static', animation_Base_Name + " static");
			babyArrow.animation.addByPrefix('pressed', NoteVariables.Other_Note_Anim_Stuff[usedKeyCount - 1][i] + ' press', 24, false);
			babyArrow.animation.addByPrefix('confirm', NoteVariables.Other_Note_Anim_Stuff[usedKeyCount - 1][i] + ' confirm', 24, false);

			babyArrow.scrollFactor.set();
			
			babyArrow.playAnim('static');

			babyArrow.x += (babyArrow.width + (2 + Std.parseFloat(mania_gap[usedKeyCount - 1]))) * Math.abs(i) + Std.parseFloat(mania_offset[usedKeyCount - 1]);
			babyArrow.y = strumLine.y - (babyArrow.height / 2);

			if (isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			if (isPlayer)
				playerStrums.add(babyArrow);
			else
				enemyStrums.add(babyArrow);

			babyArrow.x += 100 - ((usedKeyCount - 4) * 16) + (usedKeyCount >= 10 ? 30 : 0);
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);

			if(usedKeyCount != 4 && isPlayer && FlxG.save.data.extraKeyReminders)
			{
				//var coolWidth = Std.int(40 - ((key_Count - 5) * 2) + (key_Count == 10 ? 30 : 0));
										// funny 4 key math i guess, full num is 2.836842105263158 (width / previous key width thingy which was 38)
				var coolWidth = Math.ceil(babyArrow.width / 2.83684);

				var keyThingLolShadow = new FlxText((babyArrow.x + (babyArrow.width / 2)) - (coolWidth / 2), babyArrow.y - (coolWidth / 2), coolWidth, binds[i], coolWidth);
				keyThingLolShadow.cameras = [camHUD];
				keyThingLolShadow.color = FlxColor.BLACK;
				keyThingLolShadow.scrollFactor.set();
				add(keyThingLolShadow);

				var keyThingLol = new FlxText(keyThingLolShadow.x - 6, keyThingLolShadow.y - 6, coolWidth, binds[i], coolWidth);
				keyThingLol.cameras = [camHUD];
				keyThingLol.scrollFactor.set();
				add(keyThingLol);

				FlxTween.tween(keyThingLolShadow, {y: keyThingLolShadow.y + 10, alpha: 0}, 3, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i), onComplete: function(_){
					remove(keyThingLolShadow);
					keyThingLolShadow.kill();
					keyThingLolShadow.destroy();
				}});

				FlxTween.tween(keyThingLol, {y: keyThingLol.y + 10, alpha: 0}, 3, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i), onComplete: function(_){
					remove(keyThingLol);
					keyThingLol.kill();
					keyThingLol.destroy();
				}});
			}
		}

		if(isPlayer && FlxG.save.data.noteBGAlpha != 0)
		{
			updateNoteBGPos();
			noteBG.alpha = FlxG.save.data.noteBGAlpha;
		}
	}

	function updateNoteBGPos()
	{
		if(startedCountdown)
		{
			var bruhVal:Float = 0.0;

			for(note in playerStrums)
			{
				bruhVal += note.swagWidth + (2 + Std.parseFloat(mania_gap[SONG.playerKeyCount - 1]));
			}
	
			noteBG.setGraphicSize(Std.int(bruhVal), FlxG.height * 2);
			noteBG.updateHitbox();
	
			noteBG.x = playerStrums.members[0].x;
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * SONG.timescale[0] / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
				FlxG.sound.music.pause();

			if(vocals != null)
				vocals.pause();

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
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;

			paused = false;

			#if discord_rpc
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, ((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if discord_rpc
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, ((songLength - Conductor.songPosition) / songMultiplier >= 1 ? (songLength - Conductor.songPosition) / songMultiplier : 1));
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if discord_rpc
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(!switchedStates)
		{
			if(!(Conductor.songPosition > 20 && FlxG.sound.music.time < 20))
			{
				trace("SONG POS: " + Conductor.songPosition + " | Musice: " + FlxG.sound.music.time + " / " + FlxG.sound.music.length);

				vocals.pause();
				FlxG.sound.music.pause();
		
				if(FlxG.sound.music.time >= FlxG.sound.music.length)
					Conductor.songPosition = FlxG.sound.music.length;
				else
					Conductor.songPosition = FlxG.sound.music.time;

				vocals.time = Conductor.songPosition;
				
				FlxG.sound.music.play();
				vocals.play();
		
				#if cpp
				@:privateAccess
				{
					lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
		
					if (vocals.playing)
						lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
				}
				#end
			}
			else
			{
				while(Conductor.songPosition > 20 && FlxG.sound.music.time < 20)
				{
					trace("SONG POS: " + Conductor.songPosition + " | Musice: " + FlxG.sound.music.time + " / " + FlxG.sound.music.length);

					FlxG.sound.music.time = Conductor.songPosition;
					vocals.time = Conductor.songPosition;
		
					FlxG.sound.music.play();
					vocals.play();
			
					#if cpp
					@:privateAccess
					{
						lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
			
						if (vocals.playing)
							lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
					}
					#end
				}
			}
		}
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	public var canFullscreen:Bool = true;
	var switchedStates:Bool = false;

	// give: [noteDataThingy, noteType]
	// get : [xOffsetToUse]
	public var prevXVals:Map<String, Float> = [];

	override public function update(elapsed:Float)
	{
		infoTxt.text = SONG.song + " - " + storyDifficultyStr + (FlxG.save.data.bot ? " (BOT)" : "") + (playingReplay ? " (REPLAY)" : "");
		infoTxt.screenCenter(X);

		if(stopSong && !switchedStates)
		{
			PlayState.instance.paused = true;

			FlxG.sound.music.volume = 0;
			PlayState.instance.vocals.volume = 0;

			FlxG.sound.music.time = 0;
			PlayState.instance.vocals.time = 0;
			Conductor.songPosition = 0;
		}

		if(!switchedStates)
		{
			if (SONG.notes[Math.floor(curStep / 16)] != null)
			{
				if (SONG.notes[Math.floor(curStep / 16)].altAnim)
					altAnim = '-alt';
				else
					altAnim = "";
			}
		}

		super.update(elapsed);

		if (generatedMusic)
		{
			if (startedCountdown && canPause && !endingSong && !switchedStates)
			{
				// Song ends abruptly on slow rate even with second condition being deleted, 
				// and if it's deleted on songs like cocoa then it would end without finishing instrumental fully,
				// so no reason to delete it at all
				if (FlxG.sound.music.length - Conductor.songPosition <= 20)
				{
					time = FlxG.sound.music.length;
					endSong();
				}
			}
		}

		if(!endingSong)
			time = FlxG.sound.music.time;
		else
			time = FlxG.sound.music.length;

		FlxG.camera.followLerp = 0.04 * (60 / Main.display.currentFPS);

		if(totalNotes != 0 && !switchedStates)
		{
			accuracy = 100 / (totalNotes / hitNotes);
			// math
			accuracy = accuracy * Math.pow(10, 2);
			accuracy = Math.round(accuracy) / Math.pow(10, 2);
		}

		scoreTxt.x = (healthBarBG.x + (healthBarBG.width / 2)) - (scoreTxt.width / 2);

		scoreTxt.text = (
			"Misses: " + misses + " | " +
			"Accuracy: " + (FlxG.save.data.ratingMode == "simple" ? Std.int(accuracy) : accuracy) + "% | " +
			"Score: " + songScore + " | " +
			Ratings.getRank(accuracy, misses)
		);

		var icon_Zoom_Lerp = 0.09;

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(iconP1.width, 150, (icon_Zoom_Lerp / (Main.display.currentFPS / 60)) * songMultiplier)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(iconP2.width, 150, (icon_Zoom_Lerp / (Main.display.currentFPS / 60)) * songMultiplier)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		#if linc_luajit
		if (executeModchart && luaModchart != null && generatedMusic && !switchedStates && startedCountdown)
		{
			luaModchart.setVar('songPos', Conductor.songPosition);
			luaModchart.setVar('hudZoom', camHUD.zoom);
			luaModchart.setVar('curBeat', currentBeat);
			luaModchart.setVar('cameraZoom', FlxG.camera.zoom);
			luaModchart.executeState('update', [elapsed]);

			if (luaModchart.getVar("showOnlyStrums", 'bool'))
			{
				healthBarBG.visible = false;
				infoTxt.visible = false;
				healthBar.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
				scoreTxt.visible = false;
				ratingText.visible = false;
				timeBar.visible = false;
				timeBarBG.visible = false;
			}
			else
			{
				healthBarBG.visible = true;
				infoTxt.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
				scoreTxt.visible = true;
				ratingText.visible = true;
				timeBar.visible = true;
				timeBarBG.visible = true;
			}

			var p1 = luaModchart.getVar("strumLine1Visible", 'bool');
			var p2 = luaModchart.getVar("strumLine2Visible", 'bool');

			for(i in 0...SONG.keyCount)
			{
				strumLineNotes.members[i].visible = p1;
			}

			for(i in 0...SONG.playerKeyCount)
			{
				if (i <= playerStrums.length)
					playerStrums.members[i].visible = p2;
			}

			if(!canFullscreen && FlxG.fullscreen)
				FlxG.fullscreen = false;

			if(controls.LEFT)
				luaModchart.executeState('baseKeyPressed', ["left"]);
			if(controls.LEFT_P)
				luaModchart.executeState('baseKeyJustPressed', ["left"]);

			if(controls.DOWN)
				luaModchart.executeState('baseKeyPressed', ["down"]);
			if(controls.DOWN_P)
				luaModchart.executeState('baseKeyJustPressed', ["down"]);

			if(controls.UP)
				luaModchart.executeState('baseKeyPressed', ["up"]);
			if(controls.UP_P)
				luaModchart.executeState('baseKeyJustPressed', ["up"]);

			if(controls.RIGHT)
				luaModchart.executeState('baseKeyPressed', ["right"]);
			if(controls.RIGHT_P)
				luaModchart.executeState('baseKeyJustPressed', ["right"]);

			if(controls.RESET)
				luaModchart.executeState('baseKeyPressed', ["reset"]);

			if(controls.ACCEPT)
				luaModchart.executeState('baseKeyPressed', ["accept"]);

			if(controls.BACK)
				luaModchart.executeState('baseKeyPressed', ["back"]);
		}
		#end

		if (health > maxHealth)
			health = maxHealth;

		if (characterPlayingAs == 1)
		{
			healthShown = maxHealth - health;
		}
		else
		{
			healthShown = health;
		}

		if (healthBar.percent < 20)
		{
			iconP1.animation.curAnim.curFrame = 1;
			iconP2.animation.curAnim.curFrame = 2;

			if(iconP2.animation.curAnim.curFrame != 2)
				iconP2.animation.curAnim.curFrame = 0;
		}
		else
		{
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
		}

		if (healthBar.percent > 80)
		{
			iconP2.animation.curAnim.curFrame = 1;
			iconP1.animation.curAnim.curFrame = 2;

			if(iconP1.animation.curAnim.curFrame != 2)
				iconP1.animation.curAnim.curFrame = 0;
		}

		if(!switchedStates)
		{
			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += (FlxG.elapsed * 1000);
	
					if (Conductor.songPosition >= 0)
						startSong();
				}
			}
			else
				Conductor.songPosition += (FlxG.elapsed * 1000) * songMultiplier;
		}

		if(generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !switchedStates && startedCountdown)
		{
			//offsetX = luaModchart.getVar("followXOffset", "float");
			//offsetY = luaModchart.getVar("followYOffset", "float");

			#if linc_luajit
			if(executeModchart && luaModchart != null)
				luaModchart.setVar("mustHit", PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			#end
			
			if(!PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				var midPos = (FlxG.save.data.cameraTracksDirections ? dad.getGraphicMidpoint() : dad.getMidpoint());

				if (camFollow.x != midPos.x + 150 + dad.cameraOffset[0])
				{
					camFollow.setPosition(midPos.x + 150 + dad.cameraOffset[0], midPos.y - 100 + dad.cameraOffset[1]);
	
					switch (dad.curCharacter)
					{
						case 'mom':
							camFollow.y = midPos.y;
						case 'senpai':
							camFollow.y = midPos.y - 430;
							camFollow.x = midPos.x - 100;
						case 'senpai-angry':
							camFollow.y = midPos.y - 430;
							camFollow.x = midPos.x - 100;
					}
	
					#if linc_luajit
					if (luaModchart != null)
						luaModchart.executeState('playerTwoTurn', []);
					#end
				}
			}

			if(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				var midPos = (FlxG.save.data.cameraTracksDirections ? boyfriend.getGraphicMidpoint() : boyfriend.getMidpoint());

				if(camFollow.x != midPos.x - 100 + boyfriend.cameraOffset[0])
				{
					camFollow.setPosition(midPos.x - 100 + boyfriend.cameraOffset[0], midPos.y - 100 + boyfriend.cameraOffset[1]);
	
					switch (curStage)
					{
						case 'limo':
							camFollow.x = midPos.x - 300;
						case 'mall':
							camFollow.y = midPos.y - 200;
							/*
						case 'school':
							camFollow.x = boyfriend.getMidpoint().x - 200;
							camFollow.y = boyfriend.getMidpoint().y - 200;
						case 'evil-school':
							camFollow.x = boyfriend.getMidpoint().x - 200;
							camFollow.y = boyfriend.getMidpoint().y - 200;*/
					}
	
					#if linc_luajit
					if (luaModchart != null)
						luaModchart.executeState('playerOneTurn', []);
					#end
				}
			}
		}

		if(FlxG.save.data.cameraZooms && camZooming && !switchedStates)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}
		else if(!FlxG.save.data.cameraZooms)
		{
			FlxG.camera.zoom = defaultCamZoom;
			camHUD.zoom = 1;
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// curbeat switch per song
		switch(curSong.toLowerCase())
		{
			case 'fresh':
				switch(curBeat)
				{
					case 16:
						gfSpeed = 2;
					case 48:
						gfSpeed = 1;
					case 80:
						gfSpeed = 2;
					case 112:
						gfSpeed = 1;
				}
			case 'bopeebo':
				switch (curBeat)
				{
					case 128, 129, 130:
						vocals.volume = 0;
				}
		}

		// RESET = Quick Game Over Screen
		if (FlxG.save.data.resetButtonOn && !switchedStates)
		{
			if (controls.RESET)
			{ 
				health = 0;
				trace("RESET = True");
			}
		}
			
		if (FlxG.save.data.nohit && misses > 0)
			health = 0;

		if (health <= 0 && !switchedStates && !invincible && !FlxG.save.data.noDeath)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			if(boyfriend.otherCharacters == null)
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			else
				openSubState(new GameOverSubstate(boyfriend.otherCharacters[0].getScreenPosition().x, boyfriend.otherCharacters[0].getScreenPosition().y));
			
			#if discord_rpc
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end

			#if linc_luajit
			if(luaModchart != null)
				luaModchart.executeState('onDeath', [Conductor.songPosition]);
			#end
		}

		if(health < 0)
			health = 0;

		if (unspawnNotes[0] != null && !switchedStates)
		{
			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < (1500 * songMultiplier))
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if(generatedMusic && !switchedStates && startedCountdown)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				var coolStrum = (daNote.mustPress ? playerStrums.members[Math.floor(Math.abs(daNote.noteData))] : enemyStrums.members[Math.floor(Math.abs(daNote.noteData))]);
				var strumY = coolStrum.y;

				if ((daNote.y > FlxG.height || daNote.y < daNote.height) || (daNote.x > FlxG.width || daNote.x < daNote.width))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				var swagWidth = daNote.width;
				var center:Float = strumY + swagWidth / 2;

				var speed = SONG.speed;

				if(FlxG.save.data.useCustomScrollSpeed)
					speed = FlxG.save.data.scrollSpeed / songMultiplier;

				if(FlxG.save.data.downscroll)
				{
					daNote.y = strumY + (0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(speed, 2));

					if(daNote.isSustainNote)
					{
						// Remember = minus makes notes go up, plus makes them go down
						if(daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
							daNote.y += daNote.prevNote.height;
						else
							daNote.y += daNote.height / speed;

						if((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit) && daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2))
						{
							// Clip to strumline
							var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
							swagRect.height = (coolStrum.y + (coolStrum.width / 2) - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
				}
				else
				{
					daNote.y = strumY - (0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(speed, 2));

					if(daNote.isSustainNote)
					{
						daNote.y -= daNote.height / 2;

						if((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit) && daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2))
						{
							// Clip to strumline
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (coolStrum.y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				daNote.calculateCanBeHit();

				if (!daNote.mustPress && daNote.strumTime <= Conductor.songPosition && daNote.shouldHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					if(characterPlayingAs == 0)
					{
						if(dad.otherCharacters == null)
							dad.playAnim(NoteVariables.Character_Animation_Arrays[SONG.keyCount - 1][Std.int(Math.abs(daNote.noteData))] + altAnim, true);
						else
						{
							if(daNote.characters.length <= 1)
								dad.otherCharacters[daNote.character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.keyCount - 1][Std.int(Math.abs(daNote.noteData))], true);
							else
							{
								for(character in daNote.characters)
								{
									dad.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.keyCount - 1][Std.int(Math.abs(daNote.noteData))], true);
								}
							}
						}
					}
					else
					{
						if(boyfriend.otherCharacters == null)
							boyfriend.playAnim(NoteVariables.Character_Animation_Arrays[SONG.keyCount - 1][Std.int(Math.abs(daNote.noteData))] + altAnim, true);
						else
							if(daNote.characters.length <= 1)
								boyfriend.otherCharacters[daNote.character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.keyCount - 1][Std.int(Math.abs(daNote.noteData))], true);
							else
							{
								for(character in daNote.characters)
								{
									boyfriend.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.keyCount - 1][Std.int(Math.abs(daNote.noteData))], true);
								}
							}
					}

					#if linc_luajit
					if (luaModchart != null)
					{
						if(daNote.isSustainNote)
							luaModchart.executeState('playerTwoSingHeld', [Math.abs(daNote.noteData), Conductor.songPosition, daNote.arrow_Type]);
						else
							luaModchart.executeState('playerTwoSing', [Math.abs(daNote.noteData), Conductor.songPosition, daNote.arrow_Type]);
					}
					#end

					if (FlxG.save.data.enemyGlow && enemyStrums.members.length - 1 == SONG.keyCount - 1)
					{
						enemyStrums.forEach(function(spr:StrumNote)
						{
							if (Math.abs(daNote.noteData) == spr.ID)
							{
								spr.playAnim('confirm', true);
								spr.resetAnim = 0;

								if(!daNote.isSustainNote && FlxG.save.data.opponentNoteSplashes)
								{
									var splash:NoteSplash = new NoteSplash(spr.x - (spr.width / 2), spr.y - (spr.height / 2), spr.ID, spr, false);
									splash.cameras = [camHUD];
									add(splash);
								}

								spr.animation.finishCallback = function(_)
								{
									spr.playAnim("static");
								}
							}
						});
					}

					if(characterPlayingAs == 0)
					{
						if(dad.otherCharacters == null)
							dad.holdTimer = 0;
						else
						{
							if(daNote.characters.length <= 1)
								dad.otherCharacters[daNote.character].holdTimer = 0;
							else
							{
								for(char in daNote.characters)
								{
									dad.otherCharacters[char].holdTimer = 0;
								}
							}
						}
					}
					else
					{
						if(boyfriend.otherCharacters == null)
							boyfriend.holdTimer = 0;
						else
							if(daNote.characters.length <= 1)
								boyfriend.otherCharacters[daNote.character].holdTimer = 0;
							else
							{
								for(char in daNote.characters)
								{
									boyfriend.otherCharacters[char].holdTimer = 0;
								}
							}
					}

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if(daNote != null)
				{
					if (daNote.mustPress && !daNote.modifiedByLua)
					{
						var coolStrum = playerStrums.members[Math.floor(Math.abs(daNote.noteData))];
						var arrayVal = Std.string([daNote.noteData, daNote.arrow_Type, daNote.isSustainNote]);
						
						daNote.visible = coolStrum.visible;

						if(!prevXVals.exists(arrayVal))
						{
							var tempShit:Float = 0.0;
	
							daNote.x = coolStrum.x;

							while(Std.int(daNote.x + (daNote.width / 2)) != Std.int(coolStrum.x + (coolStrum.width / 2)))
							{
								daNote.x += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
								tempShit += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
							}

							prevXVals.set(arrayVal, tempShit);
						}
						else
							daNote.x = coolStrum.x + prevXVals.get(arrayVal);
	
						if (!daNote.isSustainNote)
							daNote.modAngle = coolStrum.angle;
						
						if(coolStrum.alpha != 1)
							daNote.alpha = coolStrum.alpha;
	
						daNote.modAngle = coolStrum.angle;
						daNote.flipX = coolStrum.flipX;

						if (!daNote.isSustainNote)
							daNote.flipY = coolStrum.flipY;

						daNote.color = coolStrum.color;
					}
					else if (!daNote.wasGoodHit && !daNote.modifiedByLua)
					{
						var coolStrum = enemyStrums.members[Math.floor(Math.abs(daNote.noteData))];
						var arrayVal = Std.string([daNote.noteData, daNote.arrow_Type, daNote.isSustainNote]);

						daNote.visible = coolStrum.visible;

						if(!prevXVals.exists(arrayVal))
						{
							var tempShit:Float = 0.0;
	
							daNote.x = coolStrum.x;

							while(Std.int(daNote.x + (daNote.width / 2)) != Std.int(coolStrum.x + (coolStrum.width / 2)))
							{
								daNote.x += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
								tempShit += (daNote.x + daNote.width > coolStrum.x + coolStrum.width ? -0.1 : 0.1);
							}

							prevXVals.set(arrayVal, tempShit);
						}
						else
							daNote.x = coolStrum.x + prevXVals.get(arrayVal);
	
						if (!daNote.isSustainNote)
							daNote.modAngle = coolStrum.angle;
						
						if(coolStrum.alpha != 1)
							daNote.alpha = coolStrum.alpha;
	
						daNote.modAngle = coolStrum.angle;
						daNote.flipX = coolStrum.flipX;

						if (!daNote.isSustainNote)
							daNote.flipY = coolStrum.flipY;

						daNote.color = coolStrum.color;
					}
				}

				if(Conductor.songPosition - Conductor.safeZoneOffset > daNote.strumTime)
				{
					if(daNote.mustPress && daNote.playMissOnMiss)
					{
						vocals.volume = 0;
						noteMiss(daNote.noteData, daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});

			if(FlxG.save.data.noteBGAlpha != 0 && !switchedStates)
				updateNoteBGPos();
		}

		if (!inCutscene && !switchedStates)
			keyShit(elapsed);

		currentBeat = curBeat;

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause && !switchedStates)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		
			#if discord_rpc
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN && !switchedStates)
		{
			#if linc_luajit
			if(luaModchart != null)
			{
				luaModchart.die();
				luaModchart = null;
			}
			#end
			
			switchedStates = true;

			vocals.stop();
			FlxG.switchState(new ChartingState());

			#if discord_rpc
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}
	}

	function endSong():Void
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		// lol dude when a song ended in freeplay it legit reloaded the page and i was like:  o_o ok
		if(FlxG.state == instance)
		{
			#if linc_luajit
			if (luaModchart != null)
			{
				for(sound in ModchartUtilities.lua_Sounds)
				{
					sound.stop();
					sound.kill();
					sound.destroy();
				}

				luaModchart.die();
				luaModchart = null;
			}
			#end

			if (SONG.validScore)
			{
				#if !switch
				if(!hasUsedBot && songMultiplier >= 1)
				{
					Highscore.saveScore(SONG.song, songScore, storyDifficultyStr);
					Highscore.saveRank(SONG.song, Ratings.getRank(accuracy, misses), storyDifficultyStr, accuracy);
				}
				#end
			}
	
			if(playCutsceneLmao)
			{
				if(SONG.endCutscene != null && SONG.endCutscene != "")
				{
					cutscene = CutsceneUtil.loadFromJson(SONG.endCutscene);
	
					switch(cutscene.type.toLowerCase())
					{
						case "video":
							startVideo(cutscene.videoPath, cutscene.videoExt, true);
	
						case "dialogue":
							var box:DialogueBox = new DialogueBox(cutscene);
							box.scrollFactor.set();
							box.finish_Function = function() { bruhDialogue(true); };
							box.cameras = [camHUD];
	
							startDialogue(box, true);
	
						default:
							persistentUpdate = false;
							persistentDraw = true;
							paused = true;

							openSubState(new ResultsScreenSubstate());
					}
				}
				else
				{
					persistentUpdate = false;
					persistentDraw = true;
					paused = true;

					openSubState(new ResultsScreenSubstate());
				}
			}
			else
			{
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				openSubState(new ResultsScreenSubstate());
			}
			
		}
	}

	var ogJudgementTimings:Array<Float> = FlxG.save.data.judgementTimings;
	var ogGhostTapping:Bool = FlxG.save.data.ghostTapping;

	public function saveReplay()
	{
		if(!playingReplay && !savedReplay)
		{
			savedReplay = true;

			var time = Date.now().getTime();
			var json:String = Json.stringify(replay.convertToSwag());

			#if sys
			sys.io.File.saveContent("assets/replays/replay-" + SONG.song.toLowerCase() + "-" + storyDifficultyStr.toLowerCase() + "-" + time + ".json", json);
			#end
		}
	}

	var savedReplay:Bool = false;

	public function fixSettings()
	{
		FlxG.save.data.judgementTimings = ogJudgementTimings;
		Conductor.offset = FlxG.save.data.songOffset;
		FlxG.save.data.ghostTapping = ogGhostTapping;
	}

	public function finishSongStuffs()
	{
		fixSettings();

		if(isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				switchedStates = true;
				vocals.stop();

				FlxG.switchState(new StoryMenuState());

				arrow_Type_Sprites = [];

				if (SONG.validScore)
				{
					if(!hasUsedBot && songMultiplier >= 1)
					{
						Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficultyStr, (groupWeek != "" ? groupWeek + "Week" : "week"));
					}
				}
			}
			else
			{
				var difficulty:String = "";

				if (storyDifficultyStr.toLowerCase() != "normal")
					difficulty = '-' + storyDifficultyStr.toLowerCase();

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				switchedStates = true;
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		else if(!playingReplay)
		{
			trace('WENT BACK TO FREEPLAY??');
			switchedStates = true;

			if(vocals.active)
				vocals.stop();

			FlxG.switchState(new FreeplayState());

			arrow_Type_Sprites = [];
		}
		else
		{
			trace('WENT BACK TO REPLAY SELECTOR??');
			switchedStates = true;

			if(vocals.active)
				vocals.stop();

			FlxG.switchState(new ReplaySelectorState());

			arrow_Type_Sprites = [];
		}

		playingReplay = false;
	}

	var endingSong:Bool = false;

	var rating:FlxSprite = new FlxSprite();
	var ratingTween:VarTween;

	var accuracyText:FlxText = new FlxText(0,0,0,"bruh",24);
	var accuracyTween:VarTween;

	var numbers:Array<FlxSprite> = [];
	var number_Tweens:Array<VarTween> = [];

	var uiMap:Map<String, BitmapData> = [];

	private function popUpScore(strumtime:Float, noteData:Int, ?setNoteDiff:Float):Void
	{
		var noteDiff:Float = (strumtime - Conductor.songPosition);

		if(FlxG.save.data.bot)
			noteDiff = 0;

		if(setNoteDiff != null)
			noteDiff = setNoteDiff;

		if(!playingReplay)
			replay.recordKeyHit(noteData, strumtime, noteDiff);

		vocals.volume = 1;

		var daRating:String = Ratings.getRating(Math.abs(noteDiff));
		var score:Int = Ratings.getScore(daRating);

		var hitNoteAmount:Float = 0;

		// health switch case
		switch(daRating)
		{
			case 'sick' | 'marvelous':
				health += 0.035;
			case 'good':
				health += 0.015;
			case 'bad':
				health += 0.005;
			case 'shit':
				if(FlxG.save.data.antiMash)
					health -= 0.075; // yes its more than a miss so that spamming with ghost tapping on is bad

				if(FlxG.save.data.missOnShit)
					misses += 1;
				combo = 0;
		}

		#if linc_luajit
		if(luaModchart != null && executeModchart)
			luaModchart.executeState('popUpScore', [daRating, combo]);
		#end

		if(ratings.exists(daRating))
			ratings.set(daRating, ratings.get(daRating) + 1);

		updateRatingText();

		if(daRating == "sick" || daRating == "marvelous")
			hitNoteAmount = 1;
		else if(daRating == "good")
			hitNoteAmount = 0.8;
		else if(daRating == "bad")
			hitNoteAmount = 0.3;

		hitNotes += hitNoteAmount;

		if ((daRating == "sick" || daRating == "marvelous") && FlxG.save.data.playerNoteSplashes)
		{
			playerStrums.forEachAlive(function(spr:FlxSprite) {
				if(spr.ID == Math.abs(noteData))
				{
					var splash:NoteSplash = new NoteSplash(spr.x - (spr.width / 2), spr.y - (spr.height / 2), noteData, spr, true);
					splash.cameras = [camHUD];
					add(splash);
				}
			});
		}

		songScore += score;

		rating.alpha = 1;

		rating.loadGraphic(uiMap.get(daRating), false, 0, 0, true, daRating);

		rating.screenCenter();
		rating.x -= (FlxG.save.data.middleScroll ? 350 : (characterPlayingAs == 0 ? 0 : -150));
		rating.y -= 60;
		rating.velocity.y = FlxG.random.int(30, 60);
		rating.velocity.x = FlxG.random.int(-10, 10);

		var noteMath:Float = 0.0;

		// math
		noteMath = noteDiff * Math.pow(10, 2);
		noteMath = Math.round(noteMath) / Math.pow(10, 2);

		if(FlxG.save.data.msText)
		{
			accuracyText.setPosition(rating.x, rating.y + 100);
			accuracyText.text = noteMath + " ms" + (FlxG.save.data.bot ? " (BOT)" : "");

			accuracyText.cameras = [camHUD];

			if(Math.abs(noteMath) == noteMath)
				accuracyText.color = FlxColor.CYAN;
			else
				accuracyText.color = FlxColor.ORANGE;
			
			accuracyText.borderStyle = FlxTextBorderStyle.OUTLINE;
			accuracyText.borderSize = 1;
			accuracyText.font = Paths.font("vcr.ttf");

			add(accuracyText);
		}

		rating.cameras = [camHUD];

		var comboSpr:FlxSprite = new FlxSprite()/*.loadGraphic(Paths.image("ui skins/" + SONG.ui_Skin + "/ratings/combo", 'shared'))*/;
		comboSpr.screenCenter();
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		comboSpr.cameras = [camHUD];
		add(rating);

		rating.setGraphicSize(Std.int(rating.width * Std.parseFloat(ui_Settings[0]) * Std.parseFloat(ui_Settings[4])));
		comboSpr.setGraphicSize(Std.int(comboSpr.width * Std.parseFloat(ui_Settings[0]) * Std.parseFloat(ui_Settings[4])));

		rating.antialiasing = ui_Settings[3] == "true";
		comboSpr.antialiasing = ui_Settings[3] == "true";

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		for(i in 0...Std.string(combo).length)
		{
			seperatedScore.push(Std.parseInt(Std.string(combo).split("")[i]));
		}

		var daLoop:Int = 0;

		for (i in seperatedScore)
		{
			if(numbers.length - 1 < daLoop)
				numbers.push(new FlxSprite());

			var numScore = numbers[daLoop];

			numScore.alpha = 1;

			numScore.loadGraphic(uiMap.get(Std.string(i)), false, 0, 0, true, Std.string(i));
			
			numScore.screenCenter();
			numScore.x -= (FlxG.save.data.middleScroll ? 350 : (characterPlayingAs == 0 ? 0 : -150));

			numScore.x += (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.setGraphicSize(Std.int(numScore.width * Std.parseFloat(ui_Settings[1])));
			numScore.updateHitbox();

			numScore.antialiasing = ui_Settings[3] == "true";

			numScore.velocity.y = FlxG.random.int(30, 60);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			numScore.cameras = [camHUD];
			add(numScore);

			if(number_Tweens[daLoop] == null)
			{
				number_Tweens[daLoop] = FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.002
				});
			}
			else
			{
				numScore.alpha = 1;

				number_Tweens[daLoop].cancel();

				number_Tweens[daLoop] = FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.002
				});
			}

			daLoop++;
		}

		if(ratingTween == null)
		{
			ratingTween = FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001
			});
		}
		else
		{
			ratingTween.cancel();

			rating.alpha = 1;
			ratingTween = FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001
			});
		}

		if(FlxG.save.data.msText)
		{
			if(accuracyTween == null)
			{
				accuracyTween = FlxTween.tween(accuracyText, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.001
				});
			}
			else
			{
				accuracyTween.cancel();
	
				accuracyText.alpha = 1;

				accuracyTween = FlxTween.tween(accuracyText, {alpha: 0}, 0.2, {
					startDelay: Conductor.crochet * 0.001
				});
			}
		}

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				comboSpr.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function closerNote(note1:Note, note2:Note):Note
	{
		if(note1.canBeHit && !note2.canBeHit)
			return note1;
		if(!note1.canBeHit && note2.canBeHit)
			return note2;

		if(Math.abs(Conductor.songPosition - note1.strumTime) < Math.abs(Conductor.songPosition - note2.strumTime))
			return note1;

		return note2;
	}

	var justPressedArray:Array<Bool> = [];
	var releasedArray:Array<Bool> = [];
	var justReleasedArray:Array<Bool> = [];
	var heldArray:Array<Bool> = [];
	var previousReleased:Array<Bool> = [];

	private function keyShit(elapsed:Float):Void
	{
		if(generatedMusic && startedCountdown)
		{
			if(!FlxG.save.data.bot)
			{
				var bruhBinds:Array<String> = ["LEFT","DOWN","UP","RIGHT"];

				justPressedArray = [];
				justReleasedArray = [];
		
				if(!playingReplay)
				{
					previousReleased = releasedArray;
	
					releasedArray = [];
					heldArray = [];
	
					for(i in 0...binds.length)
					{
						justPressedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.JUST_PRESSED);
						releasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.RELEASED);
						justReleasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.JUST_RELEASED);
						heldArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(binds[i]), FlxInputState.PRESSED);
		
						if(releasedArray[i] == true && SONG.playerKeyCount == 4)
						{
							justPressedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.JUST_PRESSED);
							releasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.RELEASED);
							justReleasedArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.JUST_RELEASED);
							heldArray[i] = FlxG.keys.checkStatus(FlxKey.fromString(bruhBinds[i]), FlxInputState.PRESSED);
						}
					}

					for (i in 0...justPressedArray.length) {
						if (justPressedArray[i] == true) {
							replay.recordInput(i, "pressed");
						}
					};
				}
				else
				{
					for(inputIndex in 0...inputs.length)
					{
						var input = inputs[inputIndex];

						if(input != null)
						{
							if(input[2] != 2 && Conductor.songPosition >= input[1])
							{
								if(input[2] == 1)
								{
									justReleasedArray[input[0]] = true;
									releasedArray[input[0]] = true;

									justPressedArray[input[0]] = false;
									heldArray[input[0]] = false;

									playerStrums.members[input[0]].playAnim('static');
									playerStrums.members[input[0]].resetAnim = 0;
								}
								else if(input[2] == 0)
								{
									justPressedArray[input[0]] = true;
									heldArray[input[0]] = true;

									justReleasedArray[input[0]] = false;
									releasedArray[input[0]] = false;

									if(!FlxG.save.data.ghostTapping)
										noteMiss(input[0]);
								}
		
								inputs.remove(input);
							}
							else if(input[2] == 2 && Conductor.songPosition >= input[1] + input[3])
							{
								for(note in notes)
								{
									if(note.mustPress && FlxMath.roundDecimal(note.strumTime, 2) == FlxMath.roundDecimal(input[1], 2) && note.noteData == input[0])
									{
										justPressedArray[input[0]] = true;
										heldArray[input[0]] = true;
	
										justReleasedArray[input[0]] = false;
										releasedArray[input[0]] = false;

										if(characterPlayingAs == 0)
										{
											if(boyfriend.otherCharacters == null)
												boyfriend.holdTimer = 0;
											else
												if(note.characters.length <= 1)
													boyfriend.otherCharacters[note.character].holdTimer = 0;
												else
												{
													for(char in note.characters)
													{
														boyfriend.otherCharacters[char].holdTimer = 0;
													}
												}
										}
										else
										{
											if(dad.otherCharacters == null)
												dad.holdTimer = 0;
											else
												if(note.characters.length <= 1)
													dad.otherCharacters[note.character].holdTimer = 0;
												else
												{
													for(char in note.characters)
													{
														dad.otherCharacters[char].holdTimer = 0;
													}
												}
										}

										goodNoteHit(note, input[3]);
									}
								}

								inputs.remove(input);
							}
						}
					}
				}
	
				#if linc_luajit
				if (luaModchart != null)
				{
					for (i in 0...justPressedArray.length) {
						if (justPressedArray[i] == true) {
							luaModchart.executeState('keyPressed', [i]);
						}
					};
					
					for (i in 0...releasedArray.length) {
						if (releasedArray[i] == true) {
							luaModchart.executeState('keyReleased', [i]);
						}
					};
				};
				#end
				
				if(justPressedArray.contains(true) && generatedMusic && !playingReplay)
				{
					// variables
					var possibleNotes:Array<Note> = [];
					var dontHit:Array<Note> = [];
					
					// notes you can hit lol
					notes.forEachAlive(function(note:Note) {
						note.calculateCanBeHit();

						if(note.canBeHit && note.mustPress && !note.tooLate && !note.isSustainNote)
							possibleNotes.push(note);
					});
	
					if(FlxG.save.data.inputMode == "rhythm")
						possibleNotes.sort((b, a) -> Std.int(Conductor.songPosition - a.strumTime));
					else
						possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	
					if(FlxG.save.data.inputMode == "rhythm")
					{
						var coolNote:Note = null;
	
						for(note in possibleNotes) {
							if(coolNote != null)
							{
								if(note.strumTime > coolNote.strumTime && note.shouldHit)
									dontHit.push(note);
							}
							else if(note.shouldHit)
								coolNote = note;
						}
					}
		
					var noteDataPossibles:Array<Bool> = [];
					var rythmArray:Array<Bool> = [];
					var noteDataTimes:Array<Float> = [];
	
					for(i in 0...SONG.playerKeyCount)
					{
						noteDataPossibles.push(false);
						noteDataTimes.push(-1);
	
						rythmArray.push(false);
					}
		
					// if there is actual notes to hit
					if (possibleNotes.length > 0)
					{
						for(i in 0...possibleNotes.length)
						{	
							if(justPressedArray[possibleNotes[i].noteData] && !noteDataPossibles[possibleNotes[i].noteData])
							{
								noteDataPossibles[possibleNotes[i].noteData] = true;
								noteDataTimes[possibleNotes[i].noteData] = possibleNotes[i].strumTime;
	
								if(characterPlayingAs == 0)
								{
									if(boyfriend.otherCharacters == null)
										boyfriend.holdTimer = 0;
									else
										if(possibleNotes[i].characters.length <= 1)
											boyfriend.otherCharacters[possibleNotes[i].character].holdTimer = 0;
										else
										{
											for(char in possibleNotes[i].characters)
											{
												boyfriend.otherCharacters[char].holdTimer = 0;
											}
										}
								}
								else
								{
									if(dad.otherCharacters == null)
										dad.holdTimer = 0;
									else
										if(possibleNotes[i].characters.length <= 1)
											dad.otherCharacters[possibleNotes[i].character].holdTimer = 0;
										else
										{
											for(char in possibleNotes[i].characters)
											{
												dad.otherCharacters[char].holdTimer = 0;
											}
										}
								}
	
								goodNoteHit(possibleNotes[i]);
	
								if(dontHit.contains(possibleNotes[i])) // rythm mode only ?????
								{
									noteMiss(possibleNotes[i].noteData, possibleNotes[i]);
									rythmArray[i] = true;
								}
							}
						}
					}
	
					if(possibleNotes.length > 0)
					{
						for(i in 0...possibleNotes.length)
						{
							if(possibleNotes[i].strumTime == noteDataTimes[possibleNotes[i].noteData])
								goodNoteHit(possibleNotes[i]);
						}
					}
	
					if(!FlxG.save.data.ghostTapping)
					{
						for(i in 0...justPressedArray.length)
						{
							if(justPressedArray[i] && !noteDataPossibles[i] && !rythmArray[i])
								noteMiss(i);
						}
					}
				}
		
				if (heldArray.contains(true) && generatedMusic)
				{
					var thingsHit:Array<Bool> = [];
	
					for(i in 0...SONG.playerKeyCount)
					{
						thingsHit.push(false);
					}
					
					notes.forEachAlive(function(daNote:Note)
					{
						if(heldArray[daNote.noteData])
						{
							if ((daNote.strumTime > (Conductor.songPosition - (Conductor.safeZoneOffset * 1.5))
								&& daNote.strumTime < (Conductor.songPosition + (Conductor.safeZoneOffset * 0.5)))
							&& daNote.mustPress && daNote.isSustainNote && !thingsHit[daNote.noteData])
							{
								if(characterPlayingAs == 0)
								{
									if(boyfriend.otherCharacters == null)
										boyfriend.holdTimer = 0;
									else
										if(daNote.characters.length <= 1)
											boyfriend.otherCharacters[daNote.character].holdTimer = 0;
										else
										{
											for(char in daNote.characters)
											{
												boyfriend.otherCharacters[char].holdTimer = 0;
											}
										}
								}
								else
								{
									if(dad.otherCharacters == null)
										dad.holdTimer = 0;
									else
										if(daNote.characters.length <= 1)
											dad.otherCharacters[daNote.character].holdTimer = 0;
										else
										{
											for(char in daNote.characters)
											{
												dad.otherCharacters[char].holdTimer = 0;
											}
										}
								}
	
								goodNoteHit(daNote);
								thingsHit[daNote.noteData] = true;
							}
						}
					});
				}
		
				if(characterPlayingAs == 0)
				{
					if(boyfriend.otherCharacters == null)
					{
						if(boyfriend.animation.curAnim != null)
							if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
								if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
									boyfriend.dance();
					}
					else
					{
						for(character in boyfriend.otherCharacters)
						{
							if(character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
									if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
										character.dance();
						}
					}
				}
				else
				{
					if(dad.otherCharacters == null)
					{
						if(dad.animation.curAnim != null)
							if (dad.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
								if (dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss'))
									dad.dance();
					}
					else
					{
						for(character in dad.otherCharacters)
						{
							if(character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !heldArray.contains(true))
									if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
										character.dance();
						}
					}
				}
		
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (justPressedArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
					{
						spr.playAnim('pressed');
						spr.resetAnim = 0;
					}

					if (releasedArray[spr.ID])
					{
						if(spr.animation.curAnim.name != "static")
							replay.recordInput(spr.ID, "released");

						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				});
			}
			else
			{
				notes.forEachAlive(function(note:Note) {
					if(note.shouldHit)
					{
						if(note.mustPress && note.strumTime <= Conductor.songPosition)
						{
							if(characterPlayingAs == 0)
							{
								if(boyfriend.otherCharacters == null)
									boyfriend.holdTimer = 0;
								else
									if(note.characters.length <= 1)
										boyfriend.otherCharacters[note.character].holdTimer = 0;
									else
									{
										for(char in note.characters)
										{
											boyfriend.otherCharacters[char].holdTimer = 0;
										}
									}
							}
							else
							{
								if(dad.otherCharacters == null)
									dad.holdTimer = 0;
								else
									if(note.characters.length <= 1)
										dad.otherCharacters[note.character].holdTimer = 0;
									else
									{
										for(char in note.characters)
										{
											dad.otherCharacters[char].holdTimer = 0;
										}
									}
							}
		
							goodNoteHit(note);
						}
					}
				});
	
				playerStrums.forEach(function(spr:StrumNote)
				{
					if(spr.animation.finished)
					{
						spr.playAnim("static");
					}
				});
	
				if(characterPlayingAs == 0)
				{
					if(boyfriend.otherCharacters == null)
					{
						if(boyfriend.animation.curAnim != null)
							if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001)
								if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
									boyfriend.dance();
					}
					else
					{
						for(character in boyfriend.otherCharacters)
						{
							if(character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001)
									if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
										character.dance();
						}
					}
				}
				else
				{
					if(dad.otherCharacters == null)
					{
						if(dad.animation.curAnim != null)
							if (dad.holdTimer > Conductor.stepCrochet * 4 * 0.001)
								if (dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss'))
									dad.dance();
					}
					else
					{
						for(character in dad.otherCharacters)
						{
							if(character.animation.curAnim != null)
								if (character.holdTimer > Conductor.stepCrochet * 4 * 0.001)
									if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
										character.dance();
						}
					}
				}
			}
		}
	}

	function noteMiss(direction:Int = 1, ?note:Note):Void
	{
		var canMiss = false;

		if(note == null)
			canMiss = true;
		else
		{
			if(note.mustPress)
				canMiss = true;
		}

		if(canMiss && !invincible && !FlxG.save.data.bot)
		{
			if(note != null)
			{
				if(!note.isSustainNote)
					health -= note.missDamage;
				else
					health -= note.heldMissDamage;
			}
			else
				health -= Std.parseFloat(type_Configs.get("default")[2]);

			if (combo > 5 && gf.animOffsets.exists('sad'))
				gf.playAnim('sad');

			combo = 0;

			var missValues = false;

			if(note != null)
			{
				if(!note.isSustainNote || (FlxG.save.data.missOnHeldNotes && !note.missesSustains))
					missValues = true;
			}
			else
				missValues = true;

			if(missValues)
			{
				if(note != null)
				{
					if(FlxG.save.data.missOnHeldNotes && !note.missesSustains)
					{
						note.missesSustains = true;
	
						for(sustain in note.sustains)
						{
							if(sustain != null)
								sustain.missesSustains = true;
						}
					}
				}

				misses++;
				updateRatingText();
			}

			totalNotes++;

			missSounds[FlxG.random.int(0, missSounds.length - 1)].play(true);

			songScore -= 10;

			if(note != null)
			{
				if(characterPlayingAs == 0)
				{
					if(boyfriend.otherCharacters != null)
					{
						if(note.characters.length <= 1)
							boyfriend.otherCharacters[note.character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][direction] + "miss", true);
						else
						{
							for(character in note.characters)
							{
								boyfriend.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][direction] + "miss", true);
							}
						}
					}
					else
						boyfriend.playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][direction] + "miss", true);
				}
				else
				{
					if(dad.otherCharacters != null)
						if(note.characters.length <= 1)
							dad.otherCharacters[note.character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][direction] + "miss", true);
						else
						{
							for(character in note.characters)
							{
								dad.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][direction] + "miss", true);
							}
						}
					else
						dad.playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][direction] + "miss", true);
				}
			}

			#if linc_luajit
			if (luaModchart != null)
				luaModchart.executeState('playerOneMiss', [direction, Conductor.songPosition, (note != null ? note.arrow_Type : "default"), (note != null ? note.isSustainNote : false)]);
			#end
		}
	}

	var hitsound:FlxSound;

	function goodNoteHit(note:Note, ?setNoteDiff:Float):Void
	{
		if (!note.wasGoodHit)
		{
			if(note.shouldHit && !note.isSustainNote)
			{
				popUpScore(note.strumTime, note.noteData % SONG.playerKeyCount, setNoteDiff);
				combo += 1;

				if(hitSoundString != "none")
					hitsound.play(true);
			}
			else if(!note.shouldHit)
			{
				health -= note.hitDamage;
				misses++;
				missSounds[FlxG.random.int(0, missSounds.length - 1)].play(true);

				if(!playingReplay)
					replay.recordKeyHit(note.noteData % SONG.playerKeyCount, note.strumTime, (setNoteDiff != null ? setNoteDiff : note.strumTime - Conductor.songPosition));

				updateRatingText();
			}

			if(note.shouldHit && note.isSustainNote)
				health += 0.02;

			if(!note.isSustainNote)
				totalNotes++;

			if(characterPlayingAs == 0)
			{
				if(boyfriend.otherCharacters != null)
					if(note.characters.length <= 1)
						boyfriend.otherCharacters[note.character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][Std.int(Math.abs(note.noteData % SONG.playerKeyCount))], true);
					else
					{
						for(character in note.characters)
						{
							boyfriend.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][Std.int(Math.abs(note.noteData % SONG.playerKeyCount))], true);
						}
					}
				else
					boyfriend.playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][Std.int(Math.abs(note.noteData % SONG.playerKeyCount))], true);
			}
			else
			{
				if(dad.otherCharacters != null)
					if(note.characters.length <= 1)
						dad.otherCharacters[note.character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][Std.int(Math.abs(note.noteData % SONG.playerKeyCount))], true);
					else
					{
						for(character in note.characters)
						{
							dad.otherCharacters[character].playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][Std.int(Math.abs(note.noteData % SONG.playerKeyCount))], true);
						}
					}
				else
					dad.playAnim(NoteVariables.Character_Animation_Arrays[SONG.playerKeyCount - 1][Std.int(Math.abs(note.noteData % SONG.playerKeyCount))], true);
			}

			#if linc_luajit
			if (luaModchart != null)
			{
				if(note.isSustainNote)
					luaModchart.executeState('playerOneSingHeld', [note.noteData, Conductor.songPosition, note.arrow_Type]);
				else
					luaModchart.executeState('playerOneSing', [note.noteData, Conductor.songPosition, note.arrow_Type]);
			}
			#end

			if(startedCountdown)
			{
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	override function stepHit()
	{
		super.stepHit();

		var gamerValue = 20 * songMultiplier;
		
		if (FlxG.sound.music.time > Conductor.songPosition + gamerValue || FlxG.sound.music.time < Conductor.songPosition - gamerValue || FlxG.sound.music.time < 500 && (FlxG.sound.music.time > Conductor.songPosition + 5 || FlxG.sound.music.time < Conductor.songPosition - 5))
			resyncVocals();

		#if linc_luajit
		if (executeModchart && luaModchart != null)
		{
			luaModchart.setVar('curStep', curStep);
			luaModchart.executeState('stepHit', [curStep]);
		}
		#end
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic && startedCountdown)
			notes.sort(FlxSort.byY, (FlxG.save.data.downscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm, songMultiplier);
				FlxG.log.add('CHANGED BPM!');
			}

			// Dad doesnt interupt his own notes
			if(characterPlayingAs == 0)
			{
				if(dad.otherCharacters == null)
				{
					if(dad.animation.curAnim != null)
						if ((dad.animation.curAnim.name.startsWith("sing") && dad.animation.curAnim.finished || !dad.animation.curAnim.name.startsWith("sing")) && !dad.curCharacter.startsWith('gf'))
							dad.dance();
				}
				else
				{
					for(character in dad.otherCharacters)
					{
						if(character.animation.curAnim != null)
							if ((character.animation.curAnim.name.startsWith("sing") && character.animation.curAnim.finished || !character.animation.curAnim.name.startsWith("sing")) && !character.curCharacter.startsWith('gf'))
								character.dance();
					}
				}
			}
			else
			{
				if(boyfriend.otherCharacters == null)
				{
					if(boyfriend.animation.curAnim != null)
						if ((boyfriend.animation.curAnim.name.startsWith("sing") && boyfriend.animation.curAnim.finished || !boyfriend.animation.curAnim.name.startsWith("sing")) && !boyfriend.curCharacter.startsWith('gf'))
							boyfriend.dance();
				}
				else
				{
					for(character in boyfriend.otherCharacters)
					{
						if(character.animation.curAnim != null)
							if ((character.animation.curAnim.name.startsWith("sing") && character.animation.curAnim.finished || !character.animation.curAnim.name.startsWith("sing")) && !character.curCharacter.startsWith('gf'))
								character.dance();
					}
				}
			}
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + (30 / (songMultiplier < 1 ? 1 : songMultiplier))));
		iconP2.setGraphicSize(Std.int(iconP2.width + (30 / (songMultiplier < 1 ? 1 : songMultiplier))));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if(gfSpeed < 1)
			gfSpeed = 1;

		if (curBeat % gfSpeed == 0 && !SONG.player2.startsWith('gf'))
			gf.dance();
		
		if(dad.animation.curAnim != null)
			if (curBeat % gfSpeed == 0 && SONG.player2.startsWith('gf') && (dad.animation.curAnim.name.startsWith("sing") && dad.animation.curAnim.finished || !dad.animation.curAnim.name.startsWith("sing")))
				dad.dance();

		if(characterPlayingAs == 0)
		{
			if (boyfriend.otherCharacters == null)
			{
				if(boyfriend.animation.curAnim != null)
					if(!boyfriend.animation.curAnim.name.startsWith("sing"))
						boyfriend.dance();
			}
			else
			{
				for(character in boyfriend.otherCharacters)
				{
					if(character.animation.curAnim != null)
						if(!character.animation.curAnim.name.startsWith("sing"))
							character.dance();
				}
			}
		}
		else
		{
			if (dad.otherCharacters == null)
			{
				if(dad.animation.curAnim != null)
					if(!dad.animation.curAnim.name.startsWith("sing"))
						dad.dance();
			}
			else
			{
				for(character in dad.otherCharacters)
				{
					if(character.animation.curAnim != null)
						if(!character.animation.curAnim.name.startsWith("sing"))
							character.dance();
				}
			}
		}

		if (curBeat % 8 == 7 && SONG.song.toLowerCase() == 'bopeebo' && boyfriend.otherCharacters == null)
			boyfriend.playAnim('hey', true);

		if (curBeat % 16 == 15 && SONG.song.toLowerCase() == 'tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}
		else if(curBeat % 16 == 15 && SONG.song.toLowerCase() == 'tutorial' && dad.curCharacter != 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			gf.playAnim('cheer', true);
		}

		stage.beatHit();

		#if linc_luajit
		if (executeModchart && luaModchart != null)
			luaModchart.executeState('beatHit', [curBeat]);
		#end
	}

	function updateRatingText()
	{
		if(FlxG.save.data.showRatingsOnSide)
		{
			var ratingArray = [
				ratings.get("marvelous"),
				ratings.get("sick"),
				ratings.get("good"),
				ratings.get("bad"),
				ratings.get("shit")
			];

			var MA = ratingArray[1] + ratingArray[2] + ratingArray[3] + ratingArray[4];
			var PA = ratingArray[2] + ratingArray[3] + ratingArray[4];

			ratingText.text = (
				(FlxG.save.data.marvelousRatings ? "Marvelous: " + Std.string(ratingArray[0]) + "\n" : "") +
				"Sick: " + Std.string(ratingArray[1]) + "\n" +
				"Good: " + Std.string(ratingArray[2]) + "\n" +
				"Bad: " + Std.string(ratingArray[3]) + "\n" +
				"Shit: " + Std.string(ratingArray[4]) + "\n" +
				"Misses: " + Std.string(misses) + "\n" +
				(FlxG.save.data.marvelousRatings && ratingArray[0] > 0 && MA > 0 ? "MA: " + Std.string(FlxMath.roundDecimal(ratingArray[0] / MA, 2)) + "\n" : "") +
				(ratingArray[1] > 0 && PA > 0 ? "PA: " + Std.string(FlxMath.roundDecimal((ratingArray[1] + ratingArray[0]) / PA, 2)) + "\n" : "")
			);

			ratingText.screenCenter(Y);
		}
	}

	var curLight:Int = 0;
}
