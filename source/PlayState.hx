package;

import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import DifficultyIcons;
import flixel.FlxSprite;
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
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import lime.system.System;
#if sys
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flash.media.Sound;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var defaultPlaylistLength = 0;
	var halloweenLevel:Bool = false;

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

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

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

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
	var alcholNumber:Float = 0;
	var inALoop:Bool = false;
	var useVictoryScreen:Bool = true;
	override public function create()
	{
		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		var optionsJson = Json.parse(Assets.getText('assets/data/options.json'));
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];
		persistentUpdate = true;
		persistentDraw = true;
		alwaysDoCutscenes = optionsJson.alwaysDoCutscenes;
		useVictoryScreen = !optionsJson.skipVictoryScreen;
		if (!optionsJson.skipModifierMenu) {
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


		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.changeBPM(SONG.bpm);

		switch (SONG.song.toLowerCase())
		{
			default:
				// prefer player 1
				if (FileSystem.exists('assets/images/custom_chars/'+SONG.player1+'/'+SONG.song.toLowerCase()+'Dialog.txt')) {
					dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/'+SONG.player2+'/'+SONG.song.toLowerCase()+'Dialog.txt');
				// if no player 1 unique dialog, use player 2
				} else if (FileSystem.exists('assets/images/custom_chars/'+SONG.player2+'/'+SONG.song.toLowerCase()+'Dialog.txt')) {
					dialogue = CoolUtil.coolDynamicTextFile('assets/images/custom_chars/'+SONG.player1+'/'+SONG.song.toLowerCase()+'Dialog.txt');
				// if no player dialog, use default
				}	else if (FileSystem.exists('assets/data/'+SONG.song.toLowerCase()+'/dialog.txt')) {
					dialogue = CoolUtil.coolDynamicTextFile('assets/data/'+SONG.song.toLowerCase()+'/dialog.txt');
				// otherwise, make the dialog an error message
				} else {
					dialogue = [':dad: The game tried to get a dialog file but couldn\'t find it. Please make sure there is a dialog file named "dialog.txt".'];
				}
		}

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
			/*
				var bg:FlxSprite = new FlxSprite(posX, posY).loadGraphic('assets/images/weeb/evilSchoolBG.png');
				bg.scale.set(6, 6);
				// bg.setGraphicSize(Std.int(bg.width * 6));
				// bg.updateHitbox();
				add(bg);

				var fg:FlxSprite = new FlxSprite(posX, posY).loadGraphic('assets/images/weeb/evilSchoolFG.png');
				fg.scale.set(6, 6);
				// fg.setGraphicSize(Std.int(fg.width * 6));
				// fg.updateHitbox();
				add(fg);

				wiggleShit.effectType = WiggleEffectType.DREAMY;
				wiggleShit.waveAmplitude = 0.01;
				wiggleShit.waveFrequency = 60;
				wiggleShit.waveSpeed = 0.8;
			 */

			// bg.shader = wiggleShit.shader;
			// fg.shader = wiggleShit.shader;

			/*
				var waveSprite = new FlxEffectSprite(bg, [waveEffectBG]);
				var waveSpriteFG = new FlxEffectSprite(fg, [waveEffectFG]);

				// Using scale since setGraphicSize() doesnt work???
				waveSprite.scale.set(6, 6);
				waveSpriteFG.scale.set(6, 6);
				waveSprite.setPosition(posX, posY);
				waveSpriteFG.setPosition(posX, posY);

				waveSprite.scrollFactor.set(0.7, 0.8);
				waveSpriteFG.scrollFactor.set(0.9, 0.8);

				// waveSprite.setGraphicSize(Std.int(waveSprite.width * 6));
				// waveSprite.updateHitbox();
				// waveSpriteFG.setGraphicSize(Std.int(fg.width * 6));
				// waveSpriteFG.updateHitbox();

				add(waveSprite);
				add(waveSpriteFG);
			 */
		}
		else if (SONG.stage == "stage")
		{
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
			// bg.setGraphicSize(Std.int(bg.width * 2.5));
			// bg.updateHitbox();
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
		} else {
			// use assets
			var parsedStageJson = Json.parse(Assets.getText("assets/images/custom_stages/custom_stages.json"));
			switch (Reflect.field(parsedStageJson, SONG.stage)) {
				case 'stage':
					defaultCamZoom = 0.9;
					// pretend it's stage, it doesn't check for correct images
					curStage = 'stage';
					// peck it no one is gonna build this for html5 so who cares if it doesn't compile
					var bgPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/stageback.png")) {
						bgPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/stageback.png");
					} else {
						// fall back on base game file to avoid crashes
						bgPic = BitmapData.fromImage(Assets.getImage("assets/images/stageback.png"));
					}

					var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(bgPic);
					// bg.setGraphicSize(Std.int(bg.width * 2.5));
					// bg.updateHitbox();
					bg.antialiasing = true;
					bg.scrollFactor.set(0.9, 0.9);
					bg.active = false;
					add(bg);
					var frontPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/stagefront.png")) {
						frontPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/stagefront.png");
					} else {
						// fall back on base game file to avoid crashes
						frontPic = BitmapData.fromImage(Assets.getImage("assets/images/stagefront.png"));
					}

					var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(frontPic);
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
					stageFront.updateHitbox();
					stageFront.antialiasing = true;
					stageFront.scrollFactor.set(0.9, 0.9);
					stageFront.active = false;
					add(stageFront);
					var curtainPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/stagecurtains.png")) {
						curtainPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/stagecurtains.png");
					} else {
						// fall back on base game file to avoid crashes
						curtainPic = BitmapData.fromImage(Assets.getImage("assets/images/stagecurtains.png"));
					}
					var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(curtainPic);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					stageCurtains.antialiasing = true;
					stageCurtains.scrollFactor.set(1.3, 1.3);
					stageCurtains.active = false;

					add(stageCurtains);
				case 'spooky':
					curStage = "spooky";
					halloweenLevel = true;
					var bgPic:BitmapData;
					var bgXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/halloween_bg.png")) {
						bgPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/halloween_bg.png");
					} else {
						// fall back on base game file to avoid crashes
						bgPic = BitmapData.fromImage(Assets.getImage("assets/images/halloween_bg.png"));
					}
					    if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/halloween_bg.xml")) {
					   bgXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/halloween_bg.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 bgXml = Assets.getText("assets/images/halloween_bg.xml");
					}
					var hallowTex = FlxAtlasFrames.fromSparrow(bgPic, bgXml);

					halloweenBG = new FlxSprite(-200, -100);
					halloweenBG.frames = hallowTex;
					halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
					halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
					halloweenBG.animation.play('idle');
					halloweenBG.antialiasing = true;
					add(halloweenBG);

					isHalloween = true;
				case 'philly':
					curStage = 'philly';
					var bgPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/sky.png")) {
						bgPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/sky.png");
					} else {
						// fall back on base game file to avoid crashes
						bgPic = BitmapData.fromImage(Assets.getImage("assets/images/philly/sky.png"));
					}
					var bg:FlxSprite = new FlxSprite(-100).loadGraphic(bgPic);
					bg.scrollFactor.set(0.1, 0.1);
					add(bg);
					var cityPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/city.png")) {
						cityPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/city.png");
					} else {
						// fall back on base game file to avoid crashes
						cityPic = BitmapData.fromImage(Assets.getImage("assets/images/philly/city.png"));
					}
					var city:FlxSprite = new FlxSprite(-10).loadGraphic(cityPic);
					city.scrollFactor.set(0.3, 0.3);
					city.setGraphicSize(Std.int(city.width * 0.85));
					city.updateHitbox();
					add(city);

					phillyCityLights = new FlxTypedGroup<FlxSprite>();
					add(phillyCityLights);

					for (i in 0...5)
					{
						var lightPic:BitmapData;
						if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/win"+i+".png")) {
							lightPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/win"+i+".png");
						} else {
							// fall back on base game file to avoid crashes
							lightPic = BitmapData.fromImage(Assets.getImage("assets/images/philly/win"+i+".png"));
						}
						var light:FlxSprite = new FlxSprite(city.x).loadGraphic(lightPic);
						light.scrollFactor.set(0.3, 0.3);
						light.visible = false;
						light.setGraphicSize(Std.int(light.width * 0.85));
						light.updateHitbox();
						phillyCityLights.add(light);
					}
					var backstreetPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/behindTrain.png")) {
						backstreetPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/behindTrain.png");
					} else {
						// fall back on base game file to avoid crashes
						backstreetPic = BitmapData.fromImage(Assets.getImage("assets/images/philly/behindTrain.png"));
					}
					var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(backstreetPic);
					add(streetBehind);
					var trainPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/train.png")) {
						trainPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/train.png");
					} else {
						// fall back on base game file to avoid crashes
						trainPic = BitmapData.fromImage(Assets.getImage("assets/images/philly/train.png"));
					}
					phillyTrain = new FlxSprite(2000, 360).loadGraphic(trainPic);
					add(phillyTrain);

					trainSound = new FlxSound().loadEmbedded('assets/sounds/train_passes' + TitleState.soundExt);
					FlxG.sound.list.add(trainSound);


					var streetPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/street.png")) {
						streetPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/street.png");
					} else {
						// fall back on base game file to avoid crashes
						streetPic = BitmapData.fromImage(Assets.getImage("assets/images/philly/street.png"));
					}
					var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(streetPic);
					add(street);
				case 'limo':
					curStage = 'limo';
					defaultCamZoom = 0.90;
					var bgPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/limoSunset.png")) {
						bgPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/limoSunset.png");
					} else {
						// fall back on base game file to avoid crashes
						bgPic = BitmapData.fromImage(Assets.getImage("assets/images/limo/limoSunset.png"));
					}
					var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(bgPic);
					skyBG.scrollFactor.set(0.1, 0.1);
					add(skyBG);
					var bgLimoPic:BitmapData;
					var bgLimoXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bgLimo.png")) {
						bgLimoPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/bgLimo.png");
					} else {
						// fall back on base game file to avoid crashes
						bgLimoPic = BitmapData.fromImage(Assets.getImage("assets/images/limo/bgLimo.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bgLimo.xml")) {
					   bgLimoXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/bgLimo.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 bgLimoXml = Assets.getText("assets/images/limo/bgLimo.xml");
					}
					var bgLimo:FlxSprite = new FlxSprite(-200, 480);
					bgLimo.frames = FlxAtlasFrames.fromSparrow(bgLimoPic, bgLimoXml);
					bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
					bgLimo.animation.play('drive');
					bgLimo.scrollFactor.set(0.4, 0.4);
					add(bgLimo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400, SONG.stage);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}
					var limoOverlayPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/limoOverlay.png")) {
						limoOverlayPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/limoOverlay.png");
					} else {
						// fall back on base game file to avoid crashes
						limoOverlayPic = BitmapData.fromImage(Assets.getImage("assets/images/limo/limoOverlay.png"));
					}
					var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(limoOverlayPic);
					overlayShit.alpha = 0.5;
					// add(overlayShit);

					// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

					// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

					// overlayShit.shader = shaderBullshit;
					var limoPic:BitmapData;
					var limoXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/limoDrive.png")) {
						limoPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/limoDrive.png");
					} else {
						// fall back on base game file to avoid crashes
						limoPic = BitmapData.fromImage(Assets.getImage("assets/images/limo/limoDrive.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/limoDrive.xml")) {
					   limoXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/limoDrive.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 limoXml = Assets.getText("assets/images/limo/limoDrive.xml");
					}
					var limoTex = FlxAtlasFrames.fromSparrow(limoPic, limoXml);

					limo = new FlxSprite(-120, 550);
					limo.frames = limoTex;
					limo.animation.addByPrefix('drive', "Limo stage", 24);
					limo.animation.play('drive');
					limo.antialiasing = true;
					var fastCarPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"_fastcar.png");
					fastCar = new FlxSprite(-300, 160).loadGraphic(fastCarPic);
					// add(limo);
				case 'mall':
					curStage = 'mall';

					defaultCamZoom = 0.80;
					var bgPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bgWalls.png")) {
					   bgPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/bgWalls.png");
					} else {
					   // fall back on base game file to avoid crashes
						 bgPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/bgWalls.png"));
					}
					var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(bgPic);
					bg.antialiasing = true;
					bg.scrollFactor.set(0.2, 0.2);
					bg.active = false;
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					add(bg);
					var standsPic:BitmapData;
					var standsXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/upperBop.png")) {
					   standsPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/upperBop.png");
					} else {
					   // fall back on base game file to avoid crashes
						 standsPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/upperBop.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/upperBop.xml")) {
					   standsXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/upperBop.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 standsXml = Assets.getText("assets/images/christmas/upperBop.xml");
					}
					upperBoppers = new FlxSprite(-240, -90);
					upperBoppers.frames = FlxAtlasFrames.fromSparrow(standsPic, standsXml);
					upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
					upperBoppers.antialiasing = true;
					upperBoppers.scrollFactor.set(0.33, 0.33);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);
					var escalatorPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bgEscalator.png")) {
					   escalatorPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/bgEscalator.png");
					} else {
					   // fall back on base game file to avoid crashes
						 escalatorPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/bgEscalator.png"));
					}
					var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(escalatorPic);
					bgEscalator.antialiasing = true;
					bgEscalator.scrollFactor.set(0.3, 0.3);
					bgEscalator.active = false;
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
					var treePic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/christmasTree.png")) {
					   treePic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/christmasTree.png");
					} else {
					   // fall back on base game file to avoid crashes
						 treePic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/christmasTree.png"));
					}
					var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(treePic);
					tree.antialiasing = true;
					tree.scrollFactor.set(0.40, 0.40);
					add(tree);
					var crowdPic:BitmapData;
					var crowdXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bottomBop.png")) {
					   crowdPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/bottomBop.png");
					} else {
					   // fall back on base game file to avoid crashes
						 crowdPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/bottomBop.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bottomBop.xml")) {
					   crowdXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/bottomBop.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 crowdXml = Assets.getText("assets/images/christmas/bottomBop.xml");
					}
					bottomBoppers = new FlxSprite(-300, 140);
					bottomBoppers.frames = FlxAtlasFrames.fromSparrow(crowdPic, crowdXml);
					bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
					bottomBoppers.antialiasing = true;
					bottomBoppers.scrollFactor.set(0.9, 0.9);
					bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					bottomBoppers.updateHitbox();
					add(bottomBoppers);
					var snowPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/fgSnow.png")) {
					   snowPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/fgSnow.png");
					} else {
					   // fall back on base game file to avoid crashes
						 snowPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/fgSnow.png"));
					}
					var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(snowPic);
					fgSnow.active = false;
					fgSnow.antialiasing = true;
					add(fgSnow);
					var santaPic:BitmapData;
					var santaXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/santa.png")) {
					   santaPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/santa.png");
					} else {
					   // fall back on base game file to avoid crashes
						 santaPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/santa.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/santa.xml")) {
					   santaXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/santa.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 santaXml = Assets.getText("assets/images/christmas/santa.xml");
					}
					santa = new FlxSprite(-840, 150);
					santa.frames = FlxAtlasFrames.fromSparrow(santaPic, santaXml);
					santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
					santa.antialiasing = true;
					add(santa);
				case 'mallEvil':
					curStage = 'mallEvil';
					var bgPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/evilBG.png")) {
					   bgPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/evilBG.png");
					} else {
					   // fall back on base game file to avoid crashes
						 bgPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/evilBG.png"));
					}

					var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(bgPic);
					bg.antialiasing = true;
					bg.scrollFactor.set(0.2, 0.2);
					bg.active = false;
					bg.setGraphicSize(Std.int(bg.width * 0.8));
					bg.updateHitbox();
					add(bg);
					var evilTreePic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/evilTree.png")) {
					   evilTreePic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/evilTree.png");
					} else {
					   // fall back on base game file to avoid crashes
						 evilTreePic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/evilTree.png"));
					}
					var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(evilTreePic);
					evilTree.antialiasing = true;
					evilTree.scrollFactor.set(0.2, 0.2);
					add(evilTree);
					var evilSnowPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/evilSnow.png")) {
					   evilSnowPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/evilSnow.png");
					} else {
					   // fall back on base game file to avoid crashes
						 evilSnowPic = BitmapData.fromImage(Assets.getImage("assets/images/christmas/evilSnow.png"));
					}
					var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(evilSnowPic);
					evilSnow.antialiasing = true;
					add(evilSnow);
				case 'school':
					curStage = 'school';
					// school moody is just the girls are upset
					// defaultCamZoom = 0.9;
					var bgPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/weebSky.png")) {
					   bgPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/weebSky.png");
					} else {
					   // fall back on base game file to avoid crashes
						 bgPic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/weebSky.png"));
					}
					var bgSky = new FlxSprite().loadGraphic(bgPic);
					bgSky.scrollFactor.set(0.1, 0.1);
					add(bgSky);

					var repositionShit = -200;
					var schoolPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/weebSchool.png")) {
					   schoolPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/weebSchool.png");
					} else {
					   // fall back on base game file to avoid crashes
						 schoolPic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/weebSchool.png"));
					}
					var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(schoolPic);
					bgSchool.scrollFactor.set(0.6, 0.90);
					add(bgSchool);
					var streetPic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/weebStreet.png")) {
					   streetPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/weebStreet.png");
					} else {
					   // fall back on base game file to avoid crashes
						 streetPic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/weebStreet.png"));
					}
					var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(streetPic);
					bgStreet.scrollFactor.set(0.95, 0.95);
					add(bgStreet);
					var fgTreePic:BitmapData;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/weebTreesBack.png")) {
					   fgTreePic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/weebTreesBack.png");
					} else {
					   // fall back on base game file to avoid crashes
						 fgTreePic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/weebTreesBack.png"));
					}
					var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(fgTreePic);
					fgTrees.scrollFactor.set(0.9, 0.9);
					add(fgTrees);
					var treesPic:BitmapData;
					var treesTxt:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/weebTrees.png")) {
					   treesPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/weebTrees.png");
					} else {
					   // fall back on base game file to avoid crashes
						 treesPic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/weebTrees.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/weebTrees.txt")) {
					   treesTxt = File.getContent('assets/images/custom_stages/'+SONG.stage+"/weebTrees.txt");
					} else {
					   // fall back on base game file to avoid crashes
						 treesTxt = Assets.getText("assets/images/weeb/weebTrees.txt");
					}
					var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
					var treetex = FlxAtlasFrames.fromSpriteSheetPacker(treesPic, treesTxt);
					bgTrees.frames = treetex;
					bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
					bgTrees.animation.play('treeLoop');
					bgTrees.scrollFactor.set(0.85, 0.85);
					add(bgTrees);
					var petalsPic:BitmapData;
					var petalsXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/petals.png")) {
					   petalsPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/petals.png");
					} else {
					   // fall back on base game file to avoid crashes
						 petalsPic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/petals.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/petals.xml")) {
					   petalsXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/petals.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 petalsXml = Assets.getText("assets/images/weeb/petals.xml");
					}
					var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
					treeLeaves.frames = FlxAtlasFrames.fromSparrow(petalsPic, petalsXml);
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
					var gorlsPic:BitmapData;
					var gorlsXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bgFreaks.png")) {
					   gorlsPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/bgFreaks.png");
					} else {
					   // fall back on base game file to avoid crashes
						 gorlsPic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/bgFreaks.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/bgFreaks.xml")) {
					   gorlsXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/bgFreaks.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 gorlsXml = Assets.getText("assets/images/weeb/bgFreaks.xml");
					}
					bgGirls = new BackgroundGirls(-100, 190, gorlsPic, gorlsXml);
					bgGirls.scrollFactor.set(0.9, 0.9);

					if (SONG.isMoody)
					{
						bgGirls.getScared();
					}

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				case 'schoolEvil':
					curStage = 'schoolEvil';

					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

					var posX = 400;
					var posY = 200;

					var bg:FlxSprite = new FlxSprite(posX, posY);
					var evilSchoolPic:BitmapData;
					var evilSchoolXml:String;
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/animatedEvilSchool.png")) {
					   evilSchoolPic = BitmapData.fromFile('assets/images/custom_stages/'+SONG.stage+"/animatedEvilSchool.png");
					} else {
					   // fall back on base game file to avoid crashes
						 evilSchoolPic = BitmapData.fromImage(Assets.getImage("assets/images/weeb/animatedEvilSchool.png"));
					}
					if (FileSystem.exists('assets/images/custom_stages/'+SONG.stage+"/animatedEvilSchool.xml")) {
					   evilSchoolXml = File.getContent('assets/images/custom_stages/'+SONG.stage+"/animatedEvilSchool.xml");
					} else {
					   // fall back on base game file to avoid crashes
						 evilSchoolXml = Assets.getText("assets/images/weeb/animatedEvilSchool.xml");
					}
					bg.frames = FlxAtlasFrames.fromSparrow(evilSchoolPic, evilSchoolXml);
					bg.animation.addByPrefix('idle', 'background 2', 24);
					bg.animation.play('idle');
					bg.scrollFactor.set(0.8, 0.9);
					bg.scale.set(6, 6);
					add(bg);
			}
		}

		var gfVersion:String = 'gf';

		gfVersion = SONG.gf;
		trace(SONG.gf);
		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		// Shitty layering but whatev it works LOL
		add(gf);
		if (curStage == 'limo')
			add(limo);

		dad = new Character(100, 100, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode )
				{
					camPos.x += 600;
					tweenCamIn();
				}

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 130;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.x += 370;
				camPos.y += 300;
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.x += 370;
				camPos.y += 300;
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.x += 300;
			default:
				dad.x += dad.enemyOffsetX;
				dad.y += dad.enemyOffsetY;
				camPos.x += dad.camOffsetX;
				camPos.y += dad.camOffsetY;
				if (dad.like == "gf") {
					dad.setPosition(gf.x, gf.y);
					gf.visible = false;
					if (isStoryMode)
					{
						camPos.x += 600;
						tweenCamIn();
					}
				}
		}



		boyfriend = new Boyfriend(770, 450, SONG.player1);
		trace("newBF");
		switch (SONG.player1) // no clue why i didnt think of this before lol
		{
			default:
				//boyfriend.x += boyfriend.bfOffsetX; //just use sprite offsets
				//boyfriend.y += boyfriend.bfOffsetY;
				camPos.x += boyfriend.camOffsetX;
				camPos.y += boyfriend.camOffsetY;
				if (boyfriend.like == "gf") {
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

				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
		}
		trace("repositionByStage");
		add(dad);
		add(boyfriend);
		trace("addCharacters");
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		trace("doofensmirz");
		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();
		trace("before song generation");
		generateSong(SONG.song);
		trace("after song generation");
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

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic('assets/images/healthBar.png');
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		scoreTxt = new FlxText(healthBarBG.x + healthBarBG.width - 90, healthBarBG.y + 30, 0, "", 200);
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		scoreTxt.scrollFactor.set();

		healthTxt = new FlxText(healthBarBG.x + healthBarBG.width - 300, healthBarBG.y + 30, 0, "", 200);
		healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		healthTxt.scrollFactor.set();

		accuracyTxt = new FlxText(healthBarBG.x, healthBarBG.y + 30, 0, "", 200);
		accuracyTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		accuracyTxt.scrollFactor.set();
		difficTxt = new FlxText(10, FlxG.height, 0, "", 200);

		difficTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
		difficTxt.scrollFactor.set();
		difficTxt.y -= difficTxt.height;
		// screwy way of getting text
		difficTxt.text = DifficultyIcons.changeDifficultyFreeplay(storyDifficulty, 0).text;
		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);
		trace("before icons p2");
		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);
		practiceDieIcon = new HealthIcon('bf-old', false);
		practiceDieIcon.y = healthBar.y - (practiceDieIcon.height / 2);
		practiceDieIcon.x = healthBar.x - 130;
		practiceDieIcon.animation.curAnim.curFrame = 1;
		add(practiceDieIcon);
		trace("finishIcons");
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
		trace("finishCameras");
		add(scoreTxt);
		add(healthTxt);
		add(accuracyTxt);
		add(difficTxt);
		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;
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
					schoolIntro(doof);
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
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

		var senpaiEvil:FlxSprite = new FlxSprite();
		// dialog box overwrites character
		if (FileSystem.exists('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'-crazy.png')) {
			var evilImage = BitmapData.fromFile('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'-crazy.png');
			var evilXml = File.getContent('assets/images/custom_ui/dialog_boxes/'+SONG.cutsceneType+'-crazy.xml');
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow(evilImage, evilXml);
		// character then takes precendence over default
		// will make things like monika way way easier
		} else if (FileSystem.exists('assets/images/custom_chars/'+SONG.player2+'/crazy.png')) {
			var evilImage = BitmapData.fromFile('assets/images/custom_ui/dialog_boxes/'+SONG.player2+'/crazy.png');
			var evilXml = File.getContent('assets/images/custom_ui/dialog_boxes/'+SONG.player2+'/crazy.xml');
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow(evilImage, evilXml);
		} else {
			senpaiEvil.frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/senpaiCrazy.png', 'assets/images/weeb/senpaiCrazy.xml');
		}

		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
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
								FlxG.sound.play('assets/sounds/Senpai_Dies' + TitleState.soundExt, 1, false, null, true, function()
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

	var startTimer:FlxTimer;
	var perfectModeOld:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.playAnim('idle');

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('normal', ['ready.png', "set.png", "go.png"]);
			introAssets.set('pixel', [
				'weeb/pixelUI/ready-pixel.png',
				'weeb/pixelUI/set-pixel.png',
				'weeb/pixelUI/date-pixel.png'
			]);
			for (field in CoolUtil.coolTextFile('assets/data/uitypes.txt')) {
				if (field != 'pixel' && field != 'normal') {
					if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
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
					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
						altSuffix = '-pixel';
				}
			}
			if (SONG.uiType == 'normal') {
				intro3Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro3.ogg')));
				intro2Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro2.ogg')));
				intro1Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro1.ogg')));
				introGoSound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/introGo.ogg')));
			} else if (SONG.uiType == 'pixel') {
				intro3Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro3-pixel.ogg')));
				intro2Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro2-pixel.ogg')));
				intro1Sound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/intro1-pixel.ogg')));
				introGoSound = Sound.fromAudioBuffer(AudioBuffer.fromBytes(Assets.getBytes('assets/sounds/introGo-pixel.ogg')));
			} else {
				// god is dead for we have killed him
				intro3Sound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro3'+altSuffix+'.ogg');
				intro2Sound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro2'+altSuffix+'.ogg');
				intro1Sound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/intro1'+altSuffix+'.ogg');
				// apparently this crashes if we do it from audio buffer?
				// no it just understands 'hey that file doesn't exist better do an error'
				introGoSound = Sound.fromFile("assets/images/custom_ui/ui_packs/"+SONG.uiType+'/introGo'+altSuffix+'.ogg');
			}


			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(intro3Sound, 0.6);
				case 1:
					// my life is a lie, it was always this simple
					var readyImage = BitmapData.fromFile('assets/images/'+introAlts[0]);
					var ready:FlxSprite = new FlxSprite().loadGraphic(readyImage);
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
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
					var setImage = BitmapData.fromFile('assets/images/'+introAlts[1]);
					// can't believe you can actually use this as a variable name
					var set:FlxSprite = new FlxSprite().loadGraphic(setImage);
					set.scrollFactor.set();

					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
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
					var goImage = BitmapData.fromFile('assets/images/'+introAlts[2]);
					var go:FlxSprite = new FlxSprite().loadGraphic(goImage);
					go.scrollFactor.set();

					if (SONG.uiType == 'pixel' || FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
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
			if (poisonExr && !paused)
				health -= 0.005;
			if (supLove && !paused)
				health +=  0.005;
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
			if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml") && FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png")) {
				trace("has this been reached");
				customImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/NOTE_assets.png');
				customXml = File.getContent('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/NOTE_assets.xml');
			} else {
				customImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/arrow-pixels.png');
				arrowEndsImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/arrowEnds.png');
			}
		}
		trace(customImage);
		trace(customXml);
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, customImage, customXml, arrowEndsImage);
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
				else
				{
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
					if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml") && FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png")) {

					  var noteXml = File.getContent('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.xml");
						var notePic = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/NOTE_assets.png");
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

					} else if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png")){
						var notePic = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png");
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

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			if (player == 1)
			{
				playerStrums.add(babyArrow);
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
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectModeOld = false;
		#end


		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		super.update(elapsed);
		healthTxt.text = "Health:" + Math.round(health * 50) + "%";
		scoreTxt.text = "Score:" + songScore + "(" + trueScore + ")";
		if (notesPassing != 0) {
			accuracyTxt.text = "Accuracy:" + Math.round((notesHit/notesPassing) * 100) + "%";
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

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;
		if (poisonTimes == 0) {
			if (healthBar.percent < 20) {
				iconP1.animation.curAnim.curFrame = 1;
				healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.RED, RIGHT);
			}
			else {
				iconP1.animation.curAnim.curFrame = 0;
				healthTxt.setFormat("assets/fonts/vcr.ttf", 20, FlxColor.WHITE, RIGHT);
			}

		} else {
			iconP1.animation.curAnim.curFrame = 2;
		}


		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

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

			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);
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

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition((boyfriend.getMidpoint().x - 100), (boyfriend.getMidpoint().y - 100));

				switch (curStage)
				{
					// not sure that's how variable assignment works
					case 'limo':
						((camFollow.x = boyfriend.getMidpoint().x - 300) + boyfriend.followCamX); // why are you hard coded
					case 'mall':
						((camFollow.y = boyfriend.getMidpoint().y - 200) + boyfriend.followCamY);
					case 'school':
						((camFollow.x = boyfriend.getMidpoint().x - 200) + boyfriend.followCamX);
						((camFollow.y = boyfriend.getMidpoint().y - 200) + boyfriend.followCamY);
					case 'schoolEvil':
						((camFollow.x = boyfriend.getMidpoint().x - 200) + boyfriend.followCamX);
						((camFollow.y = boyfriend.getMidpoint().y - 200) + boyfriend.followCamY);
				}

				if (boyfriend.isCustom) {
					camFollow.y = boyfriend.getMidpoint().y + boyfriend.followCamY;
					camFollow.x = boyfriend.getMidpoint().x + boyfriend.followCamX;

				}

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", totalBeats);

		if (curSong == 'Fresh')
		{
			switch (totalBeats)
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
			switch (totalBeats)
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

		if (health <= 0 && !practiceMode)
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
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			}


			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		} else if (health <= 0 && !practiceDied) {
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

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					trace("DA ALT THO?: " + SONG.notes[Math.floor(curStep / 16)].altAnim);

					switch (Math.abs(daNote.noteData))
					{
						case 2:
							dad.playAnim('singUP' + altAnim, true);
						case 3:
							dad.playAnim('singRIGHT' + altAnim, true);
						case 1:
							dad.playAnim('singDOWN' + altAnim, true);
						case 0:
							dad.playAnim('singLEFT' + altAnim, true);
					}

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}



				if (drunkNotes) {
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * ((Math.sin(songTime/400)/6)+0.5) * noteSpeed * FlxMath.roundDecimal(PlayState.SONG.speed, 2));
				} else {
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (noteSpeed * FlxMath.roundDecimal(PlayState.SONG.speed, 2)));
				}
				if (vnshNotes)
					daNote.alpha = FlxMath.remapToRange(daNote.y, strumLine.y, FlxG.height, 0, 1);
				if (snakeNotes) {
					if (daNote.mustPress) {
						daNote.x = (FlxG.width/2)+snekNumber+(Note.swagWidth*daNote.noteData)+50;
					} else {
						daNote.x = snekNumber+(Note.swagWidth*daNote.noteData)+50;
					}
				}
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				if (daNote.y < -daNote.height)
				{
					if (daNote.tooLate || !daNote.wasGoodHit)
					{
						health -= 0.0475 + healthLossModifier;
						vocals.volume = 0;
						notesPassing += 1;
						trace("passed note");
						if (poisonPlus && poisonTimes < 5) {
							poisonTimes += 1;
								var poisonPlusTimer = new FlxTimer().start(0.5, function (tmr:FlxTimer) {
									health -= 0.05;
								}, 0);
								// stop timer after 3 seconds
								new FlxTimer().start(3, function (tmr:FlxTimer) {
									poisonPlusTimer.cancel();
									poisonTimes -= 1;
								});
						}
						if (fullComboMode || perfectMode) {
							// you signed up for this your fault
							health = 0;
						}
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

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}

	function endSong():Void
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore)
		{
			#if !switch
			Highscore.saveScore(SONG.song, songScore, storyDifficulty);
			#end
		}

		if (isStoryMode)
		{
			campaignScore += songScore;
			campaignAccuracy += notesHit/notesPassing;
			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);


				if (SONG.validScore)
				{
					Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
				}
				campaignAccuracy = campaignAccuracy / defaultPlaylistLength;
				if (useVictoryScreen) {
					FlxG.switchState(new VictoryLoopState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, gf.getScreenPosition().x, gf.getScreenPosition().y, campaignAccuracy, campaignScore));
				} else {
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
					transIn = null;
					transOut = null;
					prevCamFollow = camFollow;
				}
				if (FileSystem.exists('assets/data/'+PlayState.storyPlaylist[0].toLowerCase()+'/'+PlayState.storyPlaylist[0].toLowerCase()+difficulty+'.json'))
				  // do this to make custom difficulties not as unstable
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				else
					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase(), PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				FlxG.switchState(new PlayState());

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			if (useVictoryScreen) {
				FlxG.switchState(new VictoryLoopState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, gf.getScreenPosition().x,gf.getScreenPosition().y, notesHit/notesPassing, songScore));
			} else
				FlxG.switchState(new FreeplayState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float):Void
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
			daRating = 'bad';
			score = 100;
			notesHit += 0.5;
		}
		else if (noteDiff > Conductor.safeZoneOffset * 0.2)
		{
			daRating = 'good';
			score = 200;
			notesHit += 0.75;
		}
		if (daRating == 'sick')
			notesHit += 1;
		if (daRating != "sick" && perfectMode) {
			health = -50;
		}
		songScore += Math.round(score * ModifierState.scoreMultiplier);
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
		if (FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png")) {
			pixelShitPart2 = '-pixel';
		}
		var ratingImage:BitmapData;
		switch (SONG.uiType) {
			case 'pixel':
				ratingImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/weeb/pixelUI/'+daRating+'-pixel.png')));
			case 'normal':
				ratingImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/'+daRating+'.png')));
			default:
				ratingImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+PlayState.SONG.uiType+'/'+daRating+pixelShitPart2+".png");
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
		if (SONG.uiType != 'pixel' && !FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
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
					numImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/weeb/pixelUI/num'+Std.int(i)+'-pixel.png')));
				case 'normal':
					numImage = BitmapData.fromBytes(ByteArray.fromBytes(Assets.getBytes('assets/images/num'+Std.int(i)+'.png')));
				default:
					numImage = BitmapData.fromFile('assets/images/custom_ui/ui_packs/'+SONG.uiType+'/num'+Std.int(i)+pixelShitPart2+".png");
			}
			var numScore:FlxSprite = new FlxSprite().loadGraphic(numImage);
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			if (SONG.uiType != 'pixel' && !FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
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

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.UP;
		var right = controls.RIGHT;
		var down = controls.DOWN;
		var left = controls.LEFT;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var upR = controls.UP_R;
		var rightR = controls.RIGHT_R;
		var downR = controls.DOWN_R;
		var leftR = controls.LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

		// FlxG.watch.addQuick('asdfa', upP);
		if ((upP || rightP || downP || leftP) && !boyfriend.stunned && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];

			var ignoreList:Array<Int> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
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
								goodNoteHit(coolNote);
							else
							{
								var inIgnoreList:Bool = false;
								for (shit in 0...ignoreList.length)
								{
									if (controlArray[ignoreList[shit]])
										inIgnoreList = true;
								}
								if (!inIgnoreList)
									badNoteCheck();
							}
						}
					}
					else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
					{
						noteCheck(controlArray[daNote.noteData], daNote);
					}
					else
					{
						for (coolNote in possibleNotes)
						{
							noteCheck(controlArray[coolNote.noteData], coolNote);
						}
					}
				}
				else // regular notes?
				{
					noteCheck(controlArray[daNote.noteData], daNote);
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
				badNoteCheck();
			}
		}

		if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 2:
							if (up)
								goodNoteHit(daNote);
						case 3:
							if (right)
								goodNoteHit(daNote);
						case 1:
							if (down)
								goodNoteHit(daNote);
						case 0:
							if (left)
								goodNoteHit(daNote);
					}
				}
			});
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left)
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.playAnim('idle');
				trace("idle from non miss sing");
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			switch (spr.ID)
			{
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
				case 1:
					if (downP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (downR)
						spr.animation.play('static');
				case 0:
					if (leftP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (leftR)
						spr.animation.play('static');
			}

			if (spr.animation.curAnim.name == 'confirm' && SONG.uiType != 'pixel' && !FileSystem.exists('assets/images/custom_ui/ui_packs/'+SONG.uiType+"/arrows-pixels.png"))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1):Void
	{
		if (fullComboMode || perfectMode) {
			// you signed up for this your fault
			health = 0;
		}
		if (!boyfriend.stunned)
		{
			notesPassing += 1;
			health -= 0.04 + healthLossModifier;
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

			boyfriend.stunned = true;

			// get stunned for 5 seconds
			new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});

			switch (direction)
			{
				case 2:
					boyfriend.playAnim('singUPmiss', true);
				case 3:
					boyfriend.playAnim('singRIGHTmiss', true);
				case 1:
					boyfriend.playAnim('singDOWNmiss', true);
				case 0:
					boyfriend.playAnim('singLEFTmiss', true);
			}
		}
	}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		if (leftP)
			noteMiss(0);
		if (upP)
			noteMiss(2);
		if (rightP)
			noteMiss(3);
		if (downP)
			noteMiss(1);
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
		else
		{
			badNoteCheck();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				notesPassing += 1;
				popUpScore(note.strumTime);
				combo += 1;
			}

			if (note.noteData >= 0)
				health += 0.023 + healthGainModifier;
			else
				health += 0.004 + healthGainModifier;

			switch (note.noteData)
			{
				case 2:
					boyfriend.playAnim('singUP', true);
				case 3:
					boyfriend.playAnim('singRIGHT', true);
				case 1:
					boyfriend.playAnim('singDOWN', true);
				case 0:
					boyfriend.playAnim('singLEFT', true);
			}

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			note.kill();
			notes.remove(note, true);
			note.destroy();
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
		if (SONG.needsVoices)
		{
			if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
		}

		if (dad.curCharacter == 'spooky' && totalSteps % 4 == 2)
		{
			// dad.dance();
		}

		super.stepHit();
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		wiggleShit.update(Conductor.crochet);
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			else
				Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat <= 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && totalBeats % 4 == 0)
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
		if (totalBeats % gfSpeed == 0)
		{
			gf.dance();
		}

		if (!boyfriend.animation.curAnim.name.startsWith("sing"))
		{
			boyfriend.playAnim('idle');
		}

		if (totalBeats % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);

			if (SONG.song == 'Tutorial' && dad.like == 'gf')
			{
				dad.playAnim('cheer', true);
			}
		}

		switch (curStage)
		{
			case 'school':
				bgGirls.dance();

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

				if (totalBeats % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (totalBeats % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;
}
