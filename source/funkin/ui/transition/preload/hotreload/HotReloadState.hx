package funkin.ui.transition.preload.hotreload;

import flixel.util.FlxDestroyUtil;
import flixel.util.typeLimit.NextState;
import funkin.assets.FunkinAssetCache;
import funkin.graphics.FunkinSprite;
import funkin.ui.title.TitleState;
import funkin.util.tasks.TaskHandler;

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

  /**
   * If `true`, only purge and rebuild the asset cache. Mods, scripts and registries are NOT reloaded.
   * For when those were already reloaded by `ModReloader` before getting here, like the mod menu does.
   */
  var ?purgeOnly:Bool;
}

@:nullSafety
class HotReloadState extends MusicBeatState
{
  static final BAR_PAD:Int = 16;
  static final BAR_HEIGHT:Int = 24;

  var onComplete:Null<Void->Void> = null;
  var targetState:Null<NextState> = null;
  var purgeOnly:Bool = false;
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
      this.purgeOnly = params?.purgeOnly ?? false;
    }
    this.progressBar = new FunkinSprite(BAR_PAD, FlxG.height - BAR_HEIGHT - BAR_PAD);
    throbber = new FunkinSprite(0, 0);
  }

  override public function create():Void
  {
    super.create();

    FlxG.keys.enabled = false;

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
      funkin.modding.PolymodErrorHandler.printQueuedErrors();

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
      // Clears PERMANENT assets, you should know.
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

    FunkinAssetCache.instance.clearCoreAssetCache();

    // OK now that we've purged the asset cache, we can display the progress bar
    // without the assets for it getting purged while they're in use.
    // NOTE: onComplete() is run in the main thread.
    buildProgressBar();

    updateProgress(1, 10);

    rebuildSoundTray();

    if (purgeOnly)
    {
      queueRebuildAssetLists();
      return;
    }

    // Start the next step.
    queueLoadEnabledMods();
  }

  /**
   * The only step after purging, if `purgeOnly` is set. Rebuilds the asset lists the purge may have cleared,
   * since mods, scripts and registries were already reloaded.
   */
  function queueRebuildAssetLists():Void
  {
    beginStep('rebuild asset lists');

    TaskHandler.performSimpleTask(() ->
    {
      FunkinAssetCache.instance.cacheAssetLists(true);

      return true;
    }).onComplete((_) -> afterRebuildAssetLists()).onError((error) ->
      {
        reportStepFailed('rebuild asset lists', error);
        afterRebuildAssetLists();
      });
  }

  function afterRebuildAssetLists():Void
  {
    ModReloader.cachePersistentAssets(updateProgress, () ->
    {
      updateProgress(10, 10);
      isComplete = true;
    });
  }

  /**
   * Step 2. Reload the enabled mods, scripts and registries.
   * We can just use the modreloader for this step
   */
  function queueLoadEnabledMods():Void
  {
    ModReloader.reload(updateProgress, () -> isComplete = true);
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

  function beginStep(step:String):Void
  {
    trace('Queue task: $step...');
  }

  function reportStepFailed(step:String, error:Dynamic):Void
  {
    var message:String = 'Hot reload step "$step" failed: $error';

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
    FlxG.keys.enabled = true;
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

      Transition.switchState(targetState, {
        transition: LoadingScreen(Fade(North), Fade(South)),
      });
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
      if (InitState.customTitleState != null)
      {
        Transition.switchState(InitState.customTitleState, {
          assetQuery: InitState.customTitleStateAssetsQuery,
          transition: LoadingScreen(Fade(North), Fade(South)),
        });
        return;
      }

      Transition.switchState(() -> new TitleState(), {
        assetQuery: TitleState.queryAssets,
        transition: LoadingScreen(Fade(North), Fade(South)),
      });
    }
  }
}
