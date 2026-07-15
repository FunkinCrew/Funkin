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
import funkin.data.stage.StageRegistry;
import funkin.data.stickers.StickerRegistry;
import funkin.data.story.level.LevelRegistry;
import funkin.graphics.FunkinSprite;
import funkin.modding.module.ModuleHandler;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.title.TitleState;
import funkin.util.MathUtil;
import lime.app.Future;
import polymod.Polymod;

/**
 * Use this state to reload all the game's data and assets.
 * Use when pressing F5 (to force a hot reload) or when the mod list has updated.
 */
@:nullSafety
class HotReloadState extends MusicBeatState
{
  var targetState:Null<NextState> = null;
  var hasStartedLoading:Bool = false;
  var isComplete:Bool = false;
  var transitioning:Bool = false;
  var progressBar:FunkinSprite;

  public function new(?targetState:NextState)
  {
    super();

    this.targetState = targetState;
    this.progressBar = new FunkinSprite(0, FlxG.height - 24).makeSolidColor(10, 12, 0xFFFF16D2);
  }

  override public function create():Void
  {
    super.create();

    this.progressBar.zIndex = 200;
    add(progressBar);

    updateProgress(0, 10);
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
      // funkin.modding.PolymodHandler.loadEnabledMods();

      var future = loadRegistryData();

      future.onProgress((loaded:Int, total:Int) ->
      {
        updateProgress(loaded, total);
      });

      future.onComplete((_) ->
      {
        loadAdditionalData();

        initModules();

        isComplete = true;
      });
    }

    if (isComplete)
    {
      moveToTitleState();
    }
  }

  function updateProgress(loaded:Int, total:Int):Void
  {
    var currentProgress:Float = (loaded / total).clamp(0, 1);

    // Update progress bar display.
    var currentWidth:Float = progressBar.width;
    var targetWidth:Float = FlxG.width * currentProgress;

    progressBar.x = 0;
    progressBar.setGraphicSize(targetWidth, 24);
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
