package funkin.play;

import flixel.addons.display.FlxPieDial;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.Transition;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxStringUtil;
import funkin.api.newgrounds.NGio;
import funkin.audio.FunkinSound;
import funkin.audio.VoicesGroup;
import funkin.data.dialogue.conversation.ConversationRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.notestyle.NoteStyleData;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.Highscore.Tallies;
import funkin.input.PreciseInputManager;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.components.ComboMilestone;
import funkin.play.components.HealthIcon;
import funkin.play.components.PopUpStuff;
import funkin.play.cutscene.dialogue.Conversation;
import funkin.play.cutscene.VanillaCutscenes;
import funkin.play.cutscene.VideoCutscene;
import funkin.play.notes.NoteDirection;
import funkin.play.notes.NoteSplash;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.Strumline;
import funkin.play.notes.SustainTrail;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.play.scoring.Scoring;
import funkin.play.song.Song;
import funkin.play.stage.Stage;
import funkin.save.Save;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.stage.StageOffsetSubState;
import funkin.ui.mainmenu.MainMenuState;
import funkin.ui.MusicBeatSubState;
import funkin.ui.options.PreferencesMenu;
import funkin.ui.story.StoryMenuState;
import funkin.ui.transition.LoadingState;
import funkin.util.SerializerUtil;
import haxe.Int64;
import lime.ui.Haptic;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.Lib;
#if FEATURE_DISCORD_RPC
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
   * The variation to play on.
   * @default `Constants.DEFAULT_VARIATION`
   */
  ?targetVariation:String,
  /**
   * The instrumental to play with.
   * Significant if the `targetSong` supports alternate instrumentals.
   * @default `null`
   */
  ?targetInstrumental:String,
  /**
   * Whether the song should start in Practice Mode.
   * @default `false`
   */
  ?practiceMode:Bool,
  /**
   * Whether the song should start in Bot Play Mode.
   * @default `false`
   */
  ?botPlayMode:Bool,
  /**
   * Whether the song should be in minimal mode.
   * @default `false`
   */
  ?minimalMode:Bool,
  /**
   * If specified, the game will jump to the specified timestamp after the countdown ends.
   * @default `0.0`
   */
  ?startTimestamp:Float,
  /**
   * If specified, the game will play the song with the given speed.
   * @default `1.0` for 100% speed.
   */
  ?playbackRate:Float,
  /**
   * If specified, the game will not load the instrumental or vocal tracks,
   * and must be loaded externally.
   */
  ?overrideMusic:Bool,
  /**
   * The initial camera follow point.
   * Used to persist the position of the `cameraFollowPosition` between levels.
   */
  ?cameraFollowPoint:FlxPoint,
}

/**
 * The gameplay state, where all the rhythm gaming happens.
 * SubState so it can be loaded as a child of the chart editor.
 */
class PlayState extends MusicBeatSubState
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
   * This sucks. We need this because FlxG.resetState(); assumes the constructor has no arguments.
   * @see https://github.com/HaxeFlixel/flixel/issues/2541
   */
  static var lastParams:PlayStateParams = null;

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
   * The currently selected variation.
   */
  public var currentVariation:String = Constants.DEFAULT_VARIATION;

  /**
   * The currently selected instrumental ID.
   * @default `''`
   */
  public var currentInstrumental:String = '';

  /**
   * The currently active Stage. This is the object containing all the props.
   */
  public var currentStage:Stage = null;

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
   */
  public var health:Float = Constants.HEALTH_STARTING;

  /**
   * The player's current score.
   * TODO: Move this to its own class.
   */
  public var songScore:Int = 0;

  /**
   * Start at this point in the song once the countdown is done.
   * For example, if `startTimestamp` is `30000`, the song will start at the 30 second mark.
   * Used for chart playtesting or practice.
   */
  public var startTimestamp:Float = 0.0;

  /**
   * Play back the song at this speed.
   * @default `1.0` for normal speed.
   */
  public var playbackRate:Float = 1.0;

  /**
   * An empty FlxObject contained in the scene.
   * The current gameplay camera will always follow this object. Tween its position to move the camera smoothly.
   *
   * It needs to be an object in the scene for the camera to be configured to follow it.
   * We optionally make this a sprite so we can draw a debug graphic with it.
   */
  public var cameraFollowPoint:FlxObject;

  /**
   * An FlxTween that tweens the camera to the follow point.
   * Only used when tweening the camera manually, rather than tweening via follow.
   */
  public var cameraFollowTween:FlxTween;

  /**
   * An FlxTween that zooms the camera to the desired amount.
   */
  public var cameraZoomTween:FlxTween;

  /**
   * An FlxTween that changes the additive speed to the desired amount.
   */
  public var scrollSpeedTweens:Array<FlxTween> = [];

  /**
   * The camera follow point from the last stage.
   * Used to persist the position of the `cameraFollowPosition` between levels.
   */
  public var previousCameraFollowPoint:FlxPoint = null;

  /**
   * The current camera zoom level without any modifiers applied.
   */
  public var currentCameraZoom:Float = FlxCamera.defaultZoom;

  /**
   * Multiplier for currentCameraZoom for camera bops.
   * Lerped back to 1.0x every frame.
   */
  public var cameraBopMultiplier:Float = 1.0;

  /**
   * Default camera zoom for the current stage.
   * If we aren't in a stage, just use the default zoom (1.05x).
   */
  public var stageZoom(get, never):Float;

  function get_stageZoom():Float
  {
    if (currentStage != null) return currentStage.camZoom;
    else
      return FlxCamera.defaultZoom * 1.05;
  }

  /**
   * The current HUD camera zoom level.
   *
   * The camera zoom is increased every beat, and lerped back to this value every frame, creating a smooth 'zoom-in' effect.
   */
  public var defaultHUDCameraZoom:Float = FlxCamera.defaultZoom * 1.0;

  /**
   * Camera bop intensity multiplier.
   * Applied to cameraBopMultiplier on camera bops (usually every beat).
   * @default `101.5%`
   */
  public var cameraBopIntensity:Float = Constants.DEFAULT_BOP_INTENSITY;

  /**
   * Intensity of the HUD camera zoom.
   * Need to make this a multiplier later. Just shoving in 0.015 for now so it doesn't break.
   * @default `3.0%`
   */
  public var hudCameraZoomIntensity:Float = 0.015 * 2.0;

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
   * Whether the game is currently in Bot Play Mode.
   * If true, player will not lose gain or lose score from notes.
   */
  public var isBotPlayMode:Bool = false;

  /**
   * Whether the player has dropped below zero health,
   * and we are just waiting for an animation to play out before transitioning.
   */
  public var isPlayerDying:Bool = false;

  /**
   * In Minimal Mode, the stage and characters are not loaded and a standard background is used.
   */
  public var isMinimalMode:Bool = false;

  /**
   * Whether the game is currently in an animated cutscene, and gameplay should be stopped.
   */
  public var isInCutscene:Bool = false;

  /**
   * Whether the inputs should be disabled for whatever reason... used for the stage edit lol!
   */
  public var disableKeys:Bool = false;

  public var isSubState(get, never):Bool;

  function get_isSubState():Bool
  {
    return this._parentState != null;
  }

  public var isChartingMode(get, never):Bool;

  function get_isChartingMode():Bool
  {
    return this._parentState != null && Std.isOfType(this._parentState, ChartEditorState);
  }

  /**
   * The current dialogue.
   */
  public var currentConversation:Conversation;

  /**
   * Key press inputs which have been received but not yet processed.
   * These are encoded with an OS timestamp, so they
  **/
  var inputPressQueue:Array<PreciseInputEvent> = [];

  /**
   * Key release inputs which have been received but not yet processed.
   * These are encoded with an OS timestamp, so they
  **/
  var inputReleaseQueue:Array<PreciseInputEvent> = [];

  /**
   * If we just unpaused the game, we shouldn't be able to pause again for one frame.
   */
  var justUnpaused:Bool = false;

  /**
   * PRIVATE INSTANCE VARIABLES
   * Private instance variables should be used for information that must be reset or dereferenced
   * every time the state is reset, but should not be accessed externally.
   */
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
  var healthLerp:Float = Constants.HEALTH_STARTING;

  /**
   * How long the user has held the "Skip Video Cutscene" button for.
   */
  var skipHeldTimer:Float = 0;

  /**
   * Whether the PlayState was started with instrumentals and vocals already provided.
   * Used by the chart editor to prevent replacing the music.
   */
  var overrideMusic:Bool = false;

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
   * Track if we currently have the music paused for a Pause substate, so we can unpause it when we return.
   */
  var musicPausedBySubState:Bool = false;

  /**
   * Track any camera tweens we've paused for a Pause substate, so we can unpause them when we return.
   */
  var cameraTweensPausedBySubState:List<FlxTween> = new List<FlxTween>();

  /**
   * False until `create()` has completed.
   */
  var initialized:Bool = false;

  /**
   * A group of audio tracks, used to play the song's vocals.
   */
  public var vocals:VoicesGroup;

  #if FEATURE_DISCORD_RPC
  // Discord RPC variables
  var storyDifficultyText:String = '';
  var iconRPC:String = '';
  var detailsText:String = '';
  var detailsPausedText:String = '';
  #end

  /**
   * RENDER OBJECTS
   */
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
  public var healthBarBG:FunkinSprite;

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
  public var opponentStrumline:Strumline;

  /**
   * The camera which contains, and controls visibility of, the user interface elements.
   */
  public var camHUD:FlxCamera;

  /**
   * The camera which contains, and controls visibility of, the stage and characters.
   */
  public var camGame:FlxCamera;

  /**
   * Simple helper debug variable, to be able to move the camera around for debug purposes
   * without worrying about the camera tweening back to the follow point.
   */
  public var debugUnbindCameraZoom:Bool = false;

  /**
   * The camera which contains, and controls visibility of, a video cutscene, dialogue, pause menu and sticker transition.
   */
  public var camCutscene:FlxCamera;

  /**
   * The combo popups. Includes the real-time combo counter and the rating.
   */
  public var comboPopUps:PopUpStuff;

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

  var isExitingViaPauseMenu(get, never):Bool;

  function get_isExitingViaPauseMenu():Bool
  {
    if (this.subState == null) return false;
    if (!Std.isOfType(this.subState, PauseSubState)) return false;

    var pauseSubState:PauseSubState = cast this.subState;
    return !pauseSubState.allowInput;
  }

  /**
   * Data for the current difficulty for the current song.
   * Includes chart data, scroll speed, and other information.
   */
  public var currentChart(get, never):SongDifficulty;

  function get_currentChart():SongDifficulty
  {
    if (currentSong == null || currentDifficulty == null) return null;
    return currentSong.getDifficulty(currentDifficulty, currentVariation);
  }

  /**
   * The internal ID of the currently active Stage.
   * Used to retrieve the data required to build the `currentStage`.
   */
  public var currentStageId(get, never):String;

  function get_currentStageId():String
  {
    if (currentChart == null || currentChart.stage == null || currentChart.stage == '') return Constants.DEFAULT_STAGE;
    return currentChart.stage;
  }

  /**
   * The length of the current song, in milliseconds.
   */
  var currentSongLengthMs(get, never):Float;

  function get_currentSongLengthMs():Float
  {
    return FlxG?.sound?.music?.length;
  }

  // TODO: Refactor or document
  var generatedMusic:Bool = false;

  var skipEndingTransition:Bool = false;

  static final BACKGROUND_COLOR:FlxColor = FlxColor.BLACK;

  /**
   * Instantiate a new PlayState.
   * @param params The parameters used to initialize the PlayState.
   *   Includes information about what song to play and more.
   */
  public function new(params:PlayStateParams)
  {
    super();

    // Validate parameters.
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

    // Apply parameters.
    currentSong = params.targetSong;
    if (params.targetDifficulty != null) currentDifficulty = params.targetDifficulty;
    if (params.targetVariation != null) currentVariation = params.targetVariation;
    if (params.targetInstrumental != null) currentInstrumental = params.targetInstrumental;
    isPracticeMode = params.practiceMode ?? false;
    isBotPlayMode = params.botPlayMode ?? false;
    isMinimalMode = params.minimalMode ?? false;
    startTimestamp = params.startTimestamp ?? 0.0;
    playbackRate = params.playbackRate ?? 1.0;
    overrideMusic = params.overrideMusic ?? false;
    previousCameraFollowPoint = params.cameraFollowPoint;

    // Don't do anything else here! Wait until create() when we attach to the camera.
  }

  /**
   * Called when the PlayState is switched to.
   */
  public override function create():Void
  {
    if (instance != null)
    {
      // TODO: Do something in this case? IDK.
      trace('WARNING: PlayState instance already exists. This should not happen.');
    }
    instance = this;

    if (!assertChartExists()) return;

    // TODO: Add something to toggle this on!
    if (false)
    {
      // Displays the camera follow point as a sprite for debug purposes.
      var cameraFollowPoint = new FunkinSprite(0, 0);
      cameraFollowPoint.makeSolidColor(8, 8, 0xFF00FF00);
      cameraFollowPoint.visible = false;
      cameraFollowPoint.zIndex = 1000000;
      this.cameraFollowPoint = cameraFollowPoint;
    }
    else
    {
      // Camera follow point is an invisible point in space.
      cameraFollowPoint = new FlxObject(0, 0);
    }

    // Reduce physics accuracy (who cares!!!) to improve animation quality.
    FlxG.fixedTimestep = false;

    // This state receives update() even when a substate is active.
    this.persistentUpdate = true;
    // This state receives draw calls even when a substate is active.
    this.persistentDraw = true;

    // Stop any pre-existing music.
    if (!overrideMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

    // Prepare the current song's instrumental and vocals to be played.
    if (!overrideMusic && currentChart != null)
    {
      currentChart.cacheInst(currentInstrumental);
      currentChart.cacheVocals();
    }

    // Prepare the Conductor.
    Conductor.instance.forceBPM(null);

    if (currentChart.offsets != null)
    {
      Conductor.instance.instrumentalOffset = currentChart.offsets.getInstrumentalOffset(currentInstrumental);
    }

    Conductor.instance.mapTimeChanges(currentChart.timeChanges);
    Conductor.instance.update((Conductor.instance.beatLengthMs * -5) + startTimestamp);

    // The song is now loaded. We can continue to initialize the play state.
    initCameras();
    initHealthBar();
    if (!isMinimalMode)
    {
      initStage();
      initCharacters();
    }
    else
    {
      initMinimalMode();
    }
    initStrumlines();
    initPopups();

    #if FEATURE_DISCORD_RPC
    // Initialize Discord Rich Presence.
    initDiscord();
    #end

    // Read the song's note data and pass it to the strumlines.
    generateSong();

    // Reset the camera's zoom and force it to focus on the camera follow point.
    resetCamera();

    initPreciseInputs();

    FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

    // The song is loaded and in the process of starting.
    // This gets set back to false when the chart actually starts.
    startingSong = true;

    // TODO: We hardcoded the transition into Winter Horrorland. Do this with a ScriptedSong instead.
    if ((currentSong?.id ?? '').toLowerCase() == 'winter-horrorland')
    {
      // VanillaCutscenes will call startCountdown later.
      VanillaCutscenes.playHorrorStartCutscene();
    }
    else
    {
      // Call a script event to start the countdown.
      // Songs with cutscenes should call event.cancel().
      // As long as they call `PlayState.instance.startCountdown()` later, the countdown will start.
      startCountdown();
    }

    // Do this last to prevent beatHit from being called before create() is done.
    super.create();

    leftWatermarkText.cameras = [camHUD];
    rightWatermarkText.cameras = [camHUD];

    // Initialize some debug stuff.
    #if FEATURE_DEBUG_FUNCTIONS
    // Display the version number (and git commit hash) in the bottom right corner.
    this.rightWatermarkText.text = Constants.VERSION;

    FlxG.console.registerObject('playState', this);
    #end

    initialized = true;

    // This step ensures z-indexes are applied properly,
    // and it's important to call it last so all elements get affected.
    refresh();
  }

  public override function draw():Void
  {
    // if (FlxG.renderBlit)
    // {
    //  camGame.fill(BACKGROUND_COLOR);
    // }
    // else if (FlxG.renderTile)
    // {
    //  FlxG.log.warn("PlayState background not displayed properly on tile renderer!");
    // }
    // else
    // {
    //  FlxG.log.warn("PlayState background not displayed properly, unknown renderer!");
    // }

    super.draw();
  }

  function assertChartExists():Bool
  {
    // Returns null if the song failed to load or doesn't have the selected difficulty.
    if (currentSong == null || currentChart == null || currentChart.notes == null)
    {
      // We have encountered a critical error. Prevent Flixel from trying to run any gameplay logic.
      criticalFailure = true;

      // Choose an error message.
      var message:String = 'There was a critical error. Click OK to return to the main menu.';
      if (currentSong == null)
      {
        message = 'There was a critical error loading this song\'s chart. Click OK to return to the main menu.';
      }
      else if (currentDifficulty == null)
      {
        message = 'There was a critical error selecting a difficulty for this song. Click OK to return to the main menu.';
      }
      else if (currentChart == null)
      {
        message = 'There was a critical error retrieving data for this song on "$currentDifficulty" difficulty with variation "$currentVariation". Click OK to return to the main menu.';
      }
      else if (currentChart.notes == null)
      {
        message = 'There was a critical error retrieving note data for this song on "$currentDifficulty" difficulty with variation "$currentVariation". Click OK to return to the main menu.';
      }

      // Display a popup. This blocks the application until the user clicks OK.
      lime.app.Application.current.window.alert(message, 'Error loading PlayState');

      // Force the user back to the main menu.
      if (isSubState)
      {
        this.close();
      }
      else
      {
        FlxG.switchState(() -> new MainMenuState());
      }
      return false;
    }

    return true;
  }

  public override function update(elapsed:Float):Void
  {
    // TOTAL: 9.42% CPU Time when profiled in VS 2019.

    if (criticalFailure) return;

    super.update(elapsed);

    var list = FlxG.sound.list;
    updateHealthBar();
    updateScoreText();

    // Handle restarting the song when needed (player death or pressing Retry)
    if (needsReset)
    {
      if (!assertChartExists()) return;

      prevScrollTargets = [];

      dispatchEvent(new ScriptEvent(SONG_RETRY));

      resetCamera();

      var fromDeathState = isPlayerDying;

      persistentUpdate = true;
      persistentDraw = true;

      startingSong = true;
      isPlayerDying = false;

      inputSpitter = [];

      // Reset music properly.
      if (FlxG.sound.music != null)
      {
        FlxG.sound.music.time = startTimestamp - Conductor.instance.instrumentalOffset;
        FlxG.sound.music.pitch = playbackRate;
        FlxG.sound.music.pause();
      }

      if (!overrideMusic)
      {
        // Stop the vocals if they already exist.
        if (vocals != null) vocals.stop();
        vocals = currentChart.buildVocals(currentInstrumental);

        if (vocals.members.length == 0)
        {
          trace('WARNING: No vocals found for this song.');
        }
      }
      vocals.pause();
      vocals.time = 0;

      if (FlxG.sound.music != null) FlxG.sound.music.volume = 1;
      vocals.volume = 1;
      vocals.playerVolume = 1;
      vocals.opponentVolume = 1;

      if (currentStage != null) currentStage.resetStage();

      if (!fromDeathState)
      {
        playerStrumline.vwooshNotes();
        opponentStrumline.vwooshNotes();
      }

      playerStrumline.clean();
      opponentStrumline.clean();

      // Delete all notes and reset the arrays.
      regenNoteData();

      // Reset camera zooming
      cameraBopIntensity = Constants.DEFAULT_BOP_INTENSITY;
      hudCameraZoomIntensity = (cameraBopIntensity - 1.0) * 2.0;
      cameraZoomRate = Constants.DEFAULT_ZOOM_RATE;

      health = Constants.HEALTH_STARTING;
      songScore = 0;
      Highscore.tallies.combo = 0;
      Countdown.performCountdown();

      needsReset = false;
    }

    // Update the conductor.
    if (startingSong)
    {
      if (isInCountdown)
      {
        // Do NOT apply offsets at this point, because they already got applied the previous frame!
        Conductor.instance.update(Conductor.instance.songPosition + elapsed * 1000, false);
        if (Conductor.instance.songPosition >= (startTimestamp)) startSong();
      }
    }
    else
    {
      if (Constants.EXT_SOUND == 'mp3')
      {
        Conductor.instance.formatOffset = Constants.MP3_DELAY_MS;
      }
      else
      {
        Conductor.instance.formatOffset = 0.0;
      }

      Conductor.instance.update(); // Normal conductor update.
    }

    var androidPause:Bool = false;

    #if android
    androidPause = FlxG.android.justPressed.BACK;
    #end

    // Attempt to pause the game.
    if ((controls.PAUSE || androidPause) && isInCountdown && mayPauseGame && !justUnpaused)
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
        if (!isSubState && event.gitaroo)
        {
          FlxG.switchState(() -> new GitarooPause(
            {
              targetSong: currentSong,
              targetDifficulty: currentDifficulty,
              targetVariation: currentVariation,
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

          var pauseSubState:FlxSubState = new PauseSubState({mode: isChartingMode ? Charting : Standard});

          FlxTransitionableState.skipNextTransIn = true;
          FlxTransitionableState.skipNextTransOut = true;
          pauseSubState.camera = camCutscene;
          openSubState(pauseSubState);
          // boyfriendPos.put(); // TODO: Why is this here?
        }

        #if FEATURE_DISCORD_RPC
        DiscordClient.changePresence(detailsPausedText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
        #end
      }
    }

    // Cap health.
    if (health > Constants.HEALTH_MAX) health = Constants.HEALTH_MAX;
    if (health < Constants.HEALTH_MIN) health = Constants.HEALTH_MIN;

    // Apply camera zoom + multipliers.
    if (subState == null && cameraZoomRate > 0.0) // && !isInCutscene)
    {
      cameraBopMultiplier = FlxMath.lerp(1.0, cameraBopMultiplier, 0.95); // Lerp bop multiplier back to 1.0x
      var zoomPlusBop = currentCameraZoom * cameraBopMultiplier; // Apply camera bop multiplier.
      if (!debugUnbindCameraZoom) FlxG.camera.zoom = zoomPlusBop; // Actually apply the zoom to the camera.

      camHUD.zoom = FlxMath.lerp(defaultHUDCameraZoom, camHUD.zoom, 0.95);
    }

    if (currentStage != null && currentStage.getBoyfriend() != null)
    {
      FlxG.watch.addQuick('bfAnim', currentStage.getBoyfriend().getCurrentAnimation());
    }
    FlxG.watch.addQuick('health', health);
    FlxG.watch.addQuick('cameraBopIntensity', cameraBopIntensity);

    // TODO: Add a song event for Handle GF dance speed.

    // Handle player death.
    if (!isInCutscene && !disableKeys)
    {
      // RESET = Quick Game Over Screen
      if (controls.RESET)
      {
        health = Constants.HEALTH_MIN;
        trace('RESET = True');
      }

      #if CAN_CHEAT // brandon's a pussy
      if (controls.CHEAT)
      {
        health += 0.25 * Constants.HEALTH_MAX; // +25% health.
        trace('User is cheating!');
      }
      #end

      if (health <= Constants.HEALTH_MIN && !isPracticeMode && !isPlayerDying)
      {
        vocals.pause();

        if (FlxG.sound.music != null) FlxG.sound.music.pause();

        deathCounter += 1;

        dispatchEvent(new ScriptEvent(GAME_OVER));

        // Disable updates, preventing animations in the background from playing.
        persistentUpdate = false;
        #if FEATURE_DEBUG_FUNCTIONS
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
        #if FEATURE_DEBUG_FUNCTIONS
        }
        #end

        isPlayerDying = true;

        var deathPreTransitionDelay = currentStage?.getBoyfriend()?.getDeathPreTransitionDelay() ?? 0.0;
        if (deathPreTransitionDelay > 0)
        {
          new FlxTimer().start(deathPreTransitionDelay, function(_) {
            moveToGameOver();
          });
        }
        else
        {
          // Transition immediately.
          moveToGameOver();
        }

        #if FEATURE_DISCORD_RPC
        // Game Over doesn't get his own variable because it's only used here
        DiscordClient.changePresence('Game Over - ' + detailsText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
        #end
      }
      else if (isPlayerDying)
      {
        // Wait up.
      }
    }

    processSongEvents();

    // Handle keybinds.
    processInputQueue();
    if (!isInCutscene && !disableKeys) debugKeyShit();
    if (isInCutscene && !disableKeys) handleCutsceneKeys(elapsed);

    // Moving notes into position is now done by Strumline.update().
    if (!isInCutscene) processNotes(elapsed);

    justUnpaused = false;
  }

  function moveToGameOver():Void
  {
    // Reset and update a bunch of values in advance for the transition back from the game over substate.
    playerStrumline.clean();
    opponentStrumline.clean();

    songScore = 0;
    updateScoreText();

    health = Constants.HEALTH_STARTING;
    healthLerp = health;

    healthBar.value = healthLerp;

    if (!isMinimalMode)
    {
      iconP1.updatePosition();
      iconP2.updatePosition();
    }

    // Transition to the game over substate.
    var gameOverSubState = new GameOverSubState(
      {
        isChartingMode: isChartingMode,
        transparent: persistentDraw
      });
    FlxTransitionableState.skipNextTransIn = true;
    FlxTransitionableState.skipNextTransOut = true;
    openSubState(gameOverSubState);
  }

  function processSongEvents():Void
  {
    // Query and activate song events.
    // TODO: Check that these work appropriately even when songPosition is less than 0, to play events during countdown.
    if (songEvents != null && songEvents.length > 0)
    {
      var songEventsToActivate:Array<SongEventData> = SongEventRegistry.queryEvents(songEvents, Conductor.instance.songPosition);

      if (songEventsToActivate.length > 0)
      {
        trace('Found ${songEventsToActivate.length} event(s) to activate.');
        for (event in songEventsToActivate)
        {
          // If an event is trying to play, but it's over 1 second old, skip it.
          var eventAge:Float = Conductor.instance.songPosition - event.time;
          if (eventAge > 1000)
          {
            event.activated = true;
            continue;
          };

          var eventEvent:SongEventScriptEvent = new SongEventScriptEvent(event);
          dispatchEvent(eventEvent);
          // Calling event.cancelEvent() skips the event. Neat!
          if (!eventEvent.eventCanceled)
          {
            SongEventRegistry.handleEvent(event);
          }
        }
      }
    }
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    // ORDER: Module, Stage, Character, Song, Conversation, Note
    // Modules should get the first chance to cancel the event.

    // super.dispatchEvent(event) dispatches event to module scripts.
    super.dispatchEvent(event);

    // Dispatch event to note kind scripts
    NoteKindManager.callEvent(event);

    // Dispatch event to stage script.
    ScriptEventDispatcher.callEvent(currentStage, event);

    // Dispatch event to character script(s).
    if (currentStage != null) currentStage.dispatchToCharacters(event);

    // Dispatch event to song script.
    ScriptEventDispatcher.callEvent(currentSong, event);

    // Dispatch event to conversation script.
    ScriptEventDispatcher.callEvent(currentConversation, event);
  }

  /**
     * Function called before opening a new substate.
     * @param subState The substate to open.
     */
  public override function openSubState(subState:FlxSubState):Void
  {
    // If there is a substate which requires the game to continue,
    // then make this a condition.
    var shouldPause = (Std.isOfType(subState, PauseSubState) || Std.isOfType(subState, GameOverSubState));

    if (shouldPause)
    {
      // Pause the music.
      if (FlxG.sound.music != null)
      {
        if (FlxG.sound.music.playing)
        {
          FlxG.sound.music.pause();
          musicPausedBySubState = true;
        }

        // Pause vocals.
        // Not tracking that we've done this via a bool because vocal re-syncing involves pausing the vocals anyway.
        if (vocals != null) vocals.pause();
      }

      // Pause camera tweening, and keep track of which tweens we pause.
      if (cameraFollowTween != null && cameraFollowTween.active)
      {
        cameraFollowTween.active = false;
        cameraTweensPausedBySubState.add(cameraFollowTween);
      }

      if (cameraZoomTween != null && cameraZoomTween.active)
      {
        cameraZoomTween.active = false;
        cameraTweensPausedBySubState.add(cameraZoomTween);
      }

      // Pause camera follow
      FlxG.camera.followLerp = 0;

      for (tween in scrollSpeedTweens)
      {
        if (tween != null && tween.active)
        {
          tween.active = false;
          cameraTweensPausedBySubState.add(tween);
        }
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
    if (Std.isOfType(subState, PauseSubState))
    {
      var event:ScriptEvent = new ScriptEvent(RESUME, true);

      dispatchEvent(event);

      if (event.eventCanceled) return;

      // Resume music if we paused it.
      if (musicPausedBySubState)
      {
        FlxG.sound.music.play();
        musicPausedBySubState = false;
      }

      // Resume camera tweens if we paused any.
      for (camTween in cameraTweensPausedBySubState)
      {
        camTween.active = true;
      }
      cameraTweensPausedBySubState.clear();

      // Resume camera follow
      FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE;

      if (currentConversation != null)
      {
        currentConversation.resumeMusic();
      }

      // Re-sync vocals.
      if (FlxG.sound.music != null && !startingSong && !isInCutscene) resyncVocals();

      // Resume the countdown.
      Countdown.resumeCountdown();

      #if FEATURE_DISCORD_RPC
      if (startTimer.finished)
      {
        DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC, true,
          currentSongLengthMs - Conductor.instance.songPosition);
      }
      else
      {
        DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC);
      }
      #end

      justUnpaused = true;
    }
    else if (Std.isOfType(subState, Transition))
    {
      // Do nothing.
    }

    super.closeSubState();
  }

  /**
     * Function called when the game window gains focus.
     */
  public override function onFocus():Void
  {
    if (VideoCutscene.isPlaying() && FlxG.autoPause && isGamePaused) VideoCutscene.pauseVideo();
    #if html5
    else
      VideoCutscene.resumeVideo();
    #end

    #if FEATURE_DISCORD_RPC
    if (health > Constants.HEALTH_MIN && !paused && FlxG.autoPause)
    {
      if (Conductor.instance.songPosition > 0.0) DiscordClient.changePresence(detailsText, currentSong.song
        + ' ('
        + storyDifficultyText
        + ')', iconRPC, true,
        currentSongLengthMs
        - Conductor.instance.songPosition);
      else
        DiscordClient.changePresence(detailsText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
    }
    #end

    super.onFocus();
  }

  /**
     * Function called when the game window loses focus.
     */
  public override function onFocusLost():Void
  {
    #if html5
    if (FlxG.autoPause) VideoCutscene.pauseVideo();
    #end

    #if FEATURE_DISCORD_RPC
    if (health > Constants.HEALTH_MIN && !paused && FlxG.autoPause) DiscordClient.changePresence(detailsPausedText,
      currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
    #end

    super.onFocusLost();
  }

  /**
     * Call this by pressing F5 on a debug build.
     */
  override function reloadAssets():Void
  {
    funkin.modding.PolymodHandler.forceReloadAssets();
    lastParams.targetSong = SongRegistry.instance.fetchEntry(currentSong.id);
    LoadingState.loadPlayState(lastParams);
  }

  override function stepHit():Bool
  {
    if (criticalFailure || !initialized) return false;

    // super.stepHit() returns false if a module cancelled the event.
    if (!super.stepHit()) return false;

    if (isGamePaused) return false;

    if (iconP1 != null) iconP1.onStepHit(Std.int(Conductor.instance.currentStep));
    if (iconP2 != null) iconP2.onStepHit(Std.int(Conductor.instance.currentStep));

    return true;
  }

  override function beatHit():Bool
  {
    if (criticalFailure || !initialized) return false;

    // super.beatHit() returns false if a module cancelled the event.
    if (!super.beatHit()) return false;

    if (isGamePaused) return false;

    if (generatedMusic)
    {
      // TODO: Sort more efficiently, or less often, to improve performance.
      // activeNotes.sort(SortUtil.byStrumtime, FlxSort.DESCENDING);
    }

    if (!startingSong
      && FlxG.sound.music != null
      && (Math.abs(FlxG.sound.music.time - (Conductor.instance.songPosition + Conductor.instance.instrumentalOffset)) > 100
        || Math.abs(vocals.checkSyncError(Conductor.instance.songPosition + Conductor.instance.instrumentalOffset)) > 100))
    {
      trace("VOCALS NEED RESYNC");
      if (vocals != null) trace(vocals.checkSyncError(Conductor.instance.songPosition + Conductor.instance.instrumentalOffset));
      trace(FlxG.sound.music.time - (Conductor.instance.songPosition + Conductor.instance.instrumentalOffset));
      resyncVocals();
    }

    // Only bop camera if zoom level is below 135%
    if (Preferences.zoomCamera
      && FlxG.camera.zoom < (1.35 * FlxCamera.defaultZoom)
      && cameraZoomRate > 0
      && Conductor.instance.currentBeat % cameraZoomRate == 0)
    {
      // Set zoom multiplier for camera bop.
      cameraBopMultiplier = cameraBopIntensity;
      // HUD camera zoom still uses old system. To change. (+3%)
      camHUD.zoom += hudCameraZoomIntensity * defaultHUDCameraZoom;
    }
    // trace('Not bopping camera: ${FlxG.camera.zoom} < ${(1.35 * defaultCameraZoom)} && ${cameraZoomRate} > 0 && ${Conductor.instance.currentBeat} % ${cameraZoomRate} == ${Conductor.instance.currentBeat % cameraZoomRate}}');

    // That combo milestones that got spoiled that one time.
    // Comes with NEAT visual and audio effects.

    // bruh this var is bonkers i thot it was a function lmfaooo

    // Break up into individual lines to aid debugging.

    var shouldShowComboText:Bool = false;
    // TODO: Re-enable combo text (how to do this without sections?).
    // if (currentSong != null)
    // {
    //  shouldShowComboText = (Conductor.instance.currentBeat % 8 == 7);
    //  var daSection = .getSong()[Std.int(Conductor.instance.currentBeat / 16)];
    //  shouldShowComboText = shouldShowComboText && (daSection != null && daSection.mustHitSection);
    //  shouldShowComboText = shouldShowComboText && (Highscore.tallies.combo > 5);
    //
    //  var daNextSection = .getSong()[Std.int(Conductor.instance.currentBeat / 16) + 1];
    //  var isEndOfSong = .getSong().length < Std.int(Conductor.instance.currentBeat / 16);
    //  shouldShowComboText = shouldShowComboText && (isEndOfSong || (daNextSection != null && !daNextSection.mustHitSection));
    // }

    if (shouldShowComboText)
    {
      var animShit:ComboMilestone = new ComboMilestone(-100, 300, Highscore.tallies.combo);
      animShit.scrollFactor.set(0.6, 0.6);
      animShit.zIndex = 1100;
      animShit.cameras = [camHUD];
      add(animShit);

      var frameShit:Float = (1 / 24) * 2; // equals 2 frames in the animation

      new FlxTimer().start(((Conductor.instance.beatLengthMs / 1000) * 1.25) - frameShit, function(tmr) {
        animShit.forceFinish();
      });
    }

    if (playerStrumline != null) playerStrumline.onBeatHit();
    if (opponentStrumline != null) opponentStrumline.onBeatHit();

    return true;
  }

  public override function destroy():Void
  {
    performCleanup();

    super.destroy();
  }

  public override function initConsoleHelpers():Void
  {
    FlxG.console.registerFunction("debugUnbindCameraZoom", () -> {
      debugUnbindCameraZoom = !debugUnbindCameraZoom;
    });
  };

  /**
     * Initializes the game and HUD cameras.
     */
  function initCameras():Void
  {
    camGame = new FunkinCamera('playStateCamGame');
    camGame.bgColor = BACKGROUND_COLOR; // Show a pink background behind the stage.
    camHUD = new FlxCamera();
    camHUD.bgColor.alpha = 0; // Show the game scene behind the camera.
    camCutscene = new FlxCamera();
    camCutscene.bgColor.alpha = 0; // Show the game scene behind the camera.

    FlxG.cameras.reset(camGame);
    FlxG.cameras.add(camHUD, false);
    FlxG.cameras.add(camCutscene, false);

    // Configure camera follow point.
    if (previousCameraFollowPoint != null)
    {
      cameraFollowPoint.setPosition(previousCameraFollowPoint.x, previousCameraFollowPoint.y);
      previousCameraFollowPoint = null;
    }
    add(cameraFollowPoint);
  }

  /**
     * Initializes the health bar on the HUD.
     */
  function initHealthBar():Void
  {
    var healthBarYPos:Float = Preferences.downscroll ? FlxG.height * 0.1 : FlxG.height * 0.9;
    healthBarBG = FunkinSprite.create(0, healthBarYPos, 'healthBar');
    healthBarBG.screenCenter(X);
    healthBarBG.scrollFactor.set(0, 0);
    healthBarBG.zIndex = 800;
    add(healthBarBG);

    healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
      'healthLerp', 0, 2);
    healthBar.scrollFactor.set();
    healthBar.createFilledBar(Constants.COLOR_HEALTH_BAR_RED, Constants.COLOR_HEALTH_BAR_GREEN);
    healthBar.zIndex = 801;
    add(healthBar);

    // The score text below the health bar.
    scoreText = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, '', 20);
    scoreText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreText.scrollFactor.set();
    scoreText.zIndex = 802;
    add(scoreText);

    // Move the health bar to the HUD camera.
    healthBar.cameras = [camHUD];
    healthBarBG.cameras = [camHUD];
    scoreText.cameras = [camHUD];
  }

  /**
     * Generates the stage and all its props.
     */
  function initStage():Void
  {
    loadStage(currentStageId);
  }

  function initMinimalMode():Void
  {
    // Create the green background.
    var menuBG = FunkinSprite.create('menuDesat');
    menuBG.color = 0xFF4CAF50;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    menuBG.zIndex = -1000;
    add(menuBG);
  }

  /**
     * Loads stage data from cache, assembles the props,
     * and adds it to the state.
     * @param id
     */
  function loadStage(id:String):Void
  {
    currentStage = StageRegistry.instance.fetchEntry(id);

    if (currentStage != null)
    {
      currentStage.revive(); // Stages are killed and props destroyed when the PlayState is destroyed to save memory.

      // Actually create and position the sprites.
      var event:ScriptEvent = new ScriptEvent(CREATE, false);
      ScriptEventDispatcher.callEvent(currentStage, event);

      resetCameraZoom();

      // Add the stage to the scene.
      this.add(currentStage);

      #if FEATURE_DEBUG_FUNCTIONS
      FlxG.console.registerObject('stage', currentStage);
      #end
    }
    else
    {
      // lolol
      lime.app.Application.current.window.alert('Unable to load stage ${id}, is its data corrupted?.', 'Stage Error');
    }
  }

  public function resetCameraZoom():Void
  {
    if (PlayState.instance.isMinimalMode) return;
    // Apply camera zoom level from stage data.
    currentCameraZoom = stageZoom;
    FlxG.camera.zoom = currentCameraZoom;

    // Reset bop multiplier.
    cameraBopMultiplier = 1.0;
  }

  /**
     * Generates the character sprites and adds them to the stage.
     */
  function initCharacters():Void
  {
    if (currentSong == null || currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    var currentCharacterData:SongCharacterData = currentChart.characters; // Switch the variation we are playing on by manipulating targetVariation.

    //
    // GIRLFRIEND
    //
    var girlfriend:BaseCharacter = CharacterDataParser.fetchCharacter(currentCharacterData.girlfriend);

    if (girlfriend != null)
    {
      girlfriend.characterType = CharacterType.GF;
    }
    else if (currentCharacterData.girlfriend != '')
    {
      trace('WARNING: Could not load girlfriend character with ID ${currentCharacterData.girlfriend}, skipping...');
    }
    else
    {
      // Chosen GF was '' so we don't load one.
    }

    //
    // DAD
    //
    var dad:BaseCharacter = CharacterDataParser.fetchCharacter(currentCharacterData.opponent);

    if (dad != null)
    {
      dad.characterType = CharacterType.DAD;

      //
      // OPPONENT HEALTH ICON
      //
      iconP2 = new HealthIcon('dad', 1);
      iconP2.y = healthBar.y - (iconP2.height / 2);
      dad.initHealthIcon(true); // Apply the character ID here
      iconP2.zIndex = 850;
      add(iconP2);
      iconP2.cameras = [camHUD];
    }

    //
    // BOYFRIEND
    //
    var boyfriend:BaseCharacter = CharacterDataParser.fetchCharacter(currentCharacterData.player);

    if (boyfriend != null)
    {
      boyfriend.characterType = CharacterType.BF;

      //
      // PLAYER HEALTH ICON
      //
      iconP1 = new HealthIcon('bf', 0);
      iconP1.y = healthBar.y - (iconP1.height / 2);
      boyfriend.initHealthIcon(false); // Apply the character ID here
      iconP1.zIndex = 850;
      add(iconP1);
      iconP1.cameras = [camHUD];
    }

    //
    // ADD CHARACTERS TO SCENE
    //

    if (currentStage != null)
    {
      // Characters get added to the stage, not the main scene.
      if (girlfriend != null)
      {
        currentStage.addCharacter(girlfriend, GF);

        #if FEATURE_DEBUG_FUNCTIONS
        FlxG.console.registerObject('gf', girlfriend);
        #end
      }

      if (boyfriend != null)
      {
        currentStage.addCharacter(boyfriend, BF);

        #if FEATURE_DEBUG_FUNCTIONS
        FlxG.console.registerObject('bf', boyfriend);
        #end
      }

      if (dad != null)
      {
        currentStage.addCharacter(dad, DAD);
        // Camera starts at dad.
        cameraFollowPoint.setPosition(dad.cameraFocusPoint.x, dad.cameraFocusPoint.y);

        #if FEATURE_DEBUG_FUNCTIONS
        FlxG.console.registerObject('dad', dad);
        #end
      }

      // Rearrange by z-indexes.
      currentStage.refresh();
    }
  }

  /**
     * Constructs the strumlines for each player.
     */
  function initStrumlines():Void
  {
    var noteStyleId:String = currentChart.noteStyle;
    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();

    playerStrumline = new Strumline(noteStyle, !isBotPlayMode);
    playerStrumline.onNoteIncoming.add(onStrumlineNoteIncoming);
    opponentStrumline = new Strumline(noteStyle, false);
    opponentStrumline.onNoteIncoming.add(onStrumlineNoteIncoming);
    add(playerStrumline);
    add(opponentStrumline);

    // Position the player strumline on the right half of the screen
    playerStrumline.x = FlxG.width / 2 + Constants.STRUMLINE_X_OFFSET; // Classic style
    // playerStrumline.x = FlxG.width - playerStrumline.width - Constants.STRUMLINE_X_OFFSET; // Centered style
    playerStrumline.y = Preferences.downscroll ? FlxG.height - playerStrumline.height - Constants.STRUMLINE_Y_OFFSET : Constants.STRUMLINE_Y_OFFSET;
    playerStrumline.zIndex = 1001;
    playerStrumline.cameras = [camHUD];

    // Position the opponent strumline on the left half of the screen
    opponentStrumline.x = Constants.STRUMLINE_X_OFFSET;
    opponentStrumline.y = Preferences.downscroll ? FlxG.height - opponentStrumline.height - Constants.STRUMLINE_Y_OFFSET : Constants.STRUMLINE_Y_OFFSET;
    opponentStrumline.zIndex = 1000;
    opponentStrumline.cameras = [camHUD];

    playerStrumline.fadeInArrows();
    opponentStrumline.fadeInArrows();
  }

  /**
     * Configures the judgement and combo popups.
     */
  function initPopups():Void
  {
    var noteStyleId:String = currentChart.noteStyle;
    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
    // Initialize the judgements and combo meter.
    comboPopUps = new PopUpStuff(noteStyle);
    comboPopUps.zIndex = 900;
    add(comboPopUps);
    comboPopUps.cameras = [camHUD];
  }

  /**
     * Initializes the Discord Rich Presence.
     */
  function initDiscord():Void
  {
    #if FEATURE_DISCORD_RPC
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

  function initPreciseInputs():Void
  {
    PreciseInputManager.instance.onInputPressed.add(onKeyPress);
    PreciseInputManager.instance.onInputReleased.add(onKeyRelease);
  }

  /**
     * Initializes the song (applying the chart, generating the notes, etc.)
     * Should be done before the countdown starts.
     */
  function generateSong():Void
  {
    if (currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    // Conductor.instance.forceBPM(currentChart.getStartingBPM());

    if (!overrideMusic)
    {
      // Stop the vocals if they already exist.
      if (vocals != null) vocals.stop();
      vocals = currentChart.buildVocals(currentInstrumental);

      if (vocals.members.length == 0)
      {
        trace('WARNING: No vocals found for this song.');
      }
    }

    regenNoteData();

    var event:ScriptEvent = new ScriptEvent(CREATE, false);
    ScriptEventDispatcher.callEvent(currentSong, event);

    generatedMusic = true;
  }

  /**
     * Read note data from the chart and generate the notes.
     */
  function regenNoteData(startTime:Float = 0):Void
  {
    Highscore.tallies.combo = 0;
    Highscore.tallies = new Tallies();

    var event:SongLoadScriptEvent = new SongLoadScriptEvent(currentChart.song.id, currentChart.difficulty, currentChart.notes.copy(), currentChart.getEvents());

    dispatchEvent(event);

    var builtNoteData = event.notes;
    var builtEventData = event.events;

    songEvents = builtEventData;
    SongEventRegistry.resetEvents(songEvents);

    // Reset the notes on each strumline.
    var playerNoteData:Array<SongNoteData> = [];
    var opponentNoteData:Array<SongNoteData> = [];

    for (songNote in builtNoteData)
    {
      var strumTime:Float = songNote.time;
      if (strumTime < startTime) continue; // Skip notes that are before the start time.

      var noteData:Int = songNote.getDirection();
      var playerNote:Bool = true;

      if (noteData > 3) playerNote = false;

      switch (songNote.getStrumlineIndex())
      {
        case 0:
          playerNoteData.push(songNote);
          // increment totalNotes for total possible notes able to be hit by the player
          Highscore.tallies.totalNotes++;
        case 1:
          opponentNoteData.push(songNote);
      }
    }

    playerStrumline.applyNoteData(playerNoteData);
    opponentStrumline.applyNoteData(opponentNoteData);
  }

  function onStrumlineNoteIncoming(noteSprite:NoteSprite):Void
  {
    var event:NoteScriptEvent = new NoteScriptEvent(NOTE_INCOMING, noteSprite, 0, false);

    dispatchEvent(event);
  }

  /**
     * Prepares to start the countdown.
     * Ends any running cutscenes, creates the strumlines, and starts the countdown.
     * This is public so that scripts can call it.
     */
  public function startCountdown():Void
  {
    // If Countdown.performCountdown returns false, then the countdown was canceled by a script.
    var result:Bool = Countdown.performCountdown();
    if (!result) return;

    isInCutscene = false;

    // TODO: Maybe tween in the camera after any cutscenes.
    camHUD.visible = true;
  }

  /**
     * Displays a dialogue cutscene with the given ID.
     * This is used by song scripts to display dialogue.
     */
  public function startConversation(conversationId:String):Void
  {
    isInCutscene = true;

    currentConversation = ConversationRegistry.instance.fetchEntry(conversationId);
    if (currentConversation == null) return;
    if (!currentConversation.alive) currentConversation.revive();

    currentConversation.completeCallback = onConversationComplete;
    currentConversation.cameras = [camCutscene];
    currentConversation.zIndex = 1000;
    add(currentConversation);
    refresh();

    var event:ScriptEvent = new ScriptEvent(CREATE, false);
    ScriptEventDispatcher.callEvent(currentConversation, event);
  }

  /**
     * Handler function called when a conversation ends.
     */
  function onConversationComplete():Void
  {
    isInCutscene = false;

    if (currentConversation != null)
    {
      currentConversation.kill();
      remove(currentConversation);
      currentConversation = null;
    }

    if (startingSong && !isInCountdown)
    {
      startCountdown();
    }
  }

  /**
     * Starts playing the song after the countdown has completed.
     */
  function startSong():Void
  {
    startingSong = false;

    if (!overrideMusic && !isGamePaused && currentChart != null)
    {
      currentChart.playInst(1.0, currentInstrumental, false);
    }

    if (FlxG.sound.music == null)
    {
      FlxG.log.error('PlayState failed to initialize instrumental!');
      return;
    }

    FlxG.sound.music.onComplete = function() {
      endSong(skipEndingTransition);
    };
    // A negative instrumental offset means the song skips the first few milliseconds of the track.
    // This just gets added into the startTimestamp behavior so we don't need to do anything extra.
    FlxG.sound.music.play(true, startTimestamp - Conductor.instance.instrumentalOffset);
    FlxG.sound.music.pitch = playbackRate;

    // Prevent the volume from being wrong.
    FlxG.sound.music.volume = 1.0;
    if (FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();

    trace('Playing vocals...');
    add(vocals);
    vocals.play();
    vocals.volume = 1.0;
    vocals.pitch = playbackRate;
    resyncVocals();

    #if FEATURE_DISCORD_RPC
    // Updating Discord Rich Presence (with Time Left)
    DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC, true, currentSongLengthMs);
    #end

    if (startTimestamp > 0)
    {
      // FlxG.sound.music.time = startTimestamp - Conductor.instance.instrumentalOffset;
      handleSkippedNotes();
    }

    dispatchEvent(new ScriptEvent(SONG_START));
  }

  /**
     * Resyncronize the vocal tracks if they have become offset from the instrumental.
     */
  function resyncVocals():Void
  {
    if (vocals == null) return;

    // Skip this if the music is paused (GameOver, Pause menu, start-of-song offset, etc.)
    if (!(FlxG.sound.music?.playing ?? false)) return;

    var timeToPlayAt:Float = Conductor.instance.songPosition - Conductor.instance.instrumentalOffset;
    FlxG.sound.music.pause();
    vocals.pause();

    FlxG.sound.music.time = timeToPlayAt;
    FlxG.sound.music.play(false, timeToPlayAt);

    vocals.time = timeToPlayAt;
    vocals.play(false, timeToPlayAt);
  }

  /**
     * Updates the position and contents of the score display.
     */
  function updateScoreText():Void
  {
    // TODO: Add functionality for modules to update the score text.
    if (isBotPlayMode)
    {
      scoreText.text = 'Bot Play Enabled';
    }
    else
    {
      // TODO: Add an option for this maybe?
      var commaSeparated:Bool = true;
      scoreText.text = 'Score: ${FlxStringUtil.formatMoney(songScore, false, commaSeparated)}';
    }
  }

  /**
     * Updates the values of the health bar.
     */
  function updateHealthBar():Void
  {
    if (isBotPlayMode)
    {
      healthLerp = Constants.HEALTH_MAX;
    }
    else
    {
      healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
    }
  }

  /**
     * Callback executed when one of the note keys is pressed.
     */
  function onKeyPress(event:PreciseInputEvent):Void
  {
    if (isGamePaused) return;

    // Do the minimal possible work here.
    inputPressQueue.push(event);
  }

  /**
     * Callback executed when one of the note keys is released.
     */
  function onKeyRelease(event:PreciseInputEvent):Void
  {
    if (isGamePaused) return;

    // Do the minimal possible work here.
    inputReleaseQueue.push(event);
  }

  /**
     * Handles opponent note hits and player note misses.
     */
  function processNotes(elapsed:Float):Void
  {
    if (playerStrumline?.notes?.members == null || opponentStrumline?.notes?.members == null) return;

    // Process notes on the opponent's side.
    for (note in opponentStrumline.notes.members)
    {
      if (note == null) continue;

      // TODO: Are offsets being accounted for in the correct direction?
      var hitWindowStart = note.strumTime + Conductor.instance.inputOffset - Constants.HIT_WINDOW_MS;
      var hitWindowCenter = note.strumTime + Conductor.instance.inputOffset;
      var hitWindowEnd = note.strumTime + Conductor.instance.inputOffset + Constants.HIT_WINDOW_MS;

      if (Conductor.instance.songPosition > hitWindowEnd)
      {
        if (note.hasMissed || note.hasBeenHit) continue;

        note.tooEarly = false;
        note.mayHit = false;
        note.hasMissed = true;

        if (note.holdNoteSprite != null)
        {
          note.holdNoteSprite.missedNote = true;
        }
      }
      else if (Conductor.instance.songPosition > hitWindowCenter)
      {
        if (note.hasBeenHit) continue;

        // Call an event to allow canceling the note hit.
        // NOTE: This is what handles the character animations!

        var event:NoteScriptEvent = new HitNoteScriptEvent(note, 0.0, 0, 'perfect', false, 0);
        dispatchEvent(event);

        // Calling event.cancelEvent() skips all the other logic! Neat!
        if (event.eventCanceled) continue;

        // Command the opponent to hit the note on time.
        // NOTE: This is what handles the strumline and cleaning up the note itself!
        opponentStrumline.hitNote(note);

        if (note.holdNoteSprite != null)
        {
          opponentStrumline.playNoteHoldCover(note.holdNoteSprite);
        }
      }
      else if (Conductor.instance.songPosition > hitWindowStart)
      {
        if (note.hasBeenHit || note.hasMissed) continue;

        note.tooEarly = false;
        note.mayHit = true;
        note.hasMissed = false;
        if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
      }
      else
      {
        note.tooEarly = true;
        note.mayHit = false;
        note.hasMissed = false;
        if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
      }
    }

    // Process hold notes on the opponent's side.
    for (holdNote in opponentStrumline.holdNotes.members)
    {
      if (holdNote == null || !holdNote.alive) continue;

      // While the hold note is being hit, and there is length on the hold note...
      if (holdNote.hitNote && !holdNote.missedNote && holdNote.sustainLength > 0)
      {
        // Make sure the opponent keeps singing while the note is held.
        if (currentStage != null && currentStage.getDad() != null && currentStage.getDad().isSinging())
        {
          currentStage.getDad().holdTimer = 0;
        }
      }

      if (holdNote.missedNote && !holdNote.handledMiss)
      {
        // When the opponent drops a hold note.
        holdNote.handledMiss = true;

        // We dropped a hold note.
        // Play miss animation, but don't penalize.
        currentStage.getOpponent().playSingAnimation(holdNote.noteData.getDirection(), true);
      }
    }

    // Process notes on the player's side.
    for (note in playerStrumline.notes.members)
    {
      if (note == null) continue;

      if (note.hasBeenHit)
      {
        note.tooEarly = false;
        note.mayHit = false;
        note.hasMissed = false;
        continue;
      }

      var hitWindowStart = note.strumTime - Constants.HIT_WINDOW_MS;
      var hitWindowCenter = note.strumTime;
      var hitWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS;

      if (Conductor.instance.songPosition > hitWindowEnd)
      {
        if (note.hasMissed || note.hasBeenHit) continue;
        note.tooEarly = false;
        note.mayHit = false;
        note.hasMissed = true;
        if (note.holdNoteSprite != null)
        {
          note.holdNoteSprite.missedNote = true;
        }
      }
      else if (isBotPlayMode && Conductor.instance.songPosition > hitWindowCenter)
      {
        if (note.hasBeenHit) continue;

        // We call onHitNote to play the proper animations,
        // but not goodNoteHit! This means zero score and zero notes hit for the results screen!

        // Call an event to allow canceling the note hit.
        // NOTE: This is what handles the character animations!
        var event:NoteScriptEvent = new HitNoteScriptEvent(note, 0.0, 0, 'perfect', false, 0);
        dispatchEvent(event);

        // Calling event.cancelEvent() skips all the other logic! Neat!
        if (event.eventCanceled) continue;

        // Command the bot to hit the note on time.
        // NOTE: This is what handles the strumline and cleaning up the note itself!
        playerStrumline.hitNote(note);

        if (note.holdNoteSprite != null)
        {
          playerStrumline.playNoteHoldCover(note.holdNoteSprite);
        }
      }
      else if (Conductor.instance.songPosition > hitWindowStart)
      {
        note.tooEarly = false;
        note.mayHit = true;
        note.hasMissed = false;
        if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
      }
      else
      {
        note.tooEarly = true;
        note.mayHit = false;
        note.hasMissed = false;
        if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
      }

      // This becomes true when the note leaves the hit window.
      // It might still be on screen.
      if (note.hasMissed && !note.handledMiss)
      {
        // Call an event to allow canceling the note miss.
        // NOTE: This is what handles the character animations!
        var event:NoteScriptEvent = new NoteScriptEvent(NOTE_MISS, note, -Constants.HEALTH_MISS_PENALTY, 0, true);
        dispatchEvent(event);

        // Calling event.cancelEvent() skips all the other logic! Neat!
        if (event.eventCanceled) continue;

        // Skip handling the miss in botplay!
        if (!isBotPlayMode)
        {
          // Judge the miss.
          // NOTE: This is what handles the scoring.
          trace('Missed note! ${note.noteData}');
          onNoteMiss(note, event.playSound, event.healthChange);
        }

        note.handledMiss = true;
      }
    }

    // Process hold notes on the player's side.
    // This handles scoring so we don't need it on the opponent's side.
    for (holdNote in playerStrumline.holdNotes.members)
    {
      if (holdNote == null || !holdNote.alive) continue;

      // While the hold note is being hit, and there is length on the hold note...
      if (holdNote.hitNote && !holdNote.missedNote && holdNote.sustainLength > 0)
      {
        // Grant the player health.
        if (!isBotPlayMode)
        {
          health += Constants.HEALTH_HOLD_BONUS_PER_SECOND * elapsed;
          songScore += Std.int(Constants.SCORE_HOLD_BONUS_PER_SECOND * elapsed);
        }

        // Make sure the player keeps singing while the note is held by the bot.
        if (isBotPlayMode && currentStage != null && currentStage.getBoyfriend() != null && currentStage.getBoyfriend().isSinging())
        {
          currentStage.getBoyfriend().holdTimer = 0;
        }
      }

      if (holdNote.missedNote && !holdNote.handledMiss)
      {
        // The player dropped a hold note.
        holdNote.handledMiss = true;

        // Mute vocals and play miss animation, but don't penalize.
        // vocals.playerVolume = 0;
        // if (currentStage != null && currentStage.getBoyfriend() != null) currentStage.getBoyfriend().playSingAnimation(holdNote.noteData.getDirection(), true);
      }
    }
  }

  /**
     * Spitting out the input for ravy 🙇‍♂️!!
     */
  var inputSpitter:Array<ScoreInput> = [];

  function handleSkippedNotes():Void
  {
    for (note in playerStrumline.notes.members)
    {
      if (note == null || note.hasBeenHit) continue;
      var hitWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS;

      if (Conductor.instance.songPosition > hitWindowEnd)
      {
        // We have passed this note.
        // Flag the note for deletion without actually penalizing the player.
        note.handledMiss = true;
      }
    }

    // Respawns notes that were b
    playerStrumline.handleSkippedNotes();
    opponentStrumline.handleSkippedNotes();
  }

  /**
     * PreciseInputEvents are put into a queue between update() calls,
     * and then processed here.
     */
  function processInputQueue():Void
  {
    if (inputPressQueue.length + inputReleaseQueue.length == 0) return;

    // Ignore inputs during cutscenes.
    if (isInCutscene || disableKeys)
    {
      inputPressQueue = [];
      inputReleaseQueue = [];
      return;
    }

    // Generate a list of notes within range.
    var notesInRange:Array<NoteSprite> = playerStrumline.getNotesMayHit();
    var holdNotesInRange:Array<SustainTrail> = playerStrumline.getHoldNotesHitOrMissed();

    var notesByDirection:Array<Array<NoteSprite>> = [[], [], [], []];

    for (note in notesInRange)
      notesByDirection[note.direction].push(note);

    while (inputPressQueue.length > 0)
    {
      var input:PreciseInputEvent = inputPressQueue.shift();

      playerStrumline.pressKey(input.noteDirection);

      // Don't credit or penalize inputs in Bot Play.
      if (isBotPlayMode) continue;

      var notesInDirection:Array<NoteSprite> = notesByDirection[input.noteDirection];

      #if FEATURE_GHOST_TAPPING
      if ((!playerStrumline.mayGhostTap()) && notesInDirection.length == 0)
      #else
      if (notesInDirection.length == 0)
      #end
      {
        // Pressed a wrong key with no notes nearby.
        // Perform a ghost miss (anti-spam).
        ghostNoteMiss(input.noteDirection, notesInRange.length > 0);

        // Play the strumline animation.
        playerStrumline.playPress(input.noteDirection);
        trace('PENALTY Score: ${songScore}');
      }
    else if (notesInDirection.length == 0)
    {
      // Press a key with no penalty.

      // Play the strumline animation.
      playerStrumline.playPress(input.noteDirection);
      trace('NO PENALTY Score: ${songScore}');
    }
    else
    {
      // Choose the first note, deprioritizing low priority notes.
      var targetNote:Null<NoteSprite> = notesInDirection.find((note) -> !note.lowPriority);
      if (targetNote == null) targetNote = notesInDirection[0];
      if (targetNote == null) continue;

      // Judge and hit the note.
      trace('Hit note! ${targetNote.noteData}');
      goodNoteHit(targetNote, input);
      trace('Score: ${songScore}');

      notesInDirection.remove(targetNote);

      // Play the strumline animation.
      playerStrumline.playConfirm(input.noteDirection);
    }
    }

    while (inputReleaseQueue.length > 0)
    {
      var input:PreciseInputEvent = inputReleaseQueue.shift();

      // Play the strumline animation.
      playerStrumline.playStatic(input.noteDirection);

      playerStrumline.releaseKey(input.noteDirection);
    }
  }

  function goodNoteHit(note:NoteSprite, input:PreciseInputEvent):Void
  {
    // Calculate the input latency (do this as late as possible).
    // trace('Compare: ${PreciseInputManager.getCurrentTimestamp()} - ${input.timestamp}');
    var inputLatencyNs:Int64 = PreciseInputManager.getCurrentTimestamp() - input.timestamp;
    var inputLatencyMs:Float = inputLatencyNs.toFloat() / Constants.NS_PER_MS;
    // trace('Input: ${daNote.noteData.getDirectionName()} pressed ${inputLatencyMs}ms ago!');

    // Get the offset and compensate for input latency.
    // Round inward (trim remainder) for consistency.
    var noteDiff:Int = Std.int(Conductor.instance.songPosition - note.noteData.time - inputLatencyMs);

    var score = Scoring.scoreNote(noteDiff, PBOT1);
    var daRating = Scoring.judgeNote(noteDiff, PBOT1);

    var healthChange = 0.0;
    var isComboBreak = false;
    switch (daRating)
    {
      case 'sick':
        healthChange = Constants.HEALTH_SICK_BONUS;
        isComboBreak = Constants.JUDGEMENT_SICK_COMBO_BREAK;
      case 'good':
        healthChange = Constants.HEALTH_GOOD_BONUS;
        isComboBreak = Constants.JUDGEMENT_GOOD_COMBO_BREAK;
      case 'bad':
        healthChange = Constants.HEALTH_BAD_BONUS;
        isComboBreak = Constants.JUDGEMENT_BAD_COMBO_BREAK;
      case 'shit':
        isComboBreak = Constants.JUDGEMENT_SHIT_COMBO_BREAK;
        healthChange = Constants.HEALTH_SHIT_BONUS;
    }

    // Send the note hit event.
    var event:HitNoteScriptEvent = new HitNoteScriptEvent(note, healthChange, score, daRating, isComboBreak, Highscore.tallies.combo + 1, noteDiff,
      daRating == 'sick');
    dispatchEvent(event);

    // Calling event.cancelEvent() skips all the other logic! Neat!
    if (event.eventCanceled) return;

    Highscore.tallies.totalNotesHit++;
    // Display the hit on the strums
    playerStrumline.hitNote(note, !isComboBreak);
    if (event.doesNotesplash) playerStrumline.playNoteSplash(note.noteData.getDirection());
    if (note.isHoldNote && note.holdNoteSprite != null) playerStrumline.playNoteHoldCover(note.holdNoteSprite);
    vocals.playerVolume = 1;

    // Display the combo meter and add the calculation to the score.
    applyScore(event.score, event.judgement, event.healthChange, event.isComboBreak);
    popUpScore(event.judgement);
  }

  /**
     * Called when a note leaves the screen and is considered missed by the player.
     * @param note
     */
  function onNoteMiss(note:NoteSprite, playSound:Bool = false, healthChange:Float):Void
  {
    // If we are here, we already CALLED the onNoteMiss script hook!

    if (!isPracticeMode)
    {
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
              t: Std.int(Conductor.instance.songPosition),
              d: indices[i],
              l: 20
            });
        }
      }
      else
      {
        inputSpitter.push(
          {
            t: Std.int(Conductor.instance.songPosition),
            d: -1,
            l: 20
          });
      }
    }
    vocals.playerVolume = 0;

    if (Highscore.tallies.combo != 0) if (Highscore.tallies.combo >= 10) comboPopUps.displayCombo(0);

    applyScore(-10, 'miss', healthChange, true);

    if (playSound)
    {
      vocals.playerVolume = 0;
      FunkinSound.playOnce(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.5, 0.6));
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
  function ghostNoteMiss(direction:NoteDirection, hasPossibleNotes:Bool = true):Void
  {
    var event:GhostMissNoteScriptEvent = new GhostMissNoteScriptEvent(direction, // Direction missed in.
      hasPossibleNotes, // Whether there was a note you could have hit.
      - 1 * Constants.HEALTH_MISS_PENALTY, // How much health to add (negative).
      - 10 // Amount of score to add (negative).
    );
    dispatchEvent(event);

    // Calling event.cancelEvent() skips animations and penalties. Neat!
    if (event.eventCanceled) return;

    health += event.healthChange;
    songScore += event.scoreChange;

    if (!isPracticeMode)
    {
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
            t: Std.int(Conductor.instance.songPosition),
            d: indices[i],
            l: 20
          });
      }
    }

    if (event.playSound)
    {
      vocals.playerVolume = 0;
      FunkinSound.playOnce(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
    }
  }

  /**
     * Debug keys. Disabled while in cutscenes.
     */
  function debugKeyShit():Void
  {
    #if FEATURE_CHART_EDITOR
    // Open the stage editor overlaying the current state.
    if (controls.DEBUG_STAGE)
    {
      // hack for HaxeUI generation, doesn't work unless persistentUpdate is false at state creation!!
      disableKeys = true;
      persistentUpdate = false;
      openSubState(new StageOffsetSubState());
    }

    // Redirect to the chart editor playing the current song.
    if (controls.DEBUG_CHART)
    {
      disableKeys = true;
      persistentUpdate = false;
      if (isChartingMode)
      {
        FlxG.sound.music?.pause();
        this.close();
      }
      else
      {
        FlxG.switchState(() -> new ChartEditorState(
          {
            targetSongId: currentSong.id,
          }));
      }
    }
    #end

    #if FEATURE_DEBUG_FUNCTIONS
    // H: Hide the HUD.
    if (FlxG.keys.justPressed.H) camHUD.visible = !camHUD.visible;

    // 1: End the song immediately.
    if (FlxG.keys.justPressed.ONE) endSong(true);

    // 2: Gain 10% health.
    if (FlxG.keys.justPressed.TWO) health += 0.1 * Constants.HEALTH_MAX;

    // 3: Lose 5% health.
    if (FlxG.keys.justPressed.THREE) health -= 0.05 * Constants.HEALTH_MAX;
    #end

    // 9: Toggle the old icon.
    if (FlxG.keys.justPressed.NINE) iconP1.toggleOldIcon();

    #if FEATURE_DEBUG_FUNCTIONS
    // PAGEUP: Skip forward two sections.
    // SHIFT+PAGEUP: Skip forward twenty sections.
    if (FlxG.keys.justPressed.PAGEUP) changeSection(FlxG.keys.pressed.SHIFT ? 20 : 2);
    // PAGEDOWN: Skip backward two section. Doesn't replace notes.
    // SHIFT+PAGEDOWN: Skip backward twenty sections.
    if (FlxG.keys.justPressed.PAGEDOWN) changeSection(FlxG.keys.pressed.SHIFT ? -20 : -2);
    #end

    if (FlxG.keys.justPressed.B) trace(inputSpitter.join('\n'));
  }

  /**
     * Handles applying health, score, and ratings.
     */
  function applyScore(score:Int, daRating:String, healthChange:Float, isComboBreak:Bool)
  {
    switch (daRating)
    {
      case 'sick':
        Highscore.tallies.sick += 1;
      case 'good':
        Highscore.tallies.good += 1;
      case 'bad':
        Highscore.tallies.bad += 1;
      case 'shit':
        Highscore.tallies.shit += 1;
      case 'miss':
        Highscore.tallies.missed += 1;
    }
    health += healthChange;
    if (isComboBreak)
    {
      // Break the combo, but don't increment tallies.misses.
      if (Highscore.tallies.combo >= 10) comboPopUps.displayCombo(0);
      Highscore.tallies.combo = 0;
    }
    else
    {
      Highscore.tallies.combo++;
      if (Highscore.tallies.combo > Highscore.tallies.maxCombo) Highscore.tallies.maxCombo = Highscore.tallies.combo;
    }
    songScore += score;
  }

  /**
     * Handles rating popups when a note is hit.
     */
  function popUpScore(daRating:String, ?combo:Int):Void
  {
    if (daRating == 'miss')
    {
      // If daRating is 'miss', that means we made a mistake and should not continue.
      FlxG.log.warn('popUpScore judged a note as a miss!');
      // TODO: Remove this.
      // comboPopUps.displayRating('miss');
      return;
    }
    if (combo == null) combo = Highscore.tallies.combo;

    if (!isPracticeMode)
    {
      // TODO: Input splitter uses old input system, make it pull from the precise input queue directly.
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
              t: Std.int(Conductor.instance.songPosition),
              d: indices[i],
              l: 20
            });
        }
      }
      else
      {
        inputSpitter.push(
          {
            t: Std.int(Conductor.instance.songPosition),
            d: -1,
            l: 20
          });
      }
    }
    comboPopUps.displayRating(daRating);
    if (combo >= 10 || combo == 0) comboPopUps.displayCombo(combo);

    vocals.playerVolume = 1;
  }

  /**
     * Handle keyboard inputs during cutscenes.
     * This includes advancing conversations and skipping videos.
     * @param elapsed Time elapsed since last game update.
     */
  function handleCutsceneKeys(elapsed:Float):Void
  {
    if (isGamePaused) return;

    if (currentConversation != null)
    {
      // Pause/unpause may conflict with advancing the conversation!
      if (controls.CUTSCENE_ADVANCE && !justUnpaused)
      {
        currentConversation.advanceConversation();
      }
      else if (controls.PAUSE && !justUnpaused)
      {
        currentConversation.pauseMusic();

        var pauseSubState:FlxSubState = new PauseSubState({mode: Conversation});

        persistentUpdate = false;
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        pauseSubState.camera = camCutscene;
        openSubState(pauseSubState);
      }
    }
    else if (VideoCutscene.isPlaying())
    {
      // This is a video cutscene.
      if (controls.PAUSE && !justUnpaused)
      {
        VideoCutscene.pauseVideo();

        var pauseSubState:FlxSubState = new PauseSubState({mode: Cutscene});

        persistentUpdate = false;
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        pauseSubState.camera = camCutscene;
        openSubState(pauseSubState);
      }
    }
  }

  /**
     * Handle logic for actually skipping a video cutscene after it has been held.
     */
  function skipVideoCutscene():Void
  {
    VideoCutscene.finishVideo();
  }

  /**
     * End the song. Handle saving high scores and transitioning to the results screen.
     *
     * Broadcasts an `onSongEnd` event, which can be cancelled to prevent the song from ending (for a cutscene or something).
     * Remember to call `endSong` again when the song should actually end!
     * @param rightGoddamnNow If true, don't play the fancy animation where you zoom onto Girlfriend. Used after a cutscene.
     */
  public function endSong(rightGoddamnNow:Bool = false):Void
  {
    if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
    vocals.volume = 0;
    mayPauseGame = false;

    // Check if any events want to prevent the song from ending.
    var event = new ScriptEvent(SONG_END, true);
    dispatchEvent(event);
    if (event.eventCanceled) return;

    #if sys
    // spitter for ravy, teehee!!
    var writer = new json2object.JsonWriter<Array<ScoreInput>>();
    var output = writer.write(inputSpitter, '  ');
    sys.io.File.saveContent("./scores.json", output);
    #end

    deathCounter = 0;

    // TODO: This line of code makes me sad, but you can't really fix it without a breaking migration.
    // `easy`, `erect`, `normal-pico`, etc.
    var suffixedDifficulty = (currentVariation != Constants.DEFAULT_VARIATION
      && currentVariation != 'erect') ? '$currentDifficulty-${currentVariation}' : currentDifficulty;

    var isNewHighscore = false;
    var prevScoreData:Null<SaveScoreData> = Save.instance.getSongScore(currentSong.id, suffixedDifficulty);

    if (currentSong != null && currentSong.validScore)
    {
      // crackhead double thingie, sets whether was new highscore, AND saves the song!
      var data =
        {
          score: songScore,
          tallies:
            {
              sick: Highscore.tallies.sick,
              good: Highscore.tallies.good,
              bad: Highscore.tallies.bad,
              shit: Highscore.tallies.shit,
              missed: Highscore.tallies.missed,
              combo: Highscore.tallies.combo,
              maxCombo: Highscore.tallies.maxCombo,
              totalNotesHit: Highscore.tallies.totalNotesHit,
              totalNotes: Highscore.tallies.totalNotes,
            },
        };

      // adds current song data into the tallies for the level (story levels)
      Highscore.talliesLevel = Highscore.combineTallies(Highscore.tallies, Highscore.talliesLevel);

      if (!isPracticeMode && !isBotPlayMode)
      {
        isNewHighscore = Save.instance.isSongHighScore(currentSong.id, suffixedDifficulty, data);

        // If no high score is present, save both score and rank.
        // If score or rank are better, save the highest one.
        // If neither are higher, nothing will change.
        Save.instance.applySongRank(currentSong.id, suffixedDifficulty, data);

        if (isNewHighscore)
        {
          #if newgrounds
          NGio.postScore(score, currentSong.id);
          #end
        }
      }
    }

    if (PlayStatePlaylist.isStoryMode)
    {
      isNewHighscore = false;

      PlayStatePlaylist.campaignScore += songScore;

      // Pop the next song ID from the list.
      // Returns null if the list is empty.
      var targetSongId:String = PlayStatePlaylist.playlistSongIds.shift();

      if (targetSongId == null)
      {
        if (currentSong.validScore)
        {
          NGio.unlockMedal(60961);

          var data =
            {
              score: PlayStatePlaylist.campaignScore,
              tallies:
                {
                  // TODO: Sum up the values for the whole week!
                  sick: 0,
                  good: 0,
                  bad: 0,
                  shit: 0,
                  missed: 0,
                  combo: 0,
                  maxCombo: 0,
                  totalNotesHit: 0,
                  totalNotes: 0,
                },
            };

          if (Save.instance.isLevelHighScore(PlayStatePlaylist.campaignId, PlayStatePlaylist.campaignDifficulty, data))
          {
            Save.instance.setLevelScore(PlayStatePlaylist.campaignId, PlayStatePlaylist.campaignDifficulty, data);
            #if newgrounds
            NGio.postScore(score, 'Level ${PlayStatePlaylist.campaignId}');
            #end
            isNewHighscore = true;
          }
        }

        if (isSubState)
        {
          this.close();
        }
        else
        {
          if (rightGoddamnNow)
          {
            moveToResultsScreen(isNewHighscore);
          }
          else
          {
            zoomIntoResultsScreen(isNewHighscore);
          }
        }
      }
      else
      {
        var difficulty:String = '';

        trace('Loading next song ($targetSongId : $difficulty)');

        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;

        if (FlxG.sound.music != null) FlxG.sound.music.stop();
        vocals.stop();

        // TODO: Softcode this cutscene.
        if (currentSong.id == 'eggnog')
        {
          var blackBG:FunkinSprite = new FunkinSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom);
          blackBG.makeSolidColor(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
          blackBG.scrollFactor.set();
          add(blackBG);
          camHUD.visible = false;
          isInCutscene = true;

          FunkinSound.playOnce(Paths.sound('Lights_Shut_off'), function() {
            // no camFollow so it centers on horror tree
            var targetSong:Song = SongRegistry.instance.fetchEntry(targetSongId);
            var targetVariation:String = currentVariation;
            if (!targetSong.hasDifficulty(PlayStatePlaylist.campaignDifficulty, currentVariation))
            {
              targetVariation = targetSong.getFirstValidVariation(PlayStatePlaylist.campaignDifficulty) ?? Constants.DEFAULT_VARIATION;
            }
            LoadingState.loadPlayState(
              {
                targetSong: targetSong,
                targetDifficulty: PlayStatePlaylist.campaignDifficulty,
                targetVariation: targetVariation,
                cameraFollowPoint: cameraFollowPoint.getPosition(),
              });
          });
        }
        else
        {
          var targetSong:Song = SongRegistry.instance.fetchEntry(targetSongId);
          var targetVariation:String = currentVariation;
          if (!targetSong.hasDifficulty(PlayStatePlaylist.campaignDifficulty, currentVariation))
          {
            targetVariation = targetSong.getFirstValidVariation(PlayStatePlaylist.campaignDifficulty) ?? Constants.DEFAULT_VARIATION;
          }
          LoadingState.loadPlayState(
            {
              targetSong: targetSong,
              targetDifficulty: PlayStatePlaylist.campaignDifficulty,
              targetVariation: targetVariation,
              cameraFollowPoint: cameraFollowPoint.getPosition(),
            });
        }
      }
    }
    else
    {
      if (isSubState)
      {
        this.close();
      }
      else
      {
        if (rightGoddamnNow)
        {
          moveToResultsScreen(isNewHighscore, prevScoreData);
        }
        else
        {
          zoomIntoResultsScreen(isNewHighscore, prevScoreData);
        }
      }
    }
  }

  public override function close():Void
  {
    criticalFailure = true; // Stop game updates.
    performCleanup();
    super.close();
  }

  /**
     * Perform necessary cleanup before leaving the PlayState.
     */
  function performCleanup():Void
  {
    // If the camera is being tweened, stop it.
    cancelAllCameraTweens();

    // Dispatch the destroy event.
    dispatchEvent(new ScriptEvent(DESTROY, false));

    if (currentConversation != null)
    {
      remove(currentConversation);
      currentConversation.kill();
    }

    if (currentChart != null)
    {
      // TODO: Uncache the song.
    }

    if (overrideMusic)
    {
      // Stop the music. Do NOT destroy it, something still references it!
      if (FlxG.sound.music != null) FlxG.sound.music.pause();
      if (vocals != null)
      {
        vocals.pause();
        remove(vocals);
      }
    }
    else
    {
      // Stop and destroy the music.
      if (FlxG.sound.music != null) FlxG.sound.music.pause();
      if (vocals != null)
      {
        vocals.destroy();
        remove(vocals);
      }
    }

    // Remove reference to stage and remove sprites from it to save memory.
    if (currentStage != null)
    {
      remove(currentStage);
      currentStage.kill();
      currentStage = null;
    }

    GameOverSubState.reset();
    PauseSubState.reset();
    Countdown.reset();

    // Clear the static reference to this state.
    instance = null;
  }

  /**
     * Play the camera zoom animation and then move to the results screen once it's done.
     */
  function zoomIntoResultsScreen(isNewHighscore:Bool, ?prevScoreData:SaveScoreData):Void
  {
    trace('WENT TO RESULTS SCREEN!');

    // Stop camera zooming on beat.
    cameraZoomRate = 0;

    // Cancel camera and scroll tweening if it's active.
    cancelAllCameraTweens();
    cancelScrollSpeedTweens();

    // If the opponent is GF, zoom in on the opponent.
    // Else, if there is no GF, zoom in on BF.
    // Else, zoom in on GF.
    var targetDad:Bool = currentStage.getDad() != null && currentStage.getDad().characterId == 'gf';
    var targetBF:Bool = currentStage.getGirlfriend() == null && !targetDad;

    if (targetBF)
    {
      FlxG.camera.follow(currentStage.getBoyfriend(), null, 0.05);
    }
    else if (targetDad)
    {
      FlxG.camera.follow(currentStage.getDad(), null, 0.05);
    }
    else
    {
      FlxG.camera.follow(currentStage.getGirlfriend(), null, 0.05);
    }

    // TODO: Make target offset configurable.
    // In the meantime, we have to replace the zoom animation with a fade out.
    FlxG.camera.targetOffset.y -= 350;
    FlxG.camera.targetOffset.x += 20;

    // Replace zoom animation with a fade out for now.
    FlxG.camera.fade(FlxColor.BLACK, 0.6);

    FlxTween.tween(camHUD, {alpha: 0}, 0.6,
      {
        onComplete: function(_) {
          moveToResultsScreen(isNewHighscore, prevScoreData);
        }
      });

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
      // TODO: Re-enable this.
      /*
          FlxTween.tween(FlxG.camera, {zoom: 1200}, 1.1,
            {
              ease: FlxEase.expoIn,
            });
         */
    });
  }

  /**
     * Move to the results screen right goddamn now.
     */
  function moveToResultsScreen(isNewHighscore:Bool, ?prevScoreData:SaveScoreData):Void
  {
    persistentUpdate = false;
    vocals.stop();
    camHUD.alpha = 1;

    var talliesToUse:Tallies = PlayStatePlaylist.isStoryMode ? Highscore.talliesLevel : Highscore.tallies;

    var res:ResultState = new ResultState(
      {
        storyMode: PlayStatePlaylist.isStoryMode,
        songId: currentChart.song.id,
        difficultyId: currentDifficulty,
        characterId: currentChart.characters.player,
        title: PlayStatePlaylist.isStoryMode ? ('${PlayStatePlaylist.campaignTitle}') : ('${currentChart.songName} by ${currentChart.songArtist}'),
        prevScoreData: prevScoreData,
        scoreData:
          {
            score: PlayStatePlaylist.isStoryMode ? PlayStatePlaylist.campaignScore : songScore,
            tallies:
              {
                sick: talliesToUse.sick,
                good: talliesToUse.good,
                bad: talliesToUse.bad,
                shit: talliesToUse.shit,
                missed: talliesToUse.missed,
                combo: talliesToUse.combo,
                maxCombo: talliesToUse.maxCombo,
                totalNotesHit: talliesToUse.totalNotesHit,
                totalNotes: talliesToUse.totalNotes,
              },
          },
        isNewHighscore: isNewHighscore
      });
    this.persistentDraw = false;
    openSubState(res);
  }

  /**
     * Pauses music and vocals easily.
     */
  public function pauseMusic():Void
  {
    if (FlxG.sound.music != null) FlxG.sound.music.pause();
    if (vocals != null) vocals.pause();
  }

  /**
     * Resets the camera's zoom level and focus point.
     */
  public function resetCamera(?resetZoom:Bool = true, ?cancelTweens:Bool = true):Void
  {
    // Cancel camera tweens if any are active.
    if (cancelTweens)
    {
      cancelAllCameraTweens();
    }

    FlxG.camera.follow(cameraFollowPoint, LOCKON, Constants.DEFAULT_CAMERA_FOLLOW_RATE);
    FlxG.camera.targetOffset.set();

    if (resetZoom)
    {
      resetCameraZoom();
    }

    // Snap the camera to the follow point immediately.
    FlxG.camera.focusOn(cameraFollowPoint.getPosition());
  }

  /**
     * Sets the camera follow point's position and tweens the camera there.
     */
  public function tweenCameraToPosition(?x:Float, ?y:Float, ?duration:Float, ?ease:Null<Float->Float>):Void
  {
    cameraFollowPoint.setPosition(x, y);
    tweenCameraToFollowPoint(duration, ease);
  }

  /**
     * Disables camera following and tweens the camera to the follow point manually.
     */
  public function tweenCameraToFollowPoint(?duration:Float, ?ease:Null<Float->Float>):Void
  {
    // Cancel the current tween if it's active.
    cancelCameraFollowTween();

    if (duration == 0)
    {
      // Instant movement. Just reset the camera to force it to the follow point.
      resetCamera(false, false);
    }
    else
    {
      // Disable camera following for the duration of the tween.
      FlxG.camera.target = null;

      // Follow tween! Caching it so we can cancel/pause it later if needed.
      var followPos:FlxPoint = cameraFollowPoint.getPosition() - FlxPoint.weak(FlxG.camera.width * 0.5, FlxG.camera.height * 0.5);
      cameraFollowTween = FlxTween.tween(FlxG.camera.scroll, {x: followPos.x, y: followPos.y}, duration,
        {
          ease: ease,
          onComplete: function(_) {
            resetCamera(false, false); // Re-enable camera following when the tween is complete.
          }
        });
    }
  }

  public function cancelCameraFollowTween()
  {
    if (cameraFollowTween != null)
    {
      cameraFollowTween.cancel();
    }
  }

  /**
     * Tweens the camera zoom to the desired amount.
     */
  public function tweenCameraZoom(?zoom:Float, ?duration:Float, ?direct:Bool, ?ease:Null<Float->Float>):Void
  {
    // Cancel the current tween if it's active.
    cancelCameraZoomTween();

    // Direct mode: Set zoom directly.
    // Stage mode: Set zoom as a multiplier of the current stage's default zoom.
    var targetZoom = zoom * (direct ? FlxCamera.defaultZoom : stageZoom);

    if (duration == 0)
    {
      // Instant zoom. No tween needed.
      currentCameraZoom = targetZoom;
    }
    else
    {
      // Zoom tween! Caching it so we can cancel/pause it later if needed.
      cameraZoomTween = FlxTween.tween(this, {currentCameraZoom: targetZoom}, duration, {ease: ease});
    }
  }

  public function cancelCameraZoomTween()
  {
    if (cameraZoomTween != null)
    {
      cameraZoomTween.cancel();
    }
  }

  /**
     * Cancel all active camera tweens simultaneously.
     */
  public function cancelAllCameraTweens()
  {
    cancelCameraFollowTween();
    cancelCameraZoomTween();
  }

  var prevScrollTargets:Array<Dynamic> = []; // used to snap scroll speed when things go unruely

  /**
     * The magical function that shall tween the scroll speed.
     */
  public function tweenScrollSpeed(?speed:Float, ?duration:Float, ?ease:Null<Float->Float>, strumlines:Array<String>):Void
  {
    // Cancel the current tween if it's active.
    cancelScrollSpeedTweens();

    // Snap to previous event value to prevent the tween breaking when another event cancels the previous tween.
    for (i in prevScrollTargets)
    {
      var value:Float = i[0];
      var strum:Strumline = Reflect.getProperty(this, i[1]);
      strum.scrollSpeed = value;
    }

    // for next event, clean array.
    prevScrollTargets = [];

    for (i in strumlines)
    {
      var value:Float = speed;
      var strum:Strumline = Reflect.getProperty(this, i);

      if (duration == 0)
      {
        strum.scrollSpeed = value;
      }
      else
      {
        scrollSpeedTweens.push(FlxTween.tween(strum,
          {
            'scrollSpeed': value
          }, duration, {ease: ease}));
      }
      // make sure charts dont break if the charter is dumb and stupid
      prevScrollTargets.push([value, i]);
    }
  }

  public function cancelScrollSpeedTweens()
  {
    for (tween in scrollSpeedTweens)
    {
      if (tween != null)
      {
        tween.cancel();
      }
    }
    scrollSpeedTweens = [];
  }

  #if FEATURE_DEBUG_FUNCTIONS
  /**
     * Jumps forward or backward a number of sections in the song.
     * Accounts for BPM changes, does not prevent death from skipped notes.
     * @param sections The number of sections to jump, negative to go backwards.
     */
  function changeSection(sections:Int):Void
  {
    // FlxG.sound.music.pause();

    var targetTimeSteps:Float = Conductor.instance.currentStepTime + (Conductor.instance.stepsPerMeasure * sections);
    var targetTimeMs:Float = Conductor.instance.getStepTimeInMs(targetTimeSteps);

    // Don't go back in time to before the song started.
    targetTimeMs = Math.max(0, targetTimeMs);

    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.time = targetTimeMs;
    }

    handleSkippedNotes();
    SongEventRegistry.handleSkippedEvents(songEvents, Conductor.instance.songPosition);
    // regenNoteData(FlxG.sound.music.time);

    Conductor.instance.update(FlxG.sound?.music?.time ?? 0.0);

    resyncVocals();
  }
  #end
}
