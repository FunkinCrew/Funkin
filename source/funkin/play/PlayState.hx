package funkin.play;

import funkin.play.Strumline.StrumlineStyle;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
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
import funkin.charting.ChartingState;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEvent.SongTimeScriptEvent;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.modding.module.ModuleHandler;
import funkin.Note;
import funkin.play.stage.Stage;
import funkin.play.stage.StageData;
import funkin.Section.SwagSection;
import funkin.shaderslmfao.ColorSwap;
import funkin.SongLoad.SwagSong;
import funkin.ui.PopUpStuff;
import funkin.ui.PreferencesMenu;
import funkin.util.Constants;
import funkin.util.SortUtil;
import lime.ui.Haptic;

using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end

class PlayState extends MusicBeatState
{
	/**
	 * STATIC VARIABLES
	 * Static variables should be used for information that must be persisted between states or between resets,
	 * such as the active song or song playlist.
	 */
	/**
	 * The currently active PlayState.
	 * Since there is only one PlayState in existance at a time, we can use a singleton.
	 */
	public static var instance:PlayState = null;

	/**
	 * The currently active song. Includes data about what stage should be used, what characters,
	 * and the notes to be played.
	 */
	public static var currentSong:SwagSong = null;

	/**
	 * Whether the game is currently in Story Mode. If false, we are in Free Play Mode.
	 */
	public static var isStoryMode:Bool = false;

	/**
	 * Whether the game is currently in Practice Mode.
	 * If true, player will not lose gain or lose score from notes.
	 */
	public static var isPracticeMode:Bool = false;

	/**
	 * Whether the game is currently in a cutscene, and gameplay should be stopped.
	 */
	public static var isInCutscene:Bool = false;

	/**
	 * Whether the game is currently in the countdown before the song resumes.
	 */
	public static var isInCountdown:Bool = false;

	/**
	 * The current "Blueball Counter" to display in the pause menu.
	 * Resets when you beat a song or go back to the main menu.
	 */
	public static var deathCounter:Int = 0;

	/**
	 * The default camera zoom level. The camera lerps back to this after zooming in.
	 * Defaults to 1.05 but may be larger or smaller depending on the current stage.
	 */
	public static var defaultCameraZoom:Float = 1.05;

	/**
	 * Used to persist the position of the `cameraFollowPosition` between resets.
	 */
	private static var previousCameraFollowPoint:FlxObject = null;

	/**
	 * PUBLIC INSTANCE VARIABLES
	 * Public instance variables should be used for information that must be reset or dereferenced
	 * every time the state is reset, such as the currently active stage, but may need to be accessed externally.
	 */
	/**
	 * The currently active Stage. This is the object containing all the props.
	 */
	public var currentStage:Stage = null;

	/**
	 * The internal ID of the currently active Stage.
	 * Used to retrieve the data required to build the `currentStage`.
	 */
	public var currentStageId:String = '';

	/**
	 * The player's current health.
	 * The default maximum health is 2.0, and the default starting health is 1.0.
	 */
	public var health:Float = 1;

	/**
	 * An empty FlxObject contained in the scene.
	 * The current gameplay camera will be centered on this object. Tween its position to move the camera smoothly.
	 */
	public var cameraFollowPoint:FlxObject;

	/**
	 * PRIVATE INSTANCE VARIABLES
	 * Private instance variables should be used for information that must be reset or dereferenced
	 * every time the state is reset, but should not be accessed externally.
	 */
	/**
	 * The Array containing the notes that are not currently on the screen.
	 * The `update()` function regularly shifts these out to add new notes to the screen.
	 */
	private var inactiveNotes:Array<Note>;

	/**
	 * An object which the strumline (and its notes) are positioned relative to.
	 */
	private var strumlineAnchor:FlxObject;

	/**
	 * If true, the player is allowed to pause the game.
	 * Disabled during the ending of a song.
	 */
	private var mayPauseGame:Bool = true;

	/**
	 * The displayed value of the player's health.
	 * Used to provide smooth animations based on linear interpolation of the player's health.
	 */
	private var healthLerp:Float = 1;

	/**
	 * RENDER OBJECTS
	 */
	/**
	 * The SpriteGroup containing the notes that are currently on the screen or are about to be on the screen.
	 */
	private var activeNotes:FlxTypedGroup<Note> = null;

	/**
	 * The FlxText which displays the current score.
	 */
	private var scoreText:FlxText;

	/**
	 * The bar which displays the player's health.
	 * Dynamically updated based on the value of `healthLerp` (which is based on `health`).
	 */
	private var healthBar:FlxBar;

	/**
	 * The background image used for the health bar.
	 * Emma says the image is slightly skewed so I'm leaving it as an image instead of a `createGraphic`.
	 */
	public var healthBarBG:FlxSprite;

	/**
	 * The sprite group containing active player's strumline notes.
	 */
	public var playerStrumline:Strumline;

	/**
	 * The sprite group containing opponent's strumline notes.
	 */
	public var enemyStrumline:Strumline;

	/**
	 * The camera which contains, and controls visibility of, the user interface elements.
	 */
	public var camHUD:FlxCamera;

	/**
	 * The camera which contains, and controls visibility of, the stage and characters.
	 */
	public var camGame:FlxCamera;

	/**
	 * PROPERTIES
	 */
	/**
	 * If a substate is rendering over the PlayState, it is paused and normal update logic is skipped.
	 * Examples include:
	 * - The Pause screen is open.
	 * - The Game Over screen is open.
	 * - The Chart Editor screen is open.
	 */
	private var isGamePaused(get, never):Bool;

	function get_isGamePaused():Bool
	{
		// Note: If there is a substate which requires the game to act unpaused,
		//       this should be changed to include something like `&& Std.isOfType()`
		return this.subState != null;
	}

	// TODO: Reorganize these variables (maybe there should be a separate class like Conductor just to hold them?)
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var needsReset:Bool = false;
	public static var seenCutscene:Bool = false;
	public static var campaignScore:Int = 0;

	private var vocals:VoicesGroup;
	private var vocalsFinished:Bool = false;

	private var playerStrums:FlxTypedGroup<FlxSprite>;
	private var camZooming:Bool = false;
	private var gfSpeed:Int = 1;
	private var combo:Int = 0;
	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;
	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;

	var dialogue:Array<String>;
	var talking:Bool = true;
	var songScore:Int = 0;
	var doof:DialogueBox;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	var camPos:FlxPoint;
	var comboPopUps:PopUpStuff;
	var perfectMode:Bool = false;
	var previousFrameTime:Int = 0;
	var songTime:Float = 0;
	var cameraRightSide:Bool = false;

	#if discord_rpc
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var songLength:Float = 0;
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	override public function create()
	{
		super.create();

		instance = this;

		// Reduce physics accuracy (who cares!!!) to improve animation quality.
		FlxG.fixedTimestep = false;

		// This state receives update() even when a substate is active.
		this.persistentUpdate = true;
		// This state receives draw calls even when a substate is active.
		this.persistentDraw = true;

		// Stop any pre-existing music.
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Prepare the current song to be played.
		FlxG.sound.cache(Paths.inst(currentSong.song));
		FlxG.sound.cache(Paths.voices(currentSong.song));

		Conductor.songPosition = -5000;

		// Initialize stage stuff.
		initCameras();

		if (currentSong == null)
			currentSong = SongLoad.loadFromJson('tutorial');

		Conductor.mapBPMChanges(currentSong);
		Conductor.changeBPM(currentSong.bpm);

		switch (currentSong.song.toLowerCase())
		{
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('songs/senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('songs/roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('songs/thorns/thornsDialogue'));
		}

		if (dialogue != null)
		{
			doof = new DialogueBox(false, dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
			doof.cameras = [camHUD];
		}

		// Once the song is loaded, we can continue and initialize the stage.

		initStage();
		initCharacters();
		#if discord_rpc
		initDiscord();
		#end

		comboPopUps = new PopUpStuff();
		add(comboPopUps);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(noteSplash);
		noteSplash.alpha = 0.1;

		add(grpNoteSplashes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		generateSong();

		cameraFollowPoint = new FlxObject(0, 0, 1, 1);
		cameraFollowPoint.setPosition(camPos.x, camPos.y);

		if (previousCameraFollowPoint != null)
		{
			cameraFollowPoint = previousCameraFollowPoint;
			previousCameraFollowPoint = null;
		}

		add(cameraFollowPoint);
		resetCamera();

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		var healthBarYPos:Float = PreferencesMenu.getPref('downscroll') ? FlxG.height * 0.1 : FlxG.height * 0.9;
		healthBarBG = new FlxSprite(0, healthBarYPos).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set(0, 0);
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'healthLerp', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(Constants.HEALTH_BAR_RED, Constants.HEALTH_BAR_GREEN);
		add(healthBar);

		scoreText = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, "", 20);
		scoreText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreText.scrollFactor.set();
		add(scoreText);

		iconP1 = new HealthIcon(currentSong.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(currentSong.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		// Attach the groups to the HUD camera so they are rendered independent of the stage.
		grpNoteSplashes.cameras = [camHUD];
		activeNotes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreText.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			seenCutscene = true;

			switch (currentSong.song.toLowerCase())
			{
				case "winter-horrorland":
					VanillaCutscenes.playHorrorStartCutscene();
				case 'senpai' | 'roses' | 'thorns':
					schoolIntro(doof); // doof is assumed to be non-null, lol!
				case 'ugh':
					VanillaCutscenes.playUghCutscene();
				case 'stress':
					VanillaCutscenes.playStressCutscene();
				case 'guns':
					VanillaCutscenes.playGunsCutscene();
				default:
					startCountdown();
			}
		}
		else
		{
			startCountdown();
		}

		this.leftWatermarkText.text = '${currentSong.song.toUpperCase()} - ${SongLoad.curDiff.toUpperCase()}';
		this.rightWatermarkText.text = Constants.VERSION;
	}

	/**
	 * Initializes the game and HUD cameras.
	 */
	function initCameras()
	{
		// Configure the default camera zoom level.
		defaultCameraZoom = FlxCamera.defaultZoom * 1.05;

		camGame = new SwagCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
	}

	function initStage()
	{
		// TODO: Move stageId to the song file.
		switch (currentSong.song.toLowerCase())
		{
			case 'spookeez' | 'monster' | 'south':
				currentStageId = "spookyMansion";
			case 'pico' | 'blammed' | 'philly':
				currentStageId = 'phillyTrain';
			case "milf" | 'satin-panties' | 'high':
				currentStageId = 'limoRide';
			case "cocoa" | 'eggnog':
				currentStageId = 'mallXmas';
			case 'winter-horrorland':
				currentStageId = 'mallEvil';
			case 'pyro':
				currentStageId = 'pyro';
			case 'senpai' | 'roses':
				currentStageId = 'school';
			case "darnell":
				currentStageId = 'phillyStreets';
			case 'thorns':
				currentStageId = 'schoolEvil';
			case 'guns' | 'stress' | 'ugh':
				currentStageId = 'tankmanBattlefield';
			default:
				currentStageId = "mainStage";
		}
		// Loads the relevant stage based on its ID.
		loadStage(currentStageId);
	}

	function initCharacters()
	{
		// all dis is shitty, redo later for stage shit
		var gfVersion:String = 'gf';

		switch (currentStageId)
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

		if (currentSong.player1 == "pico")
		{
			gfVersion = "nene";
		}

		if (currentSong.song.toLowerCase() == 'stress')
			gfVersion = 'pico-speaker';

		var gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		switch (gfVersion)
		{
			case 'pico-speaker':
				gf.x -= 50;
				gf.y -= 200;
		}

		var dad = new Character(100, 100, currentSong.player2);

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (currentSong.player2)
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

		var boyfriend = new Boyfriend(770, 450, currentSong.player1);

		// REPOSITIONING PER STAGE
		switch (currentStageId)
		{
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// Go behind Spirit.
				evilTrail.zIndex = 190;
				add(evilTrail);
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

		if (currentStage != null)
		{
			// We're using Eric's stage handler.
			// Characters get added to the stage, not the main scene.
			currentStage.addCharacter(gf, GF);
			currentStage.addCharacter(boyfriend, BF);
			currentStage.addCharacter(dad, DAD);

			// Redo z-indexes.
			currentStage.refresh();
		}
		else
		{
			add(gf);
			add(dad);
			add(boyfriend);
		}
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
		if (this.currentStage != null)
		{
			remove(currentStage);
			var event:ScriptEvent = new ScriptEvent(ScriptEvent.DESTROY, false);
			ScriptEventDispatcher.callEvent(currentStage, event);
			currentStage = null;
		}

		ModuleHandler.clearModuleCache();

		// Forcibly reload scripts so that scripted stages can be edited.
		polymod.hscript.PolymodScriptClass.clearScriptClasses();
		polymod.hscript.PolymodScriptClass.registerAllScriptClasses();

		// Reload the stages in cache. This might cause a lag spike but who cares this is a debug utility.
		StageDataParser.loadStageCache();
		ModuleHandler.loadModuleCache();

		// Reload the level. This should use new data from the assets folder.
		LoadingState.loadAndSwitchState(new PlayState());
	}

	/**
	 * Loads stage data from cache, assembles the props,
	 * and adds it to the state.
	 * @param id 
	 */
	function loadStage(id:String)
	{
		currentStage = StageDataParser.fetchStage(id);

		if (currentStage != null)
		{
			// Actually create and position the sprites.
			var event:ScriptEvent = new ScriptEvent(ScriptEvent.CREATE, false);
			ScriptEventDispatcher.callEvent(currentStage, event);

			// Apply camera zoom.
			defaultCameraZoom *= currentStage.camZoom;

			// Add the stage to the scene.
			this.add(currentStage);
		}
	}

	function initDiscord():Void
	{
		#if discord_rpc
		storyDifficultyText = difficultyString();
		iconRPC = currentSong.player2;

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
		DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);
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
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * Constants.PIXEL_ART_SCALE));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		cameraFollowPoint.setPosition(camPos.x, camPos.y);

		if (currentSong.song.toLowerCase() == 'roses' || currentSong.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (currentSong.song.toLowerCase() == 'thorns')
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
					isInCutscene = true;

					if (currentSong.song.toLowerCase() == 'thorns')
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

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;

		if (!isGamePaused)
		{
			// if (FlxG.sound.music != null)
			// FlxG.sound.music.play(true);
			// else
			FlxG.sound.playMusic(Paths.inst(currentSong.song), 1, false);
		}

		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		#if discord_rpc
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end
	}

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());

		Conductor.changeBPM(currentSong.bpm);

		currentSong.song = currentSong.song;

		if (currentSong.needsVoices)
			vocals = new VoicesGroup(currentSong.song, currentSong.voiceList);
		else
			vocals = new VoicesGroup(currentSong.song, null, false);

		vocals.members[0].onComplete = function()
		{
			vocalsFinished = true;
		};

		activeNotes = new FlxTypedGroup<Note>();
		activeNotes.zIndex = 1000;
		add(activeNotes);

		regenNoteData();

		generatedMusic = true;
	}

	function regenNoteData():Void
	{
		// make unspawn notes shit def empty
		inactiveNotes = [];

		activeNotes.forEach(function(nt)
		{
			nt.followsTime = false;
			FlxTween.tween(nt, {y: FlxG.height + nt.y}, 0.5, {
				ease: FlxEase.expoIn,
				onComplete: function(twn)
				{
					nt.kill();
					activeNotes.remove(nt, true);
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
				if (inactiveNotes.length > 0)
					oldNote = inactiveNotes[Std.int(inactiveNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.data = songNotes;
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.data.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				inactiveNotes.push(swagNote);

				for (susNote in 0...Math.round(susLength))
				{
					oldNote = inactiveNotes[Std.int(inactiveNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					inactiveNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
						sustainNote.x += FlxG.width / 2; // general offset
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}
		}

		inactiveNotes.sort(function(a:Note, b:Note):Int
		{
			return SortUtil.byStrumtime(FlxSort.ASCENDING, a, b);
		});
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3 * FlxCamera.defaultZoom}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	#if discord_rpc
	override public function onFocus():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
		{
			if (Conductor.songPosition > 0.0)
				DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC, true,
					songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);
		}

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (health > 0 && !paused && FlxG.autoPause)
			DiscordClient.changePresence(detailsPausedText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);

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

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		updateHealthBar();

		if (needsReset)
		{
			resetCamera();

			persistentUpdate = true;
			persistentDraw = true;

			startingSong = true;

			FlxG.sound.music.pause();
			vocals.pause();

			var event:ScriptEvent = new ScriptEvent(ScriptEvent.SONG_RESET, false);

			FlxG.sound.music.time = 0;
			regenNoteData(); // loads the note data from start
			health = 1;
			Countdown.performCountdown(currentStageId.startsWith('school'));

			needsReset = false;
		}

		#if !debug
		perfectMode = false;
		#else
		if (FlxG.keys.justPressed.H)
			camHUD.visible = !camHUD.visible;
		#end

		// do this BEFORE super.update() so songPosition is accurate
		if (startingSong)
		{
			if (isInCountdown)
			{
				Conductor.songPosition += elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			if (Paths.SOUND_EXT == 'mp3')
				Conductor.offset = -13; // DO NOT FORGET TO REMOVE THE HARDCODE! WHEN I MAKE BETTER OFFSET SYSTEM!

			Conductor.songPosition = FlxG.sound.music.time + Conductor.offset; // 20 is THE MILLISECONDS??

			if (!isGamePaused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}
		}

		var androidPause:Bool = false;

		#if android
		androidPause = FlxG.android.justPressed.BACK;
		#end

		if ((controls.PAUSE || androidPause) && isInCountdown && mayPauseGame)
		{
			persistentUpdate = false;
			persistentDraw = true;

			// There is a 1/1000 change to use a special pause menu.
			// This prevents the player from resuming, but that's the point.
			// It's a reference to Gitaroo Man, which doesn't let you pause the game.
			if (FlxG.random.bool(1 / 1000))
			{
				FlxG.switchState(new GitarooPause());
			}
			else
			{
				var boyfriendPos = currentStage.getBoyfriend().getScreenPosition();
				var pauseSubState = new PauseSubState(boyfriendPos.x, boyfriendPos.y);
				openSubState(pauseSubState);
				pauseSubState.camera = camHUD;
				boyfriendPos.put();
			}

			#if discord_rpc
			DiscordClient.changePresence(detailsPausedText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());

			#if discord_rpc
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

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
			FlxG.camera.zoom = FlxMath.lerp(defaultCameraZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1 * FlxCamera.defaultZoom, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (currentSong.song == 'Fresh')
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

		if (!isInCutscene && !_exiting)
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

			if (health <= 0 && !isPracticeMode)
			{
				persistentUpdate = false;
				persistentDraw = false;

				vocals.pause();
				FlxG.sound.music.pause();

				deathCounter += 1;

				openSubState(new GameOverSubstate());

				#if discord_rpc
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);
				#end
			}
		}

		while (inactiveNotes[0] != null && inactiveNotes[0].data.strumTime - Conductor.songPosition < 1800 / SongLoad.getSpeed())
		{
			var dunceNote:Note = inactiveNotes[0];
			activeNotes.add(dunceNote);

			inactiveNotes.shift();
		}

		if (generatedMusic)
		{
			activeNotes.forEachAlive(function(daNote:Note)
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

				var strumLineMid = playerStrumline.offset.y + Note.swagWidth / 2;

				if (daNote.followsTime)
					daNote.y = (Conductor.songPosition - daNote.data.strumTime) * (0.45 * FlxMath.roundDecimal(SongLoad.getSpeed(),
						2) * daNote.noteSpeedMulti);

				if (PreferencesMenu.getPref('downscroll'))
				{
					daNote.y += playerStrumline.offset.y;
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
						daNote.y = playerStrumline.offset.y - daNote.y;
					if (daNote.isSustainNote
						&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
						&& daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
					{
						applyClipRect(daNote);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (currentSong.song != 'Tutorial')
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
						currentStage.getDad().playAnim('sing' + daNote.dirNameUpper + altAnim, true);
					}

					currentStage.getDad().holdTimer = 0;

					if (currentSong.needsVoices)
						vocals.volume = 1;

					daNote.kill();
					activeNotes.remove(daNote, true);
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
						activeNotes.remove(daNote, true);
						daNote.destroy();
					}
				}
				else if (daNote.tooLate || daNote.wasGoodHit)
				{
					// TODO: Why the hell is the noteMiss logic in two different places?
					if (daNote.tooLate)
					{
						var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_MISS, daNote, true);
						dispatchEvent(event);
						health -= 0.0775;
						vocals.volume = 0;
						killCombo();
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					activeNotes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!isInCutscene)
			keyShit();

		dispatchEvent(new UpdateScriptEvent(elapsed));
	}

	function applyClipRect(daNote:Note):Void
	{
		// clipRect is applied to graphic itself so use frame Heights
		var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
		var strumLineMid = playerStrumline.offset.y + Note.swagWidth / 2;

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
		if (combo > 5 && currentStage.getGirlfriend().animOffsets.exists('sad'))
			currentStage.getGirlfriend().playAnim('sad');

		if (combo != 0)
		{
			combo = comboPopUps.displayCombo(0);
		}
	}

	#if debug
	function changeSection(sec:Int):Void
	{
		FlxG.sound.music.pause();

		var daBPM:Float = currentSong.bpm;
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
		mayPauseGame = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (currentSong.validScore)
		{
			Highscore.saveScore(currentSong.song, songScore, storyDifficulty);
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

				switch (storyWeek)
				{
					case 7:
						FlxG.switchState(new VideoState());
					default:
						FlxG.switchState(new StoryMenuState());
				}

				// if ()
				StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

				if (currentSong.validScore)
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

				if (currentSong.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;
					isInCutscene = true;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'), function()
					{
						// no camFollow so it centers on horror tree
						currentSong = SongLoad.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
						LoadingState.loadAndSwitchState(new PlayState());
					});
				}
				else
				{
					previousCameraFollowPoint = cameraFollowPoint;

					currentSong = SongLoad.loadFromJson(storyPlaylist[0].toLowerCase() + difficulty, storyPlaylist[0]);
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
		var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_HIT, daNote, true);
		dispatchEvent(event);

		if (event.eventCanceled)
		{
			// TODO: Do a thing!
		}

		if (isSick)
		{
			var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
			noteSplash.setupNoteSplash(daNote.x, daNote.y, daNote.data.noteData);
			// new NoteSplash(daNote.x, daNote.y, daNote.noteData);
			grpNoteSplashes.add(noteSplash);
		}

		// Only add the score if you're not on practice mode
		if (!isPracticeMode)
			songScore += score;

		comboPopUps.displayRating(daRating);

		if (combo >= 10 || combo == 0)
			comboPopUps.displayCombo(combo);
	}

	function cameraMovement()
	{
		if (currentStage == null)
			return;

		if (cameraFollowPoint.x != currentStage.getDad().getMidpoint().x + 150 && !cameraRightSide)
		{
			cameraFollowPoint.setPosition(currentStage.getDad().getMidpoint().x + 150, currentStage.getDad().getMidpoint().y - 100);
			// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

			switch (currentStage.getDad().curCharacter)
			{
				case 'mom':
					cameraFollowPoint.y = currentStage.getDad().getMidpoint().y;
				case 'senpai' | 'senpai-angry':
					cameraFollowPoint.y = currentStage.getDad().getMidpoint().y - 430;
					cameraFollowPoint.x = currentStage.getDad().getMidpoint().x - 100;
			}

			if (currentStage.getDad().curCharacter == 'mom')
				vocals.volume = 1;

			if (currentSong.song.toLowerCase() == 'tutorial')
				tweenCamIn();
		}

		if (cameraRightSide && cameraFollowPoint.x != currentStage.getBoyfriend().getMidpoint().x - 100)
		{
			cameraFollowPoint.setPosition(currentStage.getBoyfriend().getMidpoint().x - 100, currentStage.getBoyfriend().getMidpoint().y - 100);

			switch (currentStageId)
			{
				case 'limo':
					cameraFollowPoint.x = currentStage.getBoyfriend().getMidpoint().x - 300;
				case 'mall':
					cameraFollowPoint.y = currentStage.getBoyfriend().getMidpoint().y - 200;
				case 'school' | 'schoolEvil':
					cameraFollowPoint.x = currentStage.getBoyfriend().getMidpoint().x - 200;
					cameraFollowPoint.y = currentStage.getBoyfriend().getMidpoint().y - 200;
			}

			if (currentSong.song.toLowerCase() == 'tutorial')
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
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && generatedMusic)
		{
			activeNotes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.data.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && generatedMusic)
		{
			Haptic.vibrate(100, 100);

			currentStage.getBoyfriend().holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later

			activeNotes.forEachAlive(function(daNote:Note)
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
				activeNotes.remove(note, true);
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

		if (currentStage == null)
			return;
		if (currentStage.getBoyfriend().holdTimer > Conductor.stepCrochet * 4 * 0.001 && !holdArray.contains(true))
		{
			if (currentStage.getBoyfriend().animation != null
				&& currentStage.getBoyfriend().animation.curAnim.name.startsWith('sing')
				&& !currentStage.getBoyfriend().animation.curAnim.name.endsWith('miss'))
			{
				currentStage.getBoyfriend().playAnim('idle');
			}
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				spr.animation.play('pressed');
			if (!holdArray[spr.ID])
				spr.animation.play('static');

			if (spr.animation.curAnim.name == 'confirm' && !currentStageId.startsWith('school'))
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:NoteDir = 1):Void
	{
		// whole function used to be encased in if (!boyfriend.stunned)
		health -= 0.07;
		killCombo();

		if (!isPracticeMode)
			songScore -= 10;

		vocals.volume = 0;
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		currentStage.getBoyfriend().playAnim('sing' + direction.nameUpper + 'miss', true);
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note.data.strumTime, note);
			}

			currentStage.getBoyfriend().playAnim('sing' + note.dirNameUpper, true);

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
				activeNotes.remove(note, true);
				note.destroy();
			}
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (currentSong.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		dispatchEvent(new SongTimeScriptEvent(ScriptEvent.SONG_STEP_HIT, curBeat, curStep));
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			activeNotes.sort(SortUtil.byStrumtime, FlxSort.DESCENDING);
		}

		if (SongLoad.getSong()[Math.floor(curStep / 16)] != null)
		{
			if (SongLoad.getSong()[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SongLoad.getSong()[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
		}

		// HARDCODING FOR MILF ZOOMS!

		if (PreferencesMenu.getPref('camera-zoom'))
		{
			if (currentSong.song.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
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

		// Make the health icons bump (the update function causes them to lerp back down).
		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));
		iconP1.updateHitbox();
		iconP2.updateHitbox();

		// Make the characters dance on the beat
		danceOnBeat();

		// Call any relevant event handlers.
		dispatchEvent(new SongTimeScriptEvent(ScriptEvent.SONG_BEAT_HIT, curBeat, curStep));
	}

	/**
	 * Handles characters dancing to the beat of the current song.
	 * 
	 * TODO: Move some of this logic into `Bopper.hx`
	 */
	public function danceOnBeat()
	{
		if (currentStage == null)
			return;

		if (curBeat % gfSpeed == 0)
			currentStage.getGirlfriend().dance();

		if (curBeat % 2 == 0)
		{
			if (currentStage.getBoyfriend().animation != null && !currentStage.getBoyfriend().animation.curAnim.name.startsWith("sing"))
				currentStage.getBoyfriend().playAnim('idle');
			if (currentStage.getDad().animation != null && !currentStage.getDad().animation.curAnim.name.startsWith("sing"))
				currentStage.getDad().dance();
		}
		else if (currentStage.getDad().curCharacter == 'spooky')
		{
			if (!currentStage.getDad().animation.curAnim.name.startsWith("sing"))
				currentStage.getDad().dance();
		}

		if (curBeat % 8 == 7 && currentSong.song == 'Bopeebo')
		{
			currentStage.getBoyfriend().playAnim('hey', true);
		}

		if (curBeat % 16 == 15
			&& currentSong.song == 'Tutorial'
			&& currentStage.getDad().curCharacter == 'gf'
			&& curBeat > 16
			&& curBeat < 48)
		{
			currentStage.getBoyfriend().playAnim('hey', true);
			currentStage.getDad().playAnim('cheer', true);
		}
	}

	/**
	 * Constructs the strumlines for each player.
	 */
	function buildStrumlines():Void
	{
		var strumlineStyle:StrumlineStyle = NORMAL;

		// TODO: Put this in the chart or something?
		switch (currentStageId)
		{
			case 'school':
				strumlineStyle = PIXEL;
			case 'schoolEvil':
				strumlineStyle = PIXEL;
		}

		var strumlineYPos = Strumline.getYPos();

		playerStrumline = new Strumline(0, strumlineStyle, 4);
		playerStrumline.offset = new FlxPoint(50 + FlxG.width / 2, strumlineYPos);
		// Set the z-index so they don't appear in front of notes.
		playerStrumline.zIndex = 100;
		add(playerStrumline);
		playerStrumline.cameras = [camHUD];

		enemyStrumline = new Strumline(1, strumlineStyle, 4);
		enemyStrumline.offset = new FlxPoint(50, strumlineYPos);
		// Set the z-index so they don't appear in front of notes.
		enemyStrumline.zIndex = 100;
		add(enemyStrumline);
		enemyStrumline.cameras = [camHUD];

		this.refresh();
	}

	/**
	 * Function called before opening a new substate.
	 * @param subState The substate to open.
	 */
	override function openSubState(subState:FlxSubState)
	{
		// If there is a substate which requires the game to continue,
		// then make this a condition.
		var shouldPause = true;

		if (shouldPause)
		{
			// Pause the music.
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				if (vocals != null)
					vocals.pause();
			}

			// Pause the countdown.
			Countdown.pauseCountdown();
		}

		var event:ScriptEvent = new ScriptEvent(ScriptEvent.PAUSE, true);

		dispatchEvent(event);

		if (event.eventCanceled)
			return;

		super.openSubState(subState);
	}

	/**
	 * Function called before closing the current substate.
	 * @param subState 
	 */
	override function closeSubState()
	{
		if (isGamePaused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			// Resume the countdown.
			Countdown.resumeCountdown();

			#if discord_rpc
			if (startTimer.finished)
				DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC, true,
					songLength - Conductor.songPosition);
			else
				DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		var event:ScriptEvent = new ScriptEvent(ScriptEvent.RESUME, true);

		dispatchEvent(event);

		if (event.eventCanceled)
			return;

		super.closeSubState();
	}

	/**
	 * Prepares to start the countdown.
	 * Ends any running cutscenes, creates the strumlines, and starts the countdown.
	 */
	function startCountdown():Void
	{
		isInCutscene = false;
		camHUD.visible = true;
		talking = false;

		buildStrumlines();

		Countdown.performCountdown(currentStageId.startsWith('school'));
	}

	override function dispatchEvent(event:ScriptEvent):Void
	{
		ScriptEventDispatcher.callEvent(currentStage, event);

		// TODO: Dispatch event to song script
		// TODO: Dispatch events to character scripts

		super.dispatchEvent(event);
	}

	/**
	 * Updates the position and contents of the score display.
	 */
	function updateScoreText():Void
	{
		// TODO: Add functionality for modules to update the score text.
		scoreText.text = "Score:" + songScore;
	}

	/**
	 * Updates the values of the health bar.
	 */
	function updateHealthBar():Void
	{
		healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
	}

	/**
	 * Resets the camera's zoom level and focus point.
	 */
	function resetCamera():Void
	{
		FlxG.camera.follow(cameraFollowPoint, LOCKON, 0.04);
		FlxG.camera.zoom = defaultCameraZoom;
		FlxG.camera.focusOn(cameraFollowPoint.getPosition());
	}

	/**
	 * Perform necessary cleanup before leaving the PlayState.
	 */
	function performCleanup()
	{
		// Uncache the song.
		openfl.utils.Assets.cache.clear(Paths.inst(currentSong.song));
		openfl.utils.Assets.cache.clear(Paths.voices(currentSong.song));

		// Remove reference to stage and remove sprites from it to save memory.
		if (currentStage != null)
		{
			remove(currentStage);
			currentStage.kill();
			currentStage = null;
		}

		// Clear the static reference to this state.
		instance = null;
	}

	/**
	 * Refreshes the state, by redoing the render order of all elements.
	 * It does this based on the `zIndex` of each element.
	 */
	public function refresh()
	{
		sort(SortUtil.byZIndex, FlxSort.ASCENDING);
		trace('Stage sorted by z-index');
	}

	/**
	 * This function is called whenever Flixel switches switching to a new FlxState.
	 */
	override function switchTo(nextState:FlxState):Bool
	{
		performCleanup();

		return super.switchTo(nextState);
	}
}
