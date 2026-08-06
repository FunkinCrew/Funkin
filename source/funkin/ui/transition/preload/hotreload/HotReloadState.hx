package funkin.ui.transition.preload.hotreload;

import flixel.util.typeLimit.NextState;
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
import lime.app.Future;
import polymod.Polymod;

/**
 * State which reloads all the game's data and assets.
 * Use when pressing F5 (to force a hot reload) or when the mod list has updated.
 *
 * Includes a progress bar and a throbber to indicate progress and working status.
 */
@:nullSafety
class HotReloadState extends MusicBeatState
{
  static final BAR_PAD:Int = 16;
  static final BAR_HEIGHT:Int = 24;

  // The state to move to.
  var targetState:Null<NextState> = null;
  // Status.
  var hasStartedLoading:Bool = false;
  var isComplete:Bool = false;
  var transitioning:Bool = false;
  var totalElapsed:Float = 0;
  // Graphical elements
  var progressBar:FunkinSprite;
  var throbber:FunkinSprite;

  public function new(?targetState:NextState)
  {
    super();

    this.targetState = targetState;
    this.progressBar = new FunkinSprite(BAR_PAD, FlxG.height - BAR_HEIGHT - BAR_PAD);

    throbber = new FunkinSprite(0, 0);
  }

  override public function create():Void
  {
    super.create();

    trace('Entered HotReloadState...');
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
    TaskHandler.performSimpleTask(() ->
    {
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

      FunkinAssetCache.instance.forceClearCache();

      trace('  Done!');

      return true;
    }).onComplete((_) ->
      {
        trace('queuePurgeCache.onComplete()');
        // OK now that we've purged the asset cache, we can display the progress bar
        // without the assets for it getting purged while they're in use.
        // NOTE: onComplete() is run in the main thread.
        buildProgressBar();

        updateProgress(1, 10);

        // Start the next step.
        queueLoadEnabledMods();
      });
  }

  /**
   * Step 2. Forcibly clear the script and module cache so they can be reloaded once mods are loaded.
   * Then, initialize mods.
   */
  function queueLoadEnabledMods():Void
  {
    trace('Queue task: Load enabled mods...');

    TaskHandler.performSimpleTask(() ->
    {
      ModuleHandler.clearModuleCache();
      Polymod.clearScripts();

      funkin.modding.PolymodHandler.loadEnabledMods();

      // This task needs to be done immediately after changing the modlist.
      FunkinAssetCache.instance.cacheAssetLists(true);

      return true;
    }).onComplete((_) ->
      {
        updateProgress(2, 10);

        queueLoadScripts();
      });
  }

  /**
   * Step 3. Asynchronously load scripts from base game and all enabled mods.
   */
  function queueLoadScripts():Void
  {
    trace('Queue task: Async load scripts...');

    var scriptFuture = funkin.modding.PolymodHandler.loadScripts(true);

    scriptFuture.onComplete((_result) ->
    {
      trace('Script loading complete');

      updateProgress(3, 10);

      // Load registry data asynchronously.
      queueLoadRegistryData();
    });
  }

  /**
   * Step 4. Asynchronously load registry data from base game and all enabled mods.
   */
  function queueLoadRegistryData():Void
  {
    trace('Queue task: Async load registry data...');

    var futures:Array<Future<LoadEntriesResult>> = [];

    // All of these create task which can be performed in parallel. Beautiful.

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

    var registryFuture = lime.app.Promises.allSettled(futures);

    registryFuture.onProgress((loaded:Int, total:Int) ->
    {
      trace('Registry loading completed: $loaded/$total');
      updateProgress(loaded, total);
    });

    registryFuture.onComplete((_) ->
    {
      updateProgress(10, 10);

      queueLoadAdditionalData();
    });
  }

  /**
   * Step 5. Load additional data that is not part of the registry system.
   */
  function queueLoadAdditionalData():Void
  {
    trace('Queue task: Load additional data...');

    TaskHandler.performSimpleTask(() ->
    {
      // These use the registry system (sorta) but need more work to support async loading.
      SongRegistry.instance.loadEntries();
      CharacterDataParser.loadCharacterCache();

      // These don't use the registry system at all, they're synchronous but fairly quick.
      SongEventRegistry.loadEventCache();
      NoteKindManager.initialize();

      // Load and initialize modules.
      // We do this only once everything else is done.
      ModuleHandler.loadModuleCache();
      ModuleHandler.callOnCreate();

      return true;
    }).onComplete((_) ->
      {
        // We can move to the title state next frame.
        updateProgress(10, 10);
        isComplete = true;
      });
  }

  /**
   * Move to the title screen state once we are done with the hot reload.
   */
  function moveToTitleState():Void
  {
    if (transitioning) return;

    trace('Transitioning to title state...');
    transitioning = true;

    if (targetState != null)
    {
      FlxG.switchState(targetState);
    }
    else if (InitState.customTitleState == null)
    {
      FlxG.switchState(() -> new TitleState());
    }
    else
    {
      FlxG.switchState(() -> InitState.customTitleState);
    }
  }
}
