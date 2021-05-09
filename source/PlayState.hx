package;

import FNFAssets.HScriptAssets;
import flixel.ui.FlxButton.FlxTypedButton;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import openfl.geom.Matrix;
import flixel.FlxGame;
import flixel.FlxObject;
#if cpp
import Discord.DiscordClient;
#end
import DifficultyIcons;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.FlxState;
import flixel.FlxSubState;
import flash.display.BitmapData;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import lime.system.System;
import openfl.media.Sound;
import flixel.group.FlxGroup;
import hscript.Interp;
import hscript.Parser;
import hscript.ParserEx;
import hscript.InterpEx;
import hscript.ClassDeclEx;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;

#end
import tjson.TJSON;
using StringTools;
typedef LuaAnim = {
	var prefix : String;
	@:optional var indices: Array<Int>;
	var name : String;
	@:optional var fps : Int;
	@:optional var loop : Bool;
}
enum abstract DisplayLayer(Int) from Int to Int {
	var BEHIND_GF = 1;
	var BEHIND_BF = 1 << 1;
	var BEHIND_DAD = 1 << 2;
	var BEHIND_ALL = BEHIND_GF | BEHIND_BF | BEHIND_DAD;
}
class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var defaultPlaylistLength = 0;
	public static var campaignScoreDef = 0;
	var halloweenLevel:Bool = false;

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Character;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;
	private var player1Icon:String;
	private var player2Icon:String;
	private static var prevCamFollow:FlxObject;
	public static var misses:Int = 0;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	private var accuracy:Float = 0.00;
	private var accuracyDefault:Float = 0.00;
	public static var sicks:Int = 0;
	var songLength:Float = 0.0;
	var songScoreDef:Int = 0;
	var nps:Int = 0;
	var playingAsRpc:String = "";
	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;
	private var enemyStrums:FlxTypedGroup<FlxSprite>;
	private var camZooming:Bool = false;
	private var curSong:String = "";
	private var strumming2:Array<Bool> = [false, false, false, false];
	private var strumming1:Array<Bool> = [false,false,false,false];

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;
	public static var duoMode:Bool = false;
	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	private var enemyColor:FlxColor = 0xFFFF0000;
	private var opponentColor:FlxColor = 0xFFFFC414;
	private var playerColor:FlxColor = 0xFF66FF33;
	private var poisonColor:FlxColor = 0xFFA22CD1;
	private var poisonColorEnemy:FlxColor = 0xFFEA2FFF;
	private var bfColor:FlxColor = 0xFF149DFF;
	private var barShowingPoison:Bool = false;
	#if windows
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end
	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;


	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;
	// this'll work... right?
	var backgroundgroup:FlxTypedGroup<BeatSprite>;
	var foregroundgroup:FlxTypedGroup<BeatSprite>;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();

	var talking:Bool = true;
	var songScore:Int = 0;
	var trueScore:Int = 0;
	var scoreTxt:FlxText;
	var healthTxt:FlxText;
	var accuracyTxt:FlxText;
	var difficTxt:FlxText;
	public static var campaignScore:Int = 0;
	public static var campaignAccuracy:Float = 0;
	var defaultCamZoom:Float = 1.05;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var bfoffset = [0.0, 0.0];
	var gfoffset = [0.0, 0.0];
	var dadoffset = [0.0, 0.0];
	var inCutscene:Bool = false;
	var alwaysDoCutscenes = false;
	var fullComboMode:Bool = false;
	var perfectMode:Bool = false;
	var practiceMode:Bool = false;
	var healthGainModifier:Float = 0;
	var healthLossModifier:Float = 0;
	var supLove:Bool = false;
	var poisonExr:Bool = false;
	var poisonPlus:Bool = false;
	var beingPoisioned:Bool = false;
	var poisonTimes:Int = 0;
	var flippedNotes:Bool = false;
	var noteSpeed:Float = 0.45;
	var practiceDied:Bool = false;
	var practiceDieIcon:HealthIcon;
	private var regenTimer:FlxTimer;
	var sickFastTimer:FlxTimer;
	var accelNotes:Bool = false;
	var notesHit:Float = 0;
	var notesPassing:Int = 0;
	var vnshNotes:Bool = false;
	var invsNotes:Bool = false;
	var snakeNotes:Bool = false;
	var snekNumber:Float = 0;
	var drunkNotes:Bool = false;
	var alcholTimer:FlxTimer;
	var notesHitArray:Array<Date> = [];
	var alcholNumber:Float = 0;
	var inALoop:Bool = false;
	var useVictoryScreen:Bool = true;
	var demoMode:Bool = false;
	var downscroll:Bool = false;
	var luaRegistered:Bool = false;
	var currentFrames:Int = 0;
	public static var opponentPlayer:Bool = false;
	// this is just so i can collapse it lol
	#if true
	var hscriptStates:Map<String, Interp> = [];
	var exInterp:InterpEx = new InterpEx();
	var haxeSprites:Map<String, FlxSprite> = [];
	function callHscript(func_name:String, args:Array<Dynamic>, usehaxe:String) {
		// if function doesn't exist
		if (!hscriptStates.get(usehaxe).variables.exists(func_name)) {
			trace("Function doesn't exist, silently skipping...");
			return;
		}
		var method = hscriptStates.get(usehaxe).variables.get(func_name);
		switch(args.length) {
			case 0:
				method();
			case 1:
				method(args[0]);
		}
	}
	function callAllHScript(func_name:String, args:Array<Dynamic>) {
		for (key in hscriptStates.keys()) {
			callHscript(func_name, args, key);
		}
	}
	function setHaxeVar(name:String, value:Dynamic, usehaxe:String) {
		hscriptStates.get(usehaxe).variables.set(name,value);
	}
	function getHaxeVar(name:String, usehaxe:String):Dynamic {
		return hscriptStates.get(usehaxe).variables.get(name);
	}
	function setAllHaxeVar(name:String, value:Dynamic) {
		for (key in hscriptStates.keys())
			setHaxeVar(name, value, key);
	}
	function getHaxeActor(name:String):Dynamic {
		switch (name) {
			case "boyfriend" | "bf":
				return boyfriend;
			case "girlfriend" | "gf":
				return gf;
			case "dad":
				return dad;
			default:
				return strumLineNotes.members[Std.parseInt(name)];
		}
	}
	function makeHaxeState(usehaxe:String, path:String, filename:String) {
		trace("opening a haxe state (because we are cool :))");
		var parser = new ParserEx();
		var program = parser.parseString(FNFAssets.getText(path + filename));
		var interp = new Interp();
		// set vars
		interp.variables.set("BEHIND_GF", BEHIND_GF);
		interp.variables.set("BEHIND_BF", BEHIND_BF);
		interp.variables.set("BEHIND_DAD", BEHIND_DAD);
		interp.variables.set("BEHIND_ALL", BEHIND_ALL);
		interp.variables.set("BEHIND_NONE", 0);
		interp.variables.set("difficulty", storyDifficulty);
		interp.variables.set("bpm", Conductor.bpm);
		interp.variables.set("songData", SONG);
		interp.variables.set("curSong", SONG.song);
		interp.variables.set("curStep", 0);
		interp.variables.set("curBeat", 0);
		interp.variables.set("Conductor", Conductor);
		interp.variables.set("camHUD", camHUD);
		interp.variables.set("showOnlyStrums", false);
		interp.variables.set("playerStrums", playerStrums);
		interp.variables.set("enemyStrums", enemyStrums);
		interp.variables.set("mustHit", false);
		interp.variables.set("strumLineY", strumLine.y);
		interp.variables.set("FlxSprite", FlxSprite);
		interp.variables.set("FlxSound", FlxSound);
		interp.variables.set("FlxAtlasFrames", FlxAtlasFrames);
		interp.variables.set("FlxGroup",FlxGroup);
		interp.variables.set("FlxAngle", FlxAngle);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("Type", Type);
		interp.variables.set("hscriptPath", path);
		interp.variables.set("makeRangeArray", CoolUtil.numberArray);
		interp.variables.set("boyfriend", boyfriend);
		interp.variables.set("gf", gf);
		interp.variables.set("dad", dad);
		interp.variables.set("FNFAssets", HScriptAssets);
		// give them access to save data, everything will be fine ;)
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("FlxTimer", FlxTimer);
		interp.variables.set("FlxTween", FlxTween);
		interp.variables.set("Std", Std);
		interp.variables.set("isInCutscene", function () return inCutscene);
		interp.variables.set("MetroSprite", plugins.tools.MetroSprite);
		trace("set vars");
		// callbacks

		interp.variables.set("addSprite", function (sprite, position) {
			// sprite is a FlxSprite
			// position is a Int
			if (position & BEHIND_GF != 0)
				remove(gf);
			if (position & BEHIND_DAD != 0)
				remove(dad);
			if (position & BEHIND_BF != 0)
				remove(boyfriend);
			add(sprite);
			if (position & BEHIND_GF != 0)
				add(gf);
			if (position & BEHIND_DAD != 0)
				add(dad);
			if (position & BEHIND_BF != 0)
				add(boyfriend); 
		});
		interp.variables.set("setDefaultZoom", function(zoom) {defaultCamZoom = zoom;});
		interp.variables.set("removeSprite", function(sprite) {
			remove(sprite);
		});
		interp.variables.set("getHaxeActor", getHaxeActor);
		interp.variables.set("instancePluginClass", instanceExClass);
		trace("set stuff");
		interp.execute(program);
		hscriptStates.set(usehaxe,interp);
		callHscript("start", [SONG.song], usehaxe);
		trace('executed');
		
	}
	function instanceExClass(classname:String, args:Array<Dynamic> = null) {
		return exInterp.createScriptClassInstance(classname, args);
	}
	function makeHaxeExState(usehaxe:String, path:String, filename:String)
	{
		trace("opening a haxe state (because we are cool :))");
		var parser = new ParserEx();
		var program = parser.parseModule(FNFAssets.getText(path + filename));
		trace("set stuff");
		exInterp.registerModule(program);

		trace('executed');
	}
	#end
	override public function create()
	{
		misses = 0;
		bads = 0;
		goods = 0;
		sicks = 0;
		shits = 0;
		#if windows
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

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
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end
		
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];
		persistentUpdate = true;
		persistentDraw = true;
		alwaysDoCutscenes = OptionsHandler.options.alwaysDoCutscenes;
		useVictoryScreen = !OptionsHandler.options.skipVictoryScreen;
		downscroll = OptionsHandler.options.downscroll;
		if (!OptionsHandler.options.skipModifierMenu) {
			fullComboMode = ModifierState.modifiers[1].value;
			perfectMode = ModifierState.modifiers[0].value;
			practiceMode = ModifierState.modifiers[2].value;
			flippedNotes = ModifierState.modifiers[10].value;
			accelNotes= ModifierState.modifiers[13].value;
			vnshNotes = ModifierState.modifiers[14].value;
			invsNotes = ModifierState.modifiers[15].value;
			snakeNotes = ModifierState.modifiers[16].value;
			drunkNotes = ModifierState.modifiers[17].value;
			inALoop = ModifierState.modifiers[18].value;
			duoMode = ModifierState.modifiers[19].value;
			opponentPlayer = ModifierState.modifiers[20].value;
			demoMode = ModifierState.modifiers[21].value;
			if (ModifierState.modifiers[3].value) {
				healthGainModifier += 0.02;
			} else if (ModifierState.modifiers[4].value) {
				healthGainModifier -= 0.01;
			}
			if (ModifierState.modifiers[5].value) {
				healthLossModifier += 0.02;
			} else if (ModifierState.modifiers[6].value) {
				healthLossModifier -= 0.02;
			}
			if (ModifierState.modifiers[11].value)
				noteSpeed = 0.3;
			if (accelNotes) {
				noteSpeed = 0.45;
				trace("accel arrows");
			}


			if (ModifierState.modifiers[12].value)
				noteSpeed = 0.9;
			supLove = ModifierState.modifiers[7].value;
			poisonExr = ModifierState.modifiers[8].value;
			poisonPlus = ModifierState.modifiers[9].value;
		}

		if (opponentPlayer) {
			controlsPlayerTwo.setKeyboardScheme(Solo);
		} else {
			controlsPlayerTwo.setKeyboardScheme(Duo(false));
		}
		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		var sploosh = new NoteSplash(100, 100, 0);
		sploosh.alpha = 0.1;
		grpNoteSplashes.add(sploosh);
		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		backgroundgroup = new FlxTypedGroup<BeatSprite>();
		foregroundgroup  = new FlxTypedGroup<BeatSprite>();
		if (FNFAssets.exists('assets/images/custom_chars/' + SONG.player1 + '/' + SONG.song.toLowerCase() + 'Dialog.txt'))
		{
			dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/' + SONG.player1 + '/' + SONG.song.toLowerCase() + 'Dialog.txt');
			// haxe exclusive...
			// for each modifier... later mods preferred.
			for (mod in 0...22)
			{
				// evaluate this first to take advantage of short circut evaluation
				if (ModifierState.modifiers[mod].value
					&& FNFAssets.exists('assets/images/custom_chars/' + SONG.player1 + '/' + SONG.song.toLowerCase() + 'Dialog' + mod + '.txt'))
				{
					dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/' + SONG.player1 + '/' + SONG.song.toLowerCase() + 'Dialog' + mod
						+ '.txt');
				}
			}
			// if no player 1 unique dialog, use player 2
		}
		else if (FNFAssets.exists('assets/images/custom_chars/' + SONG.player2 + '/' + SONG.song.toLowerCase() + 'Dialog.txt'))
		{
			dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/' + SONG.player2 + '/' + SONG.song.toLowerCase() + 'Dialog.txt');
			for (mod in 0...22)
			{
				// evaluate this first to take advantage of short circut evaluation
				if (ModifierState.modifiers[mod].value
					&& FNFAssets.exists('assets/images/custom_chars/' + SONG.player2 + '/' + SONG.song.toLowerCase() + 'Dialog' + mod + '.txt'))
				{
					dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/' + SONG.player2 + '/' + SONG.song.toLowerCase() + 'Dialog' + mod
						+ '.txt');
				}
			}
			// if no player dialog, use default
		}
		else if (FNFAssets.exists('assets/data/' + SONG.song.toLowerCase() + '/dialog.txt'))
		{
			dialogue = CoolUtil.coolDynamicTextFile('assets/data/' + SONG.song.toLowerCase() + '/dialog.txt');
			for (mod in 0...22)
			{
				// evaluate this first to take advantage of short circut evaluation
				if (ModifierState.modifiers[mod].value
					&& FNFAssets.exists('assets/data/' + SONG.song.toLowerCase() + '/dialog' + mod + '.txt'))
				{
					dialogue = CoolUtil.coolDynamicTextFile('assets/data/' + SONG.song.toLowerCase() + '/dialog' + mod + '.txt');
				}
			}
		}
		else if (FNFAssets.exists('assets/data/' + SONG.song.toLowerCase() + '/dialogue.txt'))
		{
			// nerds spell dialogue properly gotta make em happy
			dialogue = CoolUtil.coolDynamicTextFile('assets/data/' + SONG.song.toLowerCase() + '/dialogue.txt');
			for (mod in 0...22)
			{
				// evaluate this first to take advantage of short circut evaluation
				if (ModifierState.modifiers[mod].value
					&& FNFAssets.exists('assets/data/' + SONG.song.toLowerCase() + '/dialogue' + mod + '.txt'))
				{
					dialogue = CoolUtil.coolDynamicTextFile('assets/data/' + SONG.song.toLowerCase() + '/dialogue' + mod + '.txt');
				}
			}
			// otherwise, make the dialog an error message
		}
		else
		{
			dialogue = [
				':dad: The game tried to get a dialog file but couldn\'t find it. Please make sure there is a dialog file named "dialog.txt".'
			];
		}
		#if false
		if (SONG.stage == 'spooky')
		{
			curStage = "spooky";
			halloweenLevel = true;

			var hallowTex = FlxAtlasFrames.fromSparrow('assets/images/halloween_bg.png', 'assets/images/halloween_bg.xml');

			halloweenBG = new FlxSprite(-200, -100);
			halloweenBG.frames = hallowTex;
			halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
			halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
			halloweenBG.animation.play('idle');
			halloweenBG.antialiasing = true;
			add(halloweenBG);

			isHalloween = true;
		}
		else if (SONG.stage == 'philly')
		{
			curStage = 'philly';

			var bg:FlxSprite = new FlxSprite(-100).loadGraphic('assets/images/philly/sky.png');
			bg.scrollFactor.set(0.1, 0.1);
			add(bg);

			var city:FlxSprite = new FlxSprite(-10).loadGraphic('assets/images/philly/city.png');
			city.scrollFactor.set(0.3, 0.3);
			city.setGraphicSize(Std.int(city.width * 0.85));
			city.updateHitbox();
			add(city);

			phillyCityLights = new FlxTypedGroup<FlxSprite>();
			add(phillyCityLights);

			for (i in 0...5)
			{
				var light:FlxSprite = new FlxSprite(city.x).loadGraphic('assets/images/philly/win' + i + '.png');
				light.scrollFactor.set(0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				light.antialiasing = true;
				phillyCityLights.add(light);
			}

			var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic('assets/images/philly/behindTrain.png');
			add(streetBehind);

			phillyTrain = new FlxSprite(2000, 360).loadGraphic('assets/images/philly/train.png');
			add(phillyTrain);

			trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
			FlxG.sound.list.add(trainSound);

			// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

			var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic('assets/images/philly/street.png');
			add(street);
		}
		else if (SONG.stage == 'limo')
		{
			curStage = 'limo';
			defaultCamZoom = 0.90;

			var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic('assets/images/limo/limoSunset.png');
			skyBG.scrollFactor.set(0.1, 0.1);
			add(skyBG);

			var bgLimo:FlxSprite = new FlxSprite(-200, 480);
			bgLimo.frames = FlxAtlasFrames.fromSparrow('assets/images/limo/bgLimo.png', 'assets/images/limo/bgLimo.xml');
			bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
			bgLimo.animation.play('drive');
			bgLimo.scrollFactor.set(0.4, 0.4);
			add(bgLimo);

			grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
			add(grpLimoDancers);

			for (i in 0...5)
			{
				var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
				dancer.scrollFactor.set(0.4, 0.4);
				grpLimoDancers.add(dancer);
			}

			var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic('assets/images/limo/limoOverlay.png');
			overlayShit.alpha = 0.5;
			// add(overlayShit);

			// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

			// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

			// overlayShit.shader = shaderBullshit;

			var limoTex = FlxAtlasFrames.fromSparrow('assets/images/limo/limoDrive.png', 'assets/images/limo/limoDrive.xml');

			limo = new FlxSprite(-120, 550);
			limo.frames = limoTex;
			limo.animation.addByPrefix('drive', "Limo stage", 24);
			limo.animation.play('drive');
			limo.antialiasing = true;

			fastCar = new FlxSprite(-300, 160).loadGraphic('assets/images/limo/fastCarLol.png');
			// add(limo);
		}
		else if (SONG.stage == 'mall')
		{
			curStage = 'mall';

			defaultCamZoom = 0.80;

			var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic('assets/images/christmas/bgWalls.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.2, 0.2);
			bg.active = false;
			bg.setGraphicSize(Std.int(bg.width * 0.8));
			bg.updateHitbox();
			add(bg);

			upperBoppers = new FlxSprite(-240, -90);
			upperBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/upperBop.png', 'assets/images/christmas/upperBop.xml');
			upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
			upperBoppers.antialiasing = true;
			upperBoppers.scrollFactor.set(0.33, 0.33);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic('assets/images/christmas/bgEscalator.png');
			bgEscalator.antialiasing = true;
			bgEscalator.scrollFactor.set(0.3, 0.3);
			bgEscalator.active = false;
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);

			var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic('assets/images/christmas/christmasTree.png');
			tree.antialiasing = true;
			tree.scrollFactor.set(0.40, 0.40);
			add(tree);

			bottomBoppers = new FlxSprite(-300, 140);
			bottomBoppers.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/bottomBop.png', 'assets/images/christmas/bottomBop.xml');
			bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
			bottomBoppers.antialiasing = true;
			bottomBoppers.scrollFactor.set(0.9, 0.9);
			bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
			bottomBoppers.updateHitbox();
			add(bottomBoppers);

			var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic('assets/images/christmas/fgSnow.png');
			fgSnow.active = false;
			fgSnow.antialiasing = true;
			add(fgSnow);

			santa = new FlxSprite(-840, 150);
			santa.frames = FlxAtlasFrames.fromSparrow('assets/images/christmas/santa.png', 'assets/images/christmas/santa.xml');
			santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
			santa.antialiasing = true;
			add(santa);
		}
		else if (SONG.stage == 'mallEvil')
		{
			curStage = 'mallEvil';
			var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic('assets/images/christmas/evilBG.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.2, 0.2);
			bg.active = false;
			bg.setGraphicSize(Std.int(bg.width * 0.8));
			bg.updateHitbox();
			add(bg);

			var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic('assets/images/christmas/evilTree.png');
			evilTree.antialiasing = true;
			evilTree.scrollFactor.set(0.2, 0.2);
			add(evilTree);

			var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic("assets/images/christmas/evilSnow.png");
			evilSnow.antialiasing = true;
			add(evilSnow);
		}
		else if (SONG.stage == 'school')
		{
			curStage = 'school';
			// defaultCamZoom = 0.9;

			var bgSky = new FlxSprite().loadGraphic('assets/images/weeb/weebSky.png');
			bgSky.scrollFactor.set(0.1, 0.1);
			add(bgSky);

			var repositionShit = -200;

			var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic('assets/images/weeb/weebSchool.png');
			bgSchool.scrollFactor.set(0.6, 0.90);
			add(bgSchool);

			var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic('assets/images/weeb/weebStreet.png');
			bgStreet.scrollFactor.set(0.95, 0.95);
			add(bgStreet);

			var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic('assets/images/weeb/weebTreesBack.png');
			fgTrees.scrollFactor.set(0.9, 0.9);
			add(fgTrees);

			var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
			var treetex = FlxAtlasFrames.fromSpriteSheetPacker('assets/images/weeb/weebTrees.png', 'assets/images/weeb/weebTrees.txt');
			bgTrees.frames = treetex;
			bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
			bgTrees.animation.play('treeLoop');
			bgTrees.scrollFactor.set(0.85, 0.85);
			add(bgTrees);

			var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
			treeLeaves.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/petals.png', 'assets/images/weeb/petals.xml');
			treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
			treeLeaves.animation.play('leaves');
			treeLeaves.scrollFactor.set(0.85, 0.85);
			add(treeLeaves);

			var widShit = Std.int(bgSky.width * 6);

			bgSky.setGraphicSize(widShit);
			bgSchool.setGraphicSize(widShit);
			bgStreet.setGraphicSize(widShit);
			bgTrees.setGraphicSize(Std.int(widShit * 1.4));
			fgTrees.setGraphicSize(Std.int(widShit * 0.8));
			treeLeaves.setGraphicSize(widShit);

			fgTrees.updateHitbox();
			bgSky.updateHitbox();
			bgSchool.updateHitbox();
			bgStreet.updateHitbox();
			bgTrees.updateHitbox();
			treeLeaves.updateHitbox();

			bgGirls = new BackgroundGirls(-100, 190);
			bgGirls.scrollFactor.set(0.9, 0.9);

			if (SONG.isMoody)
			{
				bgGirls.getScared();
			}

			bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
			bgGirls.updateHitbox();
			add(bgGirls);
		}
		else if (SONG.stage == 'schoolEvil')
		{
			curStage = 'schoolEvil';

			var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
			var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

			var posX = 400;
			var posY = 200;

			var bg:FlxSprite = new FlxSprite(posX, posY);
			bg.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/animatedEvilSchool.png', 'assets/images/weeb/animatedEvilSchool.xml');
			bg.animation.addByPrefix('idle', 'background 2', 24);
			bg.animation.play('idle');
			bg.scrollFactor.set(0.8, 0.9);
			bg.scale.set(6, 6);
			add(bg);
			trace("schoolEvilComplete");
		}
		else if (SONG.stage == "stage")
		{
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/stagefront.png');
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);

			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/stagecurtains.png');
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);
		}
		#end
		var gfVersion:String = 'gf';

		gfVersion = SONG.gf;
		trace(SONG.gf);
		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		dad = new Character(100, 100, SONG.player2);
		if (duoMode || opponentPlayer)
			dad.beingControlled = true;
		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			default:
				dad.x += dad.enemyOffsetX;
				dad.y += dad.enemyOffsetY;
				camPos.x += dad.camOffsetX;
				camPos.y += dad.camOffsetY;
				if (dad.likeGf) {
					dad.setPosition(gf.x, gf.y);
					gf.visible = false;
					if (isStoryMode)
					{
						camPos.x += 600;
						tweenCamIn();
					}
				}
		}



		boyfriend = new Character(770, 450, SONG.player1, true);
		if (!opponentPlayer)
			boyfriend.beingControlled = true;
		trace("newBF");
		switch (SONG.player1) // no clue why i didnt think of this before lol
		{
			default:
				//boyfriend.x += boyfriend.bfOffsetX; //just use sprite offsets
				//boyfriend.y += boyfriend.bfOffsetY;
				camPos.x += boyfriend.camOffsetX;
				camPos.y += boyfriend.camOffsetY;
				boyfriend.x += boyfriend.playerOffsetX;
				boyfriend.y += boyfriend.playerOffsetY;
				if (boyfriend.likeGf) {
					boyfriend.setPosition(gf.x, gf.y);
					gf.visible = false;
					if (isStoryMode)
					{
						camPos.x += 600;
						tweenCamIn();
					}
				}
		}

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'schoolEvil':
				// trailArea.scrollFactor.set();
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			default:
				boyfriend.x += bfoffset[0];
				boyfriend.y += bfoffset[1];
				gf.x += gfoffset[0];
				gf.y += gfoffset[1];
				dad.x += dadoffset[0];
				dad.y += dadoffset[1];

		}
		trace('befpre spoop check');
		if (SONG.isSpooky) {
			trace("WOAH SPOOPY");
			var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
			// evilTrail.changeValuesEnabled(false, false, false, false);
			// evilTrail.changeGraphic()
			add(evilTrail);
		}
		add(gf);
		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);
		add(foregroundgroup);
		trace('dad');
		add(dad);
		trace('dy UWU');
		add(boyfriend);
		trace('bf cheeks');

		var doof:DialogueBox = new DialogueBox(false, dialogue);
		trace('doofensmiz');
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		Conductor.songPosition = -5000;
		trace('prepare your strumlime');
		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		if (downscroll) {
			strumLine.y = FlxG.height - 165;
		}
		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);
		add(grpNoteSplashes);
		playerStrums = new FlxTypedGroup<FlxSprite>();
		enemyStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();
		trace('before generate');
		generateSong(SONG.song);

		// add(strumLine);
		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		trace('gay');
		healthBarBG = new FlxSprite(0, FlxG.height * 0.85).loadGraphic('assets/images/healthBar.png');
		if (downscroll)
			healthBarBG.y = FlxG.height * 0.1;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		var leftSideFill = opponentPlayer ? opponentColor : enemyColor;
		if (duoMode)
			leftSideFill = opponentColor;
		var rightSideFill = opponentPlayer ? bfColor : playerColor;
		if (duoMode)
			rightSideFill = bfColor;
		healthBar.createFilledBar(leftSideFill, rightSideFill);
		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x, healthBarBG.y + 40, 0, "", 200);
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();

		healthTxt = new FlxText(healthBarBG.x + healthBarBG.width - 300, scoreTxt.y, 0, "", 200);
		healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		healthTxt.scrollFactor.set();
		healthTxt.visible = false;
		accuracyTxt = new FlxText(healthBarBG.x, scoreTxt.y, 0, "", 200);
		accuracyTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		accuracyTxt.scrollFactor.set();
		// shitty work around but okay
		accuracyTxt.visible = false;
		difficTxt = new FlxText(10, FlxG.height, 0, "", 200);
		
		difficTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		difficTxt.scrollFactor.set();
		difficTxt.y -= difficTxt.height;
		if (downscroll) {
			difficTxt.y = 0;
		}
		// screwy way of getting text
		difficTxt.text = DifficultyIcons.changeDifficultyFreeplay(storyDifficulty, 0).text;
		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);
		practiceDieIcon = new HealthIcon('bf-old', false);
		practiceDieIcon.y = healthBar.y - (practiceDieIcon.height / 2);
		practiceDieIcon.x = healthBar.x - 130;
		practiceDieIcon.animation.curAnim.curFrame = 1;
		add(practiceDieIcon);
		grpNoteSplashes.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		practiceDieIcon.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		healthTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		accuracyTxt.cameras = [camHUD];
		difficTxt.cameras = [camHUD];
		practiceDieIcon.visible = false;

		add(scoreTxt);
		add(healthTxt);

		add(accuracyTxt);
		add(difficTxt);
		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
		trace('finish uo');
		
		var stageJson = CoolUtil.parseJson(FNFAssets.getText("assets/images/custom_stages/custom_stages.json"));
		makeHaxeState("stages", "assets/images/custom_stages/" + SONG.stage + "/", "../"+Reflect.field(stageJson, SONG.stage)+".hscript");
	if (alwaysDoCutscenes || isStoryMode )
		{

			switch (SONG.cutsceneType)
			{
				case "monster":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play('assets/sounds/Lights_Turn_On' + TitleState.soundExt);
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
				case 'senpai':
					schoolIntro(doof);
				case 'angry-senpai':
					FlxG.sound.play('assets/sounds/ANGRY' + TitleState.soundExt);
					schoolIntro(doof);
				case 'spirit':
					schoolIntro(doof);
				case 'none':
					startCountdown();
				default:
					if (SONG.cutsceneType.endsWith('-mp4'))
						videoIntro("assets/music/" + SONG.cutsceneType.substr(0, SONG.cutsceneType.length - 4)+'Cutscene.mp4');
						// :grief: idk how videos work
						// startCountdown();
					else
						schoolIntro(doof);
			}
		}
		else
		{

			startCountdown();
		}

		super.create();

	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();
		var senpaiSound:Sound;
		// try and find a player2 sound first
		if (FNFAssets.exists('assets/images/custom_chars/'+SONG.player2+'/Senpai_Dies.ogg')) {
			senpaiSound = FNFAssets.getSound('assets/images/custom_chars/'+SONG.player2+'/Senpai_Dies.ogg');
		// otherwise, try and find a song one
		} else if (FNFAssets.exists('assets/data/'+SONG.song.toLowerCase()+'/Senpai_Dies.ogg')) {
			senpaiSound = FNFAssets.getSound('assets/data/'+SONG.song.toLowerCase()+'Senpai_Dies.ogg');
		// otherwise, use the default sound
		} else {
			senpaiSound = FNFAssets.getSound('assets/sounds/Senpai_Dies.ogg');
		}
		var senpaiEvil:FlxSprite = new FlxSprite();
		// dialog box overwrites character
		if (FNFAssets.exists('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'/crazy.png')) {
			var evilImage = FNFAssets.getBitmapData('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'/crazy.png');
			var evilXml = FNFAssets.getText('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'/crazy.xml');
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow(evilImage, evilXml);
		// character then takes precendence over default
		// will make things like monika way way easier
		} else if (FNFAssets.exists('assets/images/custom_chars/'+SONG.player2+'/crazy.png')) {
			var evilImage = FNFAssets.getBitmapData('assets/images/custom_chars/'+SONG.player2+'/crazy.png');
			var evilXml = FNFAssets.getText('assets/images/custom_chars/'+SONG.player2+'/crazy.xml');
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow(evilImage, evilXml);
		} else {
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/senpaiCrazy.png', 'assets/images/weeb/senpaiCrazy.xml');
		}

		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		if (dad.isPixel) {
			senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		}
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (dialogueBox != null && dialogueBox.like != 'senpai')
		{
			remove(black);

			if (dialogueBox.like == 'spirit')
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

					if (dialogueBox.like == 'spirit')
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
								FlxG.sound.play(senpaiSound, 1, false, null, true, function()
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
	function videoIntro(filename:String) {
		startCountdown();
		/*
		var b = new FlxSprite(-200, -200).makeGraphic(2*FlxG.width,2*FlxG.height, -16777216);
		b.scrollFactor.set();
		add(b);
		trace(filename);
		new FlxVideo(filename).finishCallback = function () {
			remove(b);
			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});
			startCountdown();
		}*/
	}
	var startTimer:FlxTimer;
	var perfectModeOld:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);
		if (FNFAssets.exists("assets/data/" + SONG.song.toLowerCase() + "/modchart.hscript"))
		{
			makeHaxeState("modchart", "assets/data/" + SONG.song.toLowerCase() + "/", "/modchart.hscript");
		}
		if (duoMode)
		{
			controls.setKeyboardScheme(Duo(true));
		}
		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if (!duoMode || opponentPlayer)
				dad.dance();
			if (opponentPlayer)
				boyfriend.dance();
			gf.dance();


			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('normal', ['ready.png', "set.png", "go.png"]);
			introAssets.set('pixel', [
				'weeb/pixelUI/ready-pixel.png',
				'weeb/pixelUI/set-pixel.png',
				'weeb/pixelUI/date-pixel.png'
			]);
			for (field in CoolUtil.coolTextFile('assets/data/uitypes.txt')) {
				if (field != 'pixel' && field != 'normal') {
					if (FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						introAssets.set(field, ['custom_ui/ui_packs/'+field+'/ready-pixel.png','custom_ui/ui_packs/'+field+'/set-pixel.png','custom_ui/ui_packs/'+field+'/date-pixel.png']);
					else
						introAssets.set(field, ['custom_ui/ui_packs/'+field+'/ready.png','custom_ui/ui_packs/'+field+'/set.png','custom_ui/ui_packs/'+field+'/go.png']);
				}
			}

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";
			var intro3Sound:Sound;
			var intro2Sound:Sound;
			var intro1Sound:Sound;
			var introGoSound:Sound;
			for (value in introAssets.keys())
			{
				if (value == SONG.uiType)
				{
					introAlts = introAssets.get(value);
					// ok so apparently a leading slash means absolute soooooo
					if (SONG.uiType == 'pixel' || FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						altSuffix = '-pixel';
				}
			}
			if (SONG.uiType == 'normal') {
				intro3Sound = FNFAssets.getSound('assets/sounds/intro3.ogg');
				intro2Sound = FNFAssets.getSound('assets/sounds/intro2.ogg');
				intro1Sound = FNFAssets.getSound('assets/sounds/intro1.ogg');
				introGoSound = FNFAssets.getSound('assets/sounds/introGo.ogg');
			} else if (SONG.uiType == 'pixel') {
				intro3Sound = FNFAssets.getSound('assets/sounds/intro3-pixel.ogg');
				intro2Sound = FNFAssets.getSound('assets/sounds/intro2-pixel.ogg');
				intro1Sound = FNFAssets.getSound('assets/sounds/intro1-pixel.ogg');
				introGoSound = FNFAssets.getSound('assets/sounds/introGo-pixel.ogg');
			} else {
				// god is dead for we have killed him
				intro3Sound = FNFAssets.getSound("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro3'+altSuffix+'.ogg');
				intro2Sound = FNFAssets.getSound("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro2'+altSuffix+'.ogg');
				intro1Sound = FNFAssets.getSound("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro1'+altSuffix+'.ogg');
				// apparently this crashes if we do it from audio buffer?
				// no it just understands 'hey that file doesn't exist better do an error'
				introGoSound = FNFAssets.getSound("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/introGo'+altSuffix+'.ogg');
			}


			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(intro3Sound, 0.6);
				case 1:
					// my life is a lie, it was always this simple
					var readyImage = FNFAssets.getBitmapData('assets/images/'+introAlts[0]);
					var ready:FlxSprite = new FlxSprite().loadGraphic(readyImage);
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (SONG.uiType == 'pixel' || FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(intro2Sound, 0.6);
				case 2:
					var setImage = FNFAssets.getBitmapData('assets/images/'+introAlts[1]);
					// can't believe you can actually use this as a variable name
					var set:FlxSprite = new FlxSprite().loadGraphic(setImage);
					set.scrollFactor.set();

					if (SONG.uiType == 'pixel' || FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(intro1Sound, 0.6);
				case 3:
					var goImage = FNFAssets.getBitmapData('assets/images/'+introAlts[2]);
					var go:FlxSprite = new FlxSprite().loadGraphic(goImage);
					go.scrollFactor.set();

					if (SONG.uiType == 'pixel' || FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

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
					FlxG.sound.play(introGoSound, 0.6);
				case 4:
					// what is this here for?
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
		regenTimer = new FlxTimer().start(2, function (tmr:FlxTimer) {
			var bonus = 0.005;
			if (opponentPlayer) {
				bonus = -0.005;
			}
			if (poisonExr && !paused)
				health -= bonus;
			if (supLove && !paused)
				health +=  bonus;
		}, 0);
		sickFastTimer = new FlxTimer().start(2, function (tmr:FlxTimer) {
			if (accelNotes && !paused) {
				trace("tick:" + noteSpeed);
				noteSpeed += 0.01;
			}

		}, 0);
		var snekBase:Float = 0;
		var snekTimer = new FlxTimer().start(0.01, function (tmr:FlxTimer) {
			if (snakeNotes && !paused) {
				snekNumber = Math.sin(snekBase) * 100;
				snekBase += Math.PI/100;
			}

		}, 0);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;
		if (FlxG.sound.music != null) {
			// cuck lunchbox
			FlxG.sound.music.stop();
		}
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			#if sys
			FlxG.sound.playMusic(Sound.fromFile("assets/music/"+SONG.song+"_Inst"+TitleState.soundExt), 1, false);
			#else
			FlxG.sound.playMusic("assets/music/" + SONG.song + "_Inst" + TitleState.soundExt, 1, false);
			#end
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices) {
			#if sys
			var vocalSound = Sound.fromFile("assets/music/"+SONG.song+"_Voices"+TitleState.soundExt);
			vocals = new FlxSound().loadEmbedded(vocalSound);
			#else
			vocals = new FlxSound().loadEmbedded("assets/music/" + curSong + "_Voices" + TitleState.soundExt);
			#end
		}	else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		var customImage:Null<BitmapData> = null;
		var customXml:Null<String> = null;
		var arrowEndsImage:Null<BitmapData> = null;
		if (SONG.uiType != 'normal' && SONG.uiType != 'pixel') {
			if (FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml") && FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png")) {
				trace("has this been reached");
				customImage = FNFAssets.getBitmapData('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/NOTE_assets.png');
				customXml = FNFAssets.getText('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/NOTE_assets.xml');
			} else {
				customImage = FNFAssets.getBitmapData('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/arrows-pixels.png');
				arrowEndsImage = FNFAssets.getBitmapData('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/arrowEnds.png');
			}
		}

		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;
				var altNote:Bool = false;
				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}
				if (songNotes[3] || section.altAnim)
				{
					altNote = true;
				}
				
				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, customImage, customXml, arrowEndsImage);
				// altNote
				swagNote.altNote = altNote;
				// so much more complicated but makes playstation like shit work
				if (flippedNotes) {
					if (swagNote.animation.curAnim.name == 'greenScroll') {
						swagNote.animation.play('blueScroll');
					} else if (swagNote.animation.curAnim.name == 'blueScroll') {
						swagNote.animation.play('greenScroll');
					} else if (swagNote.animation.curAnim.name == 'redScroll') {
						swagNote.animation.play('purpleScroll');
					} else if (swagNote.animation.curAnim.name == 'purpleScroll') {
						swagNote.animation.play('redScroll');
					}
				}
				if (duoMode)
				{
					swagNote.duoMode = true;
				}
				if (opponentPlayer) {
					swagNote.oppMode = true;
				}
				if (demoMode)
					swagNote.funnyMode = true;
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				// when the imposter is sus XD
				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, customImage, customXml, arrowEndsImage);
					if (duoMode)
					{
						sustainNote.duoMode = true;
					}
					if (opponentPlayer)
					{
						sustainNote.oppMode = true;
					}
					if (demoMode)
						sustainNote.funnyMode = true;
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}


				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;
		// to get around how pecked up the note system is
		for (epicNote in unspawnNotes) {
			if (epicNote.isSustainNote) {
				if (flippedNotes) {
					if (epicNote.animation.curAnim.name == 'greenhold') {
						epicNote.animation.play('bluehold');
					} else if (epicNote.animation.curAnim.name == 'bluehold') {
						epicNote.animation.play('greenhold');
					} else if (epicNote.animation.curAnim.name == 'redhold') {
						epicNote.animation.play('purplehold');
					} else if (epicNote.animation.curAnim.name == 'purplehold') {
						epicNote.animation.play('redhold');
					} else if (epicNote.animation.curAnim.name == 'greenholdend') {
						epicNote.animation.play('blueholdend');
					} else if (epicNote.animation.curAnim.name == 'blueholdend') {
						epicNote.animation.play('greenholdend');
					} else if (epicNote.animation.curAnim.name == 'redholdend') {
						epicNote.animation.play('purpleholdend');
					} else if (epicNote.animation.curAnim.name == 'purpleholdend') {
						epicNote.animation.play('redholdend');
					}
				}
				if (downscroll) {
					if (epicNote.animation.curAnim.name == 'greenholdend' 
					|| epicNote.animation.curAnim.name == 'blueholdend'
						|| epicNote.animation.curAnim.name == 'redholdend'
						|| epicNote.animation.curAnim.name == 'purpleholdend')
					{
						epicNote.flipY = true;
					}
				}
			}
		}
		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);
			switch (SONG.uiType)
			{
				case 'pixel':
					babyArrow.loadGraphic('assets/images/weeb/pixelUI/arrows-pixels.png', true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);
					if (flippedNotes) {
						babyArrow.animation.add('blue', [6]);
						babyArrow.animation.add('purplel', [7]);
						babyArrow.animation.add('green', [5]);
						babyArrow.animation.add('red', [4]);
					}
					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					switch (Math.abs(i))
					{
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [1]);
								babyArrow.animation.add('pressed', [5, 9], 12, false);
								babyArrow.animation.add('confirm', [13, 17], 12, false);
							}
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [0]);
								babyArrow.animation.add('pressed', [4, 8], 12, false);
								babyArrow.animation.add('confirm', [12, 16], 24, false);
							}
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [2]);
								babyArrow.animation.add('pressed', [6, 10], 12, false);
								babyArrow.animation.add('confirm', [14, 18], 12, false);
							}
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
							if (flippedNotes) {
								babyArrow.animation.add('static', [3]);
								babyArrow.animation.add('pressed', [7, 11], 12, false);
								babyArrow.animation.add('confirm', [15, 19], 24, false);
							}
					}

				case 'normal':
					babyArrow.frames = FlxAtlasFrames.fromSparrow('assets/images/NOTE_assets.png', 'assets/images/NOTE_assets.xml');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
					if (flippedNotes) {
						babyArrow.animation.addByPrefix('blue', 'arrowUP');
						babyArrow.animation.addByPrefix('green', 'arrowDOWN');
						babyArrow.animation.addByPrefix('red', 'arrowLEFT');
						babyArrow.animation.addByPrefix('purple', 'arrowRIGHT');
					}
					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowDOWN');
								babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
							}
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowLEFT');
								babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
							}
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowUP');
								babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
							}
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
							if (flippedNotes) {
								babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
								babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
							}
					}
				default:
					if (FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml") && FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png")) {

					  var noteXml = FNFAssets.getText('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml");
						var notePic = FNFAssets.getBitmapData('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png");
						babyArrow.frames = FlxAtlasFrames.fromSparrow(notePic, noteXml);
						babyArrow.animation.addByPrefix('green', 'arrowUP');
						babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
						babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
						babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
						if (flippedNotes) {
							babyArrow.animation.addByPrefix('blue', 'arrowUP');
							babyArrow.animation.addByPrefix('green', 'arrowDOWN');
							babyArrow.animation.addByPrefix('red', 'arrowLEFT');
							babyArrow.animation.addByPrefix('purple', 'arrowRIGHT');
						}
						babyArrow.antialiasing = true;
						babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

						switch (Math.abs(i))
						{
							case 2:
								babyArrow.x += Note.swagWidth * 2;
								babyArrow.animation.addByPrefix('static', 'arrowUP');
								babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								}
							case 3:
								babyArrow.x += Note.swagWidth * 3;
								babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
								babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								}
							case 1:
								babyArrow.x += Note.swagWidth * 1;
								babyArrow.animation.addByPrefix('static', 'arrowDOWN');
								babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								}
							case 0:
								babyArrow.x += Note.swagWidth * 0;
								babyArrow.animation.addByPrefix('static', 'arrowLEFT');
								babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								}
						}

					} else if (FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png")){
						var notePic = FNFAssets.getBitmapData('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png");
						babyArrow.loadGraphic(notePic, true, 17, 17);
						babyArrow.animation.add('green', [6]);
						babyArrow.animation.add('red', [7]);
						babyArrow.animation.add('blue', [5]);
						babyArrow.animation.add('purplel', [4]);
						if (flippedNotes) {
							babyArrow.animation.add('blue', [6]);
							babyArrow.animation.add('purplel', [7]);
							babyArrow.animation.add('green', [5]);
							babyArrow.animation.add('red', [4]);
						}
						babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
						babyArrow.updateHitbox();
						babyArrow.antialiasing = false;

						switch (Math.abs(i))
						{
							case 2:
								babyArrow.x += Note.swagWidth * 2;
								babyArrow.animation.add('static', [2]);
								babyArrow.animation.add('pressed', [6, 10], 12, false);
								babyArrow.animation.add('confirm', [14, 18], 12, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [1]);
									babyArrow.animation.add('pressed', [5, 9], 12, false);
									babyArrow.animation.add('confirm', [13, 17], 12, false);
								}
							case 3:
								babyArrow.x += Note.swagWidth * 3;
								babyArrow.animation.add('static', [3]);
								babyArrow.animation.add('pressed', [7, 11], 12, false);
								babyArrow.animation.add('confirm', [15, 19], 24, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [0]);
									babyArrow.animation.add('pressed', [4, 8], 12, false);
									babyArrow.animation.add('confirm', [12, 16], 24, false);
								}
							case 1:
								babyArrow.x += Note.swagWidth * 1;
								babyArrow.animation.add('static', [1]);
								babyArrow.animation.add('pressed', [5, 9], 12, false);
								babyArrow.animation.add('confirm', [13, 17], 24, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [2]);
									babyArrow.animation.add('pressed', [6, 10], 12, false);
									babyArrow.animation.add('confirm', [14, 18], 12, false);
								}
							case 0:
								babyArrow.x += Note.swagWidth * 0;
								babyArrow.animation.add('static', [0]);
								babyArrow.animation.add('pressed', [4, 8], 12, false);
								babyArrow.animation.add('confirm', [12, 16], 24, false);
								if (flippedNotes) {
									babyArrow.animation.add('static', [3]);
									babyArrow.animation.add('pressed', [7, 11], 12, false);
									babyArrow.animation.add('confirm', [15, 19], 24, false);
								}
						}
					} else {
						// no crashing today :)
						babyArrow.frames = FlxAtlasFrames.fromSparrow('assets/images/NOTE_assets.png', 'assets/images/NOTE_assets.xml');
						babyArrow.animation.addByPrefix('green', 'arrowUP');
						babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
						babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
						babyArrow.animation.addByPrefix('red', 'arrowRIGHT');
						if (flippedNotes) {
							babyArrow.animation.addByPrefix('blue', 'arrowUP');
							babyArrow.animation.addByPrefix('green', 'arrowDOWN');
							babyArrow.animation.addByPrefix('red', 'arrowLEFT');
							babyArrow.animation.addByPrefix('purple', 'arrowRIGHT');
						}
						babyArrow.antialiasing = true;
						babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

						switch (Math.abs(i))
						{
							case 2:
								babyArrow.x += Note.swagWidth * 2;
								babyArrow.animation.addByPrefix('static', 'arrowUP');
								babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowDOWN');
									babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								}
							case 3:
								babyArrow.x += Note.swagWidth * 3;
								babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
								babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowLEFT');
									babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								}
							case 1:
								babyArrow.x += Note.swagWidth * 1;
								babyArrow.animation.addByPrefix('static', 'arrowDOWN');
								babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowUP');
									babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
								}
							case 0:
								babyArrow.x += Note.swagWidth * 0;
								babyArrow.animation.addByPrefix('static', 'arrowLEFT');
								babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
								babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
								if (flippedNotes) {
									babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
									babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
									babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
								}
						}
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
			{
				playerStrums.add(babyArrow);
			} else {
				enemyStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
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

			#if windows
			DiscordClient.changePresence("PAUSED on "
				+ SONG.song
				+ " ("
				+ storyDifficultyText
				+ ") "
				+ Ratings.GenerateLetterRank(accuracy),
				"Acc: "
				+ HelperFunctions.truncateFloat(accuracy, 2)
				+ "% | Score: "
				+ songScore
				+ " | Misses: "
				+ misses, iconRPC, null, null, playingAsRpc);
			#end
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
			var currentIconState = "";
			if (opponentPlayer)
			{
				if (healthBar.percent > 80)
				{
					currentIconState = "Dying";
				}
				else
				{
					currentIconState = "Playing";
				}
				if (poisonTimes != 0)
				{
					currentIconState = "Being Posioned";
				}
			}
			else
			{
				if (healthBar.percent > 20)
				{
					currentIconState = "Dying";
				}
				else
				{
					currentIconState = "Playing";
				}
				if (poisonTimes != 0)
				{
					currentIconState = "Being Posioned";
				}
			}
			#if windows
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText
					+ " "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC, true,
					songLength
					- Conductor.songPosition, playingAsRpc);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy), iconRPC,
					playingAsRpc);
			}
			#end
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
		
		#if windows
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC,
			playingAsRpc);
		#end
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectModeOld = false;
		#end
		
		callAllHScript('update', [elapsed]);
		if (hscriptStates.exists("modchart")) {
			if (getHaxeVar("showOnlyStrums", "modchart"))
			{
				healthBarBG.visible = false;
				healthBar.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
				scoreTxt.visible = false;
			}
			else
			{
				healthBarBG.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
				scoreTxt.visible = true;
			}

		}
		if (currentFrames == FlxG.save.data.fpsCap)
		{
			for (i in 0...notesHitArray.length)
			{
				var cock:Date = notesHitArray[i];
				if (cock != null)
					if (cock.getTime() + 2000 < Date.now().getTime())
						notesHitArray.remove(cock);
			}
			nps = Math.floor(notesHitArray.length / 2);
			currentFrames = 0;
		}
		else
			currentFrames++;
		super.update(elapsed);
		var properHealth = opponentPlayer ? 100 - Math.round(health*50) : Math.round(health*50);
		healthTxt.text = "Health:" + properHealth + "%";
		if (notesPassing != 0)
			accuracy = HelperFunctions.truncateFloat((notesHit / notesPassing) * 100, 2);
		else
			accuracy = 100;
		scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, nps, accuracy);
		if (notesPassing != 0) {
			accuracyTxt.text = "Accuracy:" + accuracy + "%";
		} else {
			accuracyTxt.text = "Accuracy:100%";
		}
		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			#if windows
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
			FlxG.switchState(new ChartingState());
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));
		practiceDieIcon.setGraphicSize(Std.int(FlxMath.lerp(150, practiceDieIcon.width, 0.50)));
		iconP1.updateHitbox();
		iconP2.updateHitbox();
		practiceDieIcon.updateHitbox();
		var iconOffset:Int = 26;
		
		if (poisonTimes > 0 && !barShowingPoison) {
			var leftSideFill = opponentPlayer ? poisonColorEnemy : enemyColor;
			var rightSideFill = opponentPlayer ? bfColor : poisonColor;
			healthBar.createFilledBar(leftSideFill, rightSideFill);
			barShowingPoison = true;
		} else if (poisonTimes == 0 && barShowingPoison) {
			var leftSideFill = opponentPlayer ? opponentColor : enemyColor;
			var rightSideFill = opponentPlayer ? bfColor : playerColor;
			if (duoMode) {
				leftSideFill = opponentColor;
				rightSideFill = bfColor;
			}
			healthBar.createFilledBar(leftSideFill, rightSideFill);
			barShowingPoison = false;
		}

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
		player1Icon = SONG.player1;
		switch(SONG.player1) {
			case "bf-car":
				player1Icon = "bf";
			case "bf-christmas":
				player1Icon = "bf";
			case "bf-holding-gf":
				player1Icon = "bf";
			case "monster-christmas":
				player1Icon = "monster";
			case "mom-car":
				player1Icon = "mom";
			case "pico-speaker":
				player1Icon = "pico";
			case "gf-car":
				player1Icon = "gf";
			case "gf-christmas":
				player1Icon = "gf";
			case "gf-pixel":
				player1Icon = "gf";
			case "gf-tankman":
				player1Icon = "gf";
				
		}
		if (poisonTimes == 0 || opponentPlayer) {
			if (healthBar.percent < 20) {
				iconP1.animation.curAnim.curFrame = 1;
				#if windows
				iconRPC = player1Icon+"-dead";
				#end
			}
			else {
				iconP1.animation.curAnim.curFrame = 0;
				#if windows
				iconRPC = player1Icon;
				#end
			}

		} else {
			if (!opponentPlayer) {
				iconP1.animation.curAnim.curFrame = 2;
				#if windows
				iconRPC = player1Icon+"-dazed";
				#end
			}	
			
		}
		// duo mode shouldn't show low health
		if (properHealth < 20 && !duoMode) {
			healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.RED, RIGHT, OUTLINE, FlxColor.BLACK);
		} else {
			healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		}	
		player2Icon = SONG.player2;
		switch (SONG.player2)
		{
			case "bf-car":
				player2Icon = "bf";
			case "bf-christmas":
				player2Icon = "bf";
			case "bf-holding-gf":
				player2Icon = "bf";
			case "monster-christmas":
				player2Icon = "monster";
			case "mom-car":
				player2Icon = "mom";
			case "pico-speaker":
				player2Icon = "pico";
			case "gf-car":
				player2Icon = "gf";
			case "gf-christmas":
				player2Icon = "gf";
			case "gf-pixel":
				player2Icon = "gf";
			case "gf-tankman":
				player2Icon = "gf";
		}

		if (healthBar.percent > 80) {
			iconP2.animation.curAnim.curFrame = 1;
			#if windows
			if (opponentPlayer)
				iconRPC = player2Icon + "-dead";
			#end
		}
		else {
			iconP2.animation.curAnim.curFrame = 0;
			#if windows
			if (opponentPlayer)
				iconRPC = player2Icon;
			#end
		}
			
		if (poisonTimes != 0 && opponentPlayer) {
			iconP2.animation.curAnim.curFrame = 2;
			#if windows
			if (opponentPlayer)
				iconRPC = player2Icon + "-dazed";
			#end
		}
			
		
		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		if (FlxG.keys.justPressed.EIGHT) // stop checking for debug so i can fix my offsets!
			FlxG.switchState(new AnimationDebug(SONG.player2, SONG.player1));

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
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

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

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (curBeat % 4 == 0)
			{
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}
			setAllHaxeVar("mustHit", PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
				callAllHScript("playerTwoTurn", []);
				if (dad.like == 'mom')
					camFollow.y = dad.getMidpoint().y;
				if (dad.like == 'senpai' || dad.like == 'senpai-angry') {
					camFollow.y = dad.getMidpoint().y - 430;
					camFollow.x = dad.getMidpoint().x - 100;
				}
				if (dad.isCustom) {
					camFollow.y = dad.getMidpoint().y + dad.followCamY;
					camFollow.x = dad.getMidpoint().x + dad.followCamX;
				}
				vocals.volume = 1;
				/*
				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
				*/
			}
			var currentIconState = "";
			if (opponentPlayer)
			{
				if (healthBar.percent > 80)
				{
					currentIconState = "Dying";
				}
				else
				{
					currentIconState = "Playing";
				}
				if (poisonTimes != 0)
				{
					currentIconState = "Being Posioned";
				}
			}
			else
			{
				if (healthBar.percent < 20)
				{
					currentIconState = "Dying";
				}
				else
				{
					currentIconState = "Playing";
				}
				if (poisonTimes != 0)
				{
					currentIconState = "Being Posioned";
				}
			}
			playingAsRpc = "Playing as " + (opponentPlayer ? player2Icon : player1Icon) + " | " + currentIconState;
			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition((boyfriend.getMidpoint().x - 100 + boyfriend.followCamX), (boyfriend.getMidpoint().y - 100+boyfriend.followCamY));
				callAllHScript("playerOneTurn", []);
				switch (curStage)
				{
					// not sure that's how variable assignment works
					#if !windows
					case 'limo':
						camFollow.x = boyfriend.getMidpoint().x - 300 + boyfriend.followCamX; // why are you hard coded
					
					case 'mall':
						camFollow.y = boyfriend.getMidpoint().y - 200 + boyfriend.followCamY;
					#end
					case 'school':
						camFollow.x = boyfriend.getMidpoint().x - 200 + boyfriend.followCamX;
						camFollow.y = boyfriend.getMidpoint().y - 200 + boyfriend.followCamY;
					case 'schoolEvil':
						camFollow.x = boyfriend.getMidpoint().x - 200 + boyfriend.followCamX;
						camFollow.y = boyfriend.getMidpoint().y - 200 + boyfriend.followCamY;
				}
				
				/*
				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
				*/
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
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
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}
		// better streaming of shit

		// RESET = Quick Game Over Screen
		if (controls.RESET)
		{
			health = 0;
			trace("RESET = True");
		}

		// CHEAT = brandon's a pussy
		if (controls.CHEAT)
		{
			health += 1;
			trace("User is cheating!");
		}

		if (((health <= 0 && !opponentPlayer) || (health >= 2 && opponentPlayer)) && !practiceMode && !duoMode)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();
			
			if (inALoop) {
				FlxG.switchState(new PlayState());
			} else {
				// 1 / 1000 chance for Gitaroo Man easter egg
				if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					FlxG.switchState(new GitarooPause());
				}
				else
					openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				#if windows
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("GAME OVER -- "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC, null, null,
					playingAsRpc);
				#end

			}

			
			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}
		else if (((health <= 0 && !opponentPlayer) || (health >= 2 && opponentPlayer)) && !practiceDied && practiceMode) {
			practiceDied = true;
			practiceDieIcon.visible = true;
		}
		health = FlxMath.bound(health,0,2);
		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = !invsNotes;
					daNote.active = true;
				}
				if (!daNote.modifiedByLua) {
					if (downscroll) {
						daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));
					} else {
						daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(SONG.speed, 2)));
					}
					

					// i am so fucking sorry for this if condition
					if (daNote.isSustainNote
						&& (((daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2) && !downscroll)
						|| (downscroll && (daNote.y + daNote.offset.y >= strumLine.y + Note.swagWidth / 2)))
						&& (((!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))) && !opponentPlayer && !duoMode)
						|| ((daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))) && opponentPlayer)))
					{
						var swagRect = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
						swagRect.y /= daNote.scale.y;
						swagRect.height -= swagRect.y;

						daNote.clipRect = swagRect;
					}
				}
				

				if (!daNote.mustPress && daNote.wasGoodHit && ((!duoMode && !opponentPlayer) || demoMode))
				{
					/*
					if (SONG.song != 'Tutorial')
						camZooming = true;
					*/
					var altAnim:String = "";
					
					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if ((SONG.notes[Math.floor(curStep / 16)].altAnimNum > 0 && SONG.notes[Math.floor(curStep / 16)].altAnimNum != null) || SONG.notes[Math.floor(curStep / 16)].altAnim)
							// backwards compatibility shit
							if (SONG.notes[Math.floor(curStep / 16)].altAnimNum == 1 || SONG.notes[Math.floor(curStep / 16)].altAnim || daNote.altNote)
								altAnim = '-alt';
							else if (SONG.notes[Math.floor(curStep / 16)].altAnimNum != 0)
								altAnim = '-' + SONG.notes[Math.floor(curStep / 16)].altAnimNum+'alt';
					}
					if (daNote.altNote) {
						altAnim = '-alt';
					}
					callAllHScript("playerTwoSing", []);
					switch (Math.abs(daNote.noteData))
					{
						case 0:
							
							dad.playAnim('singLEFT' + altAnim, true);
						case 1:
							dad.playAnim('singDOWN' + altAnim, true);
						case 2:
							dad.playAnim('singUP' + altAnim, true);
						case 3:
							dad.playAnim('singRIGHT' + altAnim, true);
					}
					enemyStrums.forEach(function(spr:FlxSprite)
					{
						if (Math.abs(daNote.noteData) == spr.ID)
						{
							spr.animation.play('confirm');
							sustain2(spr.ID, spr, daNote);
						}
					});
					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				} else if (daNote.mustPress && daNote.wasGoodHit && (opponentPlayer || demoMode)) {
					callAllHScript("playerOneSing", []);
					switch (Math.abs(daNote.noteData))
					{
						case 0:
							boyfriend.playAnim('singLEFT', true);
						case 1:
							boyfriend.playAnim('singDOWN', true);
						case 2:
							boyfriend.playAnim('singUP', true);
						case 3:
							boyfriend.playAnim('singRIGHT', true);
					}
					playerStrums.forEach(function(spr:FlxSprite)
					{
						if (Math.abs(daNote.noteData) == spr.ID)
						{
							spr.animation.play('confirm');
							sustain2(spr.ID, spr, daNote);
						}
					});
					boyfriend.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				var neg = downscroll ? -1 : 1;
				if (drunkNotes) {
					daNote.y = (strumLine.y - neg * (Conductor.songPosition - daNote.strumTime) * ((Math.sin(songTime/400)/6)+0.5) * noteSpeed * FlxMath.roundDecimal(PlayState.SONG.speed, 2));
				} else {
					daNote.y = (strumLine.y - neg * (Conductor.songPosition - daNote.strumTime) * (noteSpeed * FlxMath.roundDecimal(PlayState.SONG.speed, 2)));
				}
				if (vnshNotes) {
					if (downscroll) {
						daNote.alpha = FlxMath.remapToRange(daNote.y, 0,strumLine.y , 0, 1);
					} else {
						daNote.alpha = FlxMath.remapToRange(daNote.y, strumLine.y, FlxG.height, 0, 1);
					}
				}
					
				if (snakeNotes) {
					if (daNote.mustPress) {
						daNote.x = (FlxG.width/2)+snekNumber+(Note.swagWidth*daNote.noteData)+50;
					} else {
						daNote.x = snekNumber+(Note.swagWidth*daNote.noteData)+50;
					}
				}
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if ((daNote.y < -daNote.height && !downscroll) || (daNote.y > FlxG.height + daNote.height && downscroll))
				{

						if ((daNote.tooLate || !daNote.wasGoodHit) && !daNote.isSustainNote)
						{
							if (!daNote.mustPress) {
								health += 0.0475;
							} else if (!opponentPlayer) {
								health -= 0.0475;
							}
							
							vocals.volume = 0;
							if (poisonPlus && poisonTimes < 3)
							{
								poisonTimes += 1;
								var poisonPlusTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer)
								{
									if (opponentPlayer)
										health += 0.04;
									else
										health -= 0.04;
								}, 0);
								// stop timer after 3 seconds
								new FlxTimer().start(3, function(tmr:FlxTimer)
								{
									poisonPlusTimer.cancel();
									poisonTimes -= 1;
								});
							}
							if (fullComboMode || perfectMode)
							{
								// you signed up for this your fault
								if (opponentPlayer)
									health = 2;
								else
									health = 0;
							}
						}

						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
				}
				if ((!duoMode && !opponentPlayer) || demoMode) {
					enemyStrums.forEach(function(spr:FlxSprite)
					{
						if (strumming2[spr.ID])
						{
							spr.animation.play("confirm");
						}

						if (spr.animation.curAnim.name == 'confirm' && !daNote.isPixel)
						{
							spr.centerOffsets();
							spr.offset.x -= 13;
							spr.offset.y -= 13;
						}
						else
							spr.centerOffsets();
					});
				} 
				if (opponentPlayer || demoMode) {
					playerStrums.forEach(function(spr:FlxSprite)
					{
						if (strumming1[spr.ID])
						{
							spr.animation.play("confirm");
						}

						if (spr.animation.curAnim.name == 'confirm' && !daNote.isPixel)
						{
							spr.centerOffsets();
							spr.offset.x -= 13;
							spr.offset.y -= 13;
						}
						else
							spr.centerOffsets();
					});
				}
				
			});
		}

		if (!inCutscene && !demoMode) {
			// is that why it was crashing
			if (!opponentPlayer)
				keyShit(true);
			if (duoMode || opponentPlayer)
			{
				keyShit(false);
			}
		}
			

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}
	function sustain2(strum:Int, spr:FlxSprite, note:Note):Void
	{
		var length:Float = note.sustainLength;
		
		if (length > 0)
		{
			if (opponentPlayer)
				strumming1[strum] = true;
			else
				strumming2[strum] = true;
		}

		var bps:Float = Conductor.bpm / 60;
		var spb:Float = 1 / bps;

		if (!note.isSustainNote)
		{
			new FlxTimer().start(length == 0 ? 0.2 : (length / Conductor.crochet * spb) + 0.1, function(tmr:FlxTimer)
			{
				if (opponentPlayer) {
					if (!strumming1[strum])
					{
						spr.animation.play("static", true);
					}
					else if (length > 0)
					{
						strumming1[strum] = false;
						spr.animation.play("static", true);
					}
				} else {
					if (!strumming2[strum])
					{
						spr.animation.play("static", true);
					}
					else if (length > 0)
					{
						strumming2[strum] = false;
						spr.animation.play("static", true);
					}
				}
				
			});
		}
	}
	function endSong():Void
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		
		#if !switch
		Highscore.saveScore(SONG.song, songScore, storyDifficulty, (notesHit / notesPassing));
		#end
		controls.setKeyboardScheme(Solo);
		if (isStoryMode)
		{
			campaignScore += songScore;
			campaignScoreDef += songScoreDef;
			campaignAccuracy += notesHit/notesPassing;
			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);

				
				Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty, campaignAccuracy / defaultPlaylistLength);
				campaignAccuracy = campaignAccuracy / defaultPlaylistLength;
				if (useVictoryScreen) {
					#if windows	
					DiscordClient.changePresence("Reviewing Score -- "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC, playingAsRpc);
					#end
					FlxG.switchState(new VictoryLoopState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, gf.getScreenPosition().x, gf.getScreenPosition().y, campaignAccuracy, campaignScore, dad.getScreenPosition().x, dad.getScreenPosition().y));
				} else {
					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;
					FlxG.switchState(new StoryMenuState());
				}
				FlxG.save.flush();
			}
			else
			{
				var difficulty:String = "";

				difficulty = DifficultyIcons.getEndingFP(storyDifficulty);
				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play('assets/sounds/Lights_Shut_off' + TitleState.soundExt);
				}

				if (SONG.song.toLowerCase() == 'senpai')
				{
					FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;
				}
				if (FNFAssets.exists('assets/data/'+PlayState.storyPlaylist[0].toLowerCase()+'/'+PlayState.storyPlaylist[0].toLowerCase()+difficulty+'.json'))
				  // do this to make custom difficulties not as unstable
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				else
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase(), PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				FlxG.switchState(new PlayState());
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			if (useVictoryScreen) {
				#if windows
				DiscordClient.changePresence("Reviewing Score -- "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC, playingAsRpc);
				#end
				FlxG.switchState(new VictoryLoopState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, gf.getScreenPosition().x,gf.getScreenPosition().y, notesHit/notesPassing, songScore, dad.getScreenPosition().x, dad.getScreenPosition().y));
			} else
				FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float, daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * 0.9)
		{
			daRating = 'shit';
			score = 50;
			notesHit += 0.25;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.75)
		{
			bads += 1;
			daRating = 'bad';
			score = 100;
			notesHit += 0.75;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
			// good needs to be punished somewhat
			notesHit += 0.95;
		} else {
			var recycledNote = grpNoteSplashes.recycle(NoteSplash);
			recycledNote.setupNoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(recycledNote);
		}
		if (daRating == 'sick')
			notesHit += 1;
		if (daRating != "sick" && perfectMode) {
			if (opponentPlayer)
				health = 50;
			else 
				health = -50;
		}
		if (notesHit > notesPassing) {
			notesHit = notesPassing;
		}
		songScore += Math.round(score * ModifierState.scoreMultiplier);
		songScoreDef += Math.round(ConvertScore.convertScore(noteDiff));
		trueScore += score;
		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';
		if (FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png")) {
			pixelShitPart2 = '-pixel';
		}
		var ratingImage:BitmapData;
		switch (SONG.uiType) {
			case 'pixel':
				ratingImage = FNFAssets.getBitmapData('assets/images/weeb/pixelUI/'+daRating+'-pixel.png');
			case 'normal':
				ratingImage = FNFAssets.getBitmapData('assets/images/'+daRating+'.png');
			default:
				ratingImage = FNFAssets.getBitmapData('assets/images/custom_ui/ui_packs/'+PlayState.SONG.uiType+'/'+daRating+pixelShitPart2+".png");
		}

		rating.loadGraphic(ratingImage);
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(ratingImage);
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);
		// gonna be fun explaining this
		if (SONG.uiType != 'pixel' && !FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = true;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numImage:BitmapData;
			switch (SONG.uiType) {
				case 'pixel':
					numImage = FNFAssets.getBitmapData('assets/images/weeb/pixelUI/num'+Std.int(i)+'-pixel.png');
				case 'normal':
					numImage = FNFAssets.getBitmapData('assets/images/num'+Std.int(i)+'.png');
				default:
					numImage = FNFAssets.getBitmapData('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/num'+Std.int(i)+pixelShitPart2+".png");
			}
			var numScore:FlxSprite = new FlxSprite().loadGraphic(numImage);
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (SONG.uiType != 'pixel' && !FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
			{
				numScore.antialiasing = true;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/*
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit(?playerOne:Bool=true):Void
	{
		// HOLDING
		var coolControls = playerOne ? controls : controlsPlayerTwo;
		var up = coolControls.UP;
		var right = coolControls.RIGHT;
		var down = coolControls.DOWN;
		var left = coolControls.LEFT;

		var upP = coolControls.UP_P;
		var rightP = coolControls.RIGHT_P;
		var downP = coolControls.DOWN_P;
		var leftP = coolControls.LEFT_P;

		var upR = coolControls.UP_R;
		var rightR = coolControls.RIGHT_R;
		var downR = coolControls.DOWN_R;
		var leftR = coolControls.LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

		// FlxG.watch.addQuick('asdfa', upP);
		var actingOn:Character = playerOne ? boyfriend : dad;

		if ((upP || rightP || downP || leftP) && !actingOn.stunned && generatedMusic)
		{
			actingOn.holdTimer = 0;

			var possibleNotes:Array<Note> = [];

			var ignoreList:Array<Int> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				var coolShouldPress = playerOne ? daNote.mustPress : !daNote.mustPress;
				if (daNote.canBeHit && coolShouldPress && !daNote.tooLate)
				{
					// the sorting probably doesn't need to be in here? who cares lol
					possibleNotes.push(daNote);
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					ignoreList.push(daNote.noteData);
				}
			});

			if (possibleNotes.length > 0)
			{
				var daNote = possibleNotes[0];

				if (perfectModeOld)
					noteCheck(true, daNote);

				// Jump notes
				if (possibleNotes.length >= 2)
				{
					if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
					{
						for (coolNote in possibleNotes)
						{
							if (controlArray[coolNote.noteData])
								goodNoteHit(coolNote,playerOne);
							else
							{
								var inIgnoreList:Bool = false;
								for (shit in 0...ignoreList.length)
								{
									if (controlArray[ignoreList[shit]])
										inIgnoreList = true;
								}
								if (!inIgnoreList)
									badNoteCheck(playerOne);
							}
						}
					}
					else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
					{
						noteCheck(controlArray[daNote.noteData], daNote, playerOne);
					}
					else
					{
						for (coolNote in possibleNotes)
						{
							noteCheck(controlArray[coolNote.noteData], coolNote, playerOne);
						}
					}
				}
				else // regular notes?
				{
					noteCheck(controlArray[daNote.noteData], daNote, playerOne);
				}
				/*
					if (controlArray[daNote.noteData])
						goodNoteHit(daNote);
				 */
				// trace(daNote.noteData);
				/*
					switch (daNote.noteData)
					{
						case 2: // NOTES YOU JUST PRESSED
							if (upP || rightP || downP || leftP)
								noteCheck(upP, daNote);
						case 3:
							if (upP || rightP || downP || leftP)
								noteCheck(rightP, daNote);
						case 1:
							if (upP || rightP || downP || leftP)
								noteCheck(downP, daNote);
						case 0:
							if (upP || rightP || downP || leftP)
								noteCheck(leftP, daNote);
					}
				 */
				if (daNote.wasGoodHit)
				{
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			}
			else
			{
				badNoteCheck(playerOne);
			}
		}

		if ((up || right || down || left) && !actingOn.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				var coolShouldPress = playerOne ? daNote.mustPress : !daNote.mustPress;
				if (daNote.canBeHit && coolShouldPress && daNote.isSustainNote)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 0:
							if (left)
								goodNoteHit(daNote,playerOne);
						case 1:
							if (down)
								goodNoteHit(daNote,playerOne);
						case 2:
							if (up)
								goodNoteHit(daNote,playerOne);
						case 3:
							if (right)
								goodNoteHit(daNote,playerOne);
					}
				}
			});
		}
		if (actingOn.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left)
		{
			if (actingOn.animation.curAnim.name.startsWith('sing') && !actingOn.animation.curAnim.name.endsWith('miss'))
			{
				actingOn.dance();
				trace("idle from non miss sing");
			}
		}
		var strums = playerOne ? playerStrums : enemyStrums;
		strums.forEach(function(spr:FlxSprite)
		{
			switch (spr.ID)
			{
				case 0:
					if (leftP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (leftR)
						spr.animation.play('static');
				case 1:
					if (downP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (downR)
						spr.animation.play('static');
				case 2:
					if (upP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (upR)
						spr.animation.play('static');
				case 3:
					if (rightP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (rightR)
						spr.animation.play('static');
			}
			
			if (spr.animation.curAnim.name == 'confirm' && SONG.uiType != 'pixel' && !FNFAssets.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1, playerOne:Bool=true):Void
	{
		var actingOn = playerOne ? boyfriend : dad;
		if (fullComboMode || perfectMode) {
			// you signed up for this your fault
			if (opponentPlayer)
				health = 2;
			else
				health = 0;
		}
		if (!actingOn.stunned)
		{
			misses += 1;
			notesPassing += 1;
			if (playerOne)
				health -= 0.04 + healthLossModifier;
			else
				health += 0.04 + healthLossModifier;
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			combo = 0;
			if (!practiceMode) {
				songScore -= 10;

			}
			trueScore -= 10;
			FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play('assets/sounds/missnote1' + TitleState.soundExt, 1, false);
			// FlxG.log.add('played imss note');

			actingOn.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				actingOn.stunned = false;
			});

			switch (direction)
			{
				case 0:
					actingOn.playAnim('singLEFTmiss', true);
				case 1:
					actingOn.playAnim('singDOWNmiss', true);
				case 2:
					actingOn.playAnim('singUPmiss', true);
				case 3:
					actingOn.playAnim('singRIGHTmiss', true);
			}

			if (playerOne) {
				callAllHScript("playerOneMiss", []);
			} else {
				callAllHScript("playerTwoMiss", []);
			}
		}
	}

	function badNoteCheck(?playerOne:Bool=true)
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var coolControls = playerOne ? controls : controlsPlayerTwo;
		var upP = coolControls.UP_P;
		var rightP = coolControls.RIGHT_P;
		var downP = coolControls.DOWN_P;
		var leftP = coolControls.LEFT_P;

		if (leftP)
			noteMiss(0, playerOne);
		if (downP)
			noteMiss(1, playerOne);
		if (upP)
			noteMiss(2,playerOne);
		if (rightP)
			noteMiss(3,playerOne);
	}

	function noteCheck(keyP:Bool, note:Note, ?playerOne:Bool=true):Void
	{
		if (keyP)
			goodNoteHit(note,playerOne);
		else
		{
			badNoteCheck(playerOne);
		}
	}

	function goodNoteHit(note:Note, ?playerOne:Bool=true):Void
	{
		var actingOn = playerOne ? boyfriend : dad;
		if (opponentPlayer) {
			actingOn = dad;
		}
		if (!note.isSustainNote)
			notesHitArray.push(Date.now());
		if (!note.wasGoodHit)
		{
			var altAnim = "";
			if (SONG.notes[Math.floor(curStep / 16)] != null)
			{
				if ((SONG.notes[Math.floor(curStep / 16)].altAnimNum > 0 && SONG.notes[Math.floor(curStep / 16)].altAnimNum != null)
					|| SONG.notes[Math.floor(curStep / 16)].altAnim)
					// backwards compatibility shit
					if (SONG.notes[Math.floor(curStep / 16)].altAnimNum == 1
						|| SONG.notes[Math.floor(curStep / 16)].altAnim
						|| note.altNote)
						altAnim = '-alt';
					else if (SONG.notes[Math.floor(curStep / 16)].altAnimNum != 0)
						altAnim = '-' + SONG.notes[Math.floor(curStep / 16)].altAnimNum + 'alt';
			}
			if (note.altNote)
			{
				altAnim = '-alt';
			}
			if (!note.isSustainNote)
			{
				notesPassing += 1;
				popUpScore(note.strumTime, note);
				combo += 1;
			}
			if (playerOne) {
				if (note.noteData >= 0)
					health += 0.023 + healthGainModifier;
				else
					health += 0.004 + healthGainModifier;
			} else {
				if (note.noteData >= 0)
					health -= 0.023 + healthGainModifier;
				else
					health -= 0.004 + healthGainModifier;
			}
			
			if (playerOne)
				altAnim = "";
			switch (note.noteData)
			{
				case 0:
					actingOn.playAnim('singLEFT'+altAnim, true);
				case 1:
					actingOn.playAnim('singDOWN'+altAnim, true);
				case 2:
					actingOn.playAnim('singUP'+altAnim, true);
				case 3:
					actingOn.playAnim('singRIGHT'+altAnim, true);
			}
			if (playerOne)
				callAllHScript("playerOneSing", []);
			else
				callAllHScript("playerTwoSing", []);
			var strums = playerOne ? playerStrums : enemyStrums;
			strums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
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

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play('assets/sounds/carPass' + FlxG.random.int(0, 1) + TitleState.soundExt, 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play('assets/sounds/thunder_' + FlxG.random.int(1, 2) + TitleState.soundExt);
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();
		if (SONG.needsVoices)
		{
			if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
		}

		setAllHaxeVar("curStep", curStep);
		callAllHScript("stepHit", [curStep]);

		#if windows
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"Acc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC,true,
			songLength
			- Conductor.songPosition, playingAsRpc);
		#end
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();
		
		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, downscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection && ((!duoMode && !opponentPlayer) || demoMode))
				dad.dance();
			if (!SONG.notes[Math.floor(curStep / 16)].mustHitSection && (opponentPlayer || demoMode))
				boyfriend.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));
		practiceDieIcon.setGraphicSize(Std.int(practiceDieIcon.width + 30));
		iconP1.updateHitbox();
		iconP2.updateHitbox();
		practiceDieIcon.updateHitbox();
		if (curBeat % gfSpeed == 0)
		{
			gf.dance();
		}

		if (!boyfriend.animation.curAnim.name.startsWith("sing") && !opponentPlayer || demoMode)
		{
			boyfriend.dance();
		}
		if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith("sing") && (duoMode || opponentPlayer) || demoMode) {
			dad.dance();
		}
		if (curBeat % 8 == 7 && SONG.isHey)
		{
			boyfriend.playAnim('hey', true);

			
		}
		if (curBeat % 8 == 7 && SONG.isCheer && dad.gfEpicLevel >= cast Character.EpicLevel.Level_Sing)
		{
			dad.playAnim('cheer', true);
		}
		for (sprite in backgroundgroup.members) {
			sprite.runEvent(curBeat, boyfriend, gf, dad);
		}
		for (sprite in foregroundgroup.members)
		{
			sprite.runEvent(curBeat, boyfriend, gf, dad);
		}
		switch (curStage)
		{
			case 'school':
				bgGirls.dance();
			#if !windows
			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			#end
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		setAllHaxeVar('curBeat', curBeat);
		callAllHScript('beatHit', [curBeat]);
	}

	var curLight:Int = 0;
}
