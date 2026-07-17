package funkin.ui.transition.preload.hotreload;

import flixel.util.typeLimit.NextState;
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
import funkin.modding.module.ModuleHandler;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.title.TitleState;
import flixel.tweens.FlxTween;
import funkin.graphics.FunkinCamera;
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
  var mainCamera:FunkinCamera;
  var progressBar:FunkinSprite;
  var throbber:FunkinSprite;

  public function new(?targetState:NextState)
  {
    super();

    mainCamera = new FunkinCamera('hotReload');

    this.targetState = targetState;
    this.progressBar = new FunkinSprite(BAR_PAD, FlxG.height - BAR_HEIGHT - BAR_PAD).makeSolidColor(10, 12, Constants.COLOR_PRELOADER_BAR);

    throbber = FunkinSprite.create(Paths.image('ui/loading/throbber'));
  }

  override public function create():Void
  {
    super.create();

    // Set up our own camera to ensure consistent rendering.
    FlxG.cameras.reset(mainCamera);

    // Build progress bar

    var progressBarBack = new FunkinSprite(0, 0).makeSolidColor(10, 12, 0xFFCCCCCC);
    progressBarBack.zIndex = 100;
    progressBarBack.setGraphicSize(FlxG.width - BAR_PAD - BAR_PAD, BAR_HEIGHT);
    progressBarBack.updateHitbox();
    progressBarBack.x = BAR_PAD;
    progressBarBack.y = FlxG.height - BAR_HEIGHT - BAR_PAD;
    add(progressBarBack);

    this.progressBar.zIndex = 200;
    add(progressBar);

    updateProgress(0, 10);

    throbber.setGraphicSize(64, 64);
    throbber.updateHitbox();
    throbber.x = FlxG.width - BAR_PAD - throbber.width;
    throbber.y = FlxG.height - throbber.height - BAR_PAD - BAR_HEIGHT - BAR_PAD;
    add(throbber);

    // Fade the throbber in over a short period.
    throbber.alpha = 0;
    FlxTween.tween(throbber, {
      alpha: 1.0
    }, 0.2);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (transitioning) return;

    if (!hasStartedLoading)
    {
      hasStartedLoading = true;
      clearScripts();

      // TODO: Make this async, then call loadRegistryData in onComplete
      funkin.modding.PolymodHandler.loadEnabledMods();

      var scriptFuture = funkin.modding.PolymodHandler.loadScripts(true);

      scriptFuture.onProgress((loaded:Int, total:Int) ->
      {
        trace('Script loading completed: $loaded/$total');

        updateProgress(loaded, total);
      });

      scriptFuture.onComplete((_result) ->
      {
        trace('Script loading complete');

        var registryFuture = loadRegistryData();

        registryFuture.onProgress((loaded:Int, total:Int) ->
        {
          trace('Registry loading completed: $loaded/$total');

          updateProgress(loaded, total);
        });

        registryFuture.onComplete((_) ->
        {
          loadAdditionalData();

          initModules();

          isComplete = true;
        });
      });
    }

    // Update throbber.
    totalElapsed += elapsed;

    var timesPerSecond:Int = 8;
    var angleSnaps:Int = 12;

    var rotation:Float = Math.floor(totalElapsed * timesPerSecond) % angleSnaps;
    throbber.angle = 360 / angleSnaps * rotation;

    if (isComplete)
    {
      moveToTitleState();
    }
  }

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
   * Forcibly clear scripts so that we can reload them later.
   */
  function clearScripts():Void
  {
    ModuleHandler.clearModuleCache();
    Polymod.clearScripts();
  }

  /**
   * Tell the game to asynchronously load all the registry data.
   *
   * @return A future, which calls `onComplete()` when all the
   */
  function loadRegistryData():Future<Array<Future<LoadEntriesResult>>>
  {
    var futures:Array<Future<LoadEntriesResult>> = [];

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

    return lime.app.Promises.allSettled(futures);
  }

  /**
   * Load additional data, that needs to be loaded synchronously.
   */
  function loadAdditionalData():Void
  {
    // Load additional data that needs to be loaded synchronously
    // TODO: Fix these up to be async, then call them in loadRegistryData.
    SongEventRegistry.loadEventCache();
    SongRegistry.instance.loadEntries();
    CharacterDataParser.loadCharacterCache();
    NoteKindManager.initialize();
  }

  function initModules():Void
  {
    ModuleHandler.loadModuleCache();
    ModuleHandler.callOnCreate();
  }

  /**
   * Move to the title screen state once we are done with the hot reload.
   */
  function moveToTitleState():Void
  {
    if (transitioning) return;
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
