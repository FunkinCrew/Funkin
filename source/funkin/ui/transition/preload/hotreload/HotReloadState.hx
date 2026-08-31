package funkin.ui.transition.preload.hotreload;

import funkin.assets.FunkinAssetCache;
import funkin.data.BaseRegistry.LoadEntriesResult;
import funkin.data.character.CharacterData.CharacterDataParser;
import funkin.data.dialogue.ConversationRegistry;
import funkin.data.dialogue.DialogueBoxRegistry;
import funkin.data.dialogue.SpeakerRegistry;
import funkin.data.event.SongEventRegistry;
import funkin.data.freeplay.album.AlbumRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.data.notestyle.NoteStyleRegistry;
import funkin.data.song.SongRegistry;
import funkin.data.stage.StageRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.graphics.FunkinSprite;
import flixel.util.FlxDestroyUtil;
import funkin.modding.module.ModuleHandler;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.title.TitleState;
import funkin.util.tasks.TaskHandler;
import flixel.util.typeLimit.NextState;
import lime.app.Future;
import polymod.Polymod;

/**
 * State which reloads all the game's data and assets.
 * Use when pressing F5 (to force a hot reload) or when the mod list has updated.
 *
 * Includes a progress bar and a throbber to indicate progress and working status.
 */
typedef HotReloadStateParams =
{
  /**
   * Callback for when hotreloading finishes.
   */
  var ?onComplete:Void->Void;

  /**
   * The state to switch to after hot reloading is complete.
   * If `null`, `HotReloadState` will go to the Title instead unless explicitly specified in `onComplete`
   */
  var ?targetState:NextState;
}

@:nullSafety
class HotReloadState extends MusicBeatState
{
  static final BAR_PAD:Int = 16;
  static final BAR_HEIGHT:Int = 24;

  var onComplete:Null<Void->Void> = null;
  var targetState:Null<NextState> = null;
  // Status.
  var hasStartedLoading:Bool = false;
  var isComplete:Bool = false;
  var transitioning:Bool = false;
  var totalElapsed:Float = 0;
  // Graphical elements
  var progressBar:FunkinSprite;
  var throbber:FunkinSprite;

  public function new(?params:HotReloadStateParams)
  {
    super();
    @:nullSafety(Off)
    {
      this.onComplete = params?.onComplete ?? null;
      this.targetState = params?.targetState ?? null;
    }
    this.progressBar = new FunkinSprite(BAR_PAD, FlxG.height - BAR_HEIGHT - BAR_PAD);
    throbber = new FunkinSprite(0, 0);
  }

  override public function create():Void
  {
    super.create();

    FlxG.plugins.get(funkin.util.plugins.EvacuateDebugPlugin).active = false;
    FlxG.plugins.get(funkin.util.plugins.ReloadAssetsDebugPlugin).active = false;

    // Fix a specific bug where the game tries to render the 0-character long text,
    // fails and shits its pants.
    if (leftWatermarkText != null)
    {
      remove(leftWatermarkText);
      leftWatermarkText = FlxDestroyUtil.destroy(leftWatermarkText);
    }
    if (rightWatermarkText != null)
    {
      remove(rightWatermarkText);
      rightWatermarkText = FlxDestroyUtil.destroy(rightWatermarkText);
    }
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (transitioning) return;

    if (!hasStartedLoading)
    {
      hasStartedLoading = true;

      queuePurgeCache();
    }

    updateThrobber(elapsed);

    if (isComplete)
    {
      #if FEATURE_MULTITHREADING
      funkin.modding.PolymodErrorHandler.printQueuedErrors();
      #end

      moveToTitleState();
    }
  }

  /**
   * Create and display the progress bar visuals.
   * Call this only AFTER assets have been purged.
   */
  function buildProgressBar():Void
  {
    trace('Building progress bar for display...');

    // Build progress bar
    var progressBarBack = new FunkinSprite(0, 0).makeSolidColor(10, 12, 0xFFCCCCCC);
    progressBarBack.zIndex = 100;
    progressBarBack.setGraphicSize(FlxG.width - BAR_PAD - BAR_PAD, BAR_HEIGHT);
    progressBarBack.updateHitbox();
    progressBarBack.x = BAR_PAD;
    progressBarBack.y = FlxG.height - BAR_HEIGHT - BAR_PAD;
    add(progressBarBack);

    progressBar.makeSolidColor(10, 12, Constants.COLOR_PRELOADER_BAR);
    progressBar.zIndex = 200;
    add(progressBar);

    updateProgress(0, 10);

    // You can load textures asynchronously.
    var throbberFuture = throbber.loadTextureAsync(funkin.assets.Paths.image('ui/loading/throbber'), true);
    throbberFuture.onComplete((_) ->
    {
      throbber.setGraphicSize(64, 64);
      throbber.updateHitbox();
      throbber.x = FlxG.width - BAR_PAD - throbber.width;
      throbber.y = FlxG.height - throbber.height - BAR_PAD - BAR_HEIGHT - BAR_PAD;
      add(throbber);
    });
  }

  /**
   * Update the visuals for the spinning throbber.
   * The throbber indicates that work is being done in the background, and the game is not frozen.
   *
   * @param elapsed The time that has elapsed since the last frame.
   */
  function updateThrobber(elapsed:Float):Void
  {
    totalElapsed += elapsed;

    var timesPerSecond:Int = 8;
    var angleSnaps:Int = 12;

    var rotation:Float = Math.floor(totalElapsed * timesPerSecond) % angleSnaps;
    throbber.angle = 360 / angleSnaps * rotation;
  }

  /**
   * Update the visuals for the progress bar.
   *
   * @param loaded The number of items that have been loaded so far.
   * @param total The total number of items that need to be loaded.
   */
  function updateProgress(loaded:Int, total:Int):Void
  {
    var currentProgress:Float = (loaded / total).clamp(0, 1);

    // Update progress bar display.
    var targetWidth:Float = FlxG.width * currentProgress - BAR_PAD - BAR_PAD;

    progressBar.x = BAR_PAD;
    progressBar.setGraphicSize(targetWidth, BAR_HEIGHT);
    progressBar.updateHitbox();
  }

  /**
   * Step 1. Forcibly clear all assets in the `FunkinAssetCache`.
   */
  function queuePurgeCache():Void
  {
    beginStep('purge cache');

    TaskHandler.performSimpleTask(() ->
    {
      FunkinAssetCache.instance.forceClearCache();

      return true;
    }).onComplete((_) -> afterPurgeCache()).onError((error) ->
      {
        reportStepFailed('purge cache', error);
        afterPurgeCache();
      });
  }

  function afterPurgeCache():Void
  {
    trace('queuePurgeCache.onComplete()');
    // OK now that we've purged the asset cache, we can display the progress bar
    // without the assets for it getting purged while they're in use.
    // NOTE: onComplete() is run in the main thread.
    buildProgressBar();

    updateProgress(1, 10);

    rebuildSoundTray();

    // Start the next step.
    queueLoadEnabledMods();
  }

  /**
   * Step 2. Forcibly clear the script and module cache so they can be reloaded once mods are loaded.
   * Then, initialize mods.
   */
  function queueLoadEnabledMods():Void
  {
    beginStep('load enabled mods');

    TaskHandler.performSimpleTask(() ->
    {
      ModuleHandler.clearModuleCache();
      Polymod.clearScripts();

      funkin.modding.PolymodHandler.loadEnabledMods();

      // This task needs to be done immediately after changing the modlist.
      FunkinAssetCache.instance.cacheAssetLists(true);

      return true;
    }).onComplete((_) -> afterLoadEnabledMods()).onError((error) ->
      {
        reportStepFailed('load enabled mods', error);
        afterLoadEnabledMods();
      });
  }

  function afterLoadEnabledMods():Void
  {
    updateProgress(2, 10);

    queueLoadScripts();
  }

  function rebuildSoundTray():Void
  {
    // Since its graphics got destroyed,
    // we have to manually reconstruct the sound tray.
    @:privateAccess
    {
      FlxG.game.removeChild(FlxG.game.soundTray);
      FlxG.game.soundTray = Type.createInstance(FlxG.game._customSoundTray, []);
      FlxG.game.addChild(FlxG.game.soundTray);
    }
  }

  /**
   * Step 3. Asynchronously load scripts from base game and all enabled mods.
   */
  function queueLoadScripts():Void
  {
    beginStep('load scripts');

    var scriptFuture = funkin.modding.PolymodHandler.loadScripts(true);

    scriptFuture.onComplete((_result) -> afterLoadScripts()).onError((error) ->
    {
      reportStepFailed('load scripts', error);
      afterLoadScripts();
    });
  }

  function afterLoadScripts():Void
  {
    trace('Script loading complete');

    updateProgress(3, 10);

    // Load registry data asynchronously.
    queueLoadRegistryData();
  }

  /**
   * Step 4. Asynchronously load registry data from base game and all enabled mods.
   */
  function queueLoadRegistryData():Void
  {
    beginStep('load registry data');

    var futures:Array<Future<LoadEntriesResult>> = [];

    futures.push(SongRegistry.instance.loadEntriesAsync());
    futures.push(LevelRegistry.instance.loadEntriesAsync());
    futures.push(NoteStyleRegistry.instance.loadEntriesAsync());
    futures.push(PlayerRegistry.instance.loadEntriesAsync());
    futures.push(ConversationRegistry.instance.loadEntriesAsync());
    futures.push(DialogueBoxRegistry.instance.loadEntriesAsync());
    futures.push(SpeakerRegistry.instance.loadEntriesAsync());
    futures.push(AlbumRegistry.instance.loadEntriesAsync());
    futures.push(StageRegistry.instance.loadEntriesAsync());
    futures.push(StickerRegistry.instance.loadEntriesAsync());
    futures.push(FreeplayStyleRegistry.instance.loadEntriesAsync());
    futures.push(SongEventRegistry.loadEventCacheAsync());
    futures.push(NoteKindManager.loadNoteKindsAsync());
    futures.push(CharacterDataParser.loadCharacterCacheAsync());
    futures.push(ModuleHandler.loadModuleCacheAsync());

    var registryFuture = lime.app.Promises.allSettled(futures);

    registryFuture.onProgress((loaded:Int, total:Int) ->
    {
      trace('Registry loading completed: $loaded/$total');
      updateProgress(loaded, total);
    });

    registryFuture.onComplete((_) -> afterLoadRegistryData()).onError((error) ->
    {
      reportStepFailed('load registry data', error);
      afterLoadRegistryData();
    });
  }

  function afterLoadRegistryData():Void
  {
    beginStep('module create');

    // Call create() on each module when the future is complte.
    try
    {
      ModuleHandler.callOnCreate();

      updateProgress(10, 10);
    }
    catch (e:Dynamic)
    {
      reportStepFailed('module create', e);
    }
    isComplete = true;
  }

  function beginStep(step:String):Void
  {
    trace('Queue task: $step...');

    funkin.util.logging.CrashHandler.setContext('hot reload: $step');
  }

  function reportStepFailed(step:String, error:Dynamic):Void
  {
    var message:String = 'Hot reload step "$step" failed: $error';

    trace(message);
    FlxG.log.error(message);
  }

  function afterLoadRegistryData():Void
  {
    // Call create() on each module when the future is complte.
    try
    {
      ModuleHandler.callOnCreate();
    }
    catch (error:Dynamic)
    {
      reportStepFailed('module create', error);
    }

    updateProgress(10, 10);

    isComplete = true;
  }

  function reportStepFailed(step:String, error:Dynamic):Void
  {
    var message:String = 'Hot reload step "$step" failed: $error';

    trace(message);
    FlxG.log.error(message);
  }

  /**
   * Move to the title screen state once we are done with the hot reload.
   */
  function moveToTitleState():Void
  {
    if (transitioning) return;

    trace('Transitioning to title state...');
    transitioning = true;

    FlxG.plugins.get(funkin.util.plugins.EvacuateDebugPlugin).active = true;
    FlxG.plugins.get(funkin.util.plugins.ReloadAssetsDebugPlugin).active = true;
    funkin.util.plugins.ReloadAssetsDebugPlugin.hotReloadInProgress = false;
    var postHotReloadCallback = () ->
    {
      var state:Dynamic = cast FlxG.state;
      if (state is MusicBeatState || state is MusicBeatSubState)
      {
        state.onPostHotReload();
      }
    }

    // This'll dispatch after create() is called when the state is created.
    FlxG.signals.postStateSwitch.addOnce(postHotReloadCallback);

    if (targetState != null)
    {
      if (onComplete != null) onComplete();

      FlxG.switchState(targetState);
    }
    else
    {
      if (onComplete != null)
      {
        // Assume `onComplete` handles switching to the next state.
        this.onComplete();
        return;
      }

      // Fallback to TitleState.
      if (InitState.customTitleState == null)
      {
        FlxG.switchState(() -> new TitleState());
      }
      else
      {
        FlxG.switchState(() -> InitState.customTitleState);
      }
    }
  }
}
