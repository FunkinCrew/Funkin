package funkin.play;

import flixel.addons.transition.FlxTransitionableSubState;
import funkin.ui.debug.charting.ChartEditorState;
import haxe.Int64;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.data.notestyle.NoteStyleData;
import funkin.data.notestyle.NoteStyleRegistry;
import flixel.addons.display.FlxPieDial;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import funkin.audio.VoicesGroup;
import funkin.Highscore.Tallies;
import funkin.input.PreciseInputManager;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.cutscene.dialogue.Conversation;
import funkin.play.cutscene.dialogue.ConversationDataParser;
import funkin.play.cutscene.VanillaCutscenes;
import funkin.play.cutscene.VideoCutscene;
import funkin.play.event.SongEventData.SongEventParser;
import funkin.play.notes.NoteSprite;
import funkin.play.notes.NoteDirection;
import funkin.play.notes.Strumline;
import funkin.play.notes.SustainTrail;
import funkin.play.scoring.Scoring;
import funkin.NoteSplash;
import funkin.play.song.Song;
import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.SongData.SongEventData;
import funkin.play.song.SongData.SongNoteData;
import funkin.play.song.SongData.SongPlayableChar;
import funkin.play.stage.Stage;
import funkin.play.stage.StageData.StageDataParser;
import funkin.ui.PopUpStuff;
import funkin.ui.PreferencesMenu;
import funkin.ui.stageBuildShit.StageOffsetSubState;
import funkin.ui.story.StoryMenuState;
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
  /**
   * Whether the song should start in Practice Mode.
   * @default `false`
   */
  ?practiceMode:Bool,
  /**
   * Whether the song should be in minimal mode.
   * @default `false`
   */
  ?minimalMode:Bool,
  /**
   * If specified, the game will jump to the specified timestamp after the countdown ends.
   */
  ?startTimestamp:Float,
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
   * The player character being used for this level, as a character ID.
   */
  public var currentPlayerId:String = 'bf';

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
   * An empty FlxObject contained in the scene.
   * The current gameplay camera will always follow this object. Tween its position to move the camera smoothly.
   *
   * It needs to be an object in the scene for the camera to be configured to follow it.
   * We optionally make this an FlxSprite so we can draw a debug graphic with it.
   */
  public var cameraFollowPoint:FlxObject;

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

  public var startTimestamp:Float = 0.0;

  public var isSubState(get, null):Bool;

  function get_isSubState():Bool
  {
    return this._parentState != null;
  }

  public var isChartingMode(get, null):Bool;

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

  #if discord_rpc
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
   * The camera which contains, and controls visibility of, a video cutscene.
   */
  public var camCutscene:FlxCamera;

  /**
   * The combo popups. Includes the real-time combo counter and the rating.
   */
  var comboPopUps:PopUpStuff;

  /**
   * The circular sprite that appears while the user is holding down the Skip Cutscene button.
   */
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

  /**
   * Data for the current difficulty for the current song.
   * Includes chart data, scroll speed, and other information.
   */
  public var currentChart(get, null):SongDifficulty;

  function get_currentChart():SongDifficulty
  {
    if (currentSong == null || currentDifficulty == null) return null;
    return currentSong.getDifficulty(currentDifficulty);
  }

  /**
   * The internal ID of the currently active Stage.
   * Used to retrieve the data required to build the `currentStage`.
   */
  public var currentStageId(get, null):String;

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
  var perfectMode:Bool = false;

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
    if (params.targetCharacter != null) currentPlayerId = params.targetCharacter;
    isPracticeMode = params.practiceMode ?? false;
    isMinimalMode = params.minimalMode ?? false;
    startTimestamp = params.startTimestamp ?? 0.0;

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

    NoteSplash.buildSplashFrames();

    // Returns null if the song failed to load or doesn't have the selected difficulty.
    if (currentSong == null || currentChart == null)
    {
      // We have encountered a critical error. Prevent Flixel from trying to run any gameplay logic.
      criticalFailure = true;

      // Choose an error message.
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

      // Display a popup. This blocks the application until the user clicks OK.
      lime.app.Application.current.window.alert(message, 'Error loading PlayState');

      // Force the user back to the main menu.
      if (isSubState)
      {
        this.close();
      }
      else
      {
        FlxG.switchState(new MainMenuState());
      }
      return;
    }

    if (false)
    {
      // Displays the camera follow point as a sprite for debug purposes.
      cameraFollowPoint = new FlxSprite(0, 0).makeGraphic(8, 8, 0xFF00FF00);
      cameraFollowPoint.visible = false;
      cameraFollowPoint.zIndex = 1000000;
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
    if (FlxG.sound.music != null) FlxG.sound.music.stop();

    // Prepare the current song's instrumental and vocals to be played.
    if (currentChart != null)
    {
      currentChart.cacheInst(currentPlayerId);
      currentChart.cacheVocals(currentPlayerId);
    }

    // Prepare the Conductor.
    Conductor.mapTimeChanges(currentChart.timeChanges);
    Conductor.update((Conductor.beatLengthMs * -5) + startTimestamp);

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

    // Initialize the judgements and combo meter.
    comboPopUps = new PopUpStuff();
    comboPopUps.cameras = [camHUD];
    add(comboPopUps);

    // The little dial that shows up when you hold the Skip Cutscene key.
    skipTimer = new FlxPieDial(16, 16, 32, FlxColor.WHITE, 36, CIRCLE, true, 24);
    skipTimer.amount = 0;
    skipTimer.zIndex = 1000;
    add(skipTimer);
    // Renders only in video cutscene mode.
    skipTimer.cameras = [camCutscene];

    #if discord_rpc
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
    if ((currentSong?.songId ?? '').toLowerCase() == 'winter-horrorland')
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
    #if debug
    // Display the version number (and git commit hash) in the bottom right corner.
    this.rightWatermarkText.text = Constants.VERSION;

    FlxG.console.registerObject('playState', this);
    #end
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
      FlxG.sound.music.time = (startTimestamp);
      vocals.time = 0;

      FlxG.sound.music.volume = 1;
      vocals.volume = 1;
      vocals.playerVolume = 1;
      vocals.opponentVolume = 1;

      if (currentStage != null) currentStage.resetStage();

      playerStrumline.vwooshNotes();
      opponentStrumline.vwooshNotes();

      playerStrumline.clean();
      opponentStrumline.clean();

      // Delete all notes and reset the arrays.
      regenNoteData();

      // Reset camera zooming
      cameraZoomIntensity = Constants.DEFAULT_ZOOM_INTENSITY;
      hudCameraZoomIntensity = Constants.DEFAULT_ZOOM_INTENSITY * 2.0;
      cameraZoomRate = Constants.DEFAULT_ZOOM_RATE;

      health = Constants.HEALTH_STARTING;
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
        Conductor.update(Conductor.songPosition + elapsed * 1000);
        if (Conductor.songPosition >= startTimestamp) startSong();
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
        // Interpolation type beat
        if (Conductor.lastSongPos != Conductor.songPosition)
        {
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
        if (!isSubState && event.gitaroo)
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

          var pauseSubState:FlxSubState = new PauseSubState(isChartingMode);

          FlxTransitionableSubState.skipNextTransIn = true;
          FlxTransitionableSubState.skipNextTransOut = true;
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
    if (health > Constants.HEALTH_MAX) health = Constants.HEALTH_MAX;
    if (health < Constants.HEALTH_MIN) health = Constants.HEALTH_MIN;

    // Lerp the camera zoom towards the target level.
    if (subState == null)
    {
      FlxG.camera.zoom = FlxMath.lerp(defaultCameraZoom, FlxG.camera.zoom, 0.95);
      camHUD.zoom = FlxMath.lerp(defaultHUDCameraZoom, camHUD.zoom, 0.95);
    }

    if (currentStage != null)
    {
      FlxG.watch.addQuick('bfAnim', currentStage.getBoyfriend().getCurrentAnimation());
    }

    if (currentStage.getBoyfriend() != null)
    {
      FlxG.watch.addQuick('bfCameraFocus', currentStage.getBoyfriend().cameraFocusPoint);
    }

    if (currentStage.getDad() != null)
    {
      FlxG.watch.addQuick('dadCameraFocus', currentStage.getDad().cameraFocusPoint);
    }

    // TODO: Add a song event for Handle GF dance speed.

    // Handle player death.
    if (!isInCutscene && !disableKeys && !_exiting)
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

      if (health <= Constants.HEALTH_MIN && !isPracticeMode)
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
        FlxTransitionableSubState.skipNextTransIn = true;
        FlxTransitionableSubState.skipNextTransOut = true;
        openSubState(gameOverSubState);

        #if discord_rpc
        // Game Over doesn't get his own variable because it's only used here
        DiscordClient.changePresence('Game Over - ' + detailsText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
        #end
      }
    }

    // Query and activate song events.
    // TODO: Check that these work even when songPosition is less than 0.
    if (songEvents != null && songEvents.length > 0)
    {
      var songEventsToActivate:Array<SongEventData> = SongEventParser.queryEvents(songEvents, Conductor.songPosition);

      if (songEventsToActivate.length > 0)
      {
        trace('Found ${songEventsToActivate.length} event(s) to activate.');
        for (event in songEventsToActivate)
        {
          // If an event is trying to play, but it's over 5 seconds old, skip it.
          if (event.time - Conductor.songPosition < -5000)
          {
            event.activated = true;
            continue;
          };

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
    // if (!isInCutscene && !disableKeys) keyShit(true);
    processInputQueue();
    if (!isInCutscene && !disableKeys) debugKeyShit();
    if (isInCutscene && !disableKeys) handleCutsceneKeys(elapsed);

    // Moving notes into position is now done by Strumline.update().
    processNotes(elapsed);

    // Dispatch the onUpdate event to scripted elements.
    dispatchEvent(new UpdateScriptEvent(elapsed));
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    // ORDER: Module, Stage, Character, Song, Conversation, Note
    // Modules should get the first chance to cancel the event.

    // super.dispatchEvent(event) dispatches event to module scripts.
    super.dispatchEvent(event);

    // Dispatch event to stage script.
    ScriptEventDispatcher.callEvent(currentStage, event);

    // Dispatch event to character script(s).
    if (currentStage != null) currentStage.dispatchToCharacters(event);

    // Dispatch event to song script.
    ScriptEventDispatcher.callEvent(currentSong, event);

    // Dispatch event to conversation script.
    ScriptEventDispatcher.callEvent(currentConversation, event);

    // TODO: Dispatch event to note scripts
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

      // Resume
      FlxG.sound.music.play();

      if (FlxG.sound.music != null && !startingSong && !isInCutscene) resyncVocals();

      // Resume the countdown.
      Countdown.resumeCountdown();

      #if discord_rpc
      if (startTimer.finished)
      {
        DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC, true,
          currentSongLengthMs - Conductor.songPosition);
      }
      else
      {
        DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC);
      }
      #end
    }

    super.closeSubState();
  }

  #if discord_rpc
  /**
   * Function called when the game window gains focus.
   */
  public override function onFocus():Void
  {
    if (health > Constants.HEALTH_MIN && !paused && FlxG.autoPause)
    {
      if (Conductor.songPosition > 0.0) DiscordClient.changePresence(detailsText, currentSong.song
        + ' ('
        + storyDifficultyText
        + ')', iconRPC, true,
        currentSongLengthMs
        - Conductor.songPosition);
      else
        DiscordClient.changePresence(detailsText, currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);
    }

    super.onFocus();
  }

  /**
   * Function called when the game window loses focus.
   */
  public override function onFocusLost():Void
  {
    if (health > Constants.HEALTH_MIN && !paused && FlxG.autoPause) DiscordClient.changePresence(detailsPausedText,
      currentSong.song + ' (' + storyDifficultyText + ')', iconRPC);

    super.onFocusLost();
  }
  #end

  /**
   * This function is called whenever Flixel switches switching to a new FlxState.
   * @return Whether to actually switch to the new state.
   */
  @:haxe.warning("-WDeprecated")
  override function switchTo(nextState:FlxState):Bool
  {
    var result:Bool = super.switchTo(nextState);

    if (result)
    {
      performCleanup();
    }

    return result;
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
    // Prevent further gameplay updates, which will try to reference dead objects.
    criticalFailure = true;

    // Remove the current stage. If the stage gets deleted while it's still in use,
    // it'll probably crash the game or something.
    if (this.currentStage != null)
    {
      remove(currentStage);
      var event:ScriptEvent = new ScriptEvent(ScriptEvent.DESTROY, false);
      ScriptEventDispatcher.callEvent(currentStage, event);
      currentStage = null;
    }

    // Stop the instrumental.
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.stop();
    }

    // Stop the vocals.
    if (vocals != null && vocals.exists)
    {
      vocals.stop();
    }

    super.debug_refreshModules();

    var event:ScriptEvent = new ScriptEvent(ScriptEvent.CREATE, false);
    ScriptEventDispatcher.callEvent(currentSong, event);
  }

  override function stepHit():Bool
  {
    if (criticalFailure) return false;

    // super.stepHit() returns false if a module cancelled the event.
    if (!super.stepHit()) return false;

    if (isGamePaused) return false;

    if (!startingSong
      && FlxG.sound.music != null
      && (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 200
        || Math.abs(vocals.checkSyncError(Conductor.songPosition - Conductor.offset)) > 200))
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
    if (criticalFailure) return false;

    // super.beatHit() returns false if a module cancelled the event.
    if (!super.beatHit()) return false;

    if (isGamePaused) return false;

    if (generatedMusic)
    {
      // TODO: Sort more efficiently, or less often, to improve performance.
      // activeNotes.sort(SortUtil.byStrumtime, FlxSort.DESCENDING);
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
      var animShit:ComboMilestone = new ComboMilestone(-100, 300, Highscore.tallies.combo);
      animShit.scrollFactor.set(0.6, 0.6);
      animShit.cameras = [camHUD];
      add(animShit);

      var frameShit:Float = (1 / 24) * 2; // equals 2 frames in the animation

      new FlxTimer().start(((Conductor.beatLengthMs / 1000) * 1.25) - frameShit, function(tmr) {
        animShit.forceFinish();
      });
    }

    if (playerStrumline != null) playerStrumline.onBeatHit();
    if (opponentStrumline != null) opponentStrumline.onBeatHit();

    // Make the characters dance on the beat
    danceOnBeat();

    return true;
  }

  override function destroy():Void
  {
    if (currentConversation != null)
    {
      remove(currentConversation);
      currentConversation.kill();
    }

    super.destroy();
  }

  /**
   * Handles characters dancing to the beat of the current song.
   *
   * TODO: Move some of this logic into `Bopper.hx`, or individual character scripts.
   */
  function danceOnBeat():Void
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
   * Initializes the game and HUD cameras.
   */
  function initCameras():Void
  {
    camGame = new SwagCamera();
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

    // The score text below the health bar.
    scoreText = new FlxText(healthBarBG.x + healthBarBG.width - 190, healthBarBG.y + 30, 0, '', 20);
    scoreText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    scoreText.scrollFactor.set();
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
    var menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
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

  /**
   * Generates the character sprites and adds them to the stage.
   */
  function initCharacters():Void
  {
    if (currentSong == null || currentChart == null)
    {
      trace('Song difficulty could not be loaded.');
    }

    // Switch the character we are playing as by manipulating currentPlayerId.
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

    //
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
    iconP2 = new HealthIcon('dad', 1);
    iconP2.y = healthBar.y - (iconP2.height / 2);
    dad.initHealthIcon(true); // Apply the character ID here
    add(iconP2);
    iconP2.cameras = [camHUD];

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
    iconP1 = new HealthIcon('bf', 0);
    iconP1.y = healthBar.y - (iconP1.height / 2);
    boyfriend.initHealthIcon(false); // Apply the character ID here
    add(iconP1);
    iconP1.cameras = [camHUD];

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
   * Constructs the strumlines for each player.
   */
  function initStrumlines():Void
  {
    var noteStyleId:String = switch (currentStageId)
    {
      case 'school': 'pixel';
      case 'schoolEvil': 'pixel';
      default: 'funkin';
    }
    var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();

    playerStrumline = new Strumline(noteStyle, true);
    opponentStrumline = new Strumline(noteStyle, false);
    add(playerStrumline);
    add(opponentStrumline);

    // Position the player strumline on the right half of the screen
    playerStrumline.x = FlxG.width / 2 + Constants.STRUMLINE_X_OFFSET; // Classic style
    // playerStrumline.x = FlxG.width - playerStrumline.width - Constants.STRUMLINE_X_OFFSET; // Centered style
    playerStrumline.y = PreferencesMenu.getPref('downscroll') ? FlxG.height - playerStrumline.height - Constants.STRUMLINE_Y_OFFSET : Constants.STRUMLINE_Y_OFFSET;
    playerStrumline.zIndex = 200;
    playerStrumline.cameras = [camHUD];

    // Position the opponent strumline on the left half of the screen
    opponentStrumline.x = Constants.STRUMLINE_X_OFFSET;
    opponentStrumline.y = PreferencesMenu.getPref('downscroll') ? FlxG.height - opponentStrumline.height - Constants.STRUMLINE_Y_OFFSET : Constants.STRUMLINE_Y_OFFSET;
    opponentStrumline.zIndex = 100;
    opponentStrumline.cameras = [camHUD];

    if (!PlayStatePlaylist.isStoryMode)
    {
      playerStrumline.fadeInArrows();
      opponentStrumline.fadeInArrows();
    }

    this.refresh();
  }

  /**
   * Initializes the Discord Rich Presence.
   */
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

  function initPreciseInputs():Void
  {
    FlxG.keys.preventDefaultKeys = [];
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

    Conductor.forceBPM(currentChart.getStartingBPM());

    vocals = currentChart.buildVocals(currentPlayerId);
    if (vocals.members.length == 0)
    {
      trace('WARNING: No vocals found for this song.');
    }

    regenNoteData();

    generatedMusic = true;
  }

  /**
   * Read note data from the chart and generate the notes.
   */
  function regenNoteData(startTime:Float = 0):Void
  {
    Highscore.tallies.combo = 0;
    Highscore.tallies = new Tallies();

    // Reset song events.
    songEvents = currentChart.getEvents();
    SongEventParser.resetEvents(songEvents);

    // Reset the notes on each strumline.
    var playerNoteData:Array<SongNoteData> = [];
    var opponentNoteData:Array<SongNoteData> = [];

    for (songNote in currentChart.notes)
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
        case 1:
          opponentNoteData.push(songNote);
      }
    }

    playerStrumline.applyNoteData(playerNoteData);
    opponentStrumline.applyNoteData(opponentNoteData);
  }

  /**
   * Prepares to start the countdown.
   * Ends any running cutscenes, creates the strumlines, and starts the countdown.
   * This is public so that scripts can call it.
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

  /**
   * Displays a dialogue cutscene with the given ID.
   * This is used by song scripts to display dialogue.
   */
  public function startConversation(conversationId:String):Void
  {
    isInCutscene = true;

    currentConversation = ConversationDataParser.fetchConversation(conversationId);
    if (currentConversation == null) return;

    currentConversation.completeCallback = onConversationComplete;
    currentConversation.cameras = [camCutscene];
    currentConversation.zIndex = 1000;
    add(currentConversation);
    refresh();

    var event:ScriptEvent = new ScriptEvent(ScriptEvent.CREATE, false);
    ScriptEventDispatcher.callEvent(currentConversation, event);
  }

  /**
   * Handler function called when a conversation ends.
   */
  function onConversationComplete():Void
  {
    isInCutscene = true;
    remove(currentConversation);
    currentConversation = null;

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
    dispatchEvent(new ScriptEvent(ScriptEvent.SONG_START));

    startingSong = false;

    if (!isGamePaused && currentChart != null)
    {
      currentChart.playInst(1.0, false);
    }

    FlxG.sound.music.onComplete = endSong;
    FlxG.sound.music.play(false, startTimestamp);
    trace('Playing vocals...');
    add(vocals);
    vocals.play();
    resyncVocals();

    #if discord_rpc
    // Updating Discord Rich Presence (with Time Left)
    DiscordClient.changePresence(detailsText, '${currentChart.songName} ($storyDifficultyText)', iconRPC, true, currentSongLengthMs);
    #end

    if (startTimestamp > 0)
    {
      FlxG.sound.music.time = startTimestamp;
      handleSkippedNotes();
    }
  }

  /**
   * Resyncronize the vocal tracks if they have become offset from the instrumental.
   */
  function resyncVocals():Void
  {
    if (_exiting || vocals == null) return;

    // Skip this if the music is paused (GameOver, Pause menu, etc.)
    if (!FlxG.sound.music.playing) return;

    vocals.pause();

    FlxG.sound.music.play();
    Conductor.update();

    vocals.time = FlxG.sound.music.time;
    vocals.play(false, FlxG.sound.music.time);
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

      var hitWindowStart = note.strumTime - Constants.HIT_WINDOW_MS;
      var hitWindowCenter = note.strumTime;
      var hitWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS;

      if (Conductor.songPosition > hitWindowEnd)
      {
        if (note.hasMissed) continue;

        note.tooEarly = false;
        note.mayHit = false;
        note.hasMissed = true;

        if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = true;
      }
      else if (Conductor.songPosition > hitWindowCenter)
      {
        if (note.hasBeenHit) continue;

        // Call an event to allow canceling the note hit.
        // NOTE: This is what handles the character animations!
        var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_HIT, note, 0, true);
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
      else if (Conductor.songPosition > hitWindowStart)
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

      // TODO: Potential penalty for dropping a hold note?
      // if (holdNote.missedNote && !holdNote.handledMiss) { holdNote.handledMiss = true; }
    }

    // Process notes on the player's side.
    for (note in playerStrumline.notes.members)
    {
      if (note == null || note.hasBeenHit) continue;

      var hitWindowStart = note.strumTime - Constants.HIT_WINDOW_MS;
      var hitWindowCenter = note.strumTime;
      var hitWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS;

      if (Conductor.songPosition > hitWindowEnd)
      {
        note.tooEarly = false;
        note.mayHit = false;
        note.hasMissed = true;
        if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = true;
      }
      else if (Conductor.songPosition > hitWindowStart)
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
        var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_MISS, note, 0, true);
        dispatchEvent(event);

        // Calling event.cancelEvent() skips all the other logic! Neat!
        if (event.eventCanceled) continue;

        // Judge the miss.
        // NOTE: This is what handles the scoring.
        trace('Missed note! ${note.noteData}');
        onNoteMiss(note);

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
        health += Constants.HEALTH_HOLD_BONUS_PER_SECOND * elapsed;
      }

      // TODO: Potential penalty for dropping a hold note?
      // if (holdNote.missedNote && !holdNote.handledMiss) { holdNote.handledMiss = true; }
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

      if (Conductor.songPosition > hitWindowEnd)
      {
        // We have passed this note.
        // Flag the note for deletion without actually penalizing the player.
        note.handledMiss = true;
      }
    }

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

    // If there are notes in range, pressing a key will cause a ghost miss.

    var notesByDirection:Array<Array<NoteSprite>> = [[], [], [], []];

    for (note in notesInRange)
      notesByDirection[note.direction].push(note);

    while (inputPressQueue.length > 0)
    {
      var input:PreciseInputEvent = inputPressQueue.shift();

      playerStrumline.pressKey(input.noteDirection);

      var notesInDirection:Array<NoteSprite> = notesByDirection[input.noteDirection];

      if (!Constants.GHOST_TAPPING && notesInDirection.length == 0)
      {
        // Pressed a wrong key with no notes nearby.
        // Perform a ghost miss (anti-spam).
        ghostNoteMiss(input.noteDirection, notesInRange.length > 0);

        // Play the strumline animation.
        playerStrumline.playPress(input.noteDirection);
      }
      else if (Constants.GHOST_TAPPING && (holdNotesInRange.length + notesInRange.length > 0) && notesInDirection.length == 0)
      {
        // Pressed a wrong key with no notes nearby AND with notes in a different direction available.
        // Perform a ghost miss (anti-spam).
        ghostNoteMiss(input.noteDirection, notesInRange.length > 0);

        // Play the strumline animation.
        playerStrumline.playPress(input.noteDirection);
      }
      else if (notesInDirection.length > 0)
      {
        // Choose the first note, deprioritizing low priority notes.
        var targetNote:Null<NoteSprite> = notesInDirection.find((note) -> !note.lowPriority);
        if (targetNote == null) targetNote = notesInDirection[0];
        if (targetNote == null) continue;

        // Judge and hit the note.
        trace('Hit note! ${targetNote.noteData}');
        goodNoteHit(targetNote, input);

        targetNote.visible = false;
        targetNote.kill();
        notesInDirection.remove(targetNote);

        // Play the strumline animation.
        playerStrumline.playConfirm(input.noteDirection);
      }
      else
      {
        // Play the strumline animation.
        playerStrumline.playPress(input.noteDirection);
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

  /**
   * Handle player inputs.
   */
  function keyShit(test:Bool):Void
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

    // if (pressArray.contains(true))
    // {
    //   var lol:Array<Int> = cast pressArray;
    //   inputSpitter.push(Std.int(Conductor.songPosition) + ' ' + lol.join(' '));
    // }

    // HOLDS, check for sustain notes
    if (holdArray.contains(true) && generatedMusic)
    {
      /*
        activeNotes.forEachAlive(function(daNote:Note) {
          if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.data.noteData]) goodNoteHit(daNote);
        });
       */
    }

    // PRESSES, check for note hits
    if (pressArray.contains(true) && generatedMusic)
    {
      Haptic.vibrate(100, 100);

      if (currentStage != null && currentStage.getBoyfriend() != null)
      {
        currentStage.getBoyfriend().holdTimer = 0;
      }

      var possibleNotes:Array<NoteSprite> = []; // notes that can be hit
      var directionList:Array<Int> = []; // directions that can be hit
      var dumbNotes:Array<NoteSprite> = []; // notes to kill later

      for (note in dumbNotes)
      {
        FlxG.log.add('killing dumb ass note at ' + note.noteData.time);
        note.kill();
        // activeNotes.remove(note, true);
        note.destroy();
      }

      possibleNotes.sort((a, b) -> Std.int(a.noteData.time - b.noteData.time));

      if (perfectMode)
      {
        goodNoteHit(possibleNotes[0], null);
      }
      else if (possibleNotes.length > 0)
      {
        for (shit in 0...pressArray.length)
        { // if a direction is hit that shouldn't be
          if (pressArray[shit] && !directionList.contains(shit)) ghostNoteMiss(shit);
        }
        for (coolNote in possibleNotes)
        {
          if (pressArray[coolNote.noteData.getDirection()]) goodNoteHit(coolNote, null);
        }
      }
      else
      {
        // HNGGG I really want to add an option for ghost tapping
        // L + ratio
        for (shit in 0...pressArray.length)
          if (pressArray[shit]) ghostNoteMiss(shit, false);
      }
    }

    if (currentStage == null) return;

    for (keyId => isPressed in pressArray)
    {
      if (playerStrumline == null) continue;

      var dir:NoteDirection = Strumline.DIRECTIONS[keyId];

      if (isPressed && !playerStrumline.isConfirm(dir)) playerStrumline.playPress(dir);
      if (!holdArray[keyId]) playerStrumline.playStatic(dir);
    }
  }

  function goodNoteHit(note:NoteSprite, input:PreciseInputEvent):Void
  {
    var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_HIT, note, Highscore.tallies.combo + 1, true);
    dispatchEvent(event);

    // Calling event.cancelEvent() skips all the other logic! Neat!
    if (event.eventCanceled) return;

    if (!note.isHoldNote)
    {
      Highscore.tallies.combo++;
      Highscore.tallies.totalNotesHit++;

      if (Highscore.tallies.combo > Highscore.tallies.maxCombo) Highscore.tallies.maxCombo = Highscore.tallies.combo;

      popUpScore(note, input);
    }

    playerStrumline.hitNote(note);

    if (note.holdNoteSprite != null)
    {
      playerStrumline.playNoteHoldCover(note.holdNoteSprite);
    }

    vocals.playerVolume = 1;
  }

  /**
   * Called when a note leaves the screen and is considered missed by the player.
   * @param note
   */
  function onNoteMiss(note:NoteSprite):Void
  {
    // a MISS is when you let a note scroll past you!!
    Highscore.tallies.missed++;

    var event:NoteScriptEvent = new NoteScriptEvent(ScriptEvent.NOTE_MISS, note, Highscore.tallies.combo, true);
    dispatchEvent(event);
    // Calling event.cancelEvent() skips all the other logic! Neat!
    if (event.eventCanceled) return;

    health -= Constants.HEALTH_MISS_PENALTY;
    songScore -= 10;

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

  /**
   * Debug keys. Disabled while in cutscenes.
   */
  function debugKeyShit():Void
  {
    #if !debug
    perfectMode = false;
    #else
    if (FlxG.keys.justPressed.H) camHUD.visible = !camHUD.visible;
    #end

    // Eject button
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
    if (FlxG.keys.justPressed.TWO) health += 0.1 * Constants.HEALTH_MAX;

    // 3: Lose 5% health.
    if (FlxG.keys.justPressed.THREE) health -= 0.05 * Constants.HEALTH_MAX;
    #end

    // 7: Move to the charter.
    if (FlxG.keys.justPressed.SEVEN)
    {
      lime.app.Application.current.window.alert("Press ~ on the main menu to get to the editor", 'LOL');
    }

    // 8: Move to the offset editor.
    if (FlxG.keys.justPressed.EIGHT)
    {
      lime.app.Application.current.window.alert("Press ~ on the main menu to get to the editor", 'LOL');
    }

    // 9: Toggle the old icon.
    if (FlxG.keys.justPressed.NINE) iconP1.toggleOldIcon();

    #if debug
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
   * Handles health, score, and rating popups when a note is hit.
   */
  function popUpScore(daNote:NoteSprite, input:PreciseInputEvent):Void
  {
    vocals.playerVolume = 1;

    // Calculate the input latency (do this as late as possible).
    var currentTimestampNs:Int64 = PreciseInputManager.getCurrentTimestamp();
    var inputLatencyMs:Float = haxe.Int64.toInt(currentTimestampNs - input.timestamp) / Constants.NS_PER_MS;
    trace('Input: ${daNote.noteData.getDirectionName()} pressed ${inputLatencyMs}ms ago!');

    // Get the offset and compensate for input latency.
    // Round inward (trim remainder) for consistency.
    var noteDiff:Int = Std.int(Conductor.songPosition - daNote.noteData.time - inputLatencyMs);

    var score = Scoring.scoreNote(noteDiff, PBOT1);
    var daRating = Scoring.judgeNote(noteDiff, PBOT1);

    switch (daRating)
    {
      case 'killer':
        Highscore.tallies.killer += 1;
        health += Constants.HEALTH_KILLER_BONUS;
      case 'sick':
        Highscore.tallies.sick += 1;
        health += Constants.HEALTH_SICK_BONUS;
      case 'good':
        Highscore.tallies.good += 1;
        health += Constants.HEALTH_GOOD_BONUS;
      case 'bad':
        Highscore.tallies.bad += 1;
        health += Constants.HEALTH_BAD_BONUS;
      case 'shit':
        Highscore.tallies.shit += 1;
        health += Constants.HEALTH_SHIT_BONUS;
      case 'miss':
        Highscore.tallies.missed += 1;
        health -= Constants.HEALTH_MISS_PENALTY;
    }

    if (daRating == "sick" || daRating == "killer")
    {
      playerStrumline.playNoteSplash(daNote.noteData.getDirection());
    }

    songScore += score;

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
   * Handle keyboard inputs during cutscenes.
   * This includes advancing conversations and skipping videos.
   * @param elapsed Time elapsed since last game update.
   */
  function handleCutsceneKeys(elapsed:Float):Void
  {
    if (currentConversation != null)
    {
      if (controls.CUTSCENE_ADVANCE) currentConversation?.advanceConversation();

      if (controls.CUTSCENE_SKIP)
      {
        currentConversation?.trySkipConversation(elapsed);
      }
      else
      {
        currentConversation?.trySkipConversation(-1);
      }
    }
    else if (VideoCutscene.isPlaying())
    {
      // This is a video cutscene.

      if (controls.CUTSCENE_SKIP)
      {
        trySkipVideoCutscene(elapsed);
      }
      else
      {
        trySkipVideoCutscene(-1);
      }
    }
  }

  /**
   * Handle logic for the skip timer.
   * If the skip button is being held, pass the amount of time elapsed since last game update.
   * If the skip button has been released, pass a negative number.
   */
  function trySkipVideoCutscene(elapsed:Float):Void
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

  /**
   * End the song. Handle saving high scores and transitioning to the results screen.
   */
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
        FlxG.sound.playMusic(Paths.music('freakyMenu/freakyMenu'));

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

        if (isSubState)
        {
          this.close();
        }
        else
        {
          moveToResultsScreen();
        }
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
      if (isSubState)
      {
        this.close();
      }
      else
      {
        moveToResultsScreen();
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
    if (currentChart != null)
    {
      // TODO: Uncache the song.
    }

    // Stop the music.
    FlxG.sound.music.pause();
    vocals.stop();

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
    var targetDad:Bool = currentStage.getDad() != null && currentStage.getDad().characterId == 'gf';
    var targetBF:Bool = currentStage.getGirlfriend() == null && !targetDad;

    if (targetBF)
    {
      FlxG.camera.follow(currentStage.getBoyfriend(), null, 0.05);
      FlxG.camera.targetOffset.y -= 350;
      FlxG.camera.targetOffset.x += 20;
    }
    else if (targetDad)
    {
      FlxG.camera.follow(currentStage.getDad(), null, 0.05);
      FlxG.camera.targetOffset.y -= 350;
      FlxG.camera.targetOffset.x += 20;
    }
    else
    {
      FlxG.camera.follow(currentStage.getGirlfriend(), null, 0.05);
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

  /**
   * Pauses music and vocals easily.
   */
  public function pauseMusic():Void
  {
    FlxG.sound.music.pause();
    vocals.pause();
  }

  /**
   * Resets the camera's zoom level and focus point.
   */
  public function resetCamera():Void
  {
    FlxG.camera.follow(cameraFollowPoint, LOCKON, 0.04);
    FlxG.camera.targetOffset.set();
    FlxG.camera.zoom = defaultCameraZoom;
    // Snap the camera to the follow point immediately.
    FlxG.camera.focusOn(cameraFollowPoint.getPosition());
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

    var targetTimeSteps:Float = Conductor.currentStepTime + (Conductor.timeSignatureNumerator * Constants.STEPS_PER_BEAT * sections);
    var targetTimeMs:Float = Conductor.getStepTimeInMs(targetTimeSteps);

    FlxG.sound.music.time = targetTimeMs;

    handleSkippedNotes();
    // regenNoteData(FlxG.sound.music.time);

    Conductor.update(FlxG.sound.music.time);

    resyncVocals();
  }
  #end
}
