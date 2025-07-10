package funkin;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.TransitionData;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.debug.log.LogStyle;
import flixel.util.FlxColor;
import funkin.graphics.FunkinSprite;
import funkin.data.dialogue.conversation.ConversationRegistry;
import funkin.data.dialogue.dialoguebox.DialogueBoxRegistry;
import funkin.data.dialogue.speaker.SpeakerRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.modding.module.ModuleHandler;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.play.PlayStatePlaylist;
import funkin.ui.debug.charting.ChartEditorState;
import funkin.ui.debug.stageeditor.StageEditorState;
import funkin.ui.title.TitleState;
import funkin.ui.transition.LoadingState;
import funkin.util.CLIUtil;
import funkin.util.CLIUtil.CLIParams;
import funkin.util.macro.MacroUtil;
import funkin.util.TrackerUtil;
import funkin.util.WindowUtil;
import openfl.display.BitmapData;
#if FEATURE_DISCORD_RPC
import funkin.api.discord.DiscordClient;
#end
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.NewgroundsClient;
#end

/**
 * A core class which performs initialization of the game.
 * The initialization state has several functions:
 * - Calls code to set up the game, including loading saves and parsing game data.
 * - Chooses whether to start via debug or via launching normally.
 *
 * It should not contain any sprites or rendering.
 */
@:nullSafety
class InitState extends FlxState
{
  /**
   * Perform a bunch of game setup, then immediately transition to the title screen.
   */
  public override function create():Void
  {
    // Setup a bunch of important Flixel stuff.
    setupShit();

    // Load player options from save data.
    // Flixel has already loaded the save data, so we can just use it.
    Preferences.init();

    // Load controls from save data.
    PlayerSettings.init();

    startGame();
  }

  /**
   * Setup a bunch of important Flixel stuff.
   */
  function setupShit():Void
  {
    //
    // GAME SETUP
    //

    // Setup window events (like callbacks for onWindowClose)
    // and fullscreen keybind setup
    WindowUtil.initWindowEvents();
    // Disable the thing on Windows where it tries to send a bug report to Microsoft because why do they care?
    WindowUtil.disableCrashHandler();

    #if FEATURE_DEBUG_TRACY
    funkin.util.WindowUtil.initTracy();
    #end

    #if FEATURE_HAPTICS
    // Setup Haptic feedback
    extension.haptics.Haptic.initialize();
    #end

    #if FEATURE_MOBILE_ADVERTISEMENTS
    // Setup Admob
    funkin.mobile.util.AdMobUtil.init();
    #end

    #if FEATURE_MOBILE_IAP
    // Setup In-App purchases
    funkin.mobile.util.InAppPurchasesUtil.init();
    #end

    #if FEATURE_MOBILE_IAR
    // Setup In-App purchases
    funkin.mobile.util.InAppReviewUtil.init();
    #end

    #if ios
    // Setup Audio session
    funkin.mobile.external.ios.AudioSession.initialize();
    #end

    // This ain't a pixel art game! (most of the time)
    FlxSprite.defaultAntialiasing = true;

    // Disable default keybinds for volume (we manually control volume in MusicBeatState with custom binds)
    FlxG.sound.volumeUpKeys = [];
    FlxG.sound.volumeDownKeys = [];
    FlxG.sound.muteKeys = [];

    // A small jumpstart to the soundtray, it usually sets itself to inactive (somewhere...)
    // but that makes our soundtray not show up on init if we have the game muted.
    // We set it to active so it at least calls it's update function once (see FlxGame.onEnterFrame(), it's called there)
    // and also see FunkinSoundTray.update() to see what we do and how we check if we are muted or not
    #if !mobile
    FlxG.game.soundTray.active = true;
    #end

    // Set the game to a lower frame rate while it is in the background.
    FlxG.game.focusLostFramerate = 30;

    // Makes Flixel use frame times instead of locked movements per frame for things like tweens
    FlxG.fixedTimestep = false;

    setupFlixelDebug();

    //
    // FLIXEL TRANSITIONS
    //

    // Diamond Transition
    var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
    diamond.persist = true;
    diamond.destroyOnNoUse = false;

    // NOTE: tileData is ignored if TransitionData.type is FADE instead of TILES.
    var tileData:TransitionTileData = {asset: diamond, width: 32, height: 32};

    FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), tileData,
      new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
    FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), tileData,
      new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
    // Don't play transition in when entering the title state.
    FlxTransitionableState.skipNextTransIn = true;

    FlxG.signals.gameResized.add(function(width:Int, height:Int) {
      FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), tileData,
        new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
      FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1), tileData,
        new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
    });

    // SDL for some reason enables VSync on focus lost/gained in Android
    // Since we don't really need VSync on Android we're gonna forcefully disable it on these signals for now
    // This is fixed on SDL3 from what I've heared but that doodoo isn't working poperly for Android
    #if android
    FlxG.signals.focusLost.add(function() {
      WindowUtil.setVSyncMode(lime.ui.WindowVSyncMode.OFF);
    });
    FlxG.signals.focusGained.add(function() {
      WindowUtil.setVSyncMode(lime.ui.WindowVSyncMode.OFF);
    });
    #end

    //
    // NEWGROUNDS API SETUP
    //
    #if FEATURE_NEWGROUNDS
    NewgroundsClient.instance.init();
    #end

    //
    // DISCORD API SETUP
    //
    #if FEATURE_DISCORD_RPC
    DiscordClient.instance.init();

    lime.app.Application.current.onExit.add(function(exitCode) {
      DiscordClient.instance.shutdown();
    });
    #end

    //
    // ANDROID SETUP
    //
    #if android
    FlxG.android.preventDefaultKeys = [flixel.input.android.FlxAndroidKey.BACK];
    funkin.mobile.external.android.CallbackUtil.init();
    #end

    //
    // FLIXEL PLUGINS
    //
    // Plugins provide a useful interface for globally active Flixel objects,
    // that receive update events regardless of the current state.
    // TODO: Move scripted Module behavior to a Flixel plugin.
    #if FEATURE_DEBUG_FUNCTIONS
    funkin.util.plugins.MemoryGCPlugin.initialize();
    #end
    #if FEATURE_SCREENSHOTS
    funkin.util.plugins.ScreenshotPlugin.initialize();
    #end
    #if FEATURE_NEWGROUNDS
    funkin.util.plugins.NewgroundsMedalPlugin.initialize();
    #end
    funkin.util.plugins.EvacuateDebugPlugin.initialize();
    funkin.util.plugins.ForceCrashPlugin.initialize();
    funkin.util.plugins.ReloadAssetsDebugPlugin.initialize();
    #if !mobile
    funkin.util.plugins.VolumePlugin.initialize();
    #end
    funkin.util.plugins.WatchPlugin.initialize();
    #if mobile
    funkin.util.plugins.TouchPointerPlugin.initialize();
    funkin.mobile.input.ControlsHandler.initInputTrackers();
    #end

    //
    // GAME DATA PARSING
    //

    // NOTE: Registries must be imported and not referenced with fully qualified names,
    // to ensure build macros work properly.
    trace('Parsing game data...');
    SongEventRegistry.loadEventCache(); // SongEventRegistry is structured differently so it's not a BaseRegistry.
    SongRegistry.instance.loadEntries();
    LevelRegistry.instance.loadEntries();
    NoteStyleRegistry.instance.loadEntries();
    PlayerRegistry.instance.loadEntries();
    ConversationRegistry.instance.loadEntries();
    DialogueBoxRegistry.instance.loadEntries();
    SpeakerRegistry.instance.loadEntries();
    FreeplayStyleRegistry.instance.loadEntries();
    AlbumRegistry.instance.loadEntries();
    StageRegistry.instance.loadEntries();
    StickerRegistry.instance.loadEntries();

    // TODO: CharacterDataParser doesn't use json2object, so it's way slower than the other parsers and more prone to syntax errors.
    // Move it to use a BaseRegistry.
    CharacterDataParser.loadCharacterCache();

    NoteKindManager.loadScripts();

    ModuleHandler.buildModuleCallbacks();
    ModuleHandler.loadModuleCache();
    ModuleHandler.callOnCreate();

    funkin.input.Cursor.hide();

    #if !html5
    // This fucking breaks on HTML5 builds because the "shared" library isn't loaded yet.
    funkin.FunkinMemory.initialCache();
    #end
  }

  /**
   * Start the game.
   *
   * By default, moves to the `TitleState`.
   * But based on compile defines, the game can start immediately on a specific song,
   * or immediately in a specific debug menu.
   */
  function startGame():Void
  {
    #if SONG
    // -DSONG=bopeebo
    startSong(defineSong(), defineDifficulty());
    #elseif LEVEL
    // -DLEVEL=week1 -DDIFFICULTY=hard
    startLevel(defineLevel(), defineDifficulty());
    #elseif FREEPLAY
    // -DFREEPLAY
    FlxG.switchState(() -> new funkin.ui.freeplay.FreeplayState());
    #elseif DIALOGUE
    // -DDIALOGUE
    FlxG.switchState(() -> new funkin.ui.debug.dialogue.ConversationDebugState());
    #elseif ANIMATE
    // -DANIMATE
    FlxG.switchState(() -> new funkin.ui.debug.anim.FlxAnimateTest());
    #elseif WAVEFORM
    // -DWAVEFORM
    FlxG.switchState(() -> new funkin.ui.debug.WaveformTestState());
    #elseif CHARTING
    // -DCHARTING
    FlxG.switchState(() -> new funkin.ui.debug.charting.ChartEditorState());
    #elseif STAGING
    // -DSTAGING
    FlxG.switchState(() -> new funkin.ui.debug.stageeditor.StageEditorState());
    #elseif STAGEBUILD
    // -DSTAGEBUILD
    FlxG.switchState(() -> new funkin.ui.debug.stage.StageBuilderState());
    #elseif RESULTS
    // -DRESULTS
    FlxG.switchState(() -> new funkin.play.ResultState(
      {
        storyMode: true,
        title: "Cum Song Erect by Kawai Sprite",
        songId: "cum",
        characterId: "pico",
        difficultyId: "hard",
        isNewHighscore: true,
        scoreData:
          {
            score: 1_234_567,
            tallies:
              {
                sick: 130,
                good: 60,
                bad: 69,
                shit: 69,
                missed: 69,
                combo: 69,
                maxCombo: 69,
                totalNotesHit: 140,
                totalNotes: 240
              }
            // 2400 total notes = 7% = LOSS
            // 275 total notes = 69% = NICE
            // 240 total notes = 79% = GOOD
            // 230 total notes = 82% = GREAT
            // 210 total notes = 91% = EXCELLENT
            // 190 total notes = PERFECT
          },
      }));
    #elseif ANIMDEBUG
    // -DANIMDEBUG
    FlxG.switchState(() -> new funkin.ui.debug.anim.DebugBoundingState());
    #elseif LATENCY
    // -DLATENCY
    FlxG.switchState(() -> new funkin.LatencyState());
    #else
    startGameNormally();
    #end
  }

  /**
   * Start the game by moving to the title state and play the game as normal.
   */
  function startGameNormally():Void
  {
    var params:CLIParams = CLIUtil.processArgs();
    trace('Command line args: ${params}');

    if (params.chart.shouldLoadChart)
    {
      FlxG.switchState(() -> new ChartEditorState(
        {
          fnfcTargetPath: params.chart.chartPath,
        }));
    }
    else if (params.stage.shouldLoadStage)
    {
      FlxG.switchState(() -> new StageEditorState(
        {
          fnfsTargetPath: params.stage.stagePath,
        }));
    }
    else
    {
      // FlxG.sound.cache(Paths.music('freakyMenu/freakyMenu'));
      FlxG.switchState(() -> new TitleState());
    }
  }

  /**
   * Start the game by directly loading into a specific song.
   * @param songId
   * @param difficultyId
   */
  function startSong(songId:String, difficultyId:String = 'normal'):Void
  {
    var songData:Null<funkin.play.song.Song> = funkin.data.song.SongRegistry.instance.fetchEntry(songId);

    if (songData == null)
    {
      startGameNormally();
      return;
    }

    // TODO: Rework loading behavior so we don't have to do this.
    switch (songId)
    {
      case 'tutorial' | 'bopeebo' | 'fresh' | 'dadbattle':
        Paths.setCurrentLevel('week1');
        PlayStatePlaylist.campaignId = 'week1';
      case 'spookeez' | 'south' | 'monster':
        Paths.setCurrentLevel('week2');
        PlayStatePlaylist.campaignId = 'week2';
      case 'pico' | 'philly-nice' | 'blammed':
        Paths.setCurrentLevel('week3');
        PlayStatePlaylist.campaignId = 'week3';
      case 'high' | 'satin-panties' | 'milf':
        Paths.setCurrentLevel('week4');
        PlayStatePlaylist.campaignId = 'week4';
      case 'cocoa' | 'eggnog' | 'winter-horrorland':
        Paths.setCurrentLevel('week5');
        PlayStatePlaylist.campaignId = 'week5';
      case 'senpai' | 'roses' | 'thorns':
        Paths.setCurrentLevel('week6');
        PlayStatePlaylist.campaignId = 'week6';
      case 'ugh' | 'guns' | 'stress':
        Paths.setCurrentLevel('week7');
        PlayStatePlaylist.campaignId = 'week7';
      case 'darnell' | 'lit-up' | '2hot' | 'blazin':
        Paths.setCurrentLevel('weekend1');
        PlayStatePlaylist.campaignId = 'weekend1';
    }

    @:nullSafety(Off) // Cannot unify?
    LoadingState.loadPlayState(
      {
        targetSong: songData,
        targetDifficulty: difficultyId,
      });
  }

  /**
   * Start the game by directly loading into a specific story mode level.
   * @param levelId
   * @param difficultyId
   */
  function startLevel(levelId:String, difficultyId:String = 'normal'):Void
  {
    var currentLevel:Null<funkin.ui.story.Level> = funkin.data.story.level.LevelRegistry.instance.fetchEntry(levelId);

    if (currentLevel == null)
    {
      startGameNormally();
      return;
    }

    // TODO: Rework loading behavior so we don't have to do this.
    Paths.setCurrentLevel(levelId);
    PlayStatePlaylist.campaignId = levelId;

    PlayStatePlaylist.playlistSongIds = currentLevel.getSongs();
    PlayStatePlaylist.isStoryMode = true;
    PlayStatePlaylist.campaignScore = 0;

    var targetSongId:Null<String> = PlayStatePlaylist.playlistSongIds.shift();

    var targetSong:Null<funkin.play.song.Song> = null;

    if (targetSongId != null) targetSong = SongRegistry.instance.fetchEntry(targetSongId);

    if (targetSongId == null)
    {
      startGameNormally();
      return;
    }

    @:nullSafety(Off)
    LoadingState.loadPlayState(
      {
        targetSong: targetSong,
        targetDifficulty: difficultyId,
      });
  }

  @:nullSafety(Off) // Meh, remove when flixel.system.debug.log.LogStyle is null safe
  function setupFlixelDebug():Void
  {
    //
    // FLIXEL DEBUG SETUP
    //
    #if FEATURE_DEBUG_FUNCTIONS
    trace('Initializing Flixel debugger...');

    #if !debug
    // Make errors less annoying on release builds.
    LogStyle.ERROR.openConsole = false;
    LogStyle.ERROR.errorSound = null;
    #end

    // Make errors and warnings less annoying.
    LogStyle.WARNING.openConsole = false;
    LogStyle.WARNING.errorSound = null;

    // Disable using ~ to open the console (we use that for the Editor menu)
    FlxG.debugger.toggleKeys = [F2];
    TrackerUtil.initTrackers();
    // Adds an additional Close Debugger button.
    // This big obnoxious white button is for MOBILE, so that you can press it
    // easily with your finger when debug bullshit pops up during testing lol!
    FlxG.debugger.addButton(LEFT, new BitmapData(200, 200), function() {
      FlxG.debugger.visible = false;

      // Make errors and warnings less annoying.
      // Forcing this always since I have never been happy to have the debugger to pop up
      LogStyle.ERROR.openConsole = false;
      LogStyle.ERROR.errorSound = null;
      LogStyle.WARNING.openConsole = false;
      LogStyle.WARNING.errorSound = null;
    });

    // Adds a red button to the debugger.
    // This pauses the game AND the music! This ensures the Conductor stops.
    FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFFCC2233), function() {
      if (FlxG.vcr.paused)
      {
        FlxG.vcr.resume();

        for (snd in FlxG.sound.list)
        {
          snd.resume();
        }

        FlxG.sound.music.resume();
      }
      else
      {
        FlxG.vcr.pause();

        for (snd in FlxG.sound.list)
        {
          snd.pause();
        }

        FlxG.sound.music.pause();
      }
    });

    // Adds a blue button to the debugger.
    // This skips forward in the song.
    FlxG.debugger.addButton(CENTER, new BitmapData(20, 20, true, 0xFF2222CC), function() {
      FlxG.game.debugger.vcr.onStep();

      for (snd in FlxG.sound.list)
      {
        snd.pause();
        snd.time += FlxG.elapsed * 1000;
      }

      FlxG.sound.music.pause();
      FlxG.sound.music.time += FlxG.elapsed * 1000;
    });
    #end
  }

  function defineSong():Null<String>
  {
    return MacroUtil.getDefine('SONG');
  }

  function defineLevel():Null<String>
  {
    return MacroUtil.getDefine('LEVEL');
  }

  function defineDifficulty():Null<String>
  {
    return MacroUtil.getDefine('DIFFICULTY');
  }
}
