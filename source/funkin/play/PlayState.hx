package funkin.play;

import funkin.play.song.SongData.SongEventData;
import funkin.play.event.SongEvent.SongEventParser;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import funkin.Highscore.Tallies;
import funkin.Note;
import funkin.Section.SwagSection;
import funkin.SongLoad.SwagSong;
import funkin.charting.ChartingState;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.GameOverSubstate;
import funkin.play.HealthIcon;
import funkin.play.Strumline.StrumlineArrow;
import funkin.play.Strumline.StrumlineStyle;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData;
import funkin.play.scoring.Scoring;
import funkin.play.song.Song;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongData.SongPlayableChar;
import funkin.play.song.SongValidator;
import funkin.play.stage.Stage;
import funkin.play.stage.StageData;
import funkin.ui.PopUpStuff;
import funkin.ui.PreferencesMenu;
import funkin.ui.stageBuildShit.StageOffsetSubstate;
import funkin.util.Constants;
import funkin.util.SortUtil;
import lime.ui.Haptic;
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

  public static var currentSong_NEW:Song = null;

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
   * Gets set to true when the PlayState needs to reset (player opted to restart or died).
   * Gets disabled once resetting happens.
   */
  public static var needsReset:Bool = false;

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

  public var currentChart(get, null):SongDifficulty;

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
   * The player's current score.
   */
  public var songScore:Int = 0;

  /**
   * An empty FlxObject contained in the scene.
   * The current gameplay camera will be centered on this object. Tween its position to move the camera smoothly.
   * 
   * This is an FlxSprite for two reasons:
   * 1. It needs to be an object in the scene for the camera to be configured to follow it.
   * 2. It needs to be an FlxSprite to allow a graphic (optionally, for debug purposes) to be drawn on it.
   */
  public var cameraFollowPoint:FlxSprite = new FlxSprite(0, 0);

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

  private var songEvents:Array<SongEventData>;

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
   * Forcibly disables all update logic while the game moves back to the Menu state.
   * This is used only when a critical error occurs and the game cannot continue.
   */
  private var criticalFailure:Bool = false;

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
  public var healthBar:FlxBar;

  /**
   * The background image used for the health bar.
   * Emma says the image is slightly skewed so I'm leaving it as an image instead of a `createGraphic`.
   */
  public var healthBarBG:FlxSprite;

  /**
   * The health icon representing the player.
   */
  public var iconP1:HealthIcon;

  /**
   * The health icon representing the opponent.
   */
  public var iconP2:HealthIcon;

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
  public static var storyDifficulty_NEW:String = "normal";
  public static var seenCutscene:Bool = false;
  public static var campaignScore:Int = 0;

  private var vocals:VoicesGroup;
  private var vocalsFinished:Bool = false;

  private var camZooming:Bool = false;
  private var gfSpeed:Int = 1;
  // private var combo:Int = 0;
  private var generatedMusic:Bool = false;
  private var startingSong:Bool = false;

  var dialogue:Array<String>;
  var talking:Bool = true;
  var doof:DialogueBox;
  var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
  var comboPopUps:PopUpStuff;
  var perfectMode:Bool = false;
  var previousFrameTime:Int = 0;
  var songTime:Float = 0;

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

    if (currentSong == null && currentSong_NEW == null)
    {
      criticalFailure = true;

      lime.app.Application.current.window.alert("There was a critical error while accessing the selected song. Click OK to return to the main menu.",
        "Error loading PlayState");
      FlxG.switchState(new MainMenuState());
      return;
    }

    instance = this;

    if (currentSong_NEW != null)
    {
      // TODO: Do this in the loading state.
      currentSong_NEW.cacheCharts(true);
    }

    // Displays the camera follow point as a sprite for debug purposes.
    // TODO: Put this on a toggle?
    cameraFollowPoint.makeGraphic(8, 8, 0xFF00FF00);
    cameraFollowPoint.visible = false;
    cameraFollowPoint.zIndex = 1000000;

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
    if (currentChart != null)
    {
      currentChart.cacheInst();
      currentChart.cacheVocals();
    }
    else
    {
      FlxG.sound.cache(Paths.inst(currentSong.song));
      FlxG.sound.cache(Paths.voices(currentSong.song));
    }

    // Initialize stage stuff.
    initCameras();

    if (currentSong == null && currentSong_NEW == null)
    {
      currentSong = SongLoad.loadFromJson('tutorial');
    }

    if (currentSong_NEW != null)
    {
      Conductor.mapTimeChanges(currentChart.timeChanges);
      // Conductor.bpm = currentChart.getStartingBPM();

      // TODO: Support for dialog.
    }
    else
    {
      Conductor.mapBPMChanges(currentSong);
      // Conductor.bpm = currentSong.bpm;

      switch (currentSong.song.toLowerCase())
      {
        case 'senpai':
          dialogue = CoolUtil.coolTextFile(Paths.txt('songs/senpai/senpaiDialogue'));
        case 'roses':
          dialogue = CoolUtil.coolTextFile(Paths.txt('songs/roses/rosesDialogue'));
        case 'thorns':
          dialogue = CoolUtil.coolTextFile(Paths.txt('songs/thorns/thornsDialogue'));
      }
    }

    Conductor.update(-5000);

    if (dialogue != null)
    {
      doof = new DialogueBox(false, dialogue);
      doof.scrollFactor.set();
      doof.finishThing = startCountdown;
      doof.cameras = [camHUD];
    }

    // Once the song is loaded, we can continue and initialize the stage.

    var healthBarYPos:Float = PreferencesMenu.getPref('downscroll') ? FlxG.height * 0.1 : FlxG.height * 0.9;
    healthBarBG = new FlxSprite(0, healthBarYPos).loadGraphic(Paths.image('healthBar'));
    healthBarBG.screenCenter(X);
    healthBarBG.scrollFactor.set(0, 0);
    add(healthBarBG);

    healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
      'healthLerp', 0, 2);
    healthBar.scrollFactor.set();
    healthBar.createFilledBar(Constants.COLOR_HEALTH_BAR_RED, Constants.COLOR_HEALTH_BAR_GREEN);
    add(healthBar);

    initStage();
    initCharacters();
    #if discord_rpc
    initDiscord();
    #end

    // Configure camera follow point.
    if (previousCameraFollowPoint != null)
    {
      cameraFollowPoint.setPosition(previousCameraFollowPoint.x, previousCameraFollowPoint.y);
      previousCameraFollowPoint = null;
    }
    add(cameraFollowPoint);

    comboPopUps = new PopUpStuff();
    comboPopUps.cameras = [camHUD];
    add(comboPopUps);

    grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

    var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
    grpNoteSplashes.add(noteSplash);
    noteSplash.alpha = 0.1;

    add(grpNoteSplashes);

    if (currentSong_NEW != null)
    {
      generateSong_NEW();
    }
    else
    {
      generateSong();
    }

    resetCamera();

    FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

    scoreText = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, "", 20);
    scoreText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreText.scrollFactor.set();
    add(scoreText);

    // Attach the groups to the HUD camera so they are rendered independent of the stage.
    grpNoteSplashes.cameras = [camHUD];
    activeNotes.cameras = [camHUD];
    healthBar.cameras = [camHUD];
    healthBarBG.cameras = [camHUD];
    iconP1.cameras = [camHUD];
    iconP2.cameras = [camHUD];
    scoreText.cameras = [camHUD];
    leftWatermarkText.cameras = [camHUD];
    rightWatermarkText.cameras = [camHUD];

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
          // VanillaCutscenes will call startCountdown later.
          // TODO: Alternatively: make a song script that allows startCountdown to be called,
          // then cancels the countdown, hides the strumline, plays the cutscene,
          // then calls Countdown.performCountdown()
          startCountdown();
      }
    }
    else
    {
      startCountdown();
    }

    #if debug
    this.rightWatermarkText.text = Constants.VERSION;
    #end
  }

  function get_currentChart():SongDifficulty
  {
    if (currentSong_NEW == null || storyDifficulty_NEW == null)
      return null;
    return currentSong_NEW.getDifficulty(storyDifficulty_NEW);
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
    if (currentSong_NEW != null)
    {
      initStage_NEW();
      return;
    }

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
      case 'senpai' | 'roses':
        currentStageId = 'school';
      case "darnell" | "lit-up" | "2hot":
        currentStageId = 'phillyStreets';
      // currentStageId = 'pyro';
      case "blazin":
        currentStageId = 'phillyBlazin';
      // currentStageId = 'pyro';
      case 'pyro':
        currentStageId = 'pyro';
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

  function initStage_NEW()
  {
    if (currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    if (currentChart.stage != null && currentChart.stage != '')
    {
      currentStageId = currentChart.stage;
    }
    else
    {
      currentStageId = SongValidator.DEFAULT_STAGE;
    }

    loadStage(currentStageId);
  }

  function initCharacters()
  {
    if (currentSong_NEW != null)
    {
      initCharacters_NEW();
      return;
    }

    iconP1 = new HealthIcon(currentSong.player1, 0);
    iconP1.y = healthBar.y - (iconP1.height / 2);
    add(iconP1);

    iconP2 = new HealthIcon(currentSong.player2, 1);
    iconP2.y = healthBar.y - (iconP2.height / 2);
    add(iconP2);

    //
    // GIRLFRIEND
    //

    // TODO: Tie the GF version to the song data, not the stage ID or the current player.
    var gfVersion:String = 'gf';

    switch (currentStageId)
    {
      case 'pyro' | 'phillyStreets':
        gfVersion = 'nene';
      case 'blazin':
        gfVersion = '';
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
      gfVersion = "nene";

    if (currentSong.song.toLowerCase() == 'stress')
      gfVersion = 'pico-speaker';

    if (currentSong.song.toLowerCase() == 'tutorial')
      gfVersion = '';

    //
    // GIRLFRIEND
    //
    var girlfriend:BaseCharacter = CharacterDataParser.fetchCharacter(gfVersion);

    if (girlfriend != null)
    {
      girlfriend.characterType = CharacterType.GF;
      girlfriend.scrollFactor.set(0.95, 0.95);
      if (gfVersion == 'pico-speaker')
      {
        girlfriend.x -= 50;
        girlfriend.y -= 200;
      }
    }
    else if (gfVersion != '')
    {
      trace('WARNING: Could not load girlfriend character with ID ${gfVersion}, skipping...');
    }

    //
    // DAD
    //
    var dad:BaseCharacter = CharacterDataParser.fetchCharacter(currentSong.player2);

    if (dad != null)
    {
      dad.characterType = CharacterType.DAD;
    }

    switch (currentSong.player2)
    {
      case 'gf':
        if (isStoryMode)
        {
          cameraFollowPoint.x += 600;
          tweenCamIn();
        }
    }

    //
    // BOYFRIEND
    //
    var boyfriend:BaseCharacter = CharacterDataParser.fetchCharacter(currentSong.player1);

    if (boyfriend != null)
    {
      boyfriend.characterType = CharacterType.BF;
    }

    if (currentStage != null)
    {
      // We're using Eric's stage handler.
      // Characters get added to the stage, not the main scene.
      if (girlfriend != null)
      {
        currentStage.addCharacter(girlfriend, GF);
      }

      if (boyfriend != null)
      {
        currentStage.addCharacter(boyfriend, BF);
      }

      if (dad != null)
      {
        currentStage.addCharacter(dad, DAD);
        // Camera starts at dad.
        cameraFollowPoint.setPosition(dad.cameraFocusPoint.x, dad.cameraFocusPoint.y);
      }

      // Redo z-indexes.
      currentStage.refresh();
    }
  }

  function initCharacters_NEW()
  {
    if (currentSong_NEW == null || currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    // TODO: Switch playable character by manipulating this value.
    // TODO: How to choose which one to use for story mode?

    var playableChars = currentChart.getPlayableChars();
    var currentPlayer = 'bf';

    if (playableChars.length == 0)
    {
      trace('WARNING: No playable characters found for this song.');
    }
    else if (playableChars.indexOf(currentPlayer) == -1)
    {
      currentPlayer = playableChars[0];
    }

    var currentCharData:SongPlayableChar = currentChart.getPlayableChar(currentPlayer);

    //
    // GIRLFRIEND
    //
    var girlfriend:BaseCharacter = CharacterDataParser.fetchCharacter(currentCharData.girlfriend);

    if (girlfriend != null)
    {
      girlfriend.characterType = CharacterType.GF;
    }
    else if (currentCharData.girlfriend != '')
    {
      trace('WARNING: Could not load girlfriend character with ID ${currentCharData.girlfriend}, skipping...');
    }
    else
    {
      // Chosen GF was '' so we don't load one.
    }

    //
    // DAD
    //
    var dad:BaseCharacter = CharacterDataParser.fetchCharacter(currentCharData.opponent);

    if (dad != null)
    {
      dad.characterType = CharacterType.DAD;
    }

    // TODO: Cut out this code/make it generic.
    switch (currentCharData.opponent)
    {
      case 'gf':
        if (isStoryMode)
        {
          cameraFollowPoint.x += 600;
          tweenCamIn();
        }
    }

    //
    // OPPONENT HEALTH ICON
    //
    iconP2 = new HealthIcon(currentCharData.opponent, 1);
    iconP2.y = healthBar.y - (iconP2.height / 2);
    add(iconP2);

    //
    // BOYFRIEND
    //
    var boyfriend:BaseCharacter = CharacterDataParser.fetchCharacter(currentPlayer);

    if (boyfriend != null)
    {
      boyfriend.characterType = CharacterType.BF;
    }

    //
    // PLAYER HEALTH ICON
    //
    iconP1 = new HealthIcon(currentPlayer, 0);
    iconP1.y = healthBar.y - (iconP1.height / 2);
    add(iconP1);

    //
    // ADD CHARACTERS TO SCENE
    //

    if (currentStage != null)
    {
      // Characters get added to the stage, not the main scene.
      if (girlfriend != null)
      {
        currentStage.addCharacter(girlfriend, GF);
      }

      if (boyfriend != null)
      {
        currentStage.addCharacter(boyfriend, BF);
      }

      if (dad != null)
      {
        currentStage.addCharacter(dad, DAD);
        // Camera starts at dad.
        cameraFollowPoint.setPosition(dad.cameraFocusPoint.x, dad.cameraFocusPoint.y);
      }

      // Rearrange by z-indexes.
      currentStage.refresh();
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
  override function debug_refreshModules()
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

    super.debug_refreshModules();
  }

  /**
   * Pauses music and vocals easily.
   */
  public function pauseMusic()
  {
    FlxG.sound.music.pause();
    vocals.pause();
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
      defaultCameraZoom = currentStage.camZoom;

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
    dispatchEvent(new ScriptEvent(ScriptEvent.SONG_START));

    startingSong = false;

    previousFrameTime = FlxG.game.ticks;

    if (!isGamePaused)
    {
      // if (FlxG.sound.music != null)
      // FlxG.sound.music.play(true);
      // else
      if (currentChart != null)
      {
        currentChart.playInst(1.0, false);
      }
      else
      {
        FlxG.sound.playMusic(Paths.inst(currentSong.song), 1, false);
      }
    }

    FlxG.sound.music.onComplete = endSong;
    trace('Playing vocals...');
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

    Conductor.forceBPM(currentSong.bpm);

    currentSong.song = currentSong.song;

    if (currentSong.needsVoices)
      vocals = VoicesGroup.build(currentSong.song, currentSong.voiceList);
    else
      vocals = VoicesGroup.build(currentSong.song, null);

    vocals.members[0].onComplete = function()
    {
      vocalsFinished = true;
    };

    trace(vocals);

    activeNotes = new FlxTypedGroup<Note>();
    activeNotes.zIndex = 1000;
    add(activeNotes);

    regenNoteData();

    generatedMusic = true;
  }

  private function generateSong_NEW():Void
  {
    if (currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    Conductor.forceBPM(currentChart.getStartingBPM());

    // TODO: Fix grouped vocals
    vocals = currentChart.buildVocals();
    vocals.members[0].onComplete = function()
    {
      vocalsFinished = true;
    }

    // Create the rendered note group.
    activeNotes = new FlxTypedGroup<Note>();
    activeNotes.zIndex = 1000;
    add(activeNotes);

    regenNoteData_NEW();

    generatedMusic = true;
  }

  function regenNoteData():Void
  {
    // resets combo, should prob put somewhere else!
    Highscore.tallies.combo = 0;
    Highscore.tallies = new Tallies();
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
        // TODO: Replace 4 with strumlineSize
        var daNoteData:Int = Std.int(songNotes.noteData % 4);
        var gottaHitNote:Bool = section.mustHitSection;

        if (songNotes.highStakes) // noteData > 3
          gottaHitNote = !section.mustHitSection;

        var oldNote:Note;
        if (inactiveNotes.length > 0)
          oldNote = inactiveNotes[Std.int(inactiveNotes.length - 1)];
        else
          oldNote = null;

        var strumlineStyle:StrumlineStyle = NORMAL;

        // TODO: Put this in the chart or something?
        switch (currentStageId)
        {
          case 'school':
            strumlineStyle = PIXEL;
          case 'schoolEvil':
            strumlineStyle = PIXEL;
        }

        var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, strumlineStyle);
        // swagNote.data = songNotes;
        swagNote.data.sustainLength = songNotes.sustainLength;
        swagNote.data.noteKind = songNotes.noteKind;
        swagNote.scrollFactor.set(0, 0);

        var susLength:Float = swagNote.data.sustainLength;

        susLength = susLength / Conductor.stepCrochet;
        inactiveNotes.push(swagNote);

        for (susNote in 0...Math.round(susLength))
        {
          oldNote = inactiveNotes[Std.int(inactiveNotes.length - 1)];

          var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, strumlineStyle);
          sustainNote.data.noteKind = songNotes.noteKind;
          sustainNote.scrollFactor.set();
          inactiveNotes.push(sustainNote);

          sustainNote.mustPress = gottaHitNote;

          if (sustainNote.mustPress)
            sustainNote.x += FlxG.width / 2; // general offset
        }

        // TODO: Replace 4 with strumlineSize
        swagNote.mustPress = gottaHitNote;

        if (swagNote.mustPress)
        {
          if (playerStrumline != null)
          {
            swagNote.x = playerStrumline.getArrow(swagNote.data.noteData).x;
          }
          else
          {
            swagNote.x += FlxG.width / 2; // general offset
          }
        }
        else
        {
          if (enemyStrumline != null)
          {
            swagNote.x = enemyStrumline.getArrow(swagNote.data.noteData).x;
          }
          else
          {
            // swagNote.x += FlxG.width / 2; // general offset
          }
        }
      }
    }

    inactiveNotes.sort(function(a:Note, b:Note):Int
    {
      return SortUtil.byStrumtime(FlxSort.ASCENDING, a, b);
    });
  }

  function regenNoteData_NEW():Void
  {
    Highscore.tallies.combo = 0;
    Highscore.tallies = new Tallies();

    // Reset song events.
    songEvents = currentChart.getEvents();
    SongEventParser.resetEvents(songEvents);

    // Destroy inactive notes.
    inactiveNotes = [];

    // Destroy active notes.
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

    var noteData:Array<SongNoteData> = currentChart.notes;

    var oldNote:Note = null;
    for (songNote in noteData)
    {
      var mustHitNote:Bool = songNote.getMustHitNote();

      // TODO: Put this in the chart or something?
      var strumlineStyle:StrumlineStyle = null;
      switch (currentStageId)
      {
        case 'school':
          strumlineStyle = PIXEL;
        case 'schoolEvil':
          strumlineStyle = PIXEL;
        default:
          strumlineStyle = NORMAL;
      }

      var newNote:Note = new Note(songNote.time, songNote.data, oldNote, false, strumlineStyle);
      newNote.mustPress = mustHitNote;
      newNote.data.sustainLength = songNote.length;
      newNote.data.noteKind = songNote.kind;
      newNote.scrollFactor.set(0, 0);

      // Note positioning.
      // TODO: Make this more robust.
      if (newNote.mustPress)
      {
        if (playerStrumline != null)
        {
          // Align with the strumline arrow.
          newNote.x = playerStrumline.getArrow(songNote.getDirection()).x;
        }
        else
        {
          // Assume strumline position.
          newNote.x += FlxG.width / 2;
        }
      }
      else
      {
        if (enemyStrumline != null)
        {
          newNote.x = enemyStrumline.getArrow(songNote.getDirection()).x;
        }
        else
        {
          // newNote.x += 0;
        }
      }

      inactiveNotes.push(newNote);

      oldNote = newNote;

      // Generate X sustain notes.
      var sustainSections = Math.round(songNote.length / Conductor.stepCrochet);
      for (noteIndex in 0...sustainSections)
      {
        var noteTimeOffset:Float = Conductor.stepCrochet + (Conductor.stepCrochet * noteIndex);
        var sustainNote:Note = new Note(songNote.time + noteTimeOffset, songNote.data, oldNote, true, strumlineStyle);
        sustainNote.mustPress = mustHitNote;
        sustainNote.data.noteKind = songNote.kind;
        sustainNote.scrollFactor.set(0, 0);

        if (sustainNote.mustPress)
        {
          if (playerStrumline != null)
          {
            // Align with the strumline arrow.
            sustainNote.x = playerStrumline.getArrow(songNote.getDirection()).x;
          }
          else
          {
            // Assume strumline position.
            sustainNote.x += FlxG.width / 2;
          }
        }
        else
        {
          if (enemyStrumline != null)
          {
            sustainNote.x = enemyStrumline.getArrow(songNote.getDirection()).x;
          }
          else
          {
            // newNote.x += 0;
          }
        }

        inactiveNotes.push(sustainNote);

        oldNote = sustainNote;
      }
    }

    // Sorting is an expensive operation.
    // Assume it was done in the chart file.
    /**
      inactiveNotes.sort(function(a:Note, b:Note):Int
      {
        return SortUtil.byStrumtime(FlxSort.ASCENDING, a, b);
      });
    **/
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
        DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
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
    if (_exiting || vocals == null)
      return;

    vocals.pause();

    FlxG.sound.music.play();
    Conductor.update(FlxG.sound.music.time + Conductor.offset);

    if (vocalsFinished)
      return;

    vocals.time = FlxG.sound.music.time;
    vocals.play();
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    if (criticalFailure)
      return;

    if (FlxG.keys.justPressed.U)
    {
      // hack for HaxeUI generation, doesn't work unless persistentUpdate is false at state creation!!
      persistentUpdate = false;
      openSubState(new StageOffsetSubstate());
    }

    updateHealthBar();
    updateScoreText();

    if (needsReset)
    {
      dispatchEvent(new ScriptEvent(ScriptEvent.SONG_RETRY));

      resetCamera();

      persistentUpdate = true;
      persistentDraw = true;

      startingSong = true;

      FlxG.sound.music.pause();
      vocals.pause();

      FlxG.sound.music.time = 0;

      currentStage.resetStage();

      // Delete all notes and reset the arrays.
      if (currentChart != null)
      {
        regenNoteData_NEW();
      }
      else
      {
        regenNoteData();
      }

      health = 1;
      songScore = 0;
      Highscore.tallies.combo = 0;
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

      Conductor.update(FlxG.sound.music.time + Conductor.offset);

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
      var event = new PauseScriptEvent(FlxG.random.bool(1 / 1000));

      dispatchEvent(event);

      if (!event.eventCanceled)
      {
        // Pause updates while the substate is open, preventing the game state from advancing.
        persistentUpdate = false;
        // Enable drawing while the substate is open, allowing the game state to be shown behind the pause menu.
        persistentDraw = true;

        // There is a 1/1000 change to use a special pause menu.
        // This prevents the player from resuming, but that's the point.
        // It's a reference to Gitaroo Man, which doesn't let you pause the game.
        if (event.gitaroo)
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
    }

    #if debug
    // 1: End the song immediately.
    if (FlxG.keys.justPressed.ONE)
      endSong();

    // 2: Gain 10% health.
    if (FlxG.keys.justPressed.TWO)
      health += 0.1 * 2.0;

    // 3: Lose 5% health.
    if (FlxG.keys.justPressed.THREE)
      health -= 0.05 * 2.0;
    #end

    // 7: Move to the charter.
    if (FlxG.keys.justPressed.SEVEN)
    {
      FlxG.switchState(new ChartingState());

      #if discord_rpc
      DiscordClient.changePresence("Chart Editor", null, null, true);
      #end
    }

    // 8: Move to the offset editor.
    if (FlxG.keys.justPressed.EIGHT)
      FlxG.switchState(new funkin.ui.animDebugShit.DebugBoundingState());

    // 9: Toggle the old icon.
    if (FlxG.keys.justPressed.NINE)
      iconP1.toggleOldIcon();

    #if debug
    // PAGEUP: Skip forward one section.
    // SHIFT+PAGEUP: Skip forward ten sections.
    if (FlxG.keys.justPressed.PAGEUP)
      changeSection(FlxG.keys.pressed.SHIFT ? 10 : 1);
    // PAGEDOWN: Skip backward one section. Doesn't replace notes.
    // SHIFT+PAGEDOWN: Skip backward ten sections.
    if (FlxG.keys.justPressed.PAGEDOWN)
      changeSection(FlxG.keys.pressed.SHIFT ? -10 : -1);
    #end

    if (health > 2.0)
      health = 2.0;
    if (health < 0.0)
      health = 0.0;

    if (camZooming && subState == null)
    {
      FlxG.camera.zoom = FlxMath.lerp(defaultCameraZoom, FlxG.camera.zoom, 0.95);
      camHUD.zoom = FlxMath.lerp(1 * FlxCamera.defaultZoom, camHUD.zoom, 0.95);
    }

    FlxG.watch.addQuick("beatShit", Conductor.currentBeat);
    FlxG.watch.addQuick("stepShit", Conductor.currentStep);
    if (currentStage != null)
    {
      FlxG.watch.addQuick("bfAnim", currentStage.getBoyfriend().getCurrentAnimation());
    }
    FlxG.watch.addQuick("songPos", Conductor.songPosition);

    if (currentSong != null && currentSong.song == 'Fresh')
    {
      switch (Conductor.currentBeat)
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
        vocals.pause();
        FlxG.sound.music.pause();

        deathCounter += 1;

        dispatchEvent(new ScriptEvent(ScriptEvent.GAME_OVER));

        // Disable updates, preventing animations in the background from playing.
        persistentUpdate = false;
        #if debug
        if (FlxG.keys.pressed.THREE)
        {
          // TODO: Change the key or delete this?
          // In debug builds, pressing 3 to kill the player makes the background transparent.
          persistentDraw = true;
        }
        else
        {
        #end
          persistentDraw = false;
        #if debug
        }
        #end

        var gameOverSubstate = new GameOverSubstate();
        openSubState(gameOverSubstate);

        #if discord_rpc
        // Game Over doesn't get his own variable because it's only used here
        DiscordClient.changePresence("Game Over - " + detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);
        #end
      }
    }

    while (inactiveNotes[0] != null && inactiveNotes[0].data.strumTime - Conductor.songPosition < 1800 / SongLoad.getSpeed())
    {
      var dunceNote:Note = inactiveNotes[0];

      if (dunceNote.mustPress && !dunceNote.isSustainNote)
        Highscore.tallies.totalNotes++;

      activeNotes.add(dunceNote);

      inactiveNotes.shift();
    }

    if (generatedMusic && playerStrumline != null)
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

        var strumLineMid = playerStrumline.y + Note.swagWidth / 2;

        if (daNote.followsTime)
          daNote.y = (Conductor.songPosition - daNote.data.strumTime) * (0.45 * FlxMath.roundDecimal(SongLoad.getSpeed(), 2) * daNote.noteSpeedMulti);

        if (PreferencesMenu.getPref('downscroll'))
        {
          daNote.y += playerStrumline.y;
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
            daNote.y = playerStrumline.y - daNote.y;
          if (daNote.isSustainNote
            && (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
            && daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
          {
            applyClipRect(daNote);
          }
        }

        if (!daNote.mustPress && daNote.wasGoodHit && !daNote.tooLate)
        {
          if (currentSong != null && currentSong.song != 'Tutorial')
            camZooming = true;

          var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_HIT, daNote, Highscore.tallies.combo, true);
          dispatchEvent(event);

          // Calling event.cancelEvent() in a module should force the CPU to miss the note.
          // This is useful for cool shit, including but not limited to:
          // - Making the AI ignore notes which are hazardous.
          // - Making the AI miss notes on purpose for aesthetic reasons.
          if (event.eventCanceled)
          {
            daNote.tooLate = true;
          }
          else
          {
            // Volume of DAD.
            if (currentSong != null && currentSong.needsVoices)
              vocals.volume = 1;
          }
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
        if (daNote.wasGoodHit)
        {
          daNote.active = false;
          daNote.visible = false;

          daNote.kill();
          activeNotes.remove(daNote, true);
          daNote.destroy();
        }

        if (daNote.tooLate)
        {
          noteMiss(daNote);
        }
      });
    }

    if (songEvents != null && songEvents.length > 0)
    {
      var songEventsToActivate:Array<SongEventData> = SongEventParser.queryEvents(songEvents, Conductor.songPosition);

      if (songEventsToActivate.length > 0)
      {
        trace('Found ${songEventsToActivate.length} event(s) to activate.');
        for (event in songEventsToActivate)
        {
          SongEventParser.handleEvent(event);
        }
      }
    }

    if (!isInCutscene)
      keyShit(true);
  }

  function applyClipRect(daNote:Note):Void
  {
    // clipRect is applied to graphic itself so use frame Heights
    var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
    var strumLineMid = playerStrumline.y + Note.swagWidth / 2;

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
    // Girlfriend gets sad if you combo break after hitting 5 notes.
    if (currentStage != null && currentStage.getGirlfriend() != null)
      if (Highscore.tallies.combo > 5 && currentStage.getGirlfriend().hasAnimation('sad'))
        currentStage.getGirlfriend().playAnimation('sad');

    if (Highscore.tallies.combo != 0)
    {
      Highscore.tallies.combo = comboPopUps.displayCombo(0);
    }
  }

  #if debug
  /**
   * Jumps forward or backward a number of sections in the song.
   * Accounts for BPM changes, does not prevent death from skipped notes.
   * @param sec 
   */
  function changeSection(sec:Int):Void
  {
    FlxG.sound.music.pause();

    var daBPM:Float = currentSong.bpm;
    var daPos:Float = 0;
    for (i in 0...(Std.int(Conductor.currentStep / 16 + sec)))
    {
      var section = SongLoad.getSong()[i];
      if (section == null)
        continue;
      if (section.changeBPM)
      {
        daBPM = SongLoad.getSong()[i].bpm;
      }
      daPos += 4 * (1000 * 60 / daBPM);
    }
    Conductor.songPosition = FlxG.sound.music.time = daPos;
    Conductor.songPosition += Conductor.offset;
    resyncVocals();
  }
  #end

  function endSong():Void
  {
    dispatchEvent(new ScriptEvent(ScriptEvent.SONG_END));

    seenCutscene = false;
    deathCounter = 0;
    mayPauseGame = false;
    FlxG.sound.music.volume = 0;
    vocals.volume = 0;
    if (currentSong != null && currentSong.validScore)
    {
      // crackhead double thingie, sets whether was new highscore, AND saves the song!
      Highscore.tallies.isNewHighscore = Highscore.saveScore(currentSong.song, songScore, storyDifficulty);

      Highscore.saveCompletion(currentSong.song, Highscore.tallies.totalNotesHit / Highscore.tallies.totalNotes, storyDifficulty);
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
      trace('WENT TO RESULTS SCREEN!');
      // unloadAssets();

      camZooming = false;

      FlxG.camera.follow(PlayState.instance.currentStage.getGirlfriend(), null, 0.05);
      FlxG.camera.targetOffset.y -= 350;
      FlxG.camera.targetOffset.x += 20;

      FlxTween.tween(camHUD, {alpha: 0}, 0.6);

      new FlxTimer().start(0.8, _ ->
      {
        currentStage.getGirlfriend().animation.play("cheer");

        FlxTween.tween(FlxG.camera, {zoom: 1200}, 1.1, {
          ease: FlxEase.expoIn,
          onComplete: _ ->
          {
            persistentUpdate = false;
            vocals.stop();
            camHUD.alpha = 1;
            var res:ResultState = new ResultState();
            res.camera = camHUD;
            openSubState(res);
          }
        });
      });
      // FlxG.switchState(new FreeplayState());
    }
  }

  // gives score and pops up rating
  private function popUpScore(strumtime:Float, daNote:Note):Void
  {
    var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
    // boyfriend.playAnimation('hey');
    vocals.volume = 1;

    var isSick:Bool = false;
    var score = Scoring.scoreNote(noteDiff, PBOT1);
    var daRating = Scoring.judgeNote(noteDiff, PBOT1);
    var healthMulti:Float = daNote.lowStakes ? 0.002 : 0.033;

    if (noteDiff > Note.HIT_WINDOW * Note.BAD_THRESHOLD)
    {
      healthMulti *= 0; // no health on shit note
      daRating = 'shit';
      Highscore.tallies.shit += 1;
      score = 50;
    }
    else if (noteDiff > Note.HIT_WINDOW * Note.GOOD_THRESHOLD)
    {
      healthMulti *= 0.2;
      daRating = 'bad';
      Highscore.tallies.bad += 1;
    }
    else if (noteDiff > Note.HIT_WINDOW * Note.SICK_THRESHOLD)
    {
      healthMulti *= 0.78;
      daRating = 'good';
      Highscore.tallies.good += 1;
      score = 200;
    }
    else
    {
      isSick = true;
    }

    health += healthMulti;
    if (isSick)
    {
      Highscore.tallies.sick += 1;
      var noteSplash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
      noteSplash.setupNoteSplash(daNote.x, daNote.y, daNote.data.noteData);
      // new NoteSplash(daNote.x, daNote.y, daNote.noteData);
      grpNoteSplashes.add(noteSplash);
    }
    // Only add the score if you're not on practice mode
    if (!isPracticeMode)
      songScore += score;
    comboPopUps.displayRating(daRating);
    if (Highscore.tallies.combo >= 10 || Highscore.tallies.combo == 0)
      comboPopUps.displayCombo(Highscore.tallies.combo);
  }

  /*
    function controlCamera()
    {
      if (currentStage == null)
        return;

      switch (cameraFocusCharacter)
      {
        default: // null = No change
          break;
        case 0: // Boyfriend
          var isFocusedOnBF = cameraFollowPoint.x == currentStage.getBoyfriend().cameraFocusPoint.x;
          if (!isFocusedOnBF)
          {
            // Focus the camera on the player.
            cameraFollowPoint.setPosition(currentStage.getBoyfriend().cameraFocusPoint.x, currentStage.getBoyfriend().cameraFocusPoint.y);
          }
        case 1: // Dad
          var isFocusedOnDad = cameraFollowPoint.x == currentStage.getDad().cameraFocusPoint.x;
          if (!isFocusedOnDad)
          {
            cameraFollowPoint.setPosition(currentStage.getDad().cameraFocusPoint.x, currentStage.getDad().cameraFocusPoint.y);
          }
        case 2: // Girlfriend
          var isFocusedOnGF = cameraFollowPoint.x == currentStage.getGirlfriend().cameraFocusPoint.x;
          if (!isFocusedOnGF)
          {
            cameraFollowPoint.setPosition(currentStage.getGirlfriend().cameraFocusPoint.x, currentStage.getGirlfriend().cameraFocusPoint.y);
          }
      }

      /*
        if (cameraRightSide && !isFocusedOnBF)
        {
          // Focus the camera on the player.
          cameraFollowPoint.setPosition(currentStage.getBoyfriend().cameraFocusPoint.x, currentStage.getBoyfriend().cameraFocusPoint.y);

          // TODO: Un-hardcode this.
          if (currentSong.song.toLowerCase() == 'tutorial')
            FlxTween.tween(FlxG.camera, {zoom: 1 * FlxCamera.defaultZoom}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
        }
        else if (!cameraRightSide && !isFocusedOnDad)
        {
          // Focus the camera on the opponent.
          cameraFollowPoint.setPosition(currentStage.getDad().cameraFocusPoint.x, currentStage.getDad().cameraFocusPoint.y);

          // TODO: Un-hardcode this stuff.
          if (currentStage.getDad().characterId == 'mom')
          {
            vocals.volume = 1;
          }

          if (currentSong.song.toLowerCase() == 'tutorial')
            tweenCamIn();
        }
   */
  // }

  public function keyShit(test:Bool):Void
  {
    if (PlayState.instance == null)
      return;

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
    if (holdArray.contains(true) && PlayState.instance.generatedMusic)
    {
      PlayState.instance.activeNotes.forEachAlive(function(daNote:Note)
      {
        if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.data.noteData])
          PlayState.instance.goodNoteHit(daNote);
      });
    }

    // PRESSES, check for note hits
    if (pressArray.contains(true) && PlayState.instance.generatedMusic)
    {
      Haptic.vibrate(100, 100);

      PlayState.instance.currentStage.getBoyfriend().holdTimer = 0;

      var possibleNotes:Array<Note> = []; // notes that can be hit
      var directionList:Array<Int> = []; // directions that can be hit
      var dumbNotes:Array<Note> = []; // notes to kill later

      PlayState.instance.activeNotes.forEachAlive(function(daNote:Note)
      {
        if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
        {
          if (directionList.contains(daNote.data.noteData))
          {
            for (coolNote in possibleNotes)
            {
              if (coolNote.data.noteData == daNote.data.noteData && Math.abs(daNote.data.strumTime - coolNote.data.strumTime) < 10)
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
        PlayState.instance.activeNotes.remove(note, true);
        note.destroy();
      }

      possibleNotes.sort((a, b) -> Std.int(a.data.strumTime - b.data.strumTime));

      if (PlayState.instance.perfectMode)
        PlayState.instance.goodNoteHit(possibleNotes[0]);
      else if (possibleNotes.length > 0)
      {
        for (shit in 0...pressArray.length)
        { // if a direction is hit that shouldn't be
          if (pressArray[shit] && !directionList.contains(shit))
            PlayState.instance.ghostNoteMiss(shit);
        }
        for (coolNote in possibleNotes)
        {
          if (pressArray[coolNote.data.noteData])
            PlayState.instance.goodNoteHit(coolNote);
        }
      }
      else
      {
        // HNGGG I really want to add an option for ghost tapping
        // L + ratio
        for (shit in 0...pressArray.length)
          if (pressArray[shit])
            PlayState.instance.ghostNoteMiss(shit, false);
      }
    }

    if (PlayState.instance == null || PlayState.instance.currentStage == null)
      return;

    for (keyId => isPressed in pressArray)
    {
      if (playerStrumline == null)
        continue;
      var arrow:StrumlineArrow = PlayState.instance.playerStrumline.getArrow(keyId);

      if (isPressed && arrow.animation.curAnim.name != 'confirm')
      {
        arrow.playAnimation('pressed');
      }
      if (!holdArray[keyId])
      {
        arrow.playAnimation('static');
      }
    }
  }

  /**
   * Called when a player presses a key with no note present.
   * Scripts can modify the amount of health/score lost, whether player animations or sounds are used,
   * or even cancel the event entirely.
   * 
   * @param direction 
   * @param hasPossibleNotes 
   */
  function ghostNoteMiss(direction:funkin.noteStuff.NoteBasic.NoteType = 1, hasPossibleNotes:Bool = true):Void
  {
    var event:GhostMissNoteScriptEvent = new GhostMissNoteScriptEvent(direction, // Direction missed in.
      hasPossibleNotes, // Whether there was a note you could have hit.
      - 0.035 * 2, // How much health to add (negative).
      - 10 // Amount of score to add (negative).
    );
    dispatchEvent(event);

    // Calling event.cancelEvent() skips animations and penalties. Neat!
    if (event.eventCanceled)
      return;

    health += event.healthChange;

    if (!isPracticeMode)
      songScore += event.scoreChange;

    if (event.playSound)
    {
      vocals.volume = 0;
      FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
    }
  }

  function noteMiss(note:Note):Void
  {
    // a MISS is when you let a note scroll past you!!
    Highscore.tallies.missed++;

    var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_MISS, note, Highscore.tallies.combo, true);
    dispatchEvent(event);
    // Calling event.cancelEvent() skips all the other logic! Neat!
    if (event.eventCanceled)
      return;

    health -= 0.0775;
    if (!isPracticeMode)
      songScore -= 10;
    vocals.volume = 0;

    if (Highscore.tallies.combo != 0)
    {
      Highscore.tallies.combo = comboPopUps.displayCombo(0);
    }

    note.active = false;
    note.visible = false;

    note.kill();
    activeNotes.remove(note, true);
    note.destroy();
  }

  function goodNoteHit(note:Note):Void
  {
    if (!note.wasGoodHit)
    {
      var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_HIT, note, Highscore.tallies.combo + 1, true);
      dispatchEvent(event);

      // Calling event.cancelEvent() skips all the other logic! Neat!
      if (event.eventCanceled)
        return;

      if (!note.isSustainNote)
      {
        Highscore.tallies.combo++;
        Highscore.tallies.totalNotesHit++;

        if (Highscore.tallies.combo > Highscore.tallies.maxCombo)
          Highscore.tallies.maxCombo = Highscore.tallies.combo;

        popUpScore(note.data.strumTime, note);
      }

      playerStrumline.getArrow(note.data.noteData).playAnimation('confirm', true);

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

  override function stepHit():Bool
  {
    if (SongLoad.songData == null)
      return false;

    // super.stepHit() returns false if a module cancelled the event.
    if (!super.stepHit())
      return false;

    if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
      || Math.abs(vocals.checkSyncError(Conductor.songPosition - Conductor.offset)) > 20)
    {
      resyncVocals();
    }

    if (iconP1 != null)
      iconP1.onStepHit(Std.int(Conductor.currentStep));
    if (iconP2 != null)
      iconP2.onStepHit(Std.int(Conductor.currentStep));

    return true;
  }

  override function beatHit():Bool
  {
    // super.beatHit() returns false if a module cancelled the event.
    if (!super.beatHit())
      return false;

    if (generatedMusic)
    {
      // TODO: Sort more efficiently, or less often, to improve performance.
      activeNotes.sort(SortUtil.byStrumtime, FlxSort.DESCENDING);
    }

    // Moving this code into the `beatHit` function allows for scripts and modules to control the camera better.
    if (currentSong != null)
    {
      if (generatedMusic && SongLoad.getSong()[Std.int(Conductor.currentStep / 16)] != null)
      {
        // cameraRightSide = SongLoad.getSong()[Std.int(Conductor.currentStep / 16)].mustHitSection;
      }

      if (SongLoad.getSong()[Math.floor(Conductor.currentStep / 16)] != null)
      {
        if (SongLoad.getSong()[Math.floor(Conductor.currentStep / 16)].changeBPM)
        {
          Conductor.forceBPM(SongLoad.getSong()[Math.floor(Conductor.currentStep / 16)].bpm);
          FlxG.log.add('CHANGED BPM!');
        }
      }
    }

    // Manage the camera focus, if necessary.
    // controlCamera();

    // HARDCODING FOR MILF ZOOMS!

    if (PreferencesMenu.getPref('camera-zoom'))
    {
      if (currentSong != null
        && currentSong.song.toLowerCase() == 'milf'
        && Conductor.currentBeat >= 168
        && Conductor.currentBeat < 200
        && camZooming
        && FlxG.camera.zoom < 1.35)
      {
        FlxG.camera.zoom += 0.015 * FlxCamera.defaultZoom;
        camHUD.zoom += 0.03;
      }

      if (camZooming && FlxG.camera.zoom < (1.35 * FlxCamera.defaultZoom) && Conductor.currentBeat % 4 == 0)
      {
        FlxG.camera.zoom += 0.015 * FlxCamera.defaultZoom;
        camHUD.zoom += 0.03;
      }
    }

    // That combo counter that got spoiled that one time.
    // Comes with NEAT visual and audio effects.

    // bruh this var is bonkers i thot it was a function lmfaooo

    // Break up into individual lines to aid debugging.

    var shouldShowComboText:Bool = false;
    if (currentSong != null)
    {
      shouldShowComboText = (Conductor.currentBeat % 8 == 7);
      var daSection = SongLoad.getSong()[Std.int(Conductor.currentBeat / 16)];
      shouldShowComboText = shouldShowComboText && (daSection != null && daSection.mustHitSection);
      shouldShowComboText = shouldShowComboText && (Highscore.tallies.combo > 5);

      var daNextSection = SongLoad.getSong()[Std.int(Conductor.currentBeat / 16) + 1];
      var isEndOfSong = SongLoad.getSong().length < Std.int(Conductor.currentBeat / 16);
      shouldShowComboText = shouldShowComboText && (isEndOfSong || (daNextSection != null && !daNextSection.mustHitSection));
    }

    if (shouldShowComboText)
    {
      var animShit:ComboCounter = new ComboCounter(-100, 300, Highscore.tallies.combo);
      animShit.scrollFactor.set(0.6, 0.6);
      animShit.cameras = [camHUD];
      add(animShit);

      var frameShit:Float = (1 / 24) * 2; // equals 2 frames in the animation

      new FlxTimer().start(((Conductor.crochet / 1000) * 1.25) - frameShit, function(tmr)
      {
        animShit.forceFinish();
      });
    }

    // Make the characters dance on the beat
    danceOnBeat();

    return true;
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

    // TODO: Move this to a song event.
    if (Conductor.currentBeat % 16 == 15 // && currentSong.song == 'Tutorial'
      && currentStage.getDad().characterId == 'gf'
      && Conductor.currentBeat > 16
      && Conductor.currentBeat < 48)
    {
      currentStage.getBoyfriend().playAnimation('hey', true);
      currentStage.getDad().playAnimation('cheer', true);
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
    playerStrumline.x = 50 + FlxG.width / 2;
    playerStrumline.y = strumlineYPos;
    // Set the z-index so they don't appear in front of notes.
    playerStrumline.zIndex = 100;
    add(playerStrumline);
    playerStrumline.cameras = [camHUD];

    if (!isStoryMode)
    {
      playerStrumline.fadeInArrows();
    }

    enemyStrumline = new Strumline(1, strumlineStyle, 4);
    enemyStrumline.x = 50;
    enemyStrumline.y = strumlineYPos;
    // Set the z-index so they don't appear in front of notes.
    enemyStrumline.zIndex = 100;
    add(enemyStrumline);
    enemyStrumline.cameras = [camHUD];

    if (!isStoryMode)
    {
      enemyStrumline.fadeInArrows();
    }

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
      var event:ScriptEvent = new ScriptEvent(ScriptEvent.RESUME, true);

      dispatchEvent(event);

      if (event.eventCanceled)
        return;

      if (FlxG.sound.music != null && !startingSong && !isInCutscene)
        resyncVocals();

      // Resume the countdown.
      Countdown.resumeCountdown();

      #if discord_rpc
      if (startTimer.finished)
        DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
      else
        DiscordClient.changePresence(detailsText, currentSong.song + " (" + storyDifficultyText + ")", iconRPC);
      #end
    }

    super.closeSubState();
  }

  /**
   * Prepares to start the countdown.
   * Ends any running cutscenes, creates the strumlines, and starts the countdown.
   */
  function startCountdown():Void
  {
    var result = Countdown.performCountdown(currentStageId.startsWith('school'));
    if (!result)
      return;

    isInCutscene = false;
    camHUD.visible = true;
    talking = false;

    buildStrumlines();
  }

  override function dispatchEvent(event:ScriptEvent):Void
  {
    // ORDER: Module, Stage, Character, Song, Note
    // Modules should get the first chance to cancel the event.

    // super.dispatchEvent(event) dispatches event to module scripts.
    super.dispatchEvent(event);

    // Dispatch event to stage script.
    ScriptEventDispatcher.callEvent(currentStage, event);

    // Dispatch event to character script(s).
    if (currentStage != null)
      currentStage.dispatchToCharacters(event);

    // TODO: Dispatch event to song script
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
  public function resetCamera():Void
  {
    FlxG.camera.follow(cameraFollowPoint, LOCKON, 0.04);
    FlxG.camera.targetOffset.set();
    FlxG.camera.zoom = defaultCameraZoom;
    FlxG.camera.focusOn(cameraFollowPoint.getPosition());
  }

  /**
   * Perform necessary cleanup before leaving the PlayState.
   */
  function performCleanup()
  {
    // Uncache the song.
    if (currentChart != null) {}
    else if (currentSong != null)
    {
      openfl.utils.Assets.cache.clear(Paths.inst(currentSong.song));
      openfl.utils.Assets.cache.clear(Paths.voices(currentSong.song));
    }

    // Remove reference to stage and remove sprites from it to save memory.
    if (currentStage != null)
    {
      remove(currentStage);
      currentStage.kill();
      dispatchEvent(new ScriptEvent(ScriptEvent.DESTROY, false));
      currentStage = null;
    }

    GameOverSubstate.reset();

    // Clear the static reference to this state.
    instance = null;
  }

  /**
   * This function is called whenever Flixel switches switching to a new FlxState.
   * @return Whether to actually switch to the new state.
   */
  override function switchTo(nextState:FlxState):Bool
  {
    var result = super.switchTo(nextState);

    if (result)
    {
      performCleanup();
    }

    return result;
  }
}
