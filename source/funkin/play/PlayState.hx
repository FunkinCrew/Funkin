package funkin.play;

import funkin.ui.story.StoryMenuState;
import flixel.addons.display.FlxPieDial;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
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
import funkin.audio.VoicesGroup;
import funkin.Highscore.Tallies;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.Note;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.cutscene.VanillaCutscenes;
import funkin.play.cutscene.VideoCutscene;
import funkin.play.event.SongEventData.SongEventParser;
import funkin.play.scoring.Scoring;
import funkin.play.song.Song;
import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongData.SongPlayableChar;
import funkin.play.song.SongValidator;
import funkin.play.stage.Stage;
import funkin.play.stage.StageData.StageDataParser;
import funkin.play.Strumline.StrumlineArrow;
import funkin.play.Strumline.StrumlineStyle;
import funkin.ui.PopUpStuff;
import funkin.ui.PreferencesMenu;
import funkin.ui.stageBuildShit.StageOffsetSubState;
import funkin.util.Constants;
import funkin.util.SerializerUtil;
import funkin.util.SortUtil;
import lime.ui.Haptic;
#if discord_rpc
import Discord.DiscordClient;
#end

/**
 * Parameters used to initialize the PlayState.
 */
typedef PlayStateParams =
{
  /**
   * The song to play.
   */
  targetSong:Song,

  /**
   * The difficulty to play the song on.
   * @default `Constants.DEFAULT_DIFFICULTY`
   */
  ?targetDifficulty:String,
  /**
   * The character to play as.
   * @default `bf`, or the first character in the song's character list.
   */
  ?targetCharacter:String,
}

/**
 * The gameplay state, where all the rhythm gaming happens.
 */
class PlayState extends MusicBeatState
{
  /**
   * STATIC VARIABLES
   * Static variables should be used for information that must be persisted between states or between resets,
   * such as the active song or song playlist.
   */
  /**
   * The currently active PlayState.
   * There should be only one PlayState in existance at a time, we can use a singleton.
   */
  public static var instance:PlayState = null;

  /**
   * PUBLIC INSTANCE VARIABLES
   * Public instance variables should be used for information that must be reset or dereferenced
   * every time the state is changed, but may need to be accessed externally.
   */
  /**
   * The currently selected stage.
   */
  public var currentSong:Song = null;

  /**
   * The currently selected difficulty.
   */
  public var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;

  /**
   * The player character being used for this level, as a character ID.
   */
  public var currentPlayerId:String = 'bf';

  /**
   * The currently active Stage. This is the object containing all the props.
   */
  public var currentStage:Stage = null;

  /**
   * Data for the current difficulty for the current song.
   * Includes chart data, scroll speed, and other information.
   */
  public var currentChart(get, null):SongDifficulty;

  /**
   * The internal ID of the currently active Stage.
   * Used to retrieve the data required to build the `currentStage`.
   */
  public var currentStageId(get, null):String;

  /**
   * Gets set to true when the PlayState needs to reset (player opted to restart or died).
   * Gets disabled once resetting happens.
   */
  public var needsReset:Bool = false;

  /**
   * The current 'Blueball Counter' to display in the pause menu.
   * Resets when you beat a song or go back to the main menu.
   */
  public var deathCounter:Int = 0;

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
   * The camera follow point from the last stage.
   * Used to persist the position of the `cameraFollowPosition` between levels.
   */
  public var previousCameraFollowPoint:FlxSprite = null;

  /**
   * The current camera zoom level.
   *
   * The camera zoom is increased every beat, and lerped back to this value every frame, creating a smooth 'zoom-in' effect.
   * Defaults to 1.05 but may be larger or smaller depending on the current stage,
   * and may be changed by the `ZoomCamera` song event.
   */
  public var defaultCameraZoom:Float = FlxCamera.defaultZoom * 1.05;

  /**
   * The current HUD camera zoom level.
   *
   * The camera zoom is increased every beat, and lerped back to this value every frame, creating a smooth 'zoom-in' effect.
   */
  public var defaultHUDCameraZoom:Float = FlxCamera.defaultZoom * 1.0;

  /**
   * Intensity of the gameplay camera zoom.
   * @default `1.5%`
   */
  public var cameraZoomIntensity:Float = Constants.DEFAULT_ZOOM_INTENSITY;

  /**
   * Intensity of the HUD camera zoom.
   * @default `3.0%`
   */
  public var hudCameraZoomIntensity:Float = Constants.DEFAULT_ZOOM_INTENSITY * 2.0;

  /**
   * How many beats (quarter notes) between camera zooms.
   * @default One camera zoom per measure (four beats).
   */
  public var cameraZoomRate:Int = Constants.DEFAULT_ZOOM_RATE;

  /**
   * Whether the game is currently in the countdown before the song resumes.
   */
  public var isInCountdown:Bool = false;

  /**
   * Whether the game is currently in Practice Mode.
   * If true, player will not lose gain or lose score from notes.
   */
  public var isPracticeMode:Bool = false;

  /**
   * Whether the game is currently in an animated cutscene, and gameplay should be stopped.
   */
  public var isInCutscene:Bool = false;

  /**
   * Whether the inputs should be disabled for whatever reason... used for the stage edit lol!
   */
  public var disableKeys:Bool = false;

  /**
   * PRIVATE INSTANCE VARIABLES
   * Private instance variables should be used for information that must be reset or dereferenced
   * every time the state is reset, but should not be accessed externally.
   */
  /**
   * The Array containing the notes that are not currently on the screen.
   * The `update()` function regularly shifts these out to add new notes to the screen.
   */
  var inactiveNotes:Array<Note>;

  /**
   * The Array containing the upcoming song events.
   * The `update()` function regularly shifts these out to trigger events.
   */
  var songEvents:Array<SongEventData>;

  /**
   * If true, the player is allowed to pause the game.
   * Disabled during the ending of a song.
   */
  var mayPauseGame:Bool = true;

  /**
   * The displayed value of the player's health.
   * Used to provide smooth animations based on linear interpolation of the player's health.
   */
  var healthLerp:Float = 1;

  /**
   * How long the user has held the "Skip Video Cutscene" button for.
   */
  var skipHeldTimer:Float = 0;

  /**
   * Forcibly disables all update logic while the game moves back to the Menu state.
   * This is used only when a critical error occurs and the game absolutely cannot continue.
   */
  var criticalFailure:Bool = false;

  /**
   * False as long as the countdown has not finished yet.
   */
  var startingSong:Bool = false;

  /**
   * A group of audio tracks, used to play the song's vocals.
   */
  var vocals:VoicesGroup;

  /**
   * RENDER OBJECTS
   */
  /**
   * The SpriteGroup containing the notes that are currently on the screen or are about to be on the screen.
   */
  var activeNotes:FlxTypedGroup<Note> = null;

  /**
   * The FlxText which displays the current score.
   */
  var scoreText:FlxText;

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
   * The camera which contains, and controls visibility of, a video cutscene.
   */
  public var camCutscene:FlxCamera;

  var skipTimer:FlxPieDial;

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
  var isGamePaused(get, never):Bool;

  function get_isGamePaused():Bool
  {
    // Note: If there is a substate which requires the game to act unpaused,
    //       this should be changed to include something like `&& Std.isOfType()`
    return this.subState != null;
  }

  var gfSpeed:Int = 1;
  var generatedMusic:Bool = false;

  var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
  var comboPopUps:PopUpStuff;
  var perfectMode:Bool = false;
  var previousFrameTime:Int = 0;
  var songTime:Float = 0;

  #if discord_rpc
  // Discord RPC variables
  var storyDifficultyText:String = '';
  var iconRPC:String = '';
  var songLength:Float = 0;
  var detailsText:String = '';
  var detailsPausedText:String = '';
  #end

  /**
   * This sucks. We need this because FlxG.resetState(); assumes the constructor has no arguments.
   * @see https://github.com/HaxeFlixel/flixel/issues/2541
   */
  static var lastParams:PlayStateParams = null;

  public function new(params:PlayStateParams)
  {
    super();

    if (params == null && lastParams == null)
    {
      throw 'PlayState constructor called with no available parameters.';
    }
    else if (params == null)
    {
      trace('WARNING: PlayState constructor called with no parameters. Reusing previous parameters.');
      params = lastParams;
    }
    else
    {
      lastParams = params;
    }

    currentSong = params.targetSong;
    if (params.targetDifficulty != null) currentDifficulty = params.targetDifficulty;
    if (params.targetCharacter != null) currentPlayerId = params.targetCharacter;
  }

  public override function create():Void
  {
    super.create();

    if (instance != null)
    {
      trace('WARNING: PlayState instance already exists. This should not happen.');
    }
    instance = this;

    if (currentSong != null)
    {
      // TODO: Do this in the loading state.
      currentSong.cacheCharts(true);
    }

    // Returns null if the song failed to load or doesn't have the selected difficulty.
    if (currentChart == null)
    {
      criticalFailure = true;

      var message:String = 'There was a critical error. Click OK to return to the main menu.';

      if (currentSong == null)
      {
        message = 'The was a critical error loading this song\'s chart. Click OK to return to the main menu.';
      }
      else if (currentDifficulty == null)
      {
        message = 'The was a critical error selecting a difficulty for this song. Click OK to return to the main menu.';
      }
      else if (currentSong.getDifficulty(currentDifficulty) == null)
      {
        message = 'The was a critical error retrieving data for this song on "$currentDifficulty" difficulty. Click OK to return to the main menu.';
      }

      lime.app.Application.current.window.alert(message, 'Error loading PlayState');
      FlxG.switchState(new MainMenuState());
      return;
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
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // Prepare the current song to be played.
    if (currentChart != null)
    {
      currentChart.cacheInst();
      currentChart.cacheVocals(currentPlayerId);
    }

    // Initialize stage stuff.
    initCameras();

    Conductor.mapTimeChanges(currentChart.timeChanges);

    Conductor.update(-5000);

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

    buildStrumlines();

    grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

    var noteSplash:NoteSplash = new NoteSplash(100, 100, 0);
    grpNoteSplashes.add(noteSplash);
    noteSplash.alpha = 0.1;

    add(grpNoteSplashes);

    generateSong();

    resetCamera();

    FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

    scoreText = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, '', 20);
    scoreText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreText.scrollFactor.set();
    add(scoreText);

    // Skip Video Cutscene
    skipTimer = new FlxPieDial(16, 16, 32, FlxColor.WHITE, 36, CIRCLE, true, 24);
    skipTimer.amount = 0;
    skipTimer.zIndex = 1000;
    // Renders only in video cutscene mode.
    skipTimer.cameras = [camCutscene];
    add(skipTimer);

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

    // Starting song!
    startingSong = true;

    // TODO: Softcode cutscenes.
    // TODO: Alternatively: make a song script that allows startCountdown to be called,
    // then cancels the countdown, hides the UI, plays the cutscene,
    // then calls PlayState.startCountdown later?
    if (currentSong != null)
    {
      switch (currentSong.songId.toLowerCase())
      {
        case 'winter-horrorland':
          VanillaCutscenes.playHorrorStartCutscene();
        // This one is softcoded now WOOOO!
        // case 'senpai' | 'roses' | 'thorns':
        //   schoolIntro(doof);
        // case 'ugh':
        // VanillaCutscenes.playUghCutscene();
        // case 'stress':
        // VanillaCutscenes.playStressCutscene();
        // case 'guns':
        // VanillaCutscenes.playGunsCutscene();
        default:
          // VanillaCutscenes will call startCountdown later.
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

    #if debug
    FlxG.console.registerObject('playState', this);
    #end
  }

  function get_currentChart():SongDifficulty
  {
    if (currentSong == null || currentDifficulty == null) return null;
    return currentSong.getDifficulty(currentDifficulty);
  }

  function get_currentStageId():String
  {
    if (currentChart == null || currentChart.stage == null || currentChart.stage == '') return Constants.DEFAULT_STAGE;
    return currentChart.stage;
  }

  /**
   * Initializes the game and HUD cameras.
   */
  function initCameras():Void
  {
    // Set the camera zoom. This gets overridden by the value in the stage data.
    // defaultCameraZoom = FlxCamera.defaultZoom * 1.05;

    camGame = new SwagCamera();
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0;
    camCutscene = new FlxCamera();
    camCutscene.bgColor.alpha = 0;

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.add(camCutscene, false);
  }

  function initStage():Void
  {
    if (currentSong != null)
    {
      if (currentChart == null)
      {
        trace('Song difficulty could not be loaded.');
      }

      loadStage(currentStageId);
    }
    else
    {
      // Fallback.
      loadStage('mainStage');
    }
  }

  function initCharacters():Void
  {
    if (currentSong == null || currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    // TODO: Switch playable character by manipulating this value.
    // TODO: How to choose which one to use for story mode?

    var playableChars:Array<String> = currentChart.getPlayableChars();

    if (playableChars.length == 0)
    {
      trace('WARNING: No playable characters found for this song.');
    }
    else if (playableChars.indexOf(currentPlayerId) == -1)
    {
      currentPlayerId = playableChars[0];
    }

    var currentCharData:SongPlayableChar = currentChart.getPlayableChar(currentPlayerId);

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

    //
    // OPPONENT HEALTH ICON
    //
    iconP2 = new HealthIcon(currentCharData.opponent, 1);
    iconP2.y = healthBar.y - (iconP2.height / 2);
    dad.initHealthIcon(true);
    add(iconP2);

    //
    // BOYFRIEND
    //
    var boyfriend:BaseCharacter = CharacterDataParser.fetchCharacter(currentPlayerId);

    if (boyfriend != null)
    {
      boyfriend.characterType = CharacterType.BF;
    }

    //
    // PLAYER HEALTH ICON
    //
    iconP1 = new HealthIcon(currentPlayerId, 0);
    iconP1.y = healthBar.y - (iconP1.height / 2);
    boyfriend.initHealthIcon(false);
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

        #if debug
        FlxG.console.registerObject('gf', girlfriend);
        #end
      }

      if (boyfriend != null)
      {
        currentStage.addCharacter(boyfriend, BF);

        #if debug
        FlxG.console.registerObject('bf', boyfriend);
        #end
      }

      if (dad != null)
      {
        currentStage.addCharacter(dad, DAD);
        // Camera starts at dad.
        cameraFollowPoint.setPosition(dad.cameraFocusPoint.x, dad.cameraFocusPoint.y);

        #if debug
        FlxG.console.registerObject('dad', dad);
        #end
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
  override function debug_refreshModules():Void
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

    // Stop the vocals.
    if (vocals != null)
    {
      vocals.stop();
    }

    super.debug_refreshModules();

    var event:ScriptEvent = new ScriptEvent(ScriptEvent.CREATE, false);
    ScriptEventDispatcher.callEvent(currentSong, event);
  }

  /**
   * Pauses music and vocals easily.
   */
  public function pauseMusic():Void
  {
    FlxG.sound.music.pause();
    vocals.pause();
  }

  /**
   * Loads stage data from cache, assembles the props,
   * and adds it to the state.
   * @param id
   */
  function loadStage(id:String):Void
  {
    currentStage = StageDataParser.fetchStage(id);

    if (currentStage != null)
    {
      // Actually create and position the sprites.
      var event:ScriptEvent = new ScriptEvent(ScriptEvent.CREATE, false);
      ScriptEventDispatcher.callEvent(currentStage, event);

      // Apply camera zoom level from stage data.
      defaultCameraZoom = currentStage.camZoom;

      // Add the stage to the scene.
      this.add(currentStage);

      #if debug
      FlxG.console.registerObject('stage', currentStage);
      #end
    }
    else
    {
      // lolol
      lime.app.Application.current.window.alert('Nice job, you ignoramus. $id isn\'t a real stage.\nI\'m falling back to the default so the game doesn\'t shit itself.',
        'Stage Error');
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
    detailsText = isStoryMode ? 'Story Mode: Week $storyWeek' : 'Freeplay';
    detailsPausedText = 'Paused - $detailsText';

    // Updating Discord Rich Presence.
    DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC);
    #end
  }

  function startSong():Void
  {
    dispatchEvent(new ScriptEvent(ScriptEvent.SONG_START));

    startingSong = false;

    previousFrameTime = FlxG.game.ticks;

    if (!isGamePaused && currentChart != null)
    {
      currentChart.playInst(1.0, false);
    }

    FlxG.sound.music.onComplete = endSong;
    trace('Playing vocals...');
    vocals.play();

    #if discord_rpc
    // Song duration in a float, useful for the time left feature
    songLength = FlxG.sound.music.length;

    // Updating Discord Rich Presence (with Time Left)
    DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC, true, songLength);
    #end
  }

  function generateSong():Void
  {
    if (currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    Conductor.forceBPM(currentChart.getStartingBPM());

    vocals = currentChart.buildVocals(currentPlayerId);
    if (vocals.members.length == 0)
    {
      trace('WARNING: No vocals found for this song.');
    }

    // Create the rendered note group.
    activeNotes = new FlxTypedGroup<Note>();
    activeNotes.zIndex = 1000;
    add(activeNotes);

    regenNoteData();

    generatedMusic = true;
  }

  function regenNoteData():Void
  {
    Highscore.tallies.combo = 0;
    Highscore.tallies = new Tallies();

    // Reset song events.
    songEvents = currentChart.getEvents();
    SongEventParser.resetEvents(songEvents);

    // Destroy inactive notes.
    inactiveNotes = [];

    // Destroy active notes.
    activeNotes.forEach(function(nt) {
      nt.followsTime = false;
      FlxTween.tween(nt, {y: FlxG.height + nt.y}, 0.5,
        {
          ease: FlxEase.expoIn,
          onComplete: function(twn) {
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
        newNote.alignToSturmlineArrow(playerStrumline.getArrow(songNote.getDirection()));
      }
      else
      {
        newNote.alignToSturmlineArrow(enemyStrumline.getArrow(songNote.getDirection()));
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
          // Align with the strumline arrow.
          sustainNote.alignToSturmlineArrow(playerStrumline.getArrow(songNote.getDirection()));
        }
        else
        {
          sustainNote.alignToSturmlineArrow(enemyStrumline.getArrow(songNote.getDirection()));
        }

        inactiveNotes.push(sustainNote);

        oldNote = sustainNote;
      }
    }

    // Sorting is an expensive operation.
    // TODO: Make this more efficient.
    // DO NOT assume it was done in the chart file. Notes created artificially by sustains are in here too.
    inactiveNotes.sort(function(a:Note, b:Note):Int {
      return SortUtil.byStrumtime(FlxSort.ASCENDING, a, b);
    });
    /**
    **/
  }

  #if discord_rpc
  override public function onFocus():Void
  {
    if (health > 0 && !paused && FlxG.autoPause)
    {
      if (Conductor.songPosition > 0.0) DiscordClient.changePresence(detailsText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC, true,
        songLength - Conductor.songPosition);
      else
        DiscordClient.changePresence(detailsText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
    }

    super.onFocus();
  }

  override public function onFocusLost():Void
  {
    if (health > 0 && !paused && FlxG.autoPause) DiscordClient.changePresence(detailsPausedText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);

    super.onFocusLost();
  }
  #end

  function resyncVocals():Void
  {
    if (_exiting || vocals == null) return;

    vocals.pause();

    FlxG.sound.music.play();
    Conductor.update();

    vocals.time = FlxG.sound.music.time;
    vocals.play();
  }

  public override function update(elapsed:Float):Void
  {
    if (criticalFailure) return;

    super.update(elapsed);

    if (FlxG.keys.justPressed.U)
    {
      // hack for HaxeUI generation, doesn't work unless persistentUpdate is false at state creation!!
      disableKeys = true;
      persistentUpdate = false;
      openSubState(new StageOffsetSubState());
    }

    updateHealthBar();
    updateScoreText();

    // Handle restarting the song when needed (player death or pressing Retry)
    if (needsReset)
    {
      dispatchEvent(new ScriptEvent(ScriptEvent.SONG_RETRY));

      resetCamera();

      persistentUpdate = true;
      persistentDraw = true;

      startingSong = true;

      inputSpitter = [];

      // Reset music properly.

      FlxG.sound.music.pause();
      vocals.pause();
      FlxG.sound.music.time = 0;
      vocals.time = 0;

      FlxG.sound.music.volume = 1;
      vocals.volume = 1;
      vocals.playerVolume = 1;
      vocals.opponentVolume = 1;

      currentStage.resetStage();

      // Delete all notes and reset the arrays.
      regenNoteData();

      // Reset camera zooming
      cameraZoomIntensity = Constants.DEFAULT_ZOOM_INTENSITY;
      hudCameraZoomIntensity = Constants.DEFAULT_ZOOM_INTENSITY * 2.0;
      cameraZoomRate = Constants.DEFAULT_ZOOM_RATE;

      health = 1;
      songScore = 0;
      Highscore.tallies.combo = 0;
      Countdown.performCountdown(currentStageId.startsWith('school'));

      needsReset = false;
    }

    // Update the conductor.
    if (startingSong)
    {
      if (isInCountdown)
      {
        Conductor.songPosition += elapsed * 1000;
        if (Conductor.songPosition >= 0) startSong();
      }
    }
    else
    {
      // DO NOT FORGET TO REMOVE THE HARDCODE! WHEN I MAKE BETTER OFFSET SYSTEM!

      // :nerd: um ackshually it's not 13 it's 11.97278911564
      if (Paths.SOUND_EXT == 'mp3') Conductor.offset = Constants.MP3_DELAY_MS;

      Conductor.update();

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

    // Attempt to pause the game.
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
          FlxG.switchState(new GitarooPause(
            {
              targetSong: currentSong,
              targetDifficulty: currentDifficulty,
              targetCharacter: currentPlayerId,
            }));
        }
        else
        {
          var boyfriendPos:FlxPoint = new FlxPoint(0, 0);

          // Prevent the game from crashing if Boyfriend isn't present.
          if (currentStage != null && currentStage.getBoyfriend() != null)
          {
            boyfriendPos = currentStage.getBoyfriend().getScreenPosition();
          }

          var pauseSubState:FlxSubState = new PauseSubState();

          openSubState(pauseSubState);
          pauseSubState.camera = camHUD;
          // boyfriendPos.put(); // TODO: Why is this here?
        }

        #if discord_rpc
        DiscordClient.changePresence(detailsPausedText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
        #end
      }
    }

    // Cap health.
    if (health > 2.0) health = 2.0;
    if (health < 0.0) health = 0.0;

    // Lerp the camera zoom towards the target level.
    if (subState == null)
    {
      FlxG.camera.zoom = FlxMath.lerp(defaultCameraZoom, FlxG.camera.zoom, 0.95);
      camHUD.zoom = FlxMath.lerp(defaultHUDCameraZoom, camHUD.zoom, 0.95);
    }

    FlxG.watch.addQuick('beatShit', Conductor.currentBeat);
    FlxG.watch.addQuick('stepShit', Conductor.currentStep);
    if (currentStage != null)
    {
      FlxG.watch.addQuick('bfAnim', currentStage.getBoyfriend().getCurrentAnimation());
    }
    FlxG.watch.addQuick('songPos', Conductor.songPosition);

    // Handle GF dance speed.
    // TODO: Add a song event for this.
    if (currentSong.songId == 'fresh')
    {
      switch (Conductor.currentBeat)
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
    }

    // Handle player death.
    if (!isInCutscene && !disableKeys && !_exiting)
    {
      // RESET = Quick Game Over Screen
      if (controls.RESET)
      {
        health = 0;
        trace('RESET = True');
      }

      #if CAN_CHEAT // brandon's a pussy
      if (controls.CHEAT)
      {
        health += 1;
        trace('User is cheating!');
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

        var gameOverSubState = new GameOverSubState();
        openSubState(gameOverSubState);

        #if discord_rpc
        // Game Over doesn't get his own variable because it's only used here
        DiscordClient.changePresence('Game Over - ' + detailsText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
        #end
      }
    }

    // Iterate over inactive notes.
    while (inactiveNotes[0] != null && inactiveNotes[0].data.strumTime - Conductor.songPosition < 1800 / currentChart.scrollSpeed)
    {
      var dunceNote:Note = inactiveNotes[0];

      if (dunceNote.mustPress && !dunceNote.isSustainNote) Highscore.tallies.totalNotes++;

      activeNotes.add(dunceNote);

      inactiveNotes.shift();
    }

    // Iterate over active notes.
    if (generatedMusic && playerStrumline != null)
    {
      activeNotes.forEachAlive(function(daNote:Note) {
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

        var strumLineMid:Float = playerStrumline.y + Note.swagWidth / 2;

        if (daNote.followsTime)
        {
          daNote.y = (Conductor.songPosition - daNote.data.strumTime) * (0.45 * FlxMath.roundDecimal(currentChart.scrollSpeed, 2) * daNote.noteSpeedMulti);
        }

        if (PreferencesMenu.getPref('downscroll'))
        {
          daNote.y += playerStrumline.y;
          if (daNote.isSustainNote)
          {
            if (daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
            {
              daNote.y += daNote.prevNote.height;
            }
            else
            {
              daNote.y += daNote.height / 2;
            }

            if ((!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
              && daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= strumLineMid)
            {
              applyClipRect(daNote);
            }
          }
        }
        else
        {
          if (daNote.followsTime) daNote.y = playerStrumline.y - daNote.y;
          if (daNote.isSustainNote
            && (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))
            && daNote.y + daNote.offset.y * daNote.scale.y <= strumLineMid)
          {
            applyClipRect(daNote);
          }
        }

        if (!daNote.mustPress && daNote.wasGoodHit && !daNote.tooLate)
        {
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
        }

        // WIP interpolation shit? Need to fix the pause issue
        // daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * SONG.speed[.curDiff]));

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

    // Query and activate song events.
    if (songEvents != null && songEvents.length > 0)
    {
      var songEventsToActivate:Array<SongEventData> = SongEventParser.queryEvents(songEvents, Conductor.songPosition);

      if (songEventsToActivate.length > 0)
      {
        trace('Found ${songEventsToActivate.length} event(s) to activate.');
        for (event in songEventsToActivate)
        {
          var eventEvent:SongEventScriptEvent = new SongEventScriptEvent(event);
          dispatchEvent(eventEvent);
          // Calling event.cancelEvent() skips the event. Neat!
          if (!eventEvent.eventCanceled)
          {
            SongEventParser.handleEvent(event);
          }
        }
      }
    }

    // Handle keybinds.
    if (!isInCutscene && !disableKeys) keyShit(true);
    if (!isInCutscene && !disableKeys) debugKeyShit();

    // Dispatch the onUpdate event to scripted elements.
    dispatchEvent(new UpdateScriptEvent(elapsed));
  }

  static final CUTSCENE_KEYS:Array<FlxKey> = [SPACE, ESCAPE, ENTER];

  public function trySkipVideoCutscene(elapsed:Float):Void
  {
    if (skipTimer == null || skipTimer.animation == null) return;

    if (elapsed < 0)
    {
      skipHeldTimer = 0.0;
    }
    else
    {
      skipHeldTimer += elapsed;
    }

    skipTimer.visible = skipHeldTimer >= 0.05;
    skipTimer.amount = Math.min(skipHeldTimer / 1.5, 1.0);

    if (skipHeldTimer >= 1.5)
    {
      VideoCutscene.finishVideo();
    }
  }

  function applyClipRect(daNote:Note):Void
  {
    // clipRect is applied to graphic itself so use frame Heights
    var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
    var strumLineMid:Float = playerStrumline.y + Note.swagWidth / 2;

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
    {
      if (Highscore.tallies.combo > 5 && currentStage.getGirlfriend().hasAnimation('sad'))
      {
        currentStage.getGirlfriend().playAnimation('sad');
      }
    }

    if (Highscore.tallies.combo != 0)
    {
      Highscore.tallies.combo = comboPopUps.displayCombo(0);
    }
  }

  #if debug
  /**
   * Jumps forward or backward a number of sections in the song.
   * Accounts for BPM changes, does not prevent death from skipped notes.
   * @param sections The number of sections to jump, negative to go backwards.
   */
  function changeSection(sections:Int):Void
  {
    FlxG.sound.music.pause();

    FlxG.sound.music.time += sections * Conductor.measureLengthMs;

    Conductor.update(FlxG.sound.music.time);

    /**
      *
      // TODO: Redo this for the new conductor.
      var daBPM:Float = Conductor.bpm;
      var daPos:Float = 0;
      for (i in 0...(Std.int(Conductor.currentStep / 16 + sec)))
      {
        var section = .getSong()[i];
        if (section == null) continue;
        if (section.changeBPM)
        {
          daBPM = .getSong()[i].bpm;
        }
        daPos += 4 * (1000 * 60 / daBPM);
      }
      Conductor.songPosition = FlxG.sound.music.time = daPos;
      Conductor.songPosition += Conductor.offset;

     */

    resyncVocals();
  }
  #end

  function endSong():Void
  {
    dispatchEvent(new ScriptEvent(ScriptEvent.SONG_END));

    #if sys
    // spitter for ravy, teehee!!

    var output = SerializerUtil.toJSON(inputSpitter);
    sys.io.File.saveContent("./scores.json", output);
    #end

    deathCounter = 0;
    mayPauseGame = false;
    FlxG.sound.music.volume = 0;
    vocals.volume = 0;
    if (currentSong != null && currentSong.validScore)
    {
      // crackhead double thingie, sets whether was new highscore, AND saves the song!
      Highscore.tallies.isNewHighscore = Highscore.saveScoreForDifficulty(currentSong.songId, songScore, currentDifficulty);

      Highscore.saveCompletionForDifficulty(currentSong.songId, Highscore.tallies.totalNotesHit / Highscore.tallies.totalNotes, currentDifficulty);
    }

    if (PlayStatePlaylist.isStoryMode)
    {
      PlayStatePlaylist.campaignScore += songScore;

      // Pop the next song ID from the list.
      // Returns null if the list is empty.
      var targetSongId:String = PlayStatePlaylist.playlistSongIds.shift();

      if (targetSongId == null)
      {
        FlxG.sound.playMusic(Paths.music('freakyMenu'));

        transIn = FlxTransitionableState.defaultTransIn;
        transOut = FlxTransitionableState.defaultTransOut;

        // TODO: Rework week unlock logic.
        // StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

        if (currentSong.validScore)
        {
          NGio.unlockMedal(60961);
          Highscore.saveWeekScoreForDifficulty(PlayStatePlaylist.campaignId, PlayStatePlaylist.campaignScore, currentDifficulty);
        }

        // FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
        FlxG.save.flush();

        moveToResultsScreen();
      }
      else
      {
        var difficulty:String = '';

        trace('Loading next song ($targetSongId : $difficulty)');

        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;

        FlxG.sound.music.stop();
        vocals.stop();

        // TODO: Softcode this cutscene.
        if (currentSong.songId == 'eggnog')
        {
          var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
            -FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
          blackShit.scrollFactor.set();
          add(blackShit);
          camHUD.visible = false;
          isInCutscene = true;

          FlxG.sound.play(Paths.sound('Lights_Shut_off'), function() {
            // no camFollow so it centers on horror tree
            var targetSong:Song = SongDataParser.fetchSong(targetSongId);

            var nextPlayState:PlayState = new PlayState(
              {
                targetSong: targetSong,
                targetDifficulty: currentDifficulty,
                targetCharacter: currentPlayerId,
              });
            nextPlayState.previousCameraFollowPoint = new FlxSprite(cameraFollowPoint.x, cameraFollowPoint.y);
            LoadingState.loadAndSwitchState(nextPlayState);
          });
        }
        else
        {
          var targetSong:Song = SongDataParser.fetchSong(targetSongId);
          var nextPlayState:PlayState = new PlayState(
            {
              targetSong: targetSong,
              targetDifficulty: currentDifficulty,
              targetCharacter: currentPlayerId,
            });
          nextPlayState.previousCameraFollowPoint = new FlxSprite(cameraFollowPoint.x, cameraFollowPoint.y);
          LoadingState.loadAndSwitchState(nextPlayState);
        }
      }
    }
    else
    {
      moveToResultsScreen();
    }
  }

  /**
   * Play the camera zoom animation and move to the results screen.
   */
  function moveToResultsScreen():Void
  {
    trace('WENT TO RESULTS SCREEN!');

    // Stop camera zooming on beat.
    cameraZoomRate = 0;

    // If the opponent is GF, zoom in on the opponent.
    // Else, if there is no GF, zoom in on BF.
    // Else, zoom in on GF.
    var targetDad:Bool = PlayState.instance.currentStage.getDad() != null && PlayState.instance.currentStage.getDad().characterId == 'gf';
    var targetBF:Bool = PlayState.instance.currentStage.getGirlfriend() == null && !targetDad;

    if (targetBF)
    {
      FlxG.camera.follow(PlayState.instance.currentStage.getBoyfriend(), null, 0.05);
      FlxG.camera.targetOffset.y -= 350;
      FlxG.camera.targetOffset.x += 20;
    }
    else if (targetDad)
    {
      FlxG.camera.follow(PlayState.instance.currentStage.getDad(), null, 0.05);
      FlxG.camera.targetOffset.y -= 350;
      FlxG.camera.targetOffset.x += 20;
    }
    else
    {
      FlxG.camera.follow(PlayState.instance.currentStage.getGirlfriend(), null, 0.05);
      FlxG.camera.targetOffset.y -= 350;
      FlxG.camera.targetOffset.x += 20;
    }

    FlxTween.tween(camHUD, {alpha: 0}, 0.6);

    // Zoom in on Girlfriend (or BF if no GF)
    new FlxTimer().start(0.8, function(_) {
      if (targetBF)
      {
        currentStage.getBoyfriend().animation.play('hey');
      }
      else if (targetDad)
      {
        currentStage.getDad().animation.play('cheer');
      }
      else
      {
        currentStage.getGirlfriend().animation.play('cheer');
      }

      // Zoom over to the Results screen.
      FlxTween.tween(FlxG.camera, {zoom: 1200}, 1.1,
        {
          ease: FlxEase.expoIn,
          onComplete: function(_) {
            persistentUpdate = false;
            vocals.stop();
            camHUD.alpha = 1;
            var res:ResultState = new ResultState();
            res.camera = camHUD;
            openSubState(res);
          }
        });
    });
  }

  // gives score and pops up rating
  function popUpScore(strumtime:Float, daNote:Note):Void
  {
    var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
    // boyfriend.playAnimation('hey');
    vocals.playerVolume = 1;

    var isSick:Bool = false;
    var score = Scoring.scoreNote(noteDiff, PBOT1);
    var daRating = Scoring.judgeNote(noteDiff, PBOT1);
    var healthMulti:Float = daNote.lowStakes ? 0.002 : 0.033;

    if (noteDiff > Note.HIT_WINDOW * Note.BAD_THRESHOLD)
    {
      healthMulti *= 0; // no health on shit note
      daRating = 'shit';
      Highscore.tallies.shit += 1;
      // score = 50;
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
      // score = 200;
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
    {
      songScore += score;

      var pressArray:Array<Bool> = [
        controls.NOTE_LEFT_P,
        controls.NOTE_DOWN_P,
        controls.NOTE_UP_P,
        controls.NOTE_RIGHT_P
      ];

      var indices:Array<Int> = [];
      for (i in 0...pressArray.length)
      {
        if (pressArray[i]) indices.push(i);
      }
      if (indices.length > 0)
      {
        for (i in 0...indices.length)
        {
          inputSpitter.push(
            {
              t: Std.int(Conductor.songPosition),
              d: indices[i],
              l: 20
            });
        }
      }
      else
      {
        inputSpitter.push(
          {
            t: Std.int(Conductor.songPosition),
            d: -1,
            l: 20
          });
      }
    }
    comboPopUps.displayRating(daRating);
    if (Highscore.tallies.combo >= 10 || Highscore.tallies.combo == 0) comboPopUps.displayCombo(Highscore.tallies.combo);
  }

  /**
   * Spitting out the input for ravy 🙇‍♂️!!
   */
  var inputSpitter:Array<ScoreInput> = [];

  public function keyShit(test:Bool):Void
  {
    if (PlayState.instance == null) return;

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

    // if (pressArray.contains(true))
    // {
    //   var lol:Array<Int> = cast pressArray;
    //   inputSpitter.push(Std.int(Conductor.songPosition) + ' ' + lol.join(' '));
    // }

    // HOLDS, check for sustain notes
    if (holdArray.contains(true) && PlayState.instance.generatedMusic)
    {
      PlayState.instance.activeNotes.forEachAlive(function(daNote:Note) {
        if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.data.noteData]) PlayState.instance.goodNoteHit(daNote);
      });
    }

    // PRESSES, check for note hits
    if (pressArray.contains(true) && PlayState.instance.generatedMusic)
    {
      Haptic.vibrate(100, 100);

      if (currentStage != null && currentStage.getBoyfriend() != null)
      {
        currentStage.getBoyfriend().holdTimer = 0;
      }

      var possibleNotes:Array<Note> = []; // notes that can be hit
      var directionList:Array<Int> = []; // directions that can be hit
      var dumbNotes:Array<Note> = []; // notes to kill later

      PlayState.instance.activeNotes.forEachAlive(function(daNote:Note) {
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
        FlxG.log.add('killing dumb ass note at ' + note.data.strumTime);
        note.kill();
        PlayState.instance.activeNotes.remove(note, true);
        note.destroy();
      }

      possibleNotes.sort((a, b) -> Std.int(a.data.strumTime - b.data.strumTime));

      if (PlayState.instance.perfectMode) PlayState.instance.goodNoteHit(possibleNotes[0]);
      else if (possibleNotes.length > 0)
      {
        for (shit in 0...pressArray.length)
        { // if a direction is hit that shouldn't be
          if (pressArray[shit] && !directionList.contains(shit)) PlayState.instance.ghostNoteMiss(shit);
        }
        for (coolNote in possibleNotes)
        {
          if (pressArray[coolNote.data.noteData]) PlayState.instance.goodNoteHit(coolNote);
        }
      }
      else
      {
        // HNGGG I really want to add an option for ghost tapping
        // L + ratio
        for (shit in 0...pressArray.length)
          if (pressArray[shit]) PlayState.instance.ghostNoteMiss(shit, false);
      }
    }

    if (PlayState.instance == null || PlayState.instance.currentStage == null) return;

    for (keyId => isPressed in pressArray)
    {
      if (playerStrumline == null) continue;
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
   * Debug keys. Disabled while in cutscenes.
   */
  public function debugKeyShit():Void
  {
    #if !debug
    perfectMode = false;
    #else
    if (FlxG.keys.justPressed.H) camHUD.visible = !camHUD.visible;
    #end

    if (FlxG.keys.justPressed.F4) FlxG.switchState(new MainMenuState());

    if (FlxG.keys.justPressed.F5) debug_refreshModules();

    // Press U to open stage ditor.
    if (FlxG.keys.justPressed.U)
    {
      // hack for HaxeUI generation, doesn't work unless persistentUpdate is false at state creation!!
      disableKeys = true;
      persistentUpdate = false;
      openSubState(new StageOffsetSubState());
    }

    #if debug
    // 1: End the song immediately.
    if (FlxG.keys.justPressed.ONE) endSong();

    // 2: Gain 10% health.
    if (FlxG.keys.justPressed.TWO) health += 0.1 * 2.0;

    // 3: Lose 5% health.
    if (FlxG.keys.justPressed.THREE) health -= 0.05 * 2.0;
    #end

    // 7: Move to the charter.
    if (FlxG.keys.justPressed.SEVEN)
    {
      lime.app.Application.current.window.alert("Press ~ on the main menu to get to the editor", 'LOL');
    }

    // 8: Move to the offset editor.
    if (FlxG.keys.justPressed.EIGHT) FlxG.switchState(new funkin.ui.animDebugShit.DebugBoundingState());

    // 9: Toggle the old icon.
    if (FlxG.keys.justPressed.NINE) iconP1.toggleOldIcon();

    #if debug
    // PAGEUP: Skip forward one section.
    // SHIFT+PAGEUP: Skip forward ten sections.
    if (FlxG.keys.justPressed.PAGEUP) changeSection(FlxG.keys.pressed.SHIFT ? 10 : 1);
    // PAGEDOWN: Skip backward one section. Doesn't replace notes.
    // SHIFT+PAGEDOWN: Skip backward ten sections.
    if (FlxG.keys.justPressed.PAGEDOWN) changeSection(FlxG.keys.pressed.SHIFT ? -10 : -1);
    #end

    if (FlxG.keys.justPressed.B) trace(inputSpitter.join('\n'));
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
    if (event.eventCanceled) return;

    health += event.healthChange;

    if (!isPracticeMode)
    {
      songScore += event.scoreChange;

      var pressArray:Array<Bool> = [
        controls.NOTE_LEFT_P,
        controls.NOTE_DOWN_P,
        controls.NOTE_UP_P,
        controls.NOTE_RIGHT_P
      ];

      var indices:Array<Int> = [];
      for (i in 0...pressArray.length)
      {
        if (pressArray[i]) indices.push(i);
      }
      for (i in 0...indices.length)
      {
        inputSpitter.push(
          {
            t: Std.int(Conductor.songPosition),
            d: indices[i],
            l: 20
          });
      }
    }

    if (event.playSound)
    {
      vocals.playerVolume = 0;
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
    if (event.eventCanceled) return;

    health -= 0.0775;

    if (!isPracticeMode)
    {
      songScore -= 10;

      // messy copy paste rn lol
      var pressArray:Array<Bool> = [
        controls.NOTE_LEFT_P,
        controls.NOTE_DOWN_P,
        controls.NOTE_UP_P,
        controls.NOTE_RIGHT_P
      ];

      var indices:Array<Int> = [];
      for (i in 0...pressArray.length)
      {
        if (pressArray[i]) indices.push(i);
      }
      if (indices.length > 0)
      {
        for (i in 0...indices.length)
        {
          inputSpitter.push(
            {
              t: Std.int(Conductor.songPosition),
              d: indices[i],
              l: 20
            });
        }
      }
      else
      {
        inputSpitter.push(
          {
            t: Std.int(Conductor.songPosition),
            d: -1,
            l: 20
          });
      }
    }
    vocals.playerVolume = 0;

    if (Highscore.tallies.combo != 0)
    {
      Highscore.tallies.combo = comboPopUps.displayCombo(0);
    }

    if (event.playSound)
    {
      vocals.playerVolume = 0;
      FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
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
      if (event.eventCanceled) return;

      if (!note.isSustainNote)
      {
        Highscore.tallies.combo++;
        Highscore.tallies.totalNotesHit++;

        if (Highscore.tallies.combo > Highscore.tallies.maxCombo) Highscore.tallies.maxCombo = Highscore.tallies.combo;

        popUpScore(note.data.strumTime, note);
      }

      playerStrumline.getArrow(note.data.noteData).playAnimation('confirm', true);

      note.wasGoodHit = true;
      vocals.playerVolume = 1;

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
    // super.stepHit() returns false if a module cancelled the event.
    if (!super.stepHit()) return false;

    if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 200
      || Math.abs(vocals.checkSyncError(Conductor.songPosition - Conductor.offset)) > 200)
    {
      trace("VOCALS NEED RESYNC");
      if (vocals != null) trace(vocals.checkSyncError(Conductor.songPosition - Conductor.offset));
      trace(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset));
      resyncVocals();
    }

    if (iconP1 != null) iconP1.onStepHit(Std.int(Conductor.currentStep));
    if (iconP2 != null) iconP2.onStepHit(Std.int(Conductor.currentStep));

    return true;
  }

  override function beatHit():Bool
  {
    // super.beatHit() returns false if a module cancelled the event.
    if (!super.beatHit()) return false;

    if (generatedMusic)
    {
      // TODO: Sort more efficiently, or less often, to improve performance.
      activeNotes.sort(SortUtil.byStrumtime, FlxSort.DESCENDING);
    }

    // Only zoom camera if we are zoomed by less than 35%.
    if (FlxG.camera.zoom < (1.35 * defaultCameraZoom) && cameraZoomRate > 0 && Conductor.currentBeat % cameraZoomRate == 0)
    {
      // Zoom camera in (1.5%)
      FlxG.camera.zoom += cameraZoomIntensity * defaultCameraZoom;
      // Hud zooms double (3%)
      camHUD.zoom += hudCameraZoomIntensity * defaultHUDCameraZoom;
    }
    // trace('Not bopping camera: ${FlxG.camera.zoom} < ${(1.35 * defaultCameraZoom)} && ${cameraZoomRate} > 0 && ${Conductor.currentBeat} % ${cameraZoomRate} == ${Conductor.currentBeat % cameraZoomRate}}');

    // That combo milestones that got spoiled that one time.
    // Comes with NEAT visual and audio effects.

    // bruh this var is bonkers i thot it was a function lmfaooo

    // Break up into individual lines to aid debugging.

    var shouldShowComboText:Bool = false;
    // TODO: Re-enable combo text (how to do this without sections?).
    // if (currentSong != null)
    // {
    //  shouldShowComboText = (Conductor.currentBeat % 8 == 7);
    //  var daSection = .getSong()[Std.int(Conductor.currentBeat / 16)];
    //  shouldShowComboText = shouldShowComboText && (daSection != null && daSection.mustHitSection);
    //  shouldShowComboText = shouldShowComboText && (Highscore.tallies.combo > 5);
    //
    //  var daNextSection = .getSong()[Std.int(Conductor.currentBeat / 16) + 1];
    //  var isEndOfSong = .getSong().length < Std.int(Conductor.currentBeat / 16);
    //  shouldShowComboText = shouldShowComboText && (isEndOfSong || (daNextSection != null && !daNextSection.mustHitSection));
    // }

    if (shouldShowComboText)
    {
      var animShit:ComboCounter = new ComboCounter(-100, 300, Highscore.tallies.combo);
      animShit.scrollFactor.set(0.6, 0.6);
      animShit.cameras = [camHUD];
      add(animShit);

      var frameShit:Float = (1 / 24) * 2; // equals 2 frames in the animation

      new FlxTimer().start(((Conductor.crochet / 1000) * 1.25) - frameShit, function(tmr) {
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
  public function danceOnBeat():Void
  {
    if (currentStage == null) return;

    // TODO: Add HEY! song events to Tutorial.
    if (Conductor.currentBeat % 16 == 15
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

    if (!PlayStatePlaylist.isStoryMode)
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

    if (!PlayStatePlaylist.isStoryMode)
    {
      enemyStrumline.fadeInArrows();
    }

    this.refresh();
  }

  /**
   * Function called before opening a new substate.
   * @param subState The substate to open.
   */
  public override function openSubState(subState:FlxSubState):Void
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
        if (vocals != null) vocals.pause();
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
  public override function closeSubState():Void
  {
    if (isGamePaused)
    {
      var event:ScriptEvent = new ScriptEvent(ScriptEvent.RESUME, true);

      dispatchEvent(event);

      if (event.eventCanceled) return;

      if (FlxG.sound.music != null && !startingSong && !isInCutscene) resyncVocals();

      // Resume the countdown.
      Countdown.resumeCountdown();

      #if discord_rpc
      if (startTimer.finished)
      {
        DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC, true, songLength - Conductor.songPosition);
      }
      else
      {
        DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC);
      }
      #end
    }

    super.closeSubState();
  }

  /**
   * Prepares to start the countdown.
   * Ends any running cutscenes, creates the strumlines, and starts the countdown.
   */
  public function startCountdown():Void
  {
    // If Countdown.performCountdown returns false, then the countdown was canceled by a script.
    var result:Bool = Countdown.performCountdown(currentStageId.startsWith('school'));
    if (!result) return;

    isInCutscene = false;
    camCutscene.visible = false;
    camHUD.visible = true;
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
    if (currentStage != null) currentStage.dispatchToCharacters(event);

    ScriptEventDispatcher.callEvent(currentSong, event);

    // TODO: Dispatch event to note scripts
  }

  /**
   * Updates the position and contents of the score display.
   */
  function updateScoreText():Void
  {
    // TODO: Add functionality for modules to update the score text.
    scoreText.text = 'Score:' + songScore;
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
  function performCleanup():Void
  {
    if (currentChart != null)
    {
      // TODO: Uncache the song.
    }

    // Remove reference to stage and remove sprites from it to save memory.
    if (currentStage != null)
    {
      remove(currentStage);
      currentStage.kill();
      dispatchEvent(new ScriptEvent(ScriptEvent.DESTROY, false));
      currentStage = null;
    }

    GameOverSubState.reset();

    // Clear the static reference to this state.
    instance = null;
  }

  /**
   * This function is called whenever Flixel switches switching to a new FlxState.
   * @return Whether to actually switch to the new state.
   */
  override function switchTo(nextState:FlxState):Bool
  {
    var result:Bool = super.switchTo(nextState);

    if (result)
    {
      performCleanup();
    }

    return result;
  }
}
